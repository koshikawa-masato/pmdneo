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


def parse_used_parts(mml_bytes: bytes) -> set:
    """MML から使用 part letter (= A-Q + X/Y/Z) を検出して返す

    判定: 各 letter 単独で行頭にあり、 直後が tab/space/letter+1 列目で
    note/cmd を含む行を「使用 part 行」 とみなす。 PMDDotNET MML 慣例で
    複数 letter 並列 (= "BCEFI v15 ...") も使用 part として認識。
    """
    used = set()
    # 行頭 1 文字 or 連続 letter 列 + whitespace を含む行が part 宣言
    # 例: "A\tv15 ..." / "BCEFI v15 ..." / "G v15 q1 ..."
    part_re = re.compile(rb'^([A-QXYZ]+)[\t ]')
    for raw in mml_bytes.split(b'\r\n'):
        # comment / directive / voice 定義行は skip
        if not raw or raw.startswith(b';') or raw.startswith(b'#') or raw.startswith(b'@'):
            continue
        m = part_re.match(raw)
        if not m:
            continue
        # 行 body (= part letter 以降) が note/cmd を含むか確認 (= 空 part 表記行を除外)
        body = raw[m.end():].strip()
        if not body:
            continue
        for letter_byte in m.group(1):
            used.add(chr(letter_byte))
    return used


def choose_marker_host(used: set, target_chip: str = 'ym2610') -> tuple[str, str]:
    """ADR-0006 §F priority で marker host part を 1 つ選定

    priority: SSG 空 (G/H/I) → FM 空 (B/C/E/F、 ym2610b で A/D 含む) → ADPCM-A 系 fallback

    return: (chip_type, host_letter) tuple
        chip_type ∈ {'SSG', 'FM', 'ADPCM'}
        host_letter ∈ {'A'..'Q'}

    K (= rhythm、 driver mute) と X/Y/Z (= FM3Extend、 driver mute) は候補外。
    """
    ssg_candidates = ['G', 'H', 'I']
    fm_candidates = ['B', 'C', 'E', 'F']
    if target_chip == 'ym2610b':
        fm_candidates = ['A', 'B', 'C', 'D', 'E', 'F']
    adpcm_candidates = ['L', 'M', 'N', 'O', 'P', 'Q']

    for p in ssg_candidates:
        if p not in used:
            return ('SSG', p)
    for p in fm_candidates:
        if p not in used:
            return ('FM', p)
    for p in adpcm_candidates:
        if p not in used:
            return ('ADPCM', p)
    raise RuntimeError(f'全 part 使用中、 marker host 確保失敗 (= used={sorted(used)})')


