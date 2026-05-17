# Rhythm synth analysis usage

This note is the operator-facing entry point for the deterministic drum analysis
chain added for ADR-0033 π15.5.

## Purpose

Use `scripts/feature_search.py analyze-drum` to convert a drum WAV into
deterministic analysis artifacts that Claude Code can use before any parameter
sweep or `.fxp` authoring work.

This command does not run the optimizer and does not accept or reject a sound.
It only produces diagnostic data.

## Command

```bash
python3 scripts/feature_search.py analyze-drum path/to/input.wav \
  --output-dir /private/tmp/pmdneo-analyze-drum
```

Optional profile override:

```bash
python3 scripts/feature_search.py analyze-drum path/to/input.wav \
  --profile BD \
  --output-dir /private/tmp/pmdneo-analyze-drum
```

If `--profile` is omitted, the deterministic rule-based classifier selects one
of `BD`, `SD`, `CYM`, `HH`, `TOM`, or `RIM`.

## Output Artifacts

The output directory contains:

```text
analysis-scalar.yaml
analysis-timeseries.json
analysis-summary.yaml
```

Use `analysis-summary.yaml` first. It contains:

- predicted drum kind
- selected profile
- profile-specific focus features
- sensitivity parameter axes
- SHA256 for the scalar and timeseries artifacts

`analysis-scalar.yaml` contains the common feature set. `analysis-timeseries.json`
contains envelope, band-energy, pitch-contour, centroid, and log-frequency
spectrogram series.

## Repeatability Check

For the same input WAV and same script version, all three artifacts must be
byte-identical across runs.

Example:

```bash
python3 scripts/feature_search.py analyze-drum assets/sounds/adpcma/2608_BD-roundtrip.wav \
  --output-dir /private/tmp/pmdneo-analyze-a

python3 scripts/feature_search.py analyze-drum assets/sounds/adpcma/2608_BD-roundtrip.wav \
  --output-dir /private/tmp/pmdneo-analyze-b

shasum -a 256 \
  /private/tmp/pmdneo-analyze-a/analysis-scalar.yaml \
  /private/tmp/pmdneo-analyze-b/analysis-scalar.yaml \
  /private/tmp/pmdneo-analyze-a/analysis-timeseries.json \
  /private/tmp/pmdneo-analyze-b/analysis-timeseries.json \
  /private/tmp/pmdneo-analyze-a/analysis-summary.yaml \
  /private/tmp/pmdneo-analyze-b/analysis-summary.yaml
```

The paired hashes should match.

## Claude Code Handoff

Claude Code should read `analysis-summary.yaml` and use:

- `selected_profile`
- `profile_summary.focus_features`
- `profile_summary.parameter_axes_for_sensitivity`

The next mechanical step is one-factor sensitivity work:

```text
1 baseline .fxp
1 parameter
1 delta
1 render
1 analyze-drum run
1 sensitivity table row
```

Do not resume optimizer work from this command. The classifier selects an
interpretation profile only; human audition remains the final gate.

## One-factor sensitivity sweep

After `analyze-drum` produces the deterministic baseline, the next mechanical
step is one-factor parameter sensitivity sweep. This is **not** an optimizer.
It does not pick a best candidate. It does not accept or reject anything.
It records `parameter delta -> feature delta` diagnostic rows.

### Trial protocol (literal)

```text
1 baseline .fxp
1 parameter
1 delta
1 render
1 analyze-drum run
1 sensitivity table row
```

### Command

```bash
python3 scripts/feature_search.py sensitivity-sweep \
  --baseline-fxp assets/drum_samples/synth/patches/2608_bd.fxp \
  --baseline-label "diagnostic-baseline / aesthetic-rejected" \
  --parameter a_osc1_pitch \
  --deltas=-3,-1,0,1,3 \
  --output-dir /private/tmp/pmdneo-sensitivity-osc1-pitch \
  --producer-cmd ~/Projects/surge-spike/surge/build/src/fxp2wav-surge/fxp2wav-surge
```

Notes:

- The `--deltas=...` form is required so argparse does not parse a leading `-`
  as a flag. Always use `--deltas=-3,-1,0,1,3`.
- `--producer-cmd` must point at the external fxp2wav-surge binary. It lives
  in the spike repo (see ADR-0033 §決定 25 ι'' = scope-in but not repo-in).
