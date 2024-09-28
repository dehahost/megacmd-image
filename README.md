# MEGA CMD image

MEGA CMD image for Docker or Podman.

The main motivation of this project is the functional MEGA CMD running in a container on 64-bit Rasperry Pi OS (arm64/v8).

## Build it (optional)

```bash
./build.sh
```

... or ...

```bash
docker build -t dehahost/megacmd:latest .
```

## Run it - examples

### ...on your computer

**1/** Create sync folder

```bash
mkdir $HOME/Documents/MEGAsync
```

**2/** Run MEGA CMD container in background

```bash
syncdir="${HOME}/Documents/MEGAsync"
docker run -d \
    --name megacmd \
    -u $(stat -c %u:%g ${syncdir}) \
    -v ${syncdir}:/home/mega/sync \
    dehahost/megacmd:latest
```

>[!NOTE]
>The `-u` parameter defines the same user/group for the container as for the folder.

**3/** Jump in, login and start syncing

```bash
docker exec -it megacmd mega-cmd
```

### ...on a server

**1/** Create sync folder

```bash
mkdir /srv/megasync
chown 9100:9100 /srv/megasync
```

**2/** Copy `docker-compose.yaml` from repo and change volume path

```diff
 services:
   megacmd:
     volumes:
       # ...
-      - $HOME/Documents/MEGAsync:/home/mega/sync
+      - /srv/megasync:/home/mega/sync
```

**3/** Start it and configure it

```bash
docker compose up -d
docker compose exec megacmd mega-cmd
```

## More info?

- Image is using community-maintained build of `megacmd` for Alpine Linux. For more information visit [Alpine's GitLab aports repo](https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/megacmd).
- Supported platforms are `amd64` and `arm64`.
- By default, MEGA CMD server is running unpriviledged under _"mega"_ user (UID/GID=9100).
