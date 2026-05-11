#!/usr/bin/env python3
"""
PMD 音色検証 local DB の measure script (= ADR-0005)

PMDDotNET → pmdplay 経路で reference WAV を取得し、 1ms 解像度で全指標解析、
JSONL manifest + blob (wav + mat) として local DB に蓄積する。

CLI:
    python3 measure.py <mml_path> [--category=...] [--tags=...] [--skip-mame]

依存:
    - dotnet (= PMDDotNETConsole.dll)
    - pmdplay (= SDL 2022-07-26)
    - scipy + numpy
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import scipy.io.wavfile as wf
from scipy.io import savemat

PROJECT_ROOT = Path('/Users/koshikawamasato/Projects/pmdneo')
DATA_DIR = PROJECT_ROOT / 'data'
BLOB_DIR = DATA_DIR / 'blob'
MANIFEST_PATH = DATA_DIR / 'manifest.jsonl'   # entry 定義 (= 不変、 同 id は上書き)
RUNS_PATH = DATA_DIR / 'runs.jsonl'           # 測定 run 履歴 (= append-only)
PMDDOTNET_DIR = PROJECT_ROOT / 'vendor' / 'PMDDotNET'
PMDDOTNET_DLL = PMDDOTNET_DIR / 'PMDDotNETConsole' / 'bin' / 'Debug' / 'net6.0' / 'PMDDotNETConsole.dll'


# ---- MML 解析 ----

def predict_duration_clock(mml_text_shiftjis_bytes: bytes, compile_log: str) -> tuple[int, int]:
    """compile log の Length 値と MML 内の tempo / Zenlen を読んで (max_clock, tempo) 返す"""
    # Length: NNNN
    lengths = [int(m) for m in re.findall(r'Length\s*:\s*(\d+)', compile_log)]
    max_clock = max(lengths) if lengths else 0
    # tempo: t75 等
    text = mml_text_shiftjis_bytes.decode('shift_jis', errors='replace')
    tempo_match = re.search(r'\bt\s*(\d+)', text)
    tempo = int(tempo_match.group(1)) if tempo_match else 75  # default 75
    return max_clock, tempo


def predict_duration_sec(max_clock: int, tempo: int, zenlen: int = 192) -> float:
    """duration = total_clock × 60 / (tempo × 48) (= ADR-0005 Q 公式、 Zenlen 192 想定)"""
    if max_clock == 0:
        return 5.0
    # 1 全音符 = Zenlen clock、 default Zenlen 192 で 内部 clock 48 = 4 分音符
    # tempo は「内部 clock 48 が 1 分間に何回」 = 4 分音符 / 分
    sec = max_clock * 60.0 / (tempo * 48)
    return sec


def inject_marker(mml_bytes: bytes) -> bytes:
    """marker 音色 @99 と A part click を MML に注入 (= ADR-0005 P/T/W)

    挿入位置:
        - #Memo の次に #Zenlen 192 と marker 音色定義
        - 1 つ目の B/C/I 行の前に A 行 (marker + rest) を挿入
    """
    lines = mml_bytes.split(b'\r\n')
    new_lines = []
    inserted_zenlen = False
    inserted_voice = False
    inserted_apart = False

    marker_voice = [
        b'',
        b'; marker @099 (= ADR-0005 click)',
        b'@099 007 005',
        b'; ar  dr  sr  rr  sl  tl  ks  ml  dt ams\tmarker click',
        b' 031 031 000 015 015 000 000 008 003 000',
        b' 031 031 000 015 015 000 000 008 003 000',
        b' 031 031 000 015 015 000 000 008 003 000',
        b' 031 031 000 015 015 000 000 008 003 000',
    ]
    marker_apart = b'A\t@99 v15 q1 o8 c%2 r%2'

    for i, line in enumerate(lines):
        # #Zenlen 192 を #Memo の直後に挿入 (= 既存 #Zenlen があれば skip)
        if not inserted_zenlen and line.startswith(b'#Memo'):
            new_lines.append(line)
            # 次行確認、 既に #Zenlen があれば skip
            if i + 1 < len(lines) and not lines[i+1].startswith(b'#Zenlen'):
                new_lines.append(b'#Zenlen\t\t192')
            inserted_zenlen = True
            continue
        # 既存 #Zenlen は値を 192 に上書き
        if line.startswith(b'#Zenlen'):
            new_lines.append(b'#Zenlen\t\t192')
            inserted_zenlen = True
            continue
        # marker 音色定義: 最初の @ 定義 (= @001 等) の前に挿入
        if not inserted_voice and re.match(rb'^@\d+\s', line):
            new_lines.extend(marker_voice)
            new_lines.append(b'')
            inserted_voice = True
        # A part 注入: 最初の B/C/D/E/F/I 行の前に挿入 (= 既存 A 行があれば skip)
        if not inserted_apart and re.match(rb'^[BCDEFI]\s', line):
            # 既存 A 行があるか前を見直し
            existing_a = any(re.match(rb'^A\s', l) for l in new_lines)
            if not existing_a:
                new_lines.append(marker_apart)
            inserted_apart = True
        new_lines.append(line)

    return b'\r\n'.join(new_lines)


# ---- PMDDotNET 経路 ----

def compile_pmddotnet(mml_path: Path, work_dir: Path) -> tuple[Path, str]:
    """PMDDotNET で compile、 .M file path と log を返す

    PMDDotNET dir に MML を temporary copy → cwd=PMDDotNET_DIR で dotnet 実行
    → 同 dir に .M 生成、 work_dir に move
    """
    out_m = work_dir / (mml_path.stem + '.M')
    # PMDDotNET dir に temp copy (= dotnet が same dir に .M 出力)
    pmd_mml = PMDDOTNET_DIR / mml_path.name
    shutil.copyfile(mml_path, pmd_mml)
    try:
        cmd = ['dotnet', str(PMDDOTNET_DLL), '/v', '/C', mml_path.name]
        result = subprocess.run(cmd, cwd=PMDDOTNET_DIR, capture_output=True, text=True)
        log = result.stdout + result.stderr
        # 生成された .M を work_dir に move
        generated_m = PMDDOTNET_DIR / (mml_path.stem + '.M')
        if generated_m.exists():
            shutil.move(str(generated_m), str(out_m))
        return out_m, log
    finally:
        pmd_mml.unlink(missing_ok=True)


def render_pmdplay(m_path: Path, duration_sec: float, work_dir: Path) -> Path:
    """pmdplay で WAV 録音"""
    out_wav = work_dir / (m_path.stem + '.wav')
    # pmdplay -s は整数のみ対応想定、 ceil
    sec = max(1, int(duration_sec) + 1)
    cmd = ['pmdplay', '-w', str(out_wav), '-s', str(sec), str(m_path)]
    subprocess.run(cmd, capture_output=True, text=True)
    return out_wav


# ---- 解析 ----

def detect_marker_peak(L: np.ndarray, sr: int, search_ms: int = 300) -> int:
    """先頭 search_ms 以内で最大 peak (= marker click) sample idx 返す"""
    n = min(len(L), int(sr * search_ms / 1000))
    return int(np.argmax(np.abs(L[:n])))


def analyze_full(wav_path: Path, trim_marker: bool = True, body_start_ms: int = 100) -> dict:
    """1ms 解像度で全指標計測

    trim_marker: True なら marker peak を検出 + body_start_ms 後を「本体」 とする
    """
    sr, data = wf.read(str(wav_path))
    if data.ndim == 1:
        L = data.astype(np.float64)
        R = L
    else:
        L = data[:, 0].astype(np.float64)
        R = data[:, 1].astype(np.float64) if data.shape[1] > 1 else L

    raw_full = data
    marker_idx = 0
    if trim_marker:
        marker_idx = detect_marker_peak(L, sr)
        body_start = marker_idx + int(sr * body_start_ms / 1000)
        L = L[body_start:]
        R = R[body_start:]

    rms_L = float(np.sqrt(np.mean(L ** 2))) if len(L) > 0 else 0.0
    peak_L = int(np.max(np.abs(L))) if len(L) > 0 else 0

    # 1ms 解像度 envelope follower (= window = sr/1000 samples)
    win = max(1, sr // 1000)
    n_chunks = len(L) // win
    env_1ms = np.array([
        float(np.sqrt(np.mean(L[i*win:(i+1)*win] ** 2)))
        for i in range(n_chunks)
    ])

    # FFT (= 0.5-2.0 sec sustain or 全範囲 短い場合)
    start = min(sr // 2, len(L) // 4)  # 0.5 sec or 25%
    end = min(sr * 2, len(L))
    chunk = L[start:end]
    if len(chunk) > 100:
        fft = np.fft.rfft(chunk * np.hanning(len(chunk)))
        fft_mag = np.abs(fft).astype(np.float32)
        fft_freq = np.fft.rfftfreq(len(chunk), 1.0 / sr).astype(np.float32)
        # 上位 5 peak
        top5 = np.argpartition(fft_mag, -5)[-5:]
        top5 = top5[np.argsort(-fft_mag[top5])]
        fft_top5_hz = [float(fft_freq[i]) for i in top5]
    else:
        fft_mag = np.array([], dtype=np.float32)
        fft_freq = np.array([], dtype=np.float32)
        fft_top5_hz = []

    return {
        'sample_rate': int(sr),
        'duration_sec': float(len(L) / sr),
        'raw_L': raw_full,
        'marker_peak_sample': marker_idx,
        'body_start_sample': marker_idx + int(sr * body_start_ms / 1000) if trim_marker else 0,
        'rms_L': rms_L,
        'peak_L': peak_L,
        'envelope_1ms': env_1ms,
        'fft_freq': fft_freq,
        'fft_mag': fft_mag,
        'fft_top5_hz': fft_top5_hz,
    }


def save_mat(mat_path: Path, analysis: dict, voice_def: dict, mml_text: str):
    """解析結果を MATLAB 互換 .mat で保存"""
    matdict = {
        'sample_rate': analysis['sample_rate'],
        'raw_L': analysis['raw_L'],
        'rms_L': analysis['rms_L'],
        'peak_L': analysis['peak_L'],
        'envelope_1ms': analysis['envelope_1ms'],
        'fft_freq': analysis['fft_freq'],
        'fft_mag': analysis['fft_mag'],
        'fft_top5_hz': np.array(analysis['fft_top5_hz']),
        'voice_def_json': json.dumps(voice_def),
        'mml_text': mml_text,
    }
    savemat(str(mat_path), matdict, do_compression=True)


# ---- 合致判定 (= L6) ----

def align_and_match(wav_pmd: Path, wav_mame: Path) -> dict:
    """marker 検出 + align + L1/L3/L4 計算"""
    # TODO: marker detection (= 高域 onset detect) + align
    # 現状 placeholder: 単純比較
    sr_p, dat_p = wf.read(str(wav_pmd))
    sr_m, dat_m = wf.read(str(wav_mame))
    if dat_p.ndim > 1:
        L_p = dat_p[:, 0].astype(np.float64)
    else:
        L_p = dat_p.astype(np.float64)
    if dat_m.ndim > 1:
        L_m = dat_m[:, 0].astype(np.float64)
    else:
        L_m = dat_m.astype(np.float64)
    n = min(len(L_p), len(L_m))
    L_p = L_p[:n]
    L_m = L_m[:n]

    # L1 cross-correlation (= normalized)
    norm_p = np.sqrt(np.sum(L_p ** 2))
    norm_m = np.sqrt(np.sum(L_m ** 2))
    L1 = float(np.sum(L_p * L_m) / (norm_p * norm_m + 1e-12))

    # L3 spectral cosine
    fft_p = np.abs(np.fft.rfft(L_p * np.hanning(n)))
    fft_m = np.abs(np.fft.rfft(L_m * np.hanning(n)))
    L3 = float(np.dot(fft_p, fft_m) / (np.linalg.norm(fft_p) * np.linalg.norm(fft_m) + 1e-12))

    # L4 envelope correlation (= 1ms 刻み RMS の Pearson)
    win = sr_p // 1000
    n_chunks = n // win
    env_p = np.array([np.sqrt(np.mean(L_p[i*win:(i+1)*win] ** 2)) for i in range(n_chunks)])
    env_m = np.array([np.sqrt(np.mean(L_m[i*win:(i+1)*win] ** 2)) for i in range(n_chunks)])
    if np.std(env_p) > 0 and np.std(env_m) > 0:
        L4 = float(np.corrcoef(env_p, env_m)[0, 1])
    else:
        L4 = 0.0

    thresholds = {'L1': 0.90, 'L3': 0.95, 'L4': 0.90}
    verdict = 'PASS' if (L1 >= thresholds['L1'] and L3 >= thresholds['L3'] and L4 >= thresholds['L4']) else 'FAIL'
    return {
        'L1_xcorr': L1,
        'L3_spectral': L3,
        'L4_envelope': L4,
        'thresholds': thresholds,
        'verdict': verdict,
    }


# ---- DB 操作 ----

def add_to_manifest(entry: dict):
    """manifest.jsonl の entry 定義を upsert (= 同 id は置換、 entry の不変属性のみ)"""
    entries = []
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                e = json.loads(line)
                if e.get('id') != entry['id']:
                    entries.append(e)
    entries.append(entry)
    with open(MANIFEST_PATH, 'w') as f:
        for e in entries:
            f.write(json.dumps(e, ensure_ascii=False) + '\n')


def add_to_runs(run: dict):
    """runs.jsonl に append-only で 1 行追加 (= 過去 run 履歴を保持)"""
    with open(RUNS_PATH, 'a') as f:
        f.write(json.dumps(run, ensure_ascii=False) + '\n')


def get_driver_commit() -> str:
    try:
        result = subprocess.run(['git', '-C', str(PROJECT_ROOT), 'rev-parse', '--short', 'HEAD'],
                                capture_output=True, text=True)
        return result.stdout.strip()
    except:
        return 'unknown'


# ---- main flow ----

def measure_one(mml_path: Path, category: str, tags: list[str], skip_mame: bool = False) -> dict:
    """1 entry の measure flow"""
    entry_id = mml_path.stem  # voice-tl-10 等

    with open(mml_path, 'rb') as f:
        original_mml_bytes = f.read()

    # 1. marker 注入
    injected_bytes = inject_marker(original_mml_bytes)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        # injected MML を別名で work dir に書く
        injected_mml_path = tmpdir / f'{entry_id}__injected.mml'
        injected_mml_path.write_bytes(injected_bytes)

        # 2. PMDDotNET compile
        m_path, log = compile_pmddotnet(injected_mml_path, tmpdir)

        # 3. duration 予測
        max_clock, tempo = predict_duration_clock(injected_bytes, log)
        duration_sec = predict_duration_sec(max_clock, tempo)

        # 4. pmdplay render
        wav_pmd_tmp = render_pmdplay(m_path, duration_sec + 1, tmpdir)

        # 5. 解析
        try:
            analysis_pmd = analyze_full(wav_pmd_tmp)
        except Exception as e:
            print(f'  WARN: analyze failed: {e}', file=sys.stderr)
            return {'id': entry_id, 'error': str(e)}

        # 6. blob に保存
        wav_pmd_blob = BLOB_DIR / f'{entry_id}__pmddotnet.wav'
        mat_pmd_blob = BLOB_DIR / f'{entry_id}__pmddotnet.mat'
        shutil.copyfile(wav_pmd_tmp, wav_pmd_blob)

    # MML text を JSON safe に decode
    try:
        mml_text = original_mml_bytes.decode('shift_jis')
    except:
        mml_text = original_mml_bytes.decode('shift_jis', errors='replace')

    # voice_def 抽出 (= simple parse)
    voice_def = extract_voice_def(mml_text)

    save_mat(mat_pmd_blob, analysis_pmd, voice_def, mml_text)

    # 7. MAME 経路 (= --skip-mame で skip)
    match = None
    wav_mame_blob = None
    mat_mame_blob = None
    if not skip_mame:
        # TODO: ROM build + MAME 録音 + 比較 (別 sprint で実装)
        pass

    # 8. manifest entry (= 不変属性のみ) と run (= この測定の verdict + tool 状態) を分離
    import datetime
    now = datetime.datetime.now().isoformat(timespec='seconds')
    driver_commit = get_driver_commit()

    entry = {
        'id': entry_id,
        'category': category,
        'tags': tags,
        'voice_def': voice_def,
        'mml_pattern': {
            'tempo': tempo,
            'zenlen': 192,
            'max_clock': max_clock,
            'predicted_duration_sec': duration_sec,
        },
        'source_mml_repo_path': str(mml_path.relative_to(PROJECT_ROOT)),
        'schema_version': 2,  # F3 reform 後
    }
    add_to_manifest(entry)

    run = {
        'entry_id': entry_id,
        'ran_at': now,
        'driver_commit': driver_commit,
        'data_files': {
            'wav_pmddotnet': f'blob/{wav_pmd_blob.name}',
            'mat_pmddotnet': f'blob/{mat_pmd_blob.name}',
            'wav_mame': None,
            'mat_mame': None,
            'plot_dir': None,
        },
        'expected_summary': {
            'rms_L': analysis_pmd['rms_L'],
            'peak_L': analysis_pmd['peak_L'],
            'fft_top5_hz': analysis_pmd['fft_top5_hz'],
            'duration_sec': analysis_pmd['duration_sec'],
            'marker_peak_sample': analysis_pmd['marker_peak_sample'],
        },
        'match': {'verdict': 'NOT_TESTED'} if skip_mame else match,
        'tool_versions': {
            'pmddotnet': '4.8s',
            'pmdplay': 'SDL 2022-07-26',
            'mame': None,
            'scipy': '1.x',
        },
        'analysis_version': '1.1',  # measure.py の解析 logic version
        'trim_policy': {'body_start_ms': 100, 'method': 'marker_peak_offset'},
    }
    add_to_runs(run)
    return {'entry': entry, 'run': run}


def extract_voice_def(mml_text: str) -> dict:
    """MML text から音色定義を簡易 parse (= @001 ブロック)"""
    voices = {}
    lines = mml_text.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i].strip('\r')
        m = re.match(r'^@(\d+)\s+(\d+)\s+(\d+)', line)
        if m:
            num = int(m.group(1))
            alg = int(m.group(2))
            fbl = int(m.group(3))
            voices[f'@{num:03d}'] = {'alg': alg, 'fbl': fbl, 'ops': []}
            # 次の op×4 を読む (= 直後の op data 行を 4 行)
            j = i + 1
            ops_collected = 0
            while j < len(lines) and ops_collected < 4:
                op_line = lines[j].strip('\r').strip()
                if op_line.startswith(';') or not op_line:
                    j += 1
                    continue
                vals = op_line.split()
                if len(vals) >= 10:
                    op = {
                        'AR': int(vals[0]), 'DR': int(vals[1]), 'SR': int(vals[2]), 'RR': int(vals[3]),
                        'SL': int(vals[4]), 'TL': int(vals[5]), 'KS': int(vals[6]), 'ML': int(vals[7]),
                        'DT': int(vals[8]), 'AMS': int(vals[9]),
                    }
                    voices[f'@{num:03d}']['ops'].append(op)
                    ops_collected += 1
                j += 1
            i = j
            continue
        i += 1
    return voices


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mml_path', type=Path)
    parser.add_argument('--category', default='voice/single/param-step')
    parser.add_argument('--tags', default='')
    parser.add_argument('--skip-mame', action='store_true', default=True)  # 当面 default skip
    args = parser.parse_args()

    tags = [t.strip() for t in args.tags.split(',') if t.strip()]
    entry = measure_one(args.mml_path, args.category, tags, skip_mame=args.skip_mame)
    print(json.dumps(entry, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
