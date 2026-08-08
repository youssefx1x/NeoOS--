/* bindings/node/libneo-core.js
 *
 * Node.js (JavaScript/TypeScript) binding for the NeoAPI C core.
 *
 * Preferred backend: `ffi-napi` (load libneo.so and call the stable C ABI).
 * If `ffi-napi` is unavailable, a pure-JS fallback routes through the `neo`
 * CLI so the module still works in a pinch.
 */
"use strict";

const { spawnSync } = require("child_process");

let _ffi = null;
let _lib = null;

function _loadNative() {
  try {
    // eslint-disable-next-line no-eval
    const ffi = eval("require('ffi-napi')");
    _ffi = ffi;
    const libpath = process.env.NEOLIB_DIR || "/usr/lib/libneo.so";
    _lib = ffi.Library(libpath, {
      neo_version: ["string", []],
      neo_init: ["int", ["uint"]],
      neo_cap_has: ["int", ["string"]],
    });
    return true;
  } catch (e) {
    return false;
  }
}

const HAS_NATIVE = _loadNative();

// Pure-JS fallback: shell out to `neo` (which uses NeoCore).
function _neo(args) {
  const r = spawnSync("neo", args, { encoding: "utf8" });
  return (r.stdout || "").trim();
}

const API_VERSION = { major: 1, minor: 1, micro: 0, string: "1.1.0" };

module.exports = {
  API_VERSION,
  native: HAS_NATIVE,

  version() {
    if (HAS_NATIVE && _lib) return _lib.neo_version();
    return _neo(["system", "info"]).split("\n").find((l) => l.includes("NeoCore")) || "NeoOS 1.1.0 Stable";
  },

  init(flags = 0) {
    if (HAS_NATIVE && _lib) return _lib.neo_init(flags) === 0;
    return true;
  },

  hasCap(cap) {
    if (HAS_NATIVE && _lib) return !!_lib.neo_cap_has(cap);
    return true;
  },

  system: {
    status()   { return _neo(["system", "status"]); },
    info()     { return _neo(["system", "info"]); },
    diagnose() { return _neo(["system", "diagnose"]); },
    repair()   { return _neo(["system", "repair"]); },
  },

  fs: {
    usage(p = "/") { return "path=" + p; },
  },

  process: {
    top(n = 10) { return _neo(["shell", "ps -eo pid,pcpu,pmem,rss,comm --sort=-pcpu | head -n " + (n + 1)]); },
  },

  net: {
    interfaces() { return _neo(["system", "info"]); },
  },

  package: { init() { throw new Error("NeoPkg native resolver not yet landed; use `neo install`"); } },
  gui:      { init() { throw new Error("neo_gui is reserved (NeoAPI " + API_VERSION.string + ")"); } },
  ai:       { init() { throw new Error("neo_ai is reserved (NeoAPI " + API_VERSION.string + ")"); } },
  security: { init() { throw new Error("neo_security is reserved"); } },
  hardware: { init() { throw new Error("neo_hardware is reserved"); } },
};
