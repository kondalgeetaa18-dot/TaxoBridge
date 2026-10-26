# TaxoBridge reproduction targets.
# Tier A (verify, test) needs only numpy/scipy. Tier B (data, train) needs the
# corpora and torch.

PY ?= python3
export PYTHONPATH := src:eval:$(PYTHONPATH)

.PHONY: help
help:
	@echo "TaxoBridge make targets:"
	@echo "  make install        - editable install (code only)"
	@echo "  make install-train  - editable install with torch + eval extras"
	@echo "  make test           - run the 40 unit tests"
	@echo "  make verify         - run ALL computed-artifact checks (Tier A, real logs)"
	@echo "  make table9         - Table IX  (FLOPs + CPU timing)"
	@echo "  make table10        - Table X   (Prop-6 certificate, 18k instances)"
	@echo "  make table16        - Table XVI (threshold sweep, computed part)"
	@echo "  make fig4 fig5 fig6 fig7  - the per-figure verification scripts"
	@echo "  make logs           - regenerate per-table logs + checkpoints.json"
	@echo "  make configs        - emit sensitivity + ablation configs"
	@echo "  make data           - preprocess corpora + make splits (needs raw data)"
	@echo "  make clean          - remove caches and regenerated results"

.PHONY: install install-train
install:
	$(PY) -m pip install -e .
install-train:
	$(PY) -m pip install -e ".[train,dev]"

.PHONY: test
test:
	$(PY) -m pytest tests/ -q

# ---- Tier A: computed artifacts (produce REAL logs) ----
.PHONY: verify table9 table10 table16 fig4 fig5 fig6 fig7
verify: fig4 fig5 fig6 fig7 table10 table16 table9 logs
	@echo "All Tier-A artifacts reproduced. See experiments/logs/ and results/."
table9:
	$(PY) scripts/benchmark_cost.py
table9-fast:
	$(PY) scripts/benchmark_cost.py --no-timing
table10:
	$(PY) scripts/verify_proposition6.py --instances 500
table10-quick:
	$(PY) scripts/verify_proposition6.py --instances 50
table16:
	$(PY) scripts/threshold_sweep.py
fig4:
	$(PY) scripts/compute_plans.py
fig5:
	$(PY) scripts/verify_proposition1.py
fig6:
	$(PY) scripts/verify_proposition2.py
fig7:
	$(PY) scripts/verify_proposition3.py

.PHONY: logs configs
logs:
	$(PY) scripts/gen_logs.py
configs:
	$(PY) scripts/gen_configs.py

# ---- Tier B: data + training ----
.PHONY: data
data:
	$(PY) data/preprocess/preprocess.py
	$(PY) scripts/make_splits.py

# ---- housekeeping ----
.PHONY: clean
clean:
	rm -rf .pytest_cache **/__pycache__ src/**/__pycache__ build dist *.egg-info
	@echo "caches cleaned (results/ and experiments/logs/ kept)."
