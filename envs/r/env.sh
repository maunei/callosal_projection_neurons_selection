# Environment variables for running R scripts with the workflow's renv library
# (sourced by scripts/run_r.sh). Locations are relative to this folder (envs/r),
# so they are correct wherever the workflow folder is placed.
renv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RENV_PATHS_CACHE="$renv_dir/renv_cache"
export RENV_PATHS_SANDBOX="$renv_dir/renv_sandbox"
export RENV_PATHS_SOURCE="$renv_dir/renv_source"
export RENV_CONFIG_NAMESPACES_CHECK=FALSE
export R_LIBS_USER=""
unset renv_dir
