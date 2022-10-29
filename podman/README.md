https://marcusnoble.co.uk/2021-09-01-migrating-from-docker-to-podman/

https://github.com/containers/podman-compose

# downsides
no local mounts

# upsides
automation-friendly - all CLI, no GUI app

install podman and podman-compose using the following
- may need to `xcode-select --install` before `pip3` to avoid an "invalid active developer path" error when it can't find `xcrun`
- re-assert `PATH` after `bre install python3` because `/usr/local/bin/python3` and `/usr/local/bin/pip3` are symbolic links, so resolution of `python3` and `pip3` don't change from `/usr/bin` to `/usr/local/bin` until `PATH` is reasserted.
```
brew install python3 podman
export PATH=${PATH} # fix resolution of `pip3` and `python3`
/usr/local/bin/pip3 install podman-compose
podman machine init # downloads 600+MB, so may take awhile
podman machine set --rootful # want to listen on port 80, so the process needs to have root permissions
podman machine start
```

Some notes displayed after installing `podman`. Will probably need to backtrack and run at least some of these.
- had to run the "rootful" one
```
This machine is currently configured in rootless mode. If your containers
require root permissions (e.g. ports < 1024), or if you run into compatibility
issues with non-podman clients, you can switch using the following command: 

	podman machine set --rootful

API forwarding listening on: /Users/peter/.local/share/containers/podman/machine/podman-machine-default/podman.sock

The system helper service is not installed; the default Docker API socket
address can't be used by podman. If you would like to install it run the
following commands:

	sudo /usr/local/Cellar/podman/4.2.1/bin/podman-mac-helper install
	podman machine stop; podman machine start

You can still connect Docker API clients by setting DOCKER_HOST using the
following command in your terminal session:

	export DOCKER_HOST='unix:///Users/peter/.local/share/containers/podman/machine/podman-machine-default/podman.sock'

Machine "podman-machine-default" started successfully
peter@Peters-MBP ~ % which podman-mac-helper
/usr/local/bin/podman-mac-helper
```



then pull the admin repo and deploy
```
git pull https://github.com/sourcegraph/deploy-sourcegraph-docker
cd deploy-sourcegraph-docker/docker-compose
podman-compose up -d
open http://localhost
```

results:
- can't bind to port 80 because of rootless - gotta go back and make the machine "rootful"
- one of the containers could not find `locale` (probably a db container?)
- the same container could not run `GetWinsize`. Need to updte `MinIO`?
```
performing post-bootstrap initialization ... sh: locale: not found
2022-10-16 00:42:35.390 UTC [19] WARNING:  no usable system locales were found
WARNING: MINIO_ACCESS_KEY and MINIO_SECRET_KEY are deprecated.
         Please use MINIO_ROOT_USER and MINIO_ROOT_PASSWORD
ok
syncing data to disk ... 2022/10/16 00:42:37 request /health http://127.0.0.1:44013
Formatting 1st pool, 1 set(s), 1 drives per set.
WARNING: Host local has more than 0 drives of set. A host failure will result in data becoming unavailable.
❗️ An error was returned when detecting the terminal size and capabilities:
   
   GetWinsize: inappropriate ioctl for device
   
   Execution will continue, but please report this, along with your operating
   system, terminal, and any other details, to:
     https://github.com/sourcegraph/sourcegraph/issues/new
   

 You are running an older version of MinIO released 2 months ago 
 Update: Run `mc admin update` 


sh: locale: not found
2022-10-16 00:42:39.478 UTC [19] WARNING:  no usable system locales were found
ok

```

# Potentially huge issue
podman doesn't cache images? After this:
```
podman-compose down
podman machine stop
podman machine set --rootful
podman machine start
podman-compose up
```
It is downloading all of the same images that it download last time.
