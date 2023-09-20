# MEGA CMD OCI

MEGA CMD containerized.\
The main motivation of this project is the functional MEGA CMD running on 64-bit Rasperry Pi OS (arm64/v8).

## Build it

- `build.sh` is using `podman`. Execute `sed -ie "s/podman/docker/g" build.sh` if you use Docker.
- Consider checking <https://mega.nz/linux/repo/> before building for any new `megacli` or distribution version. Update it in `build.sh`.
- Build it.

```bash
./build.sh armhf
```

## Run it

```bash
# Example 1
podman run -d --rm --name megacmd localhost/megacmd:armhf
podman exec -it megacmd mega-cmd
```

```bash
# Example 2
podman-compose up -d
```
