#!/usr/bin/env python3
"""neocore.py — Python (ctypes) binding for the NeoLIBs NeoAPI (libneo).

Exposes the stable C ABI exposed by `libneo.so` as Python modules:
    neocore.version()          -> str           (NeoCore version string)
    neocore.api_version()      -> tuple (1,1,0)
    neocore.system.status()    -> dict
    neocore.system.info()      -> dict
    neocore.fs.usage(path)     -> (used, avail, total)
    neocore.net.interfaces()  -> list[dict]
    neocore.process.top(n)    -> list[dict]
    neocore.package.init()    -> raises NotImplementedError (reserved)

Build the C library first with `neolibs neocore build` or `make -C $libneo`.
"""
import ctypes as _ct
import os as _os
import sys

_LIBNEO_PATHS = [
    _os.path.join(_os.environ.get("NEOLIB_DIR", "/usr/lib"), "libneo.so"),
    "/usr/local/lib/libneo.so",
    "libneo.so",
]

def _load():
    last = None
    for p in _LIBNEO_PATHS:
        try:
            return _ct.CDLL(p)
        except OSError as e:
            last = e
    raise ImportError(
        "libneo.so not found. Build it with `neolibs neocore build` "
        "or `make -C neolibs/libneo-core`. Searhed %s (%s)"
        % (_LIBNEO_PATHS, last)
    )

_lib = _load()

# ---- core --------------------------------------------------------------------
_lib.neo_version.restype = _ct.c_char_p
_lib.neo_api_version.restype = None
# neo_api_version returns struct by value (ABI); emulate via a small wrapper call.
class _ApiVer(_ct.Structure):
    _fields_ = [("major", _ct.c_int), ("minor", _ct.c_int), ("micro", _ct.c_int),
                ("tag", _ct.c_char_p), ("string", _ct.c_char_p)]
_lib.neo_api_version.restype = _ApiVer
_lib.neo_init.argtypes = [_ct.c_uint]
_lib.neo_init.restype = _ct.c_int

def version():
    return _lib.neo_version().decode()

def api_version():
    v = _lib.neo_api_version()
    return v.major, v.minor, v.micro, v.tag.decode() if v.tag else None

def init(flags=0):
    r = _lib.neo_init(flags)
    if r != 0:
        raise RuntimeError("neo_init failed (code %d)" % r)

# ---- capability --------------------------------------------------------------
_lib.neo_cap_has.argtypes = [_ct.c_char_p]
_lib.neo_cap_has.restype = _ct.c_int
def has_cap(cap):
    return _lib.neo_cap_has(cap.encode()) == 1

# ---- system ------------------------------------------------------------------
class _Loadavg(_ct.Structure):
    _fields_ = [("load1", _ct.c_double), ("load5", _ct.c_double),
                ("load15", _ct.c_double), ("uptime_seconds", _ct.c_ulong)]
class _Meminfo(_ct.Structure):
    _fields_ = [("total_bytes", _ct.c_ulong), ("avail_bytes", _ct.c_ulong),
                ("free_bytes", _ct.c_ulong)]
class _Diskinfo(_ct.Structure):
    _fields_ = [("total_bytes", _ct.c_ulong), ("used_bytes", _ct.c_ulong),
                ("avail_bytes", _ct.c_ulong),
                ("filesystem", _ct.c_char_p), ("mountpoint", _ct.c_char_p)]
class _Netiface(_ct.Structure):
    _fields_ = [("iface", _ct.c_char * 16), ("ipv4", _ct.c_char * 16),
                ("mac", _ct.c_char * 18), ("up", _ct.c_int)]
class _Syssum(_ct.Structure):
    _fields_ = [("api", _ApiVer), ("loadavg", _Loadavg), ("mem", _Meminfo),
                ("disk", _Diskinfo), ("net", _Netiface),
                ("users_logged", _ct.c_int), ("caps_root", _ct.c_int),
                ("caps_apt", _ct.c_int), ("caps_systemd", _ct.c_int),
                ("caps_online", _ct.c_int)]

_lib.neo_system_status.argtypes = [_ct.POINTER(_Syssum)]
_lib.neo_system_status.restype = _ct.c_int

def system_status():
    s = _Syssum()
    rc = _lib.neo_system_status(_ct.byref(s))
    if rc != 0:
        raise RuntimeError("neo_system_status failed (code %d)" % rc)
    return {
        "api": api_version(),
        "load1": s.loadavg.load1, "load5": s.loadavg.load5,
        "uptime_seconds": s.loadavg.uptime_seconds,
        "mem_total": s.mem.total_bytes, "mem_avail": s.mem.avail_bytes,
        "disk_total": s.disk.total_bytes, "disk_used": s.disk.used_bytes,
        "disk_avail": s.disk.avail_bytes,
        "net_iface": s.net.iface.decode().rstrip("\x00"),
        "users_logged": s.users_logged,
        "caps": {"root": bool(s.caps_root), "apt": bool(s.caps_apt),
                 "systemd": bool(s.caps_systemd), "online": bool(s.caps_online)},
    }

