# MEGA CMD image

Rootless image based upon the latest [Alpine Linux](https://hub.docker.com/_/alpine), and it provides a [MEGAcmd](https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/megacmd) server and its utilities.

Supported architectures: `amd64`, `arm64`

## Build it

```bash
./build.sh
```

## Run it

You may wish to pull the image from [Docker Hub](https://hub.docker.com/r/dehahost/megacmd).\
It's updated around the first Friday of each month due to base image patches.

By default, image runs with UID/GID set to 9100.

### Docker commands

**1/** Choose your sync directory, for example ...

```bash
megadir="${HOME}/Documents/MEGAsync"
```

**2/** Create it (if it doesn't exist)

```bash
mkdir "$megadir"
```

**3/** Run megacmd image as a daemon

```bash
docker run -d \
    --name megacmd \
    -u "$(stat -c %u:%g $megadir)" \
    -v "${megadir}:/home/mega/sync" \
    dehahost/megacmd:latest
```

>[!NOTE]
>The `⁣-u` parameter sets the container UID and GID to match the folder owner and group.

**4/** Manage it

```bash
docker exec -it megacmd mega-cmd
```

### Docker compose

**1/** Copy `docker-compose.yaml` from this repo\
**2/** Change sync folder(s) to your liking, for example ...

```diff
# docker-compose.yaml

 services:
   megacmd:
     volumes:
       # ...
-      - $HOME/Documents/MEGAsync:/home/mega/sync
+      - /srv/megasync:/home/mega/sync
```

**3/** Create is (if it doesn't exist)

```bash
mkdir /srv/megasync
```

**4/A/** Change the owner and group to image's default UID and GID

```bash
chown 9100:9100 /srv/megasync
```

**4/B/** Use current UID and GID of the folder

```shell-session
~ # stat -c %u:%g /srv/megasync
1010:1010
```

```diff
# docker-compose.yaml

 services:
   megacmd:
     image: "docker.io/dehahost/megacmd:latest"
     restart: "unless-stopped"
-    #user: "1001:1001"
+    user: "1010:1010"
     volumes:
       # ...
```

**5/** Start the service and configure it

```bash
docker compose up -d
docker compose exec megacmd mega-cmd
```
