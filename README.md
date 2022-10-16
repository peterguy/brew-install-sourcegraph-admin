# brew-install-sourcegraph-admin
Notes, and possibly code, for easily installing Sourcegraph Admin, with a focus on macOS

The biggest hurdle I've found so far is that the infrastructure needed to run SG is not straightforward to install automatically on macOS. The most promising is k3s, but that runs only on Linux because it relies on Linux kernel system calls. Looks like it's possible that an abstraction layer could be added to it that could proxy the system calls, but I'm not sure about that - seems like it would have been done already if it were possible.

# resources

https://jyeee.medium.com/kubernetes-on-your-macos-laptop-with-multipass-k3s-and-rancher-2-4-6e9cbf013f58

https://dnsmichi.at/2022/03/15/docker-desktop-alternatives-macos-podman-nerdctl-rancher-desktop/



https://dnsmichi.at/2022/03/15/docker-desktop-alternatives-macos-podman-nerdctl-rancher-desktop/

Podman may be an alternative for automated installs - it seems to be more CLI (and therefore automation)-friendly - but it runs currently using a qemu flavor of fedora. Not sure how well that would work. May not work on M1.

# potential tools
## Docker + Compose
## Multipass
## Rancher Desktop
## k3s
## k8s
## podman


# Obstacles

## Docker Compose approach
The Sourcegraph Admin docs recommend forking the `deploy-sourcegraph-docker` respository so that one can "track customizations made to the Sourcegraph docker-compose.yaml easily." An alternate approach would be to allow for a secondary configuration file from a second repository that would apply modifications to the deployment process. The configuration docs do discuss and suggess using a `docker-compose.override.yaml` file, which may be sufficient (I suspect an additional environment file may be necessary).

Upgrades look hairy. Need to evaluate that more thoroughly

resources requirements are large, which could lead to frustrating failures for someone who doesn't understand them. Maybe there's a way to gracefully scale down/back; remove features or something.

# hare-brained ideas
- make a "Desktop" version of SG that installs as an app, maybe with `brew install --cask`, or jsut by downloading a dmg.

# Notes
why do I need a github access token to access public repositories?
What about Subversion hosts? Doesn't lok like Subversion is supported?