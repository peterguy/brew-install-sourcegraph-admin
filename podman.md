https://marcusnoble.co.uk/2021-09-01-migrating-from-docker-to-podman/

https://github.com/containers/podman-compose

# downsides
no local mounts

# upsides
automation-friendly - all CLI, no GUI app

install podman and podman-compose using the following
(may need to `xcode-select --install` before `pip3` to avoid an "invalid active developer path" error when it can't find `xcrun`)
```
brew install python3 podman
pip3 install podman-compose
podman machine init
podman machine start
```
current issue: `pip` installs podman-compose to a non-PATH location. Need to figure out how to fix/prevent that. Maybe use `virtualenv`?

then pull the admin repo and deploy
```
git pull https://github.com/sourcegraph/deploy-sourcegraph-docker
cd deploy-sourcegraph-docker
podman-compose up -d
open http://localhost
```