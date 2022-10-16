#!/usr/bin/env bash

### installs Sourcegraph Admin docker-compose on macOS

### check for xcode commandline tools
xcll=$(xcode-select --print-path 2>&1)
[ -d "${xcll}" ] || {
    echo "Installing the Xcode command line tools"
    xcode-select --install
}
xcll=$(xcode-select --print-path 2>&1)
[ -d "${xcll}" ] || {
    echo "IUnable to find the Xcode command line tools" 1>&2
    exit 1
}

### check for Homebrew
command -v brew 2>/dev/null 1>&2 || {
    echo "installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}
command -v brew 2>/dev/null 1>&2 || {
    echo "Homebrew not installed" 1>&2
    exit 1
}

### install the dependencies
packages=(python3 podman git jq)
not_installed=()
brew_prefix=$(brew --prefix)

# TODO check the actual version in case there are dependencies on specific versions

# NOTE this loop works because by happy chance all of the packages that need installing
# have epynomous binaries. This is not always the case.
for package in ${packages[@]}
do
    ${brew_prefix}/bin/${package} --version &>/dev/null || not_installed+=("${package}")
done
[ ${#not_installed[@]} -gt 0 ] && {
    brew install ${not_installed[@]}
    # because brew installs symbolic links to the cellar,
    # the current shell won't find executables in PATH unless PATH is re-asserted
    export PATH=${PATH}
}
# NOTE this loop works because by happy chance all of the packages that need installing
# have epynomous binaries. This is not always the case.
missing=0
for package in ${packages[@]}
do
    ${brew_prefix}/bin/${package} --version &>/dev/null || {
        echo "${pckage} is not installed" 1>&2
        missing=$((missing + 1))
    }
done
[ ${missing} -gt 0 ] && exit 1

# NOTE I am assuming that pip3 gets installed with python3
command -v podman-compose &>/dev/null || pip3 install podman-compose
command -v podman-compose &>/dev/null || {
    echo "podman-compose not installed" 1>&2
    exit 1
}

### set up the sourcegraph admin machine, if not already set up
sg_machine="sourcegraph-admin"
podman machine inspect "${sg_machine}" &>/dev/null || {
    # TODO confirm machine size estimates - going with the low side for now
    # because this install is targetted at a user's machine
    # TODO re-create the machine if the specs are differnt from expected
    podman machine init \
        --cpus 4 \
        -- disk-size 200 \
        --memory 4096 \
        --rootful \
        sourcegraph-admin
}
podman machine inspect "${sg_machine}" &>/dev/null || {
    echo "failed to provision a podman machine" 1>&2
    exit 1
}
[[ $(podman machine inspect "${sg_machine}" | jq '.[0].State') = running ]] || {
    podman machine start ${sg_machine}
}
[[ $(podman machine inspect "${sg_machine}" | jq '.[0].State') = running ]] || {
    echo "failed to start a podman machine" 1>&2
    exit 1
}

cd &>/dev/null || {
    echo "unable to set up Sourcegraph in user's HOME directory" 1>&2
    exit 1
}
git pull https://github.com/sourcegraph/deploy-sourcegraph-docker || {
    echo "unable to set up Sourcegraph in user's HOME directory" 1>&2
    exit 1
}
cd deploy-sourcegraph-docker/docker-compose || {
    echo "unable to find the Sourcegraph docker-compose folder" 1>&2
    exit 1
}
podman-compose up -d || {
    echo "failed to start up sourcegraph admin" 1>&2
    exit 1
}

open http://localhost
