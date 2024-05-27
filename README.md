# MEGA CMD image

MEGA CMD image for Docker or Podman.

The main motivation of this project is the functional MEGA CMD running in a Podman container on 64-bit Rasperry Pi OS (arm64/v8).

## Build it

```bash
podman build -t megacmd:latest .
```

## Run it

```bash
# - Example 1
podman run -d \
    --name megacmd \
    -v megacmd:/home/mega/.megaCmd \
    -v /home/you/mega-drive:/home/mega/sync \
    localhost/megacmd:latest

podman exec -it megacmd mega-cmd
```

```bash
# - Example 2
podman-compose up -d

podman-compose exec -T megacmd mega-cmd
```

## More info?

- Image is using community-maintained build of `megacmd` for Alpine Linux. For more information visit [Alpine's GitLab aports repo](https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/megacmd).
- Supported platforms are `amd64` and `arm64`.
- By default, MEGA CMD server is running unpriviledged under _"mega"_ user (UID 9100, GID 9100).