- The baseline `.fxp` is the π5 NG patch, labeled `diagnostic-baseline /
  aesthetic-rejected`. It is **not** an accepted candidate. The label
  records that explicitly.
- `--seed` defaults to `2608` and is exported as `SURGE_RNG_SEED` so the
  external producer is deterministic.

### Output

```text
/private/tmp/pmdneo-sensitivity-osc1-pitch/
  baseline/
    patched.fxp
    rendered.wav
    analysis-scalar.yaml
    analysis-timeseries.json
    analysis-summary.yaml
  delta_<value>/         # one directory per delta
    patched.fxp
    rendered.wav
    analysis-scalar.yaml
    analysis-timeseries.json
    analysis-summary.yaml
  sensitivity-table.yaml
  sensitivity-table.csv
```

`sensitivity-table.yaml` carries the full row records (baseline value, delta,
new value, fxp sha256, wav sha256, analysis summary sha256, feature delta,
effect summary). `sensitivity-table.csv` is the flattened spreadsheet view.

### Vertical slice (= a_osc1_pitch, π15.6)

The first vertical slice ran one parameter (`a_osc1_pitch`) at deltas
`-3,-1,0,1,3` from baseline value `0`. The `delta=0` row produced the same
WAV SHA256 as the baseline render, confirming deterministic round-trip. Other
deltas produced one-directional changes in `band_energy_ratio`,
`rough_body_frequency_hz`, and `attack_ms`, consistent with a deterministic
parameter -> feature mapping.

### Constraints

- `sensitivity-sweep` does not invoke the optimizer
- it does not select a best candidate
- it does not accept or reject any candidate
- `effect_summary` is a machine-generated literal label only; the human
  reviewer refines it manually if needed
- one invocation runs exactly one parameter
- `--deltas=0,0,...` is allowed but redundant; the baseline row is always
  written

### Claude Code Handoff (sensitivity)

After producing a sensitivity table for a parameter:

- Read `sensitivity-table.yaml`
- Inspect per-row `feature_delta` and `effect_summary`
- Use the table as `parameter -> feature` knowledge, not as a selection oracle
- Move to the next parameter on the same profile axes list, one at a time

Do not aggregate multiple parameters into a single sweep. Do not combine
sensitivity output with optimizer or preference-learning logic. The table is
diagnostic only; human audition remains the final gate.

## Unit-converted diagnostic baseline (= π15.8)

`make-diagnostic-baseline` builds a `.fxp` whose parameter values are
**explicitly unit-converted** so that the sensitivity sweep can exercise
axes that the π5 NG passthrough baseline left as silent
(= `a_env1_decay` / `a_env2_decay` were silent under π5 baseline).

This is **not** an aesthetic patch. It is `aesthetic-rejected` by design.
It exists only to widen `parameter -> feature` measurability.

### Command

```bash
python3 scripts/feature_search.py make-diagnostic-baseline \
  --spec docs/design/rhythm-patches/synth/2608_bd-diagnostic.patch-spec.yaml \
  --template-fxp assets/drum_samples/synth/patches/2608_bd.fxp \
  --output-fxp assets/drum_samples/synth/patches/2608_bd-diagnostic.fxp \
  --output-report /private/tmp/pmdneo-make-baseline-report.yaml
```

The subcommand refuses to write if `spec.acceptance.aesthetic_acceptance`
is anything other than `"rejected"`, so the artifact cannot accidentally be
treated as an accepted candidate.

### Inputs

- `spec` = `docs/design/rhythm-patches/synth/2608_bd-diagnostic.patch-spec.yaml`
  - records `human_intent` and `converted_internal_value` per parameter
  - label = "unit-converted diagnostic baseline / aesthetic-rejected /
    for sensitivity measurement only"
- `template-fxp` = existing `2608_bd.fxp` (= π5 NG baseline, retained as
  structural-defect evidence; this command does NOT modify it)
- conversion table = `docs/design/rhythm-patches/synth/parameter-unit-conversion.yaml`
  - `status: hypothesis` / `verify_required: true` per parameter
  - conversion is applied inside the spec yaml, the subcommand only injects
    the precomputed `converted_internal_value`

### Output

