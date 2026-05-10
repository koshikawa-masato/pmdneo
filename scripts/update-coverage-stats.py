import re
import subprocess
import sys
from pathlib import Path

TOTAL = 142  # PMDMML total command count


def count_com_routines(source_text):
    # 全 com* routine (= 大文字 + underscore + 数字含む) を抽出
    all_routines = re.findall(r'^(com[a-zA-Z0-9_]+):', source_text, re.MULTILINE)
    # sub-label (= dispatch jump target / internal control flow) を除外
    # PMDMML cmd handler のみ count
    handlers = []
    for r in all_routines:
        # commandsp + commandsp_* = dispatch table + jump target
        if r.startswith('commandsp'):
            continue
        # *_done / *_repeat / *_skip = internal control flow
        if r.endswith('_done') or r.endswith('_repeat') or r.endswith('_skip'):
            continue
        # *force_reloop* = loop force path
        if 'force_reloop' in r:
            continue
        handlers.append(r)
    return len(handlers)


def get_main_routine_count():
    # Get PMD_Z80.inc from commit df4e7b6 (main HEAD baseline)
    result = subprocess.run(
        ['git', 'show', 'df4e7b6:src/driver/PMD_Z80.inc'],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return 0
    return count_com_routines(result.stdout)


def get_pmdneo_routine_count():
    p = Path('src/driver/standalone_test.s')
    if not p.exists():
        return 0
    return count_com_routines(p.read_text())


def get_main_info():
    h = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'], text=True).strip()
    d = subprocess.check_output(
        ['git', 'log', '-1', '--format=%ad', '--date=short'],
        text=True,
    ).strip()
    return h, d


def update_marker(html, marker_name, new_value):
    pattern = rf'(<!-- {marker_name} -->).*?(<!-- /{marker_name} -->)'
    return re.sub(pattern, lambda m: f'{m.group(1)}{new_value}{m.group(2)}', html, flags=re.DOTALL)


def main():
    html_path = Path('pages/pmdmml-coverage.html')
    if not html_path.exists():
        print(f'ERROR: {html_path} not found', file=sys.stderr)
        sys.exit(1)

    pmd_count = get_main_routine_count()  # PMD V4.8s 本家 (= df4e7b6 reference)
    pmdneo_count = get_pmdneo_routine_count()  # PMDNEO 自作 driver (= main HEAD)
    main_hash, main_date = get_main_info()

    pmd_pct = round(pmd_count / TOTAL * 100)
    pmdneo_pct = round(pmdneo_count / TOTAL * 100)
    last_update = f'{main_date} main {main_hash}'

    html = html_path.read_text(encoding='utf-8')
    # AUTO_MAIN_* マーカーは「PMD 本家集計」 を保持 (= 表頭 rename 後も意味継続)
    html = update_marker(html, 'AUTO_MAIN_COUNT', str(pmd_count))
    html = update_marker(html, 'AUTO_MAIN_PERCENT', str(pmd_pct))
    html = update_marker(
        html,
        'AUTO_MAIN_BAR_STYLE',
        f'<div class="progress-bar" style="width: {pmd_pct}%"></div>',
    )
    # AUTO_DEVELOP_* マーカーは「PMDNEO 自作集計」 を保持 (= main HEAD 反映)
    html = update_marker(html, 'AUTO_DEVELOP_COUNT', str(pmdneo_count))
    html = update_marker(html, 'AUTO_DEVELOP_PERCENT', str(pmdneo_pct))
    html = update_marker(
        html,
        'AUTO_DEVELOP_BAR_STYLE',
        f'<div class="progress-bar develop" style="width: {pmdneo_pct}%"></div>',
    )
    html = update_marker(html, 'AUTO_LAST_UPDATE', last_update)
    html_path.write_text(html, encoding='utf-8')

    print(f'Updated: PMD 本家={pmd_count} ({pmd_pct}%), PMDNEO 自作={pmdneo_count} ({pmdneo_pct}%)')
    print(f'Last update stamp: {last_update}')


if __name__ == '__main__':
    main()
