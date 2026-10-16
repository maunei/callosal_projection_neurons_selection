#!/bin/bash
# Run one R script of the workflow inside its renv environment.
# Usage (from the workflow folder): bash scripts/run_r.sh scripts/01_build_atlas_object.R [config/config.yaml]
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$here/envs/r/env.sh"
RSCRIPT="${RSCRIPT:-/opt/R/4.5.1/bin/Rscript}"
cd "$here"
exec "$RSCRIPT" --no-init-file "$1" "${2:-config/config.yaml}"
