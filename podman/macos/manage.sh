#!/usr/bin/env bash

start() {
    echo "Starting up the Sourcegraph VM..."

    [[ $(podman machine inspect "${sg_machine}" | jq -r '.[0].State') = running ]] || {
        podman machine start "${sg_machine}"
    }
    [[ $(podman machine inspect "${sg_machine}" | jq -r '.[0].State') = running ]] || {
        echo "failed to start a podman machine" 1>&2
        return 1
    }

    echo "OK"

    socket=$(podman machine inspect "${sg_machine}" | jq -r '.[0].ConnectionInfo.PodmanSocket.Path')
    export CONTAINER_HOST=unix://${socket}

    echo "Launching Sourcegraph..."

    podman-compose --project-name="${sg_machine}" up -d || {
        echo "failed to start Sourcegraph" 1>&2
        return 1
    }

    echo "OK"

    echo "Waiting for Sourcegraph to be ready..."
    sleep 3
    echo "OK"

    echo "Launching Sourcegraph..."
    open http://localhost
}

stop() {
    echo "Bringing down Sourcegraph..."
    podman-compose --project-name="${sg_machine}" down
    echo "OK"
    echo "Stopping the Sourcegraph VM"
    podman machine stop "${sg_machine}"
    echo "OK"
}

sg_machine="sourcegraph-admin"

pushd ~/.sourcegraph/deploy-sourcegraph-docker/docker-compose || {
    echo "cannot find SG install directory" 1>&2
    exit 1
}

podman machine inspect "${sg_machine}" &>/dev/null || {
    echo "failed to provision a VM for Sourcegraph" 1>&2
    exit 1
}

case "${1}" in
    start)
        start || exit 1
        ;;
    stop)
        stop || exit 1
        ;;
    restart)
        stop || exit 1
        start || exit 1
        ;;
    *)
        echo "${0} start|stop|restart" 1>&2
        exit 1
esac