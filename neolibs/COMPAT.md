# NeoLIBs Compatibility Notes

NeoLIBs targets NeoOS (Debian 13 trixie) but is a portable POSIX-ish bash
script with no external dependencies beyond `bash`, `coreutils`, `find`,
`curl`/`wget` and (optional) `ldconfig` + `dpkg-deb`/`apt-get` for the
`--from-deb` source.

## Known constraints

- **`--from-deb`** requires `apt-get` and `dpkg-deb` (Debian/Ubuntu). It
  extracts every `*.so*` file from the package into the store.
- **`ld.so.conf.d` integration** requires root. Non-root installs still work
  via `neolibs run` (LD_LIBRARY_PATH) and a per-user active tree.
- **SONAME matching** — NeoLIBs stores whole files; it does not rewrite
  `DT_NEEDED`/SONAME strings. Use it to pin library versions whose ABI
  already matches the consumer (typical for toolchain/library development).
- **glibc / libc.so.6 swapping** is unsupported and dangerous — NeoLIBs is
  for application-level libraries, not the C runtime.
- **proot/termux** — under proot, `ldconfig` may not be usable; use
  `neolibs run` pinning, which works without root or ld cache writes.

## Recommended practices

- Install libraries with their full SONAME filename
  (e.g. `libz.so.1.2.13`).
- Test with `neolibs run <lib>@<ver> -- <binary>` before switching globally.
- Keep the system base (glibc, libstdc++) managed by apt; let NeoLIBs handle
  application libraries that need version pinning.
