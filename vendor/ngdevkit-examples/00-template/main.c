/// PMDNEO Phase 1 PoC - dummy ROM
/// 目的: NEOGEO ROM ビルドフロー検証(ngdevkit + sdasz80 経路の動作確認)
///
/// 動作: 起動画面に「PMDNEO Phase 1 PoC」 を表示してそのまま無限ループ。
///       sound driver は dummy(busy loop、 無音)。
///       Phase 2 で フルスクラッチ driver に置換、 Phase 3+ で ADPCM 対応。
///
/// build:
///   cd vendor/ngdevkit-examples/00-template   (= pmdneo repo root から相対)
///   make
///   make gngeo  # = ngdevkit-gngeo で起動
///
/// ベース: ngdevkit-examples/00-template/main.c (GPL-3.0、 Damien Ciabrini氏作)
///
/// SPDX-License-Identifier: GPL-3.0-or-later
/// Copyright (C) 2026 越川将人 (M.Koshikawa.)

#include <ngdevkit/neogeo.h>
#include <ngdevkit/bios-calls.h>
#include <ngdevkit/ng-fix.h>
#include <ngdevkit/ng-video.h>

// REG_SOUND: M68K → Z80 sound command 発行 port
#define REG_SOUND ((volatile u8*)0x320000)

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

  // SubB-3: PMDNEO driver 起動経路 (06-sound-adpcma 流儀踏襲)
  // 1) cmd 3 = reset_driver (NMI 経由で driver init を発火、 nullsound 慣習)
  // 2) cmd 2 = play_song (= test_play_c4)
  *REG_SOUND = 3;
  // Phase 6 ADPCM-A only test: cmd 5 (= MML song init = ADPCM-A drum) のみ発火
  // cmd 2 (= Phase 5a mode 4 hardcoded chord progression) は disable
  ng_wait_vblank();
  ng_wait_vblank();
  *REG_SOUND = 5;     /* ADPCM-A drum start */

  /* LOOP cycle counter polling + display */
  u8 last_cycle = 0;
  ng_center_text(8, 0, "PMDNEO PHASE 9R DONE");
  ng_center_text(10, 0, "14 PART DISPATCH OK");
  ng_center_text(12, 0, "LOOP CYCLE: 00");

  /* Wait ~16 seconds (960 vblanks @ 60fps), polling Z80 reply for LOOP cycle updates */
  /* (= REG_SOUND read = Z80 → 68k reply、 0x320001 はコイン入力 register で誤り訂正) */
  for (int i = 0; i < 960; i++) {
    ng_wait_vblank();
    u8 cur_cycle = *REG_SOUND;
    if (cur_cycle != last_cycle) {
      last_cycle = cur_cycle;
      char buf[16];
      buf[0] = 'L'; buf[1] = 'O'; buf[2] = 'O'; buf[3] = 'P'; buf[4] = ' ';
      buf[5] = 'C'; buf[6] = 'Y'; buf[7] = 'C'; buf[8] = 'L'; buf[9] = 'E';
      buf[10] = ':'; buf[11] = ' ';
      buf[12] = '0' + (cur_cycle / 10);
      buf[13] = '0' + (cur_cycle % 10);
      buf[14] = '\0';
      ng_center_text(12, 0, buf);
    }
  }

  /* Fade trigger (= default speed 16, ~1 sec fade、 modal abandon) */
  ng_center_text(14, 0, "FADE OUT...");
  *REG_SOUND = 6;     /* fade_start with default speed 16 */
  ng_wait_vblank();
  // *REG_SOUND = 2;   // disabled: mode 4 FM chord drowns out ADPCM-A drums

  // ngdevkit のデフォルト VBlank handler が watchdog を rearm する
  for(;;) {}
  return 0;
}
