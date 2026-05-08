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
  // Z80 側の reset/NMI 完了と mainloop 再開を待ってから次 command を送る。
  ng_wait_vblank();
  ng_wait_vblank();
  // SubE-1: cmd 5 (ADPCM-B beat、 即 ret) を cmd 2 より先に発火する。
  // cmd 2 は polling loop に入って driver が新 cmd を受け付けないため、
  // ADPCM-B は cmd 2 の前に dispatch しないと無音になる。
  *REG_SOUND = 5;
  ng_wait_vblank();
  *REG_SOUND = 2;

  // ngdevkit のデフォルト VBlank handler が watchdog を rearm する
  for(;;) {}
  return 0;
}
