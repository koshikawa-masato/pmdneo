#!/usr/bin/env python3
"""
marker jitter 検証 (= ADR-0005 C3、 Codex review C3)

PMDDotNET → pmdplay 経路で marker-only MML を N 回録音、 各録音の marker peak
sample 位置を測定して jitter (= 標準偏差、 max-min) を算出。 sample 単位で揃うか
検証。

CLI: python3 marker_jitter_test.py [--runs N] [--routes pmddotnet]
"""
import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import scipy.io.wavfile as wf

sys.path.insert(0, str(Path(__file__).parent))
from measure import (
    PROJECT_ROOT, PMDDOTNET_DIR, PMDDOTNET_DLL,
    compile_pmddotnet, render_pmdplay, detect_marker_peak,
)

# marker-only MML (= 本体 melody なし、 A part marker のみ)
MARKER_ONLY_MML = (
    '#Title\t\tmarker-only fixture (= ADR-0005 C3)\r\n'
    '#Composer\tM.Koshikawa.\r\n'
    '#Memo\t\tmarker jitter 検証 fixture\r\n'
    '#Zenlen\t\t192\r\n'
    '\r\n'
    '; marker @099 (= ADR-0005 click)\r\n'
    '@099 007 005\r\n'
    '; ar  dr  sr  rr  sl  tl  ks  ml  dt ams\tmarker click\r\n'
    ' 031 031 000 015 015 000 000 008 003 000\r\n'
    ' 031 031 000 015 015 000 000 008 003 000\r\n'
    ' 031 031 000 015 015 000 000 008 003 000\r\n'
    ' 031 031 000 015 015 000 000 008 003 000\r\n'
    '\r\n'
    'A\t@99 v15 q1 o8 c%2 r%2\r\n'
    'B\tt75 r1\r\n'
).encode('shift_jis')


def run_pmddotnet_once(work_dir: Path, run_idx: int) -> dict:
    mml_path = work_dir / f'marker-fixture-{run_idx:02d}.mml'
    mml_path.write_bytes(MARKER_ONLY_MML)
    m_path, log = compile_pmddotnet(mml_path, work_dir)
    if not m_path.exists():
        return {'run_idx': run_idx, 'error': 'compile failed', 'log_tail': log[-200:]}
    wav_path = render_pmdplay(m_path, 3, work_dir)
    if not wav_path.exists():
        return {'run_idx': run_idx, 'error': 'render failed'}
    sr, data = wf.read(str(wav_path))
    L = data[:, 0].astype(np.float64) if data.ndim > 1 else data.astype(np.float64)
    peak_idx = detect_marker_peak(L, sr)
    peak_val = int(np.abs(L[peak_idx]))
    return {
        'run_idx': run_idx,
        'sample_rate': sr,
        'marker_peak_sample': peak_idx,
        'marker_peak_value': peak_val,
        'marker_peak_ms': peak_idx / sr * 1000,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--runs', type=int, default=5)
    args = parser.parse_args()

    print(f'=== marker jitter test (PMDDotNET 経路、 {args.runs} 回 render) ===\n')
    results = []
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for i in range(args.runs):
            r = run_pmddotnet_once(tmp, i)
            results.append(r)
            if 'error' in r:
                print(f'run {i}: ERROR {r["error"]}')
            else:
                print(f'run {i}: peak_sample={r["marker_peak_sample"]:>6}  peak_ms={r["marker_peak_ms"]:>7.3f}  peak_value={r["marker_peak_value"]}')

    valid = [r for r in results if 'marker_peak_sample' in r]
    if len(valid) < 2:
        print('\n[FAIL] 有効な結果が 2 未満')
        return

    samples = np.array([r['marker_peak_sample'] for r in valid])
    print(f'\n=== jitter 統計 (n={len(valid)}) ===')
    print(f'mean: {samples.mean():.2f} samples')
    print(f'std:  {samples.std():.4f} samples')
    print(f'min:  {samples.min()} samples')
    print(f'max:  {samples.max()} samples')
    print(f'range: {samples.max() - samples.min()} samples ({(samples.max() - samples.min()) / valid[0]["sample_rate"] * 1000:.4f} ms)')
    if samples.std() < 1.0:
        print('\n[PASS] jitter < 1 sample = sample 単位で揃う = align 信頼可')
    elif samples.std() < 48.0:
        print(f'\n[WARN] jitter {samples.std():.2f} samples = 1 ms 未満だが sample 単位ではない')
    else:
        print(f'\n[FAIL] jitter {samples.std():.2f} samples = 1 ms 超 = align 不信頼')


if __name__ == '__main__':
    main()
