/// PMDNEO Phase 1 PoC - dummy ROM
/// 目的: NEOGEO ROM ビルドフロー検証(ngdevkit-examples 00-template ベース)
///
/// 動作: 起動画面に「PMDNEO POC」 を表示してそのまま無限ループ。
///       sound driver は dummy(busy loop、 無音)。
///       Phase 2 で フルスクラッチ driver に置換、 Phase 3+ で ADPCM 対応。
///
/// build:
///   cd ~/Projects/neo-sisters/vendor/ngdevkit-examples/00-template
///   (このファイルを 00-template/main.c に上書き or symlink)
///   make
///   make gngeo  # = ngdevkit-gngeo で起動
///
/// ベース: ngdevkit-examples/00-template/main.c (GPL-3.0)
///
/// SPDX-License-Identifier: GPL-3.0-or-later
/// Copyright (C) 2026 越川将人 (M.Koshikawa.)

#include <ngdevkit/neogeo.h>
#include <ngdevkit/bios-calls.h>
#include <ngdevkit/ng-fix.h>


int main(void) {
  bios_fix_clear();

  // 最小パレット(背景黒、 文字白系統)
  const u16 palette[] = {0x8000, 0x0fff, 0x0555};
  for (u16 i=0; i<3; i++) {
      MMAP_PALBANK1[i] = palette[i];
  }

  // PMDNEO PoC ロゴ + バージョン表示
  ng_center_text(8, 0, "PMDNEO");
  ng_center_text(11, 0, "Phase 1 PoC");
  ng_center_text(14, 0, "ROM build flow check");
  ng_center_text(17, 0, "(C) M.Koshikawa.");

  // ngdevkit のデフォルト VBlank handler が watchdog を rearm する
  for(;;) {}
  return 0;
}
