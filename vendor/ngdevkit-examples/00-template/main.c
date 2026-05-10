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

#ifndef PMDNEO_SONG
#define PMDNEO_SONG 0
#endif

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

  // Phase 10 fixture selector (= PMDNEO_FIXTURE 環境変数で切替):
  //   0 = baseline (= 既 cmd 5 → 16 sec wait → cmd 6 fade default speed 16)
  //   1 = fade fast  (= cmd 5 → 4 sec → cmd 7 + speed 4 → cmd 6、 約 0.25 sec fade)
  //   2 = fade slow  (= cmd 5 → 4 sec → cmd 7 + speed 64 → cmd 6、 約 4 sec fade)
  //   3 = fade test  (= cmd 5 → 4 sec → cmd 7 + speed 255 → cmd 6、 約 16 sec fade)
  // 既存 cmd 6/7 protocol: cmd 7 で modal flag set → arg byte → cmd 6 で trigger
#ifndef PMDNEO_FIXTURE
#define PMDNEO_FIXTURE 0
#endif

  *REG_SOUND = 3;
  ng_wait_vblank();
  ng_wait_vblank();
  *REG_SOUND = 9 + PMDNEO_SONG;
  ng_wait_vblank();
  *REG_SOUND = 5;     /* MML song start */

  u8 last_cycle = 0;
#if PMDNEO_FIXTURE == 0
#if PMDNEO_SONG == 0
  ng_center_text(8, 0, "PMDNEO PHASE 12B-2");
  ng_center_text(10, 0, "SONG 0 = TEST01 CHORD");
#elif PMDNEO_SONG == 1
  ng_center_text(8, 0, "PMDNEO PHASE 12B-2");
  ng_center_text(10, 0, "SONG 1 = TEST02 DRUM");
#endif
#elif PMDNEO_FIXTURE == 1
  ng_center_text(8, 0, "PMDNEO PHASE 10");
  ng_center_text(10, 0, "FIXTURE 1 FADE FAST");
#elif PMDNEO_FIXTURE == 2
  ng_center_text(8, 0, "PMDNEO PHASE 10");
  ng_center_text(10, 0, "FIXTURE 2 FADE SLOW");
#elif PMDNEO_FIXTURE == 3
  ng_center_text(8, 0, "PMDNEO PHASE 10");
  ng_center_text(10, 0, "FIXTURE 3 FADE LONG");
#endif
  ng_center_text(12, 0, "LOOP CYCLE: 00");

#if PMDNEO_FIXTURE == 0
  // baseline: 16 sec wait + default fade
  int wait_vblanks = 960;
  u8 fade_speed = 16;
#elif PMDNEO_FIXTURE == 1
  int wait_vblanks = 240;  /* 4 sec */
  u8 fade_speed = 4;
#elif PMDNEO_FIXTURE == 2
  int wait_vblanks = 240;
  u8 fade_speed = 64;
#elif PMDNEO_FIXTURE == 3
  int wait_vblanks = 240;
  u8 fade_speed = 255;
#endif

  for (int i = 0; i < wait_vblanks; i++) {
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

  /* Fade trigger (= speed param protocol、 cmd 7 → arg byte → cmd 6) */
  ng_center_text(14, 0, "FADE OUT...");
#if PMDNEO_FIXTURE != 0
  *REG_SOUND = 7;          /* set_fade_speed cmd (modal flag set) */
  ng_wait_vblank();
  *REG_SOUND = fade_speed; /* speed value */
  ng_wait_vblank();
#endif
  *REG_SOUND = 6;          /* fade trigger */
  ng_wait_vblank();

  for(;;) {}
  return 0;
}
