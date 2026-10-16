# Restore the R environment of the workflow from renv.lock (R 4.5.1; CRAN snapshot 2025-12-01; Bioconductor 3.21).
# Run from this folder (envs/r):   Rscript build_env.R
# Packages are installed in envs/r/renv/library; renv's cache and build folders are
# kept in envs/r as well (same locations as in env.sh), so nothing is written elsewhere
# except, if renv itself is not installed, the renv package in the user's R library.
stopifnot(getRversion() == "4.5.1")
here <- getwd()
stopifnot(file.exists(file.path(here, "renv.lock")))
Sys.setenv(RENV_PATHS_CACHE   = file.path(here, "renv_cache"),
           RENV_PATHS_SANDBOX = file.path(here, "renv_sandbox"),
           RENV_PATHS_SOURCE  = file.path(here, "renv_source"),
           RENV_CONFIG_NAMESPACES_CHECK = "FALSE")
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", repos = "https://cloud.r-project.org")
renv::init(bare = TRUE, restart = FALSE, bioconductor = "3.21")   # creates .Rprofile/activate.R; keeps renv.lock
renv::activate()
renv::settings$snapshot.type("all")
renv::restore(lockfile = "renv.lock", prompt = FALSE)
cat("R environment restored\n")