_lib.neo_system_info.argtypes = [
    _ct.c_char * 64, _ct.c_char * 32, _ct.c_char * 64,
    _ct.c_char * 128, _ct.c_char * 32]
_lib.neo_system_info.restype = _ct.c_int
def system_info():
    k = _ct.create_string_buffer(64); a = _ct.create_string_buffer(32)
    h = _ct.create_string_buffer(64); o = _ct.create_string_buffer(128); v = _ct.create_string_buffer(32)
    rc = _lib.neo_system_info(k, a, h, o, v)
    if rc != 0: raise RuntimeError("neo_system_info failed (code %d)" % rc)
    return {"kernel": k.value.decode(), "arch": a.value.decode(),
            "hostname": h.value.decode(), "os": o.value.decode(),
            "version_id": v.value.decode()}

# ---- fs ----------------------------------------------------------------------
_lib.neo_fs_usage.argtypes = [_ct.c_char_p, _ct.POINTER(_ct.c_ulong),
                              _ct.POINTER(_ct.c_ulong), _ct.POINTER(_ct.c_ulong)]
_lib.neo_fs_usage.restype = _ct.c_int
def fs_usage(path="/"):
    used, avail, total = _ct.c_ulong(), _ct.c_ulong(), _ct.c_ulong()
    rc = _lib.neo_fs_usage(path.encode(), _ct.byref(used), _ct.byref(avail), _ct.byref(total))
    if rc != 0: raise RuntimeError("neo_fs_usage failed (code %d)" % rc)
    return (used.value, avail.value, total.value)

# ---- net ---------------------------------------------------------------------
_lib.neo_net_interfaces.argtypes = [_ct.c_void_p, _ct.c_int]
_lib.neo_net_interfaces.restype = _ct.c_int
# Use a fixed buffer of 32 interfaces for the Python call.
_NET_MAX = 32
def net_interfaces():
    buf = (_Netiface * _NET_MAX)()
    n = _lib.neo_net_interfaces(buf, _NET_MAX)
    out = []
    for i in range(n):
        ni = buf[i]
        out.append({
            "iface": ni.iface.decode().rstrip("\x00"),
            "ipv4": ni.ipv4.decode().rstrip("\x00"),
            "mac": ni.mac.decode().rstrip("\x00"),
            "up": bool(ni.up),
        })
    return out

# ---- process -----------------------------------------------------------------
class _Procinfo(_ct.Structure):
    _fields_ = [("pid", _ct.c_int), ("ppid", _ct.c_int), ("uid", _ct.c_int),
                ("cpu_percent", _ct.c_double), ("rss_kb", _ct.c_ulong),
                ("comm", _ct.c_char * 64)]
_lib.neo_process_top.argtypes = [_ct.POINTER(_Procinfo), _ct.c_int]
_lib.neo_process_top.restype = _ct.c_int
def process_top(n=10):
    buf = (_Procinfo * n)()
    got = _lib.neo_process_top(buf, n)
    return [{"pid": buf[i].pid, "ppid": buf[i].ppid,
             "cpu_percent": round(buf[i].cpu_percent, 2),
             "rss_kb": buf[i].rss_kb,
             "comm": buf[i].comm.decode().rstrip("\x00")} for i in range(got)]

# ---- reserved modules --------------------------------------------------------
_lib.neo_package_init.restype = _ct.c_int
_lib.neo_gui_init.restype = _ct.c_int
_lib.neo_ai_init.restype = _ct.c_int
_lib.neo_security_init.restype = _ct.c_int
_lib.neo_hardware_init.restype = _ct.c_int

class _Reserved:
    def init(self):
        raise NotImplementedError("module is reserved (NeoAPI %s)" % NEOAPI_VERSION_STRING)

class _Package(_Reserved):
    def init(self):
        if _lib.neo_package_init() == 2:  # NEO_ERR_UNIMPLEMENTED
            raise NotImplementedError("NeoPkg native resolver not yet landed (use `neo install`->pkg)")
        return True
package = _Package()
gui, ai, security, hardware = _Reserved(), _Reserved(), _Reserved(), _Reserved()

# public module object
class _System:
    def status(self): return system_status()
    def info(self): return system_info()
system = _System()

class _FS:
    def usage(self, path="/"): return fs_usage(path)
fs = _FS()

class _Net:
    def interfaces(self): return net_interfaces()
net = _Net()

class _Process:
    def top(self, n=10): return process_top(n)
process = _Process()

NEOAPI_VERSION_STRING = "1.1.0"

if __name__ == "__main__":
    init()
    print("NeoCore", version(), "NeoAPI", api_version()[:3])
    print("caps root/apt/systemd/online =", has_cap("root"), has_cap("apt"),
          has_cap("systemd"), has_cap("online"))
    print(system_info())
    print("disk / :", fs_usage("/"))
    print("interfaces:", net_interfaces())
    print("top:", process_top(3))
