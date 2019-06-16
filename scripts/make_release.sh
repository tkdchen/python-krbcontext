#!/bin/bash

# This script requires a virtual environment with requirements installed.

cd "$(dirname $(realpath "$0"))/.."

release_dir=release

[ -e "${release_dir}" ] && rm -rf "${release_dir}"
mkdir "${release_dir}"

name=$(python3 -c "
from configparser import ConfigParser
cfg = ConfigParser()
cfg.read('setup.cfg')
print(cfg.get('package', 'name'))
")
rel_ver=$(python -c "
from configparser import ConfigParser
cfg = ConfigParser()
cfg.read('setup.cfg')
print(float(cfg.get('package', 'version')) + 0.1)
")
rel_date=$(date --rfc-3339='date')
changelog_items=$(git log --format="- %s (%an)" HEAD..."$(git describe --tags --abbrev=0)")

function update_changelog_rst
{
    local -r changelog_head="${rel_ver} (${rel_date})"
    local -r sep_line=$(python -c "print('-' * len('${changelog_head}'))")
    echo "${changelog_head}
${sep_line}

${changelog_items}
" | sed -i "3r/dev/stdin" CHANGELOG.rst
}

# Bump version
sed -i "s/^version = [0-9]\+.[0-9]\+$/version = ${rel_ver}/" setup.cfg
update_changelog_rst
make doc
python3 setup.py sdist
mv "dist/${name}-${rel_ver}.tar.gz" "${release_dir}"
