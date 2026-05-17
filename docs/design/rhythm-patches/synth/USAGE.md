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

