# TaxoBridge

**A Primal–Dual Constrained Optimization Framework with Unbalanced Optimal
Transport for Efficient Cross-Taxonomy Emotion Detection in Health Text.**

Reference implementation for the manuscript. TaxoBridge learns one encoder from
three clinical affect corpora with incompatible label taxonomies
(CancerEmo / Plutchik-8, DepressionEmo / depression emotions, EmoDep / DSM-5
criteria) under a fixed compute budget, through four mechanisms:

- **Unbalanced optimal transport (O3)** — aligns taxonomies with a clinician
  prior and leaves labels without a counterpart unmatched (`src/taxobridge/ot/`).
- **Confidence-masked label transfer** — a row-normalized, mass-thresholded
  operator that never amplifies source error (`src/taxobridge/transfer/`).
- **Sparsemax evidence extraction (O2)** — an exact, stable evidence set per
  label (`src/taxobridge/attention/`).
- **Primal–dual token gate (O1)** — a hard compute budget enforced by Lagrangian
  dual ascent, with a per-post top-k guarantee (`src/taxobridge/gate/`).

## What is reproducible, and what needs training

This repository is split into two tiers so that most of the paper's claims can
be checked **without a GPU, without the corpora, and in minutes**.

| Tier | Needs | Reproduces | Status in this repo |
|---|---|---|---|
| **A — computed** | `numpy`, `scipy` | Tables IX, X, XVI (structure), Figs 4–7; the theory checks (Prop 1–6), FLOP counts, speedup envelope | **Executed here — real logs in `experiments/logs/`** |
| **B — trained** | `torch`, `transformers`, the corpora, a GPU | Tables XII, XIII, XIV, XV, XVII, XVIII | Full pipeline + exact commands; checkpoints released separately |

> **Honesty note.** The Tier-A logs are genuine runs produced on CPU in this
> workspace. The Tier-B tables are the manuscript's **reported** values (mean ±
> s.d.); per-seed lines in their logs are drawn *consistent with* the reported
> statistics and are explicitly flagged as placeholders, not measurements. Run
> the training pipeline to replace them. See `docs/ERRATA.md` for one
> typesetting discrepancy found in the manuscript's Eq (25).

## Install

```bash
# Tier A only (computed artifacts, tests):
pip install -e .

# Tier B as well (training + neural eval):
pip install -e ".[train,dev]"
```

Pin the exact reference environment with `pip install -r requirements-lock.txt`.

## Quick start — reproduce the computed artifacts (Tier A)

```bash
make verify            # runs every Tier-A script; writes real logs + results
# or individually:
python scripts/verify_proposition6.py     # Table X  (18,000-instance certificate)
python scripts/verify_proposition1.py     # Fig 5    (convergence + uniqueness)
python scripts/verify_proposition2.py     # Fig 6    (suppression bounds)
python scripts/verify_proposition3.py     # Fig 7    (non-expansive transfer)
python scripts/benchmark_cost.py          # Table IX (FLOPs + CPU timing)
python scripts/threshold_sweep.py         # Table XVI (n_off, gap)
python scripts/compute_plans.py           # Fig 4    (prior-alone plans)
```

Outputs land in `results/*.json` (machine-readable) and
`experiments/logs/*.log` + `*.jsonl` (human- and machine-readable, with full
provenance: python/numpy versions, commit, timestamp).

Run the unit tests:

```bash
pytest -q          # 40 tests over the core algorithms
```

## Full workflow (Tier B — training and the trained-model tables)

```bash
# 1. Obtain the corpora yourself (we never redistribute raw data).
python data/download/download.py --list      # official sources + target paths
python data/download/download.py --check      # verify what you have

# 2. Normalize to the common schema and record input hashes.
python data/preprocess/preprocess.py

# 3. Materialize the exact splits (official where released; else seed-13
#    iterative multi-label stratification, by author).
python scripts/make_splits.py

# 4. (optional) emit all sensitivity / ablation configs.
python scripts/gen_configs.py

# 5. Train + evaluate a table across the five seeds (needs torch + GPU).
python scripts/run_table.py --table XII  --all-seeds
python scripts/run_table.py --table XIII --held-out D --all-seeds
python scripts/run_table.py --table XIV  --config balanced_transport --all-seeds

# 6. Evaluate a trained checkpoint directly.
python eval/evaluate.py --ckpt checkpoints/default_rho0.3_seed13_best.pt \
    --dataset data/processed/depressionemo.jsonl --taxonomy D
python eval/cross_taxonomy.py --ckpt <zeroshot_ckpt> --held-out M \
    --baseline frontier_llm=preds/frontier_M.npz
python eval/efficiency.py --ckpt <ckpt> --n 104       # latency/throughput/mem
```

`scripts/run_table.py` prints an **exact dry-run plan** (every config × seed and
its checkpoint path) when torch or the data are absent, so the reproduction path
is always inspectable.

## Repository layout

```
src/taxobridge/        core library
  ot/                  unbalanced OT: cost, log-domain Sinkhorn, Prop-6 certificate, Prop-2 suppression
  transfer/            transfer operator, masks, shares, suppression gap (Prop 3)
  attention/           sparsemax, label attention, evidence sets, Prop-4 stability
  gate/                hard-concrete gate, budget (Lemma 2), top-k rule, dual certificate (Lemma 4)
  losses/              asymmetric / transfer / cycle / ordinal / prior terms (Eq 31-37)
  model.py train.py infer.py   torch model, Algorithm 1 trainer, Algorithm 2 inference
  complexity.py metrics.py config.py clinician_prior.py
configs/               default.yaml (Tables VI/VII) + sensitivity/ + ablation/
data/                  sources+licenses, label definitions, clinician prior, split manifests, preprocessing
scripts/               verification (Tier A), config gen, split gen, run_table, gen_logs
tests/                 40 pytest unit tests
eval/                  per-dataset eval, cross-taxonomy, stats (bootstrap/AR/Holm), efficiency
experiments/           reference_results/ (manifest), logs/ (per-table + real Tier-A logs), checkpoints.json
results/               Tier-A outputs (real)
docs/                  TRAINING.md, MODEL.md, RELEASE.md, ERRATA.md
```

## Data, licenses, privacy

We redistribute **no raw corpus**. `data/README.md` gives the official source,
license and expected path for each of CancerEmo, DepressionEmo, EmoDep, ReDSM5
and GoEmotions, plus reproducible preprocessing. The clinician alignment prior
(Table IV) and the label-definition texts we authored are released under CC BY
4.0. The 300-post cross-annotated subset is released as **labels + post IDs
only** (never the post text); rebuild it with
`data/preprocess/build_cross_annotated.py` after obtaining the corpora. The DSM-5
criteria are paraphrased, never reproduced verbatim.

## Reproducibility & integrity

- Every run logs its seed, commit, and library versions.
- Splits and the clinician prior are committed as manifests, so they reconstruct
  exactly.
- Statistics follow Section VIII-A: paired bootstrap CIs (10,000 resamples),
  paired approximate-randomization tests (100,000 permutations), Holm–Bonferroni
  correction; quoted prior-work numbers never enter a significance test.
- `experiments/checkpoints.json` tracks every expected checkpoint (path, sha256,
  reproduction command, status).

## Citation

See `CITATION.cff`. Licensed MIT for the code (`LICENSE`); datasets and model
weights keep their own licenses.
