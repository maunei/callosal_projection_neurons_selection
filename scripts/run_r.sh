#!/bin/bash
# Run one R script of the workflow inside its renv environment.
# Usage (from the workflow folder): bash scripts/run_r.sh scripts/01_build_atlas_object.R [config/config.yaml]
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$here/envs/r/env.sh"
# RSCRIPT must be exported by the user: export RSCRIPT=/path/to/R-4.5.1/bin/Rscript
fix="Export the path of R 4.5.1 first:  export RSCRIPT=/path/to/R-4.5.1/bin/Rscript"
if [ -z "${RSCRIPT:-}" ]; then
  echo "RSCRIPT is not set (or not exported). $fix" >&2
  exit 1
fi
if [ ! -x "$RSCRIPT" ]; then
  echo "R not found at '$RSCRIPT'. $fix" >&2
  exit 1
fi
r_version="$("$RSCRIPT" --no-init-file -e 'cat(as.character(getRversion()))')"
if [ "$r_version" != "4.5.1" ]; then
  echo "'$RSCRIPT' is R $r_version; this workflow needs R 4.5.1. $fix" >&2
  exit 1
fi
cd "$here"
exec "$RSCRIPT" --no-init-file "$1" "${2:-config/config.yaml}"
