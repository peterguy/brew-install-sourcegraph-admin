#!/usr/bin/env bash

### helper functions
do-or-die() {
    local message="${1}"
    local command="${2}"
    shift 2
    "${command}" "${@}" || {
        echo "${message}" 1>&2
        exit 1
    }
}

### installs Sourcegraph Admin docker-compose on macOS

### check for xcode commandline tools
xcll=$(xcode-select --print-path 2>&1)
[ -d "${xcll}" ] || {
    echo "Installing the Xcode command line tools"
    xcode-select --install
}
echo "Checking for xcode commandline tools..."
xcll=$(xcode-select --print-path 2>&1)
[ -d "${xcll}" ] || {
    echo "Unable to find the Xcode command line tools" 1>&2
    exit 1
}
echo "OK"

### check for Homebrew
command -v brew 2>/dev/null 1>&2 || {
    echo "installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}
echo "Checking for Homebrew..."
command -v brew 2>/dev/null 1>&2 || {
    echo "Homebrew not installed" 1>&2
    exit 1
}
echo "OK"

echo "Checking tooling.."

### install the dependencies
packages=(python3 podman git jq)
not_installed=()
brew_prefix=$(brew --prefix)

# TODO check the actual version in case there are dependencies on specific versions

# NOTE this loop works because by happy chance all of the packages that need installing
# have epynomous binaries. This is not always the case.
for package in "${packages[@]}"
do
    "${brew_prefix}/bin/${package}" --version &>/dev/null || not_installed+=("${package}")
done
[ ${#not_installed[@]} -gt 0 ] && {
    echo "Installing ${not_installed[*]}..."
    brew install "${not_installed[@]}"
    # because brew installs symbolic links to the cellar,
    # the current shell won't find executables in PATH unless PATH is re-asserted
    export PATH=${PATH}
}
# NOTE this loop works because by happy chance all of the packages that need installing
# have epynomous binaries. This is not always the case.
missing=0
for package in "${packages[@]}"
do
    "${brew_prefix}/bin/${package}" --version &>/dev/null || {
        echo "${package} is not installed" 1>&2
        missing=$((missing + 1))
    }
done
[ ${missing} -gt 0 ] && exit 1

# NOTE I am assuming that pip3 gets installed with python3
# For example, on Debian it is a separate package - python3-pip
command -v podman-compose &>/dev/null || pip3 install podman-compose
command -v podman-compose &>/dev/null || {
    echo "podman-compose not installed" 1>&2
    exit 1
}

echo "OK"

echo "Bringing up a VM for Sourcegraph..."

### set up the sourcegraph admin machine, if not already set up
sg_machine="sourcegraph-admin"
podman machine inspect "${sg_machine}" &>/dev/null || {
    # TODO confirm machine size estimates - going with the low side for now
    # because this install is targetted at a user's machine
    # TODO re-create the machine if the specs are differnt from expected
    podman machine init \
        --cpus 4 \
        --disk-size 200 \
        --memory 4096 \
        --rootful \
        "${sg_machine}"
}

podman machine inspect "${sg_machine}" &>/dev/null || {
    echo "failed to provision a VM for Sourcegraph" 1>&2
    exit 1
}

echo "OK"

echo "Starting up the Sourcegraph VM..."

[[ $(podman machine inspect "${sg_machine}" | jq -r '.[0].State') = running ]] || {
    podman machine start ${sg_machine}
}
[[ $(podman machine inspect "${sg_machine}" | jq -r '.[0].State') = running ]] || {
    echo "failed to start a podman machine" 1>&2
    exit 1
}

echo "OK"

echo "Downloading Sourcegraph..."

mkdir -p "${HOME}/.sourcegraph"

do-or-die "unable to set up Sourcegraph in ${HOME}" \
    pushd "${HOME}/.sourcegraph"

[ -d deploy-sourcegraph-docker ] || \
    do-or-die "unable to set up Sourcegraph in user's HOME directory" \
        git clone https://github.com/sourcegraph/deploy-sourcegraph-docker

do-or-die "unable to find the Sourcegraph folder" \
    pushd deploy-sourcegraph-docker

do-or-die "unable to update Sourcegraph" \
    git pull

do-or-die "unable to get the latest Sourcegraph version" \
    git checkout 4.1

do-or-die "unable to find the Sourcegraph docker-compose folder"\
    pushd docker-compose

echo "OK"

# since we're using a non-default machine, need to find connection info for it
# go for the unix socket first
socket=$(podman machine inspect "${sg_machine}" | jq -r '.[0].ConnectionInfo.PodmanSocket.Path')

# --url=unix://$socket

# if the unix socket doesn't work, set up for ssh
# (the podman commands seem to use ssh by default, for some reason)
#ssh_port=$(podman machine inspect "${sg_machine}" | jq -r '.[0].SSHConfig.Port')
#ssh_identity=$(podman machine inspect "${sg_machine}" | jq -r '.[0].SSHConfig.IdentityPath')

# --url=ssh://root@localhost:${ssh_port}/run/podman/podman.sock --identity=${ssh_identity}
# NOTE: don't appear to need the identity file

# export the connetion info because `podman-compose --podman-args`` adds the args after the sub-command
# instead of between `podman` and the sub-command
# (`podman volume --url=...` instead of `podman --url=... volume`)
export CONTAINER_HOST=unix://${socket}

do-or-die "failed to start up sourcegraph admin" \
    podman-compose --project-name="${sg_machine}" up -d

echo "OK"

echo "Waiting for Sourcegraph to be ready..."
sleep 3
echo "OK"

echo "Launching Sourcegraph..."
open http://localhost
