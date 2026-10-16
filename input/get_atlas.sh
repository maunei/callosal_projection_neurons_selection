#!/bin/bash
# Download the La Manno et al. 2021 atlas file (dev_all.loom, 10.3 GB) into input/atlas/
# and check it against CHECKSUMS.md5. Run from anywhere:   bash input/get_atlas.sh
# Source page: https://linnarssonlab.org/develmouse/ (see input/README.md).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
URL="https://www.dropbox.com/scl/fi/nr6ny2ysiqi7hqg7x5rm3/dev_all.loom?rlkey=lk62mswfiuxgypt0urhtmnnhv&dl=1"
mkdir -p atlas
if [[ -f atlas/dev_all.loom && $(stat -L -c %s atlas/dev_all.loom) -eq 10268831815 ]]; then
  echo "atlas/dev_all.loom already present"
else
  echo "downloading dev_all.loom (10.3 GB) ..."
  curl -L --fail --retry 5 -C - -o atlas/dev_all.loom "$URL"     # -C - resumes an interrupted download
fi
echo "checking MD5 ..."
grep " atlas/dev_all.loom$" CHECKSUMS.md5 | md5sum -c -
