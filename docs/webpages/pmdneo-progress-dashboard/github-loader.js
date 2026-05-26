// github-loader.js  —  pmdneo リポジトリから coverage を直接 fetch + parse
//
// 取得元:
//   GET https://raw.githubusercontent.com/koshikawa-masato/pmdneo/main/pages/pmdmml-coverage.html
//   GET https://api.github.com/repos/koshikawa-masato/pmdneo/commits/main
//
// 両方とも CORS 対応済 (= public repo + raw.gh / api.gh は Access-Control-Allow-Origin: *)。
// 結果は本 dashboard の data schema にマッピングして返す。

(function () {
  const REPO = {
    owner: 'koshikawa-masato',
    repo: 'pmdneo',
    branch: 'wip-pmddotnet-opnb-extension',
    coveragePath: 'pages/pmdmml-coverage.html',
    get rawBase() { return 'https://raw.githubusercontent.com/' + this.owner + '/' + this.repo + '/' + this.branch + '/'; },
    get apiBase() { return 'https://api.github.com/repos/' + this.owner + '/' + this.repo + '/'; },
  };

  async function fetchFromGithub() {
    const [commit, html] = await Promise.all([
      fetch(REPO.apiBase + 'commits/' + encodeURIComponent(REPO.branch), {
        headers: { Accept: 'application/vnd.github+json' },
        cache: 'no-store',
      }).then(r => r.ok ? r.json() : Promise.reject(new Error('commits API ' + r.status))),
      fetch(REPO.rawBase + REPO.coveragePath, { cache: 'no-store' })
        .then(r => r.ok ? r.text() : Promise.reject(new Error('coverage fetch ' + r.status))),
    ]);
    return transform(html, commit);
  }

  function transform(html, commit) {
    const doc = new DOMParser().parseFromString(html, 'text/html');

    // ── AUTO_* markers (= python script が書く field) ─────────
    const marker = name => {
      const m = html.match(new RegExp('<!-- ' + name + ' -->([\\s\\S]*?)<!-- /' + name + ' -->'));
      return m ? m[1].trim() : null;
    };
    const mainCount    = parseInt(marker('AUTO_MAIN_COUNT'),    10) || 0;
    const mainPct      = parseInt(marker('AUTO_MAIN_PERCENT'),  10) || 0;
    const developCount = parseInt(marker('AUTO_DEVELOP_COUNT'), 10) || 0;
    const developPct   = parseInt(marker('AUTO_DEVELOP_PERCENT'),10) || 0;
    const autoLast     = (marker('AUTO_LAST_UPDATE') || '').replace(/<[^>]+>/g, '').trim();

    // ── §1-§16 command tables (= #commands 内 h3 + table) ────
    const rows = [];
    doc.querySelectorAll('#commands h3').forEach(h3 => {
      const sectionTitle = h3.textContent.replace(/\s+/g, ' ').trim(); // "§1 基本事項"
      let sib = h3.nextElementSibling;
      while (sib && sib.tagName !== 'DIV') sib = sib.nextElementSibling;
      const table = sib && sib.querySelector('table');
      if (!table) return;
      table.querySelectorAll('tbody tr').forEach(tr => {
        const cells = [...tr.querySelectorAll('td')];
        if (cells.length < 6) return;
        const cmdCell = cells[1];
        const fmtCell = cells[2];
        rows.push({
          sectionGroup: sectionTitle,
          section:  cells[0].textContent.trim(),
          command:  (cmdCell.querySelector('code') || cmdCell).textContent.trim() || '—',
          format:   (fmtCell.querySelector('code') || fmtCell).textContent.trim(),
          sound:    cells[3].textContent.trim(),
          pmdMain:  badgeToStatus(cells[4]),
          pmdneo:   badgeToStatus(cells[5]),
          sprint:   cells[6] ? cells[6].textContent.trim() : '',
          memo:     cells[7] ? cells[7].textContent.trim() : '',
        });
      });
    });

    // ── PMDNEO 独自 (#pmdneo-specific) ─────────────────────────
    const specifics = [];
    doc.querySelectorAll('#pmdneo-specific table tbody tr').forEach(tr => {
      const cells = [...tr.querySelectorAll('td')];
      if (cells.length < 4) return;
      const feat = (cells[0].querySelector('code') || cells[0]).textContent.trim();
      specifics.push({
        feature: feat,
        desc:    cells[1].textContent.trim(),
        status:  badgeToStatus(cells[2]),
        lineage: cells[3].textContent.trim(),
      });
    });

    // ── 後続実装 plan (#plan) → phases ──────────────────────────
    const phases = [];
    doc.querySelectorAll('#plan table tbody tr').forEach((tr, idx) => {
      const cells = [...tr.querySelectorAll('td')];
      if (cells.length < 4) return;
      // goal column may contain badge + text
      phases.push({
        id: idx + 1,
        label: cells[0].textContent.trim(),
        content: cells[1].textContent.trim(),
        target: cells[2].textContent.trim(),
        goal:   cells[3].textContent.replace(/\s+/g, ' ').trim(),
        status: badgeToStatus(cells[3]),
        note:   cells[1].textContent.trim() + (cells[3] ? '  ・  ' + cells[3].textContent.replace(/\s+/g, ' ').trim() : ''),
      });
    });

    const commitMsg = (commit.commit && commit.commit.message || '').split('\n')[0];
    const commitDate = commit.commit && commit.commit.author && commit.commit.author.date;
    const shortSha = (commit.sha || '').slice(0, 7);

    // === Map to dashboard schema =============================
    return {
      meta: {
        title: 'PMDNEO COVERAGE DASHBOARD',
        subtitle: 'PMD V4.8s 本家  ×  PMDNEO 自作 driver',
        lastUpdated: (commitDate || '').slice(0, 10) || '—',
        schemaVersion: 'live/github@' + (shortSha || '—'),
        fillStatus: 'LIVE (' + REPO.branch + ') — auto-stamp: ' + (autoLast || '—'),
        repoUrl: 'https://github.com/' + REPO.owner + '/' + REPO.repo + '/tree/' + REPO.branch,
        commit: {
          sha: commit.sha || '',
          shortSha,
          date: commitDate || '',
          message: commitMsg,
          author: (commit.commit && commit.commit.author && commit.commit.author.name) || '',
          url: commit.html_url || '',
        },
        autoUpdateStamp: autoLast,
      },
      pmdmmlSummary: {
        total: 142,
        pmdMain: { count: mainCount, percent: mainPct, label: 'PMD 本家 (df4e7b6 reference)' },
        pmdneo:  { count: developCount, percent: developPct, label: 'PMDNEO 自作 (main HEAD)' },
      },
      legend: {
        implemented:     { label: 'DONE',    symbol: '✓', color: '#3FA64F' },
        partial:         { label: 'PARTIAL', symbol: '△', color: '#FFB000' },
        not_implemented: { label: 'TODO',    symbol: '✗', color: '#E22C30' },
        n_a:             { label: 'OUT',     symbol: '—', color: '#555577' },
        tbd:             { label: 'TBD',     symbol: '?', color: '#888899' },
      },
      mmlOpcodes: {
        columns: [
          { key: 'manual',   label: 'MANUAL',   ref: 'pages/pmdmml-coverage.html : PMD V4.8s manual reference' },
          { key: 'compiler', label: 'COMPILER', ref: 'pages/pmdmml-coverage.html : PMDNEO compile/tooling status' },
          { key: 'driver',  label: 'DRIVER',   ref: REPO.branch + ' : pages/pmdmml-coverage.html / src/driver/standalone_test.s' },
        ],
        rows: rows.map(r => ({
          opcode: r.command,
          name: r.section + (r.format && r.format !== r.command ? '  ' + r.format : '') +
                (r.sound && r.sound !== '-' ? '  [' + r.sound + ']' : ''),
          category: inferCategory(r),
          manual: r.pmdMain,
          compiler: r.pmdneo,
          driver:  r.pmdneo,
          driver_detail: r.memo,
          _sprint: r.sprint,
          _memo: r.memo,
          _sectionGroup: r.sectionGroup,
          _section: r.section,
          _format: r.format,
          _sound: r.sound,
        })),
      },
      driverFeatures: window.__inlineData?.driverFeatures || { channels: [], features: [], matrix: {} },
      phases,
      pmdneoSpecific: specifics,
    };
  }

  function badgeToStatus(td) {
    if (!td) return 'tbd';
    const badge = td.querySelector('span[class*="badge-"]');
    if (!badge) {
      // Sometimes status text is plain: ✓ / △ / ✗ / ⛔ / ⚠
      const t = td.textContent;
      if (/[✓✔]/.test(t)) return 'implemented';
      if (/△/.test(t)) return 'partial';
      if (/[✗✕×]/.test(t)) return 'not_implemented';
      if (/⛔/.test(t)) return 'n_a';
      if (/⚠/.test(t)) return 'implemented';
      return 'tbd';
    }
    const c = badge.className;
    if (c.includes('badge-done'))    return 'implemented';
    if (c.includes('badge-partial')) return 'partial';
    if (c.includes('badge-todo'))    return 'not_implemented';
    if (c.includes('badge-out'))     return 'n_a';
    if (c.includes('badge-pmdaes'))  return 'implemented'; // PMDNEO 独自実装 ≈ done
    return 'tbd';
  }

  function inferCategory(r) {
    const s = (r.sectionGroup || '') + ' ' + (r.command || '') + ' ' + (r.format || '');
    if (/SSG|LFO|noise/i.test(s)) return 'ssg';
    if (/音色|envelope/i.test(s)) return 'voice';
    if (/オクターブ|octave|デチューン|detune|shift|transpose/i.test(s)) return 'pitch';
    if (/音量|volume|フェード|fade/i.test(s)) return 'volume';
    if (/PAN|pan/i.test(s)) return 'spatial';
    if (/ループ|loop/i.test(s)) return 'flow';
    if (/テンポ|tempo|音符|休符|tie|gate|ゲート/i.test(s)) return 'rhythm';
    if (/ADPCM/i.test(s)) return 'spatial';
    return 'flow';
  }

  // expose
  window.fetchPmdneoCoverage = fetchFromGithub;
  window.PMDNEO_REPO = REPO;
})();
