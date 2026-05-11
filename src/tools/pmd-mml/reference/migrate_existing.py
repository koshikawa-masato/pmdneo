#!/usr/bin/env python3
"""
既存の voice-test/*/voice-*.mml を一括 measure → local DB へ migration (= ADR-0005 S)
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))
from measure import measure_one, PROJECT_ROOT

VOICE_TEST_DIR = PROJECT_ROOT / 'src/tools/pmd-mml/reference/pmddotnet/voice-test'

# dir 名 → category + tag mapping
CATEGORY_MAP = {
    'tl-step': ('voice/single/param-step', ['TL', 'alg-0', 'carrier']),
    'ar-step': ('voice/single/param-step', ['AR', 'alg-0', 'carrier']),
    'dr-step': ('voice/single/param-step', ['DR', 'alg-0', 'carrier']),
    'ml-step': ('voice/single/param-step', ['ML', 'alg-0', 'carrier']),
    'alg-step': ('voice/single/param-grid', ['alg', 'topology']),
    'fbl-step': ('voice/single/param-step', ['fbl', 'op1', 'feedback']),
}


def main():
    total = 0
    success = 0
    fail = 0
    for subdir in sorted(VOICE_TEST_DIR.iterdir()):
        if not subdir.is_dir() or subdir.name not in CATEGORY_MAP:
            continue
        category, tags = CATEGORY_MAP[subdir.name]
        for mml in sorted(subdir.glob('voice-*.mml')):
            total += 1
            print(f'[{total:>3}] {subdir.name}/{mml.name} ...', end=' ', flush=True)
            try:
                result = measure_one(mml, category, tags, skip_mame=True)
                if 'error' in result:
                    fail += 1
                    print(f'FAIL: {result["error"]}')
                else:
                    success += 1
                    summary = result['run']['expected_summary']
                    print(f'OK rms={summary["rms_L"]:.1f} peak={summary["peak_L"]} duration={summary["duration_sec"]:.2f}s')
            except Exception as e:
                fail += 1
                print(f'EXC: {e}')
                import traceback
                traceback.print_exc()
    print()
    print(f'=== migration 結果: {success}/{total} success、 {fail} fail ===')


if __name__ == '__main__':
    main()
