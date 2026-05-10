import re
import subprocess
import sys
from pathlib import Path

TOTAL = 142  # PMDMML total command count


def count_com_routines(source_text):
    return len(re.findall(r'^com[a-z][a-z0-9]*:', source_text, re.MULTILINE))


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


def get_develop_routine_count():
    p = Path('src/driver/standalone_test.s')
    if not p.exists():
        return 0
    return count_com_routines(p.read_text())


def get_develop_info():
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

    main_count = get_main_routine_count()
    develop_count = get_develop_routine_count()
    develop_hash, develop_date = get_develop_info()

    main_pct = round(main_count / TOTAL * 100)
    develop_pct = round(develop_count / TOTAL * 100)
    last_update = f'{develop_date} develop {develop_hash}'

    html = html_path.read_text(encoding='utf-8')
    html = update_marker(html, 'AUTO_MAIN_COUNT', str(main_count))
    html = update_marker(html, 'AUTO_MAIN_PERCENT', str(main_pct))
    html = update_marker(
        html,
        'AUTO_MAIN_BAR_STYLE',
        f'<div class="progress-bar" style="width: {main_pct}%"></div>',
    )
    html = update_marker(html, 'AUTO_DEVELOP_COUNT', str(develop_count))
    html = update_marker(html, 'AUTO_DEVELOP_PERCENT', str(develop_pct))
    html = update_marker(
        html,
        'AUTO_DEVELOP_BAR_STYLE',
        f'<div class="progress-bar develop" style="width: {develop_pct}%"></div>',
    )
    html = update_marker(html, 'AUTO_LAST_UPDATE', last_update)
    html_path.write_text(html, encoding='utf-8')

    print(f'Updated: main={main_count} ({main_pct}%), develop={develop_count} ({develop_pct}%)')
    print(f'Last update stamp: {last_update}')


if __name__ == '__main__':
    main()
