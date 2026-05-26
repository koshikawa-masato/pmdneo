#!/usr/bin/env python3
"""Build the static PMDNEO progress dashboard data.

The dashboard is published by GitHub Pages as static files.  This script turns
the human-maintained PMDMML coverage page plus the dashboard's existing driver
feature heatmap into a single data.json that the dashboard can load without
runtime GitHub API parsing.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
from datetime import datetime, timezone
from html import unescape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DASHBOARD_DIR = ROOT / "docs" / "webpages" / "pmdneo-progress-dashboard"
COVERAGE_HTML = ROOT / "pages" / "pmdmml-coverage.html"
DATA_JSON = DASHBOARD_DIR / "data.json"
INDEX_HTML = DASHBOARD_DIR / "index.html"


def git_text(args: list[str], default: str = "") -> str:
    try:
        return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()
    except Exception:
        return default


def strip_tags(value: str) -> str:
    value = re.sub(r"<[^>]+>", "", value)
    return re.sub(r"\s+", " ", unescape(value)).strip()


def marker(html: str, name: str) -> str:
    m = re.search(rf"<!-- {re.escape(name)} -->([\s\S]*?)<!-- /{re.escape(name)} -->", html)
    return strip_tags(m.group(1)) if m else ""


def status_from_cell(cell_html: str) -> str:
    if "badge-done" in cell_html or "badge-pmdaes" in cell_html:
        return "implemented"
    if "badge-partial" in cell_html:
        return "partial"
    if "badge-todo" in cell_html:
        return "not_implemented"
    if "badge-out" in cell_html:
        return "n_a"
    text = strip_tags(cell_html)
    if re.search(r"[✓✔]", text):
        return "implemented"
    if "△" in text:
        return "partial"
    if re.search(r"[✗✕×]", text):
        return "not_implemented"
    if "⛔" in text:
        return "n_a"
    return "tbd"


def infer_category(section_group: str, command: str, fmt: str) -> str:
    text = f"{section_group} {command} {fmt}"
    if re.search(r"SSG|LFO|noise|ノイズ", text, re.I):
        return "ssg"
    if re.search(r"音色|envelope|波形", text, re.I):
        return "voice"
    if re.search(r"オクターブ|octave|デチューン|detune|shift|transpose", text, re.I):
        return "pitch"
    if re.search(r"音量|volume|フェード|fade", text, re.I):
        return "volume"
    if re.search(r"PAN|pan|ADPCM", text, re.I):
        return "spatial"
    if re.search(r"ループ|loop|label|goto|マクロ|区切り|comment", text, re.I):
        return "flow"
    if re.search(r"テンポ|tempo|音符|休符|tie|タイ|gate|ゲート|リズム", text, re.I):
        return "rhythm"
    return "flow"


def table_rows(table_html: str) -> list[list[str]]:
    out: list[list[str]] = []
    for tr in re.findall(r"<tr\b[^>]*>([\s\S]*?)</tr>", table_html):
        cells = re.findall(r"<td\b[^>]*>([\s\S]*?)</td>", tr)
        if cells:
            out.append(cells)
    return out


def parse_command_rows(html: str) -> list[dict[str, str]]:
    section = re.search(r'<section id="commands">([\s\S]*?)<section id="pmdneo-specific">', html)
    if not section:
        raise RuntimeError("Could not find #commands section")

    rows: list[dict[str, str]] = []
    pattern = re.compile(
        r"<h3\b[^>]*>([\s\S]*?)</h3>\s*<div\b[^>]*class=\"table-wrap\"[^>]*>\s*<table>([\s\S]*?)</table>",
        re.M,
    )
    for h3_html, table_html in pattern.findall(section.group(1)):
        section_group = strip_tags(h3_html)
        for cells in table_rows(table_html):
            if len(cells) < 6:
                continue
            command = strip_tags(cells[1]) or "—"
            fmt = strip_tags(cells[2])
            sound = strip_tags(cells[3])
            pmd_main = status_from_cell(cells[4])
            pmdneo = status_from_cell(cells[5])
            sprint = strip_tags(cells[6]) if len(cells) > 6 else ""
            memo = strip_tags(cells[7]) if len(cells) > 7 else ""
            sec = strip_tags(cells[0])
            rows.append(
                {
                    "opcode": command,
                    "name": sec
                    + (f" {fmt}" if fmt and fmt != command else "")
                    + (f" [{sound}]" if sound and sound != "-" else ""),
                    "category": infer_category(section_group, command, fmt),
                    "manual": pmd_main,
                    "compiler": pmdneo,
                    "driver": pmdneo,
                    "driver_detail": memo,
                    "_sprint": sprint,
                    "_memo": memo,
                    "_sectionGroup": section_group,
                    "_section": sec,
                    "_format": fmt,
                    "_sound": sound,
                }
            )
    return rows


def parse_phases(html: str) -> list[dict[str, str | int]]:
    section = re.search(r'<section id="plan">([\s\S]*?)<section id="legend">', html)
    if not section:
        return []
    table = re.search(r"<table>([\s\S]*?)</table>", section.group(1))
    if not table:
        return []
    phases: list[dict[str, str | int]] = []
    for idx, cells in enumerate(table_rows(table.group(1)), start=1):
        if len(cells) < 4:
            continue
        goal = strip_tags(cells[3])
        phases.append(
            {
                "id": idx,
                "label": strip_tags(cells[0]),
                "content": strip_tags(cells[1]),
                "target": strip_tags(cells[2]),
                "goal": goal,
                "status": status_from_cell(cells[3]),
                "note": f"{strip_tags(cells[1])}  ・  {goal}",
            }
        )
    return phases


def parse_specifics(html: str) -> list[dict[str, str]]:
    section = re.search(r'<section id="pmdneo-specific">([\s\S]*?)<section id="plan">', html)
    if not section:
        return []
    table = re.search(r"<table>([\s\S]*?)</table>", section.group(1))
    if not table:
        return []
    specifics: list[dict[str, str]] = []
    for cells in table_rows(table.group(1)):
        if len(cells) < 4:
            continue
        specifics.append(
            {
                "feature": strip_tags(cells[0]),
                "desc": strip_tags(cells[1]),
                "status": status_from_cell(cells[2]),
                "lineage": strip_tags(cells[3]),
            }
        )
    return specifics


def build() -> dict:
    coverage = COVERAGE_HTML.read_text(encoding="utf-8")
    previous = json.loads(DATA_JSON.read_text(encoding="utf-8"))

    source_sha = os.environ.get("PMDNEO_DASHBOARD_SOURCE_SHA") or git_text(["rev-parse", "HEAD"])
    short_sha = source_sha[:7] if source_sha else "unknown"
    commit_date = os.environ.get("PMDNEO_DASHBOARD_SOURCE_DATE") or git_text(
        ["show", "-s", "--format=%cI", source_sha or "HEAD"]
    )
    last_updated = (commit_date or datetime.now(timezone.utc).isoformat())[:10]

    main_count = int(marker(coverage, "AUTO_PMD_COUNT") or marker(coverage, "AUTO_MAIN_COUNT") or 0)
    main_pct = int(marker(coverage, "AUTO_PMD_PERCENT") or round((main_count / 142) * 100) or 0)
    wip_count = int(marker(coverage, "AUTO_WIP_COUNT") or marker(coverage, "AUTO_DEVELOP_COUNT") or 0)
    wip_pct = int(marker(coverage, "AUTO_WIP_PERCENT") or marker(coverage, "AUTO_DEVELOP_PERCENT") or 0)
    auto_last = marker(coverage, "AUTO_LAST_UPDATE")

    return {
        "meta": {
            "title": "PMDNEO COVERAGE DASHBOARD",
            "subtitle": "PMD V4.8s 本家  ×  PMDNEO 自作 driver",
            "lastUpdated": last_updated,
            "schemaVersion": f"static/generated@{short_sha}",
            "fillStatus": f"STATIC generated from pages/pmdmml-coverage.html on push — auto-stamp: {auto_last or '—'}",
            "repoUrl": "https://github.com/koshikawa-masato/pmdneo/tree/wip-pmddotnet-opnb-extension",
            "commit": {
                "sha": source_sha,
                "shortSha": short_sha,
                "date": commit_date,
                "message": git_text(["show", "-s", "--format=%s", source_sha or "HEAD"]),
                "author": git_text(["show", "-s", "--format=%an", source_sha or "HEAD"]),
                "url": f"https://github.com/koshikawa-masato/pmdneo/commit/{source_sha}" if source_sha else "",
            },
            "autoUpdateStamp": auto_last,
        },
        "pmdmmlSummary": {
            "total": 142,
            "pmdMain": {"count": main_count, "percent": main_pct, "label": "PMD 本家 reference"},
            "pmdneo": {"count": wip_count, "percent": wip_pct, "label": "PMDNEO 自作 driver"},
        },
        "legend": previous["legend"],
        "mmlOpcodes": {
            "columns": [
                {"key": "manual", "label": "MANUAL", "ref": "pages/pmdmml-coverage.html : PMD V4.8s manual reference"},
                {"key": "compiler", "label": "COMPILER", "ref": "pages/pmdmml-coverage.html : PMDNEO compile/tooling status"},
                {"key": "driver", "label": "DRIVER", "ref": "pages/pmdmml-coverage.html / src/driver/standalone_test.s"},
            ],
            "rows": parse_command_rows(coverage),
        },
        "driverFeatures": previous["driverFeatures"],
        "phases": parse_phases(coverage),
        "pmdneoSpecific": parse_specifics(coverage),
    }


def write_index_inline(data: dict) -> None:
    html = INDEX_HTML.read_text(encoding="utf-8")
    body = json.dumps(data, ensure_ascii=False, indent=2)
    new_html, count = re.subn(
        r'(<script id="inline-data" type="application/json">\n)([\s\S]*?)(\n</script>)',
        lambda m: m.group(1) + body + m.group(3),
        html,
        count=1,
    )
    if count != 1:
        raise RuntimeError("Could not replace inline-data script in index.html")
    INDEX_HTML.write_text(new_html, encoding="utf-8")


def main() -> None:
    data = build()
    DATA_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_index_inline(data)
    print(
        "Generated dashboard data:",
        f"mml_rows={len(data['mmlOpcodes']['rows'])}",
        f"phases={len(data['phases'])}",
    )


if __name__ == "__main__":
    main()