def inject_marker(mml_bytes: bytes, target_chip: str = 'ym2610') -> bytes:
    """marker click を MML に動的注入 (= ADR-0006 §F、 ADR-0005 W 破棄)

    手順:
        1. 入力 MML を parse して使用 part を検出
        2. ADR-0006 §F priority で marker host part を動的選定
        3. SSG host: voice 定義不要、 envelope default で click 出す
           FM host: 既存 @099 FM voice 定義を注入 + host part 行に @99 click
           ADPCM host: 当面 NotImplementedError (= 想定外 fallback)
        4. #Zenlen 192 を #Memo 直後に強制 (= duration 予測前提)
    """
    used = parse_used_parts(mml_bytes)
    chip_type, host = choose_marker_host(used, target_chip)
    if chip_type == 'ADPCM':
        raise NotImplementedError(
            f'ADPCM host marker (= {host}) は当面非対応 (= SSG + FM 全埋まりは異常想定)'
        )

    lines = mml_bytes.split(b'\r\n')
    new_lines = []
    inserted_zenlen = False
    inserted_voice = False
    inserted_host = False

    # FM host のみ voice 定義注入 (= 既存 @099 FM 4 slot)
    marker_voice = [
        b'',
        '; marker @099 (= ADR-0006 §F dynamic host、 FM click)'.encode('shift_jis'),
        b'@099 007 005',
        b'; ar  dr  sr  rr  sl  tl  ks  ml  dt ams\tmarker click',
        b' 031 031 000 015 015 000 000 008 003 000',
        b' 031 031 000 015 015 000 000 008 003 000',
        b' 031 031 000 015 015 000 000 008 003 000',
        b' 031 031 000 015 015 000 000 008 003 000',
    ]
    host_byte = host.encode('ascii')
    if chip_type == 'FM':
        marker_host_line = host_byte + b'\t@99 v15 q1 o8 c%2 r%2'
    else:  # SSG
        marker_host_line = host_byte + b'\tv15 q1 o8 c%2 r%2'

    # 注入 anchor: 既存 part 行 (= host 含む可能性) のいずれか最初の行
    # 既存 host 行があれば その前に marker 行を差し込み (= 元 host 行と共存)
    part_anchor_re = re.compile(rb'^[A-QXYZ]+[\t ]')

    for i, line in enumerate(lines):
        if not inserted_zenlen and line.startswith(b'#Memo'):
            new_lines.append(line)
            if i + 1 < len(lines) and not lines[i+1].startswith(b'#Zenlen'):
                new_lines.append(b'#Zenlen\t\t192')
            inserted_zenlen = True
            continue
        if line.startswith(b'#Zenlen'):
            new_lines.append(b'#Zenlen\t\t192')
            inserted_zenlen = True
            continue
        # FM host のみ voice 定義注入: 最初の @ 定義 行の前
        if chip_type == 'FM' and not inserted_voice and re.match(rb'^@\d+\s', line):
            new_lines.extend(marker_voice)
            new_lines.append(b'')
            inserted_voice = True
        # marker host 行注入: 最初の part 行の前
        if not inserted_host and part_anchor_re.match(line):
            new_lines.append(marker_host_line)
            inserted_host = True
        new_lines.append(line)

    # part 行が 1 つも無い MML (= 想定外) には末尾に host 行追加
    if not inserted_host:
        if chip_type == 'FM' and not inserted_voice:
            new_lines.extend(marker_voice)
        new_lines.append(marker_host_line)

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


# ---- PMDNEO MAME 経路 (= ADR-0006 §5 検証) ----

MAME_TRACE_DIR = Path('/tmp/pmdneo-trace')


def render_mame(injected_mml_path: Path, duration_sec: float, target_chip: str, work_dir: Path) -> Path:
    """PMDNEO driver で ROM build + MAME headless 録音、 wav path 返す

    build-poc.sh が MML_INPUTS env で absolute path を受け入れる仕様 (= scripts/build-poc.sh:96-100) を使う。
    出力 wav は /tmp/pmdneo-trace/audio.wav に書かれる。
    """
    wav_seconds = max(8, int(duration_sec) + 3)
    env = os.environ.copy()
    env['MML_INPUTS'] = str(injected_mml_path)
    env['PMDNEO_CHIP'] = target_chip
    # --gamerom lastbld2 = ADR-0010 sprint で確立した PMDNEO 正規 gamerom (引継書 §1.D)
    result = subprocess.run(
        [
            'bash', str(PROJECT_ROOT / 'scripts' / 'run-mame.sh'),
            '--build', '--headless', '--wavwrite',
            '--wavwrite-seconds', str(wav_seconds),
            '--chip', target_chip,
            '--gamerom', 'lastbld2',
        ],
        env=env,
        capture_output=True,
        text=True,
        cwd=str(PROJECT_ROOT),
        timeout=240,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f'run-mame.sh failed: rc={result.returncode}\n'
            f'stdout tail:\n{result.stdout[-800:]}\n'
            f'stderr tail:\n{result.stderr[-800:]}'
        )
    src_wav = MAME_TRACE_DIR / 'audio.wav'
    if not src_wav.exists():
        raise RuntimeError(
            f'MAME wav not produced: {src_wav}\n'
            f'stdout tail:\n{result.stdout[-800:]}'
        )
    out_wav = work_dir / f'{injected_mml_path.stem}__mame.wav'
    shutil.copyfile(src_wav, out_wav)
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

