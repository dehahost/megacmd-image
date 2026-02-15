# MEGA CMD Image

Rootless image based upon the latest [Ubuntu LTS](https://hub.docker.com/_/ubuntu) providing the [MEGAcmd](https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/megacmd) server and its utilities.

Supported architectures: `amd64`, `arm64`

## Contents

- [Build It](#build-it)
- [Run It](#run-it)
- [Automate It](#automate-it)
  - [Autologin](#autologin)
  - [Autosync](#autosync)
- [Debug It](#debug-it)

## Build It

Make sure you have Docker installed. Then run:

```bash
./build.sh --prod
```

## Run It

You may wish to pull the image from [Docker Hub](https://hub.docker.com/r/dehahost/megacmd).\
It's updated around the first Friday of each month due to base image patches.

By default, image runs with UID/GID set to 9100.

### Docker Command

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
  -v "${megadir}:/mnt/megasync" \
  docker.io/dehahost/megacmd:latest
```

>[!NOTE]
> The `⁣-u` parameter sets the container UID and GID to match the folder owner and group.

**4/** Manage it

```bash
docker exec -it megacmd mega-cmd
```

### Docker Compose

**1/** Copy `docker-compose.yaml` from this repo\
**2/** Change sync folder(s) to your liking, for example ...

```diff
# docker-compose.yaml

 services:
   megacmd:
     volumes:
       # ...
-      - $HOME/Documents/MEGAsync:/mnt/megasync
+      - /srv/megasync:/mnt/megasync
```

**3/** Create it (if it doesn't exist)

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
-    #user: "9100:9100"
+    user: "1010:1010"
     volumes:
       # ...
```

**5/** Start the service and configure it

```bash
docker compose up -d
docker compose exec megacmd mega-cmd
```

## Automate It

### Autologin

Automation is activated by setting following env. variables:

| Env. Variable           | Description                                                                                         |
|-------------------------|-----------------------------------------------------------------------------------------------------|
| `MEGACMD_EMAIL`         | Login e-mail                                                                                        |
| `MEGACMD_PASSWORD`      | Login password                                                                                      |
| `MEGACMD_PASSWORD_FILE` | File with login password. Accepts name of a secret or path to a file. Overrides `MEGACMD_PASSWORD`. |
| `MEGACMD_TOTP`          | *(optional)* Time-Based One-Time Password. 6 digits are expected.                                   |

**1/** Store your MEGA password in a file

```text
echo "~~YourMEGAStrongPassword~~" >.megacmd-pwd
chmod 0600 .megacmd-pwd
```

**2/A/** Docker Compose: Configure autologin with a password secret

```diff
# docker-compose.yaml

  services:
    megacmd:
      image: "docker.io/dehahost/megacmd:latest"
      # ...
      environment:
+       MEGACMD_EMAIL: "someone@example.com"
+       MEGACMD_PASSWORD_FILE: "megacmd-password"
+       MEGACMD_TOTP: "123456"
+     secrets:
+       - megacmd-password
      volumes:
        # ...

+ secrets:
+   megacmd-password:
+     file: ./.megacmd-pwd
```

**2/B/** Docker command: Add following arguments to the command

```diff
  docker run -d \
    --name megacmd \
    -u "$(stat -c %u:%g $megadir)" \
+   -e "MEGACMD_EMAIL=someone@example.com" \
+   -e "MEGACMD_PASSWORD_FILE=megacmd-pwd" \
+   -e "MEGACMD_TOTP=000000" \
+   -v ".megacmd-pwd:/run/secrets/megacmd-pwd:ro" \
    -v "${megahome}:/home/mega/.megaCmd" \
    -v "${megadir}:/mnt/megasync" \
    docker.io/dehahost/megacmd:latest
```

### Autosync

Automation only adds nonexistent syncs based on the value of the `MEGACMD_SYNC_DIRS` env. variable.\
Its format is similar to a Docker volume definition, but each additional entry must be separated by a comma.

```text
<local_mounted_dir>:<remote_mega_dir>[,...]
```

It will end with code 1 if there is a problem, such as:

- Wrong definition format
- Nonexistent local or remote directory
- Incorrect owner of local folder
- Error when setting up sync

**1/** Make sure you are logged in into your MEGA account.
You may use [autologin automation](#autologin) for this.

**2/A/** Docker Compose: Configure autosync

```diff
# docker-compose.yaml

  services:
    megacmd:
      image: "docker.io/dehahost/megacmd:latest"
      # ...
      environment:
        # ...
+       MEGACMD_SYNC_DIRS: >-
+         /mnt/megasync:/MEGAsync,
+         /mnt/music:/Music
      secrets:
        # ...
      volumes:
        # ...
        - $HOME/Documents/MEGAsync:/mnt/megasync
        - $HOME/Music:/mnt/music
```

**2/B/** Docker command: Add following arguments to the command

```diff
  docker run -d \
    --name megacmd \
    -u "$(stat -c %u:%g $megadir)" \
+   -e "MEGACMD_SYNC_DIRS=/mnt/megasync:/MEGAsync" \
    -v "${megahome}:/home/mega/.megaCmd" \
    -v "${megadir}:/mnt/megasync" \
    docker.io/dehahost/megacmd:latest
```

## Debug It

Higher verbosity for debugging the MEGAcmd can be set using the `MEGACMD_LOGLEVEL` env. variable.\
Following exact levels are accepted:

- `VERBOSE`
- `FULLVERBOSE`
- `DEBUG`
- `FULLDEBUG`

>[!NOTE]
> The `FULL` prefix applies the log level also to the underlying API, not just the commands.
