#!/bin/bash
# Run the whole CPN-selection workflow step by step (without Snakemake).
# Usage, from the workflow folder:   bash run_all.sh            # steps 1-7
#                                    bash run_all.sh --validate # steps 1-7, then the validation
# Logs: logs/<step>.log
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
mkdir -p logs
steps=(01_build_atlas_object 02_select_candidates 03_cellcover_tests 04_filter_cells
       05_select_cpn_clusters 06_expression_tables 07_figures)
for s in "${steps[@]}"; do
  echo "== $s"
  bash scripts/run_r.sh "scripts/$s.R" config/config.yaml > "logs/$s.log" 2>&1 || { echo "FAILED: see logs/$s.log"; exit 1; }
  tail -n 1 "logs/$s.log"
done
if [[ "${1:-}" == "--validate" ]]; then
  echo "== validation"
  bash scripts/run_r.sh validation/check_against_expected.R config/config.yaml > logs/validation.log 2>&1
  tail -n 1 logs/validation.log
fi
