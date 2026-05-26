import re
import subprocess
import sys
from pathlib import Path

TOTAL = 142  # PMDMML total command count

# 3 lineage + PMD 本家 reference の集計対象
# (= AUTO_MAIN_* = PMDNEO main、 AUTO_DEVELOP_* = PMDNEO develop、 AUTO_WIP_* = PMDNEO wip、
#    AUTO_PMD_* = PMD V4.8s 本家 reference)
PMDNEO_DRIVER_PATH = 'src/driver/standalone_test.s'
PMD_REFERENCE_PATH = 'src/driver/PMD_Z80.inc'
PMD_REFERENCE_COMMIT = 'df4e7b6'
WIP_BRANCH = 'wip-pmddotnet-opnb-extension'  # 現在の現役開発ブランチ


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


def get_routine_count_at_ref(ref, path):
    # git show <ref>:<path> 経由で任意 branch / commit の file 内容を取得
    result = subprocess.run(
        ['git', 'show', f'{ref}:{path}'],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return 0
    return count_com_routines(result.stdout)


def get_ref_short_hash(ref):
    result = subprocess.run(
        ['git', 'rev-parse', '--short', ref],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return 'unknown'
    return result.stdout.strip()


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

    main_count = get_routine_count_at_ref('main', PMDNEO_DRIVER_PATH)
    develop_count = get_routine_count_at_ref('develop', PMDNEO_DRIVER_PATH)
    wip_count = get_routine_count_at_ref(WIP_BRANCH, PMDNEO_DRIVER_PATH)
    pmd_count = get_routine_count_at_ref(PMD_REFERENCE_COMMIT, PMD_REFERENCE_PATH)
    main_hash, main_date = get_main_info()

    main_pct = round(main_count / TOTAL * 100)
    develop_pct = round(develop_count / TOTAL * 100)
    wip_pct = round(wip_count / TOTAL * 100)
    pmd_pct = round(pmd_count / TOTAL * 100)
    last_update = f'{main_date} main {main_hash}'

    html = html_path.read_text(encoding='utf-8')
    # AUTO_MAIN_* = PMDNEO main HEAD
    html = update_marker(html, 'AUTO_MAIN_COUNT', str(main_count))
    html = update_marker(html, 'AUTO_MAIN_PERCENT', str(main_pct))
    html = update_marker(
        html,
        'AUTO_MAIN_BAR_STYLE',
        f'<div class="progress-bar" style="width: {main_pct}%"></div>',
    )
    # AUTO_DEVELOP_* = PMDNEO develop HEAD (= Phase 12a-4 停止)
    html = update_marker(html, 'AUTO_DEVELOP_COUNT', str(develop_count))
    html = update_marker(html, 'AUTO_DEVELOP_PERCENT', str(develop_pct))
    html = update_marker(
        html,
        'AUTO_DEVELOP_BAR_STYLE',
        f'<div class="progress-bar develop" style="width: {develop_pct}%"></div>',
    )
    # AUTO_WIP_* = PMDNEO wip-pmdmml-voice-parser HEAD (= 現役 sprint)
    html = update_marker(html, 'AUTO_WIP_COUNT', str(wip_count))
    html = update_marker(html, 'AUTO_WIP_PERCENT', str(wip_pct))
    html = update_marker(
        html,
        'AUTO_WIP_BAR_STYLE',
        f'<div class="progress-bar wip" style="width: {wip_pct}%"></div>',
    )
    # AUTO_PMD_* = PMD V4.8s 本家 reference (= df4e7b6 凍結時点)
    html = update_marker(html, 'AUTO_PMD_COUNT', str(pmd_count))
    html = update_marker(html, 'AUTO_PMD_PERCENT', str(pmd_pct))
    html = update_marker(html, 'AUTO_LAST_UPDATE', last_update)
    html_path.write_text(html, encoding='utf-8')

    print(
        f'Updated: main={main_count} ({main_pct}%), '
        f'develop={develop_count} ({develop_pct}%), '
        f'wip={wip_count} ({wip_pct}%), '
        f'PMD 本家={pmd_count} ({pmd_pct}%)'
    )
    print(f'Last update stamp: {last_update}')


if __name__ == '__main__':
    main()
