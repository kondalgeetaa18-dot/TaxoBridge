# Changelog

## [1.0.0] — 2026-10-25

Initial public release accompanying the TaxoBridge manuscript.

### Added
- Core library (`src/taxobridge/`): unbalanced optimal transport with log-domain
  generalized Sinkhorn and the Proposition 6 certificate; confidence-masked
  transfer operator; sparsemax label attention with evidence sets and
  Proposition 4 stability; budget-constrained token gate with the Lemma 2 budget,
  top-k inference rule and Lemma 4 dual certificate; exact FLOP counting and the
  Proposition 5 speedup envelope.
- PyTorch model, loss terms (Eq 31–37), primal–dual trainer (Algorithm 1) and
  inference (Algorithm 2).
- Data layer: per-dataset sources/licenses/download instructions, authored label
  definitions and clinician prior (Table IV), split-manifest generator (seed-13
  iterative multi-label stratification), reproducible preprocessing.
- Configs: `default.yaml` (Tables VI/VII), 55 sensitivity + 10 ablation configs,
  five seeds.
- Verification scripts producing **real** logs for Tables IX, X, XVI and
  Figs 4–7; executed on CPU in this release.
- 40 unit tests across all core algorithms.
- Evaluation + statistics (paired bootstrap, approximate randomization, Holm)
  and the three-level efficiency benchmark.
- Reference-results manifest, per-table logs (I–XVIII) and `checkpoints.json`.

### Notes
- `docs/ERRATA.md` records a typesetting discrepancy in the manuscript's Eq (25)
  (the Sinkhorn update exponent); the implementation follows the mathematically
  correct Eq (44)/(61) form, confirmed by the gradient-residual and Prop-6
  checks.
