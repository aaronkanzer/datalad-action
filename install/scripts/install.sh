#!/bin/bash
# shellcheck disable=SC2154
# SC2154 (warning): VARIABLE is referenced but not assigned.

set -e

# Show the user all relevant variables for debugging!
echo "user: ${user}"
echo "email: ${email}"
echo "repository: ${repository}"
echo "release: ${release}"
echo "branch: ${branch}"
echo "full_clone: ${full_clone}"
echo "install_root: ${install_root}"
echo "pip_install: ${pip_install}"

# This is in the install instructions
git config --global --add user.name "${user}"
git config --global --add user.email  "${email}"

python3 -m pip install --upgrade pip

# Determine OS and install git annex accordingly
# Runners done on different machines, such as EC2 Runners with Debian, are designed to use apt-get to install git-annex
# See: https://git-annex.branchable.com/install/
#
# DEBIAN_FRONTEND=noninteractive is set to noninteractive in order to avoid an EOF failure due
# to lack of ability to enter input
if [ -f "/etc/debian_version" ] || grep -q 'Ubuntu' "/etc/os-release"; then
    echo "Detected Debian/Ubuntu, installing git-annex using apt-get..."
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update
    sudo apt-get install -y git-annex
else
    echo "Non Debian/Ubuntu system detected, installing git-annex using pip..."
    python3 -m pip install datalad-installer
    datalad-installer --sudo ok git-annex
fi

git config --global filter.annex.process "git-annex filter-process"

# Ensure git annex added to path
# Datalad needs to be installed to this conda environment
echo "$CONDA/bin" >> "${GITHUB_PATH}"
export PATH="$CONDA/bin:$PATH"
command -v pip

# Do we have a release or a branch?
if [ "${release}" != "" ]; then
    echo "Installing datalad from release ${release}..."
    wget "https://github.com/${repository}/archive/refs/tags/${release}.tar.gz"
    pip install "${release}.tar.gz"

# Branch install, either shallow or full clone
else
    if [[ "${full_clone}" != "true" ]]; then
        echo "Installing datalad from branch ${branch}..."
        pip install "git+https://github.com/${repository}.git@${branch}"
    else
        echo "Installing datalad from branch ${branch} with full clone into ${install_root}..."
        git clone -b "${branch}" "https://github.com/${repository}" "${install_root}"
        cd "${install_root}"
        pip install .
        cd -
    fi
fi

if [ -n "${pip_install}" ]; then
    # shellcheck disable=SC2086
    pip install ${pip_install}
fi
