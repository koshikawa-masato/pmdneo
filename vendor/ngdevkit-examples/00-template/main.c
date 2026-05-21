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

#ifndef PMDNEO_MASK_BITS
#define PMDNEO_MASK_BITS 0
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
  //
  // PMDNEO_NO_FADE (= compile-time flag、 Makefile PMDNEO_NO_FADE=1 で -D 定義):
  //   定義時は上記 fixture に関わらず cmd 6 fade trigger を送らない。
  //   = tone-ladder audition harness mode (= 聴覚テスト用 MML を fade なしで全長
  //   再生)。 本 main.c は PMDNEO audition harness であり、 fade-out audition と
  //   tone-ladder audition は用途が異なるため flag で分離する (= driver 非改修)。
#ifndef PMDNEO_FIXTURE
#define PMDNEO_FIXTURE 0
#endif

  *REG_SOUND = 3;
  ng_wait_vblank();
  ng_wait_vblank();
  *REG_SOUND = 9 + PMDNEO_SONG;
  ng_wait_vblank();

  // Issue mask commands before song start (= PMDNEO_MASK_BITS bit ch で指定)
  // bit 0=A, bit 1=B, ... bit 10=K (FM/SSG/PCM/Rhythm)、 bit 11/12/13=X/Y/Z (FM3Extend)
  {
    int mask_bits = PMDNEO_MASK_BITS;
    for (int ch = 0; ch < 14; ch++) {
      if (mask_bits & (1 << ch)) {
        *REG_SOUND = 24 + ch;
        ng_wait_vblank();
      }
    }
  }

  /* ADR-0016 step 4-3-α (= 2026-05-12): W-3 後の本線 driver (= standalone_test.s + */
  /* TEST_MODE_CHORD=5) では cmd 0x02 は単音 FM scale test 経路 (= nmi_cmd_2_play_song)、 */
  /* 真の MML song path は cmd 0x05 + TEST_MODE_CHORD=5 → nmi_cmd_5_init_mml_song → */
  /* pmdneo_song_main 経由 (= driver standalone_test.s L319-322 / L1172)。 W-1 で cmd */
  /* 2 に切替えたのは V-1 (= PMDNEO.s build top) 時、 W-3 で build top を本線に戻し */
  /* たため cmd 0x05 が再び正規入口。 4 度目の trivial verify 補正。 */
  *REG_SOUND = 5;     /* MML song start (= nmi_cmd_5_init_mml_song 経由) */

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

  /* Fade trigger (= speed param protocol、 cmd 7 → arg byte → cmd 6)。
   * PMDNEO_NO_FADE 定義時は cmd 6 fade を送らない = tone-ladder audition harness
   * mode (= 聴覚テスト用 MML を fade なしで全長再生)。 未定義時は従来どおり
   * fade-out audition として cmd 6 送出。 fade-out audition と tone-ladder
   * audition を分離するため本 flag を追加 (= driver 非改修、 harness 分離)。 */
#ifndef PMDNEO_NO_FADE
  ng_center_text(14, 0, "FADE OUT...");
#if PMDNEO_FIXTURE != 0
#endif
  *REG_SOUND = 6;          /* fade trigger */
  ng_wait_vblank();
#endif /* PMDNEO_NO_FADE */

  for(;;) {}
  return 0;
}
