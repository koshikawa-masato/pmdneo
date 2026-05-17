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

