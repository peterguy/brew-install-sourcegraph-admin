#!/usr/bin/env bash

sg_machine="sourcegraph-admin"

case "${1}" in
    start)
        pushd ~/.sourcegraph/deploy-sourcegraph-docker/docker-compose || {
            echo "cannot find SG install directory" 1>&2
            exit 1
        }

        podman machine inspect "${sg_machine}" &>/dev/null || {
            echo "failed to provision a VM for Sourcegraph" 1>&2
            exit 1
        }

        echo "Starting up the Sourcegraph VM..."

        [[ $(podman machine inspect "${sg_machine}" | jq -r '.[0].State') = running ]] || {
            podman machine start ${sg_machine}
        }
        [[ $(podman machine inspect "${sg_machine}" | jq -r '.[0].State') = running ]] || {
            echo "failed to start a podman machine" 1>&2
            exit 1
        }

        echo "OK"

        socket=$(podman machine inspect "${sg_machine}" | jq -r '.[0].ConnectionInfo.PodmanSocket.Path')
        export CONTAINER_HOST=unix://${socket}
        podman-compose --project-name="${sg_machine}" up -d
        podman-compose --project-name="${sg_machine}" up -d

        echo "OK"

        echo "Waiting for Sourcegraph to be ready..."
        sleep 3
        echo "OK"

        echo "Launching Sourcegraph..."
        open http://localhost

        ;;
    stop)
        ;;
    restart)
        ;;
    *)
        echo "${0} start|stop|restart" 1>&2
        exit1
esac