# NeoLIBs

NeoLIBs is a multi-version shared-library manager for NeoOS (and any Debian
system). It lets you install, list, select and run against multiple versions
of the same shared library — similar to `nvm`/`pyenv` for libraries.

## Commands

```
neolibs install <name>@<version> --from <file|dir>
neolibs install <name>@<version> --from-url <url>
neolibs install <name>@<version> --from-deb <apt-package>
neolibs list [name]
neolibs current [name]
neolibs use <name>@<version>
neolibs run <name>@<version> -- <cmd> [args...]
neolibs remove <name>@<version>
neolibs sync
neolibs doctor
```

## How it works

1. **Store** — each installed version lives under
   `/opt/neolibs/store/<name>/<version>/lib/`.
2. **Registry** — `/var/lib/neolibs/<name>.reg` lists the installed versions
   for each library.
3. **Active version** — `neolibs use` creates
   `/opt/neolibs/active/<name>/` containing symlinks to the selected
   version's `.so` files plus a `.active-version` marker, and registers the
   active dir in `/etc/ld.so.conf.d/neolibs.conf`, then runs `ldconfig`.
4. **Per-command pinning** — `neolibs run <name>@<version> -- <cmd>`
   sets `LD_LIBRARY_PATH` for a single command, no root needed.

## Sources

- `--from <file|dir>` — copy one `.so` file or a whole directory of `.so*`.
- `--from-url <url>` — download a `.so`/tarball first, then install.
- `--from-deb <pkg>` — download an apt package and extract its shared
  libraries.

## Root / rootless

If `/opt` is not writable (e.g. running under proot in Termux), NeoLIBs
automatically falls back to `~/.local/share/neolibs`. Set `NEOLIBS_ROOT` and
`NEOLIBS_REGISTRY` explicitly to override.

## Example

```sh
# install two versions of zlib
neolibs install zlib@1.2.13 --from ./libz.so.1.2.13
neolibs install zlib@1.3.1  --from ./libz.so.1.3.1

# switch the whole system to 1.3.1
neolibs use zlib@1.3.1

# or pin just one invocation
neolibs run zlib@1.2.13 -- ./myapp
```

## Testing

```sh
bash tests/test-neolibs.sh
```