def measure_one(mml_path: Path, category: str, tags: list[str], skip_mame: bool = False, target_chip: str = 'ym2610') -> dict:
    """1 entry の measure flow"""
    entry_id = mml_path.stem  # voice-tl-10 等

    with open(mml_path, 'rb') as f:
        original_mml_bytes = f.read()

    # 1. marker 注入 (= ADR-0006 §F dynamic host)
    injected_bytes = inject_marker(original_mml_bytes, target_chip=target_chip)

    match = None
    wav_mame_blob = None
    mat_mame_blob = None
    analysis_mame = None

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

        # 7. PMDNEO MAME 経路 (= ADR-0006 §5 検証、 skip_mame=False で実行)
        if not skip_mame:
            print(f'  MAME path: build + headless wav record (chip={target_chip})...', file=sys.stderr)
            wav_mame_tmp = render_mame(injected_mml_path, duration_sec, target_chip, tmpdir)
            try:
                analysis_mame = analyze_full(wav_mame_tmp)
            except Exception as e:
                print(f'  WARN: MAME wav analyze failed: {e}', file=sys.stderr)
                analysis_mame = None
            wav_mame_blob = BLOB_DIR / f'{entry_id}__mame_{target_chip}.wav'
            mat_mame_blob = BLOB_DIR / f'{entry_id}__mame_{target_chip}.mat'
            shutil.copyfile(wav_mame_tmp, wav_mame_blob)
            if analysis_mame is not None:
                match = align_and_match(wav_pmd_blob, wav_mame_blob)

    # MML text を JSON safe に decode
    try:
        mml_text = original_mml_bytes.decode('shift_jis')
    except:
        mml_text = original_mml_bytes.decode('shift_jis', errors='replace')

    # voice_def 抽出 (= simple parse)
    voice_def = extract_voice_def(mml_text)

    save_mat(mat_pmd_blob, analysis_pmd, voice_def, mml_text)
    if analysis_mame is not None and mat_mame_blob is not None:
        save_mat(mat_mame_blob, analysis_mame, voice_def, mml_text)

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

    actual_summary = None
    if analysis_mame is not None:
        actual_summary = {
            'rms_L': analysis_mame['rms_L'],
            'peak_L': analysis_mame['peak_L'],
            'fft_top5_hz': analysis_mame['fft_top5_hz'],
            'duration_sec': analysis_mame['duration_sec'],
            'marker_peak_sample': analysis_mame['marker_peak_sample'],
        }

    run = {
        'entry_id': entry_id,
        'ran_at': now,
        'driver_commit': driver_commit,
        'target_chip': target_chip,
        'data_files': {
            'wav_pmddotnet': f'blob/{wav_pmd_blob.name}',
            'mat_pmddotnet': f'blob/{mat_pmd_blob.name}',
            'wav_mame': f'blob/{wav_mame_blob.name}' if wav_mame_blob else None,
            'mat_mame': f'blob/{mat_mame_blob.name}' if mat_mame_blob else None,
            'plot_dir': None,
        },
        'expected_summary': {
            'rms_L': analysis_pmd['rms_L'],
            'peak_L': analysis_pmd['peak_L'],
            'fft_top5_hz': analysis_pmd['fft_top5_hz'],
            'duration_sec': analysis_pmd['duration_sec'],
            'marker_peak_sample': analysis_pmd['marker_peak_sample'],
        },
        'actual_summary': actual_summary,
        'match': {'verdict': 'NOT_TESTED'} if skip_mame or match is None else match,
        'tool_versions': {
            'pmddotnet': '4.8s',
            'pmdplay': 'SDL 2022-07-26',
            'mame': 'mame-fork' if not skip_mame else None,
            'scipy': '1.x',
        },
        'analysis_version': '1.2',  # measure.py の解析 logic version (= MAME path 実装)
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
    # ADR-0006 §5 検証: default は MAME 経路を回す (= --skip-mame で PMDDotNET reference のみ取得に切替)
    parser.add_argument('--skip-mame', action='store_true', default=False)
    parser.add_argument(
        '--chip',
        choices=['ym2610', 'ym2610b'],
        default=os.environ.get('PMDNEO_TARGET_CHIP', 'ym2610'),
        help='target chip (= ADR-0006 §B、 marker host 候補に影響)',
    )
    args = parser.parse_args()

    tags = [t.strip() for t in args.tags.split(',') if t.strip()]
    # mml_path は CLI で相対指定されることがある、 PROJECT_ROOT.relative_to() 用に absolute 化
    mml_path = args.mml_path.resolve()
    entry = measure_one(mml_path, args.category, tags, skip_mame=args.skip_mame, target_chip=args.chip)
    print(json.dumps(entry, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