- `2608_bd-diagnostic.fxp` = chained one-parameter patches applied per
  injection target, with the existing `_fxp_patch_single_parameter` invariant
  verifier running before each write
- `make-baseline-report.yaml` (= optional, `--output-report`) = per-step log
  with `old_value` / `new_value` / `human_intent` / `conversion_status`
  / per-step .fxp sha256

### Verify by sensitivity sweep

Re-run the same 6-axis sweep against the diagnostic baseline to check which
axes become active. Example:

```bash
python3 scripts/feature_search.py sensitivity-sweep \
  --baseline-fxp assets/drum_samples/synth/patches/2608_bd-diagnostic.fxp \
  --baseline-label "unit-converted diagnostic baseline / aesthetic-rejected" \
  --parameter a_env1_decay \
  --deltas=-3,-1,0,1,3 \
  --output-dir /private/tmp/pmdneo-diag-env1-decay \
  --producer-cmd ~/Projects/surge-spike/surge/build/src/fxp2wav-surge/fxp2wav-surge
```

### 1st round result (= π15.8)

- generated `.fxp` sha256:
  `c132faee4b7e74a2f6af9f6c522956a489cf62b52280bc3d7c8ae5d78607d256`
- diagnostic baseline `delta=0` render sha256:
  `9f7f7e23c9181effb11d8aa248d73b3d059c93b5a519f5071b113a871a71fa7c`
- `a_env1_decay` = silent under π5 → **ACTIVE** under diagnostic baseline ✓
- `a_env2_decay` = silent under π5 → **silent** under diagnostic baseline ✗
- `a_env1_release` = partially active under π5 → **silent** under diagnostic
  baseline ✗ (= unexpected, see § 20 of
  `PARAMETER_SENSITIVITY_AND_ANALYSIS_DESIGN.md`)
- active axes: 4/6 ; silent axes: 2/6
- `parameter-unit-conversion.yaml` is `v0.1.0` and is **hypothesis**; 2nd
  round refinement is a separate commit / separate decision

### Constraints

- `make-diagnostic-baseline` is not an optimizer
- it does not pick an aesthetic candidate
- it does not accept or reject any sound
- it refuses to run if `spec.acceptance.aesthetic_acceptance != "rejected"`
- the output artifact is always labeled `aesthetic-rejected`

### v0.2.0 baseline = structural dependency expansion (= π15.9)

v0.1.0 left two axes silent (`a_env2_decay` and `a_env1_release`). Root cause
turned out to be **baseline state**, not the conversion formula:

- `a_env1_release` was silent because `a_env1_sustain = 0` made the release
  segment travel 0 -> 0.
- `a_env2_decay` was silent because of a 3-way chain: filter type was bypass,
  filter envmod amount was 0, and `a_env2_sustain = 1` saturated the envelope
  so decay had nothing to traverse.

v0.2.0 adds four `structural_dependency_setup` parameters on top of the v0.1.0
conversion axes:

- `a_env1_sustain = 0.5` (= enables `a_env1_release`)
- `a_filter1_type = 1` (= enables filter so envmod has a target)
- `a_filter1_envmod = 0.5` (= enables env2 -> cutoff routing)
- `a_env2_sustain = 0.0` (= breaks decay-phase saturation)

Generate v2 baseline (= existing v0.1.0 file is **not** overwritten):

```bash
python3 scripts/feature_search.py make-diagnostic-baseline \
  --spec docs/design/rhythm-patches/synth/2608_bd-diagnostic-v2.patch-spec.yaml \
  --template-fxp assets/drum_samples/synth/patches/2608_bd.fxp \
  --output-fxp assets/drum_samples/synth/patches/2608_bd-diagnostic-v2.fxp
```

Result (= π15.9):

- v2 fxp sha256:
  `c03d32284d5d9108da905bcce6674b09a5912845cb5b46f0262ab2c069013517`
- v2 delta=0 baseline render sha256:
  `28442a6ed106fa2cfcbe2b5b8eb008244faeea092c0f55d80823f7de17858114`
- 6/6 axes active, 0/6 silent
- v0.1.0 (`2608_bd-diagnostic.fxp`) retained as 1st-round failure evidence

The conversion formula in `parameter-unit-conversion.yaml` is unchanged
between v0.1.0 and v0.2.0; the new entries live in the new
`structural_dependencies` section. v0.1.0 history is preserved.

