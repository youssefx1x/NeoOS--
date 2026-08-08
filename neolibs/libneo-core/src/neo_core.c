/* libneo-core — core: version, logging, init, capabilities. */
#define _GNU_SOURCE
#include "neo.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/utsname.h>

static const char *ESTR[] = {
  [NEO_OK] = "success",
  [NEO_ERR] = "error",
  [NEO_ERR_UNIMPLEMENTED] = "not implemented",
  [NEO_ERR_NOMEM] = "out of memory",
  [NEO_ERR_IO] = "i/o error",
  [NEO_ERR_INVAL] = "invalid argument",
  [NEO_ERR_NOTFOUND] = "not found"
};

const char *neo_version(void) { return NEOCORE_VERSION_STRING; }

neo_api_version_t neo_api_version(void) {
  neo_api_version_t v;
  v.major   = NEOAPI_VERSION_MAJOR;
  v.minor   = NEOAPI_VERSION_MINOR;
  v.micro   = NEOAPI_VERSION_MICRO;
  v.tag     = "stable";
  v.string  = NEOAPI_VERSION_STRING;
  return v;
}

const char *neo_strerror(neo_err_t e) {
  if (e < 0 || e >= (int)(sizeof(ESTR)/sizeof(ESTR[0]))) return "unknown error";
  return ESTR[e];
}

neo_err_t neo_init(unsigned flags) {
  (void)flags;
  return NEO_OK;
}

void neo_log(int level, const char *msg) {
  const char *lvl = "INFO";
  if (level < 0 || level > 3) lvl = "INFO";
  static const char *lvls[] = { "ERR", "WARN", "INFO", "DEBUG" };
  if (level >= 0 && level <= 3) lvl = lvls[level];
  fprintf(stderr, "[neo:%s] %s\n", lvl, msg ? msg : "");
}

int neo_cap_has(const char *cap) {
  if (!cap) return 0;
  if (strcmp(cap, "root") == 0)     return geteuid() == 0 ? 1 : 0;
  if (strcmp(cap, "systemd") == 0)   return access("/run/systemd/system", F_OK) == 0 ? 1 : 0;
  if (strcmp(cap, "apt") == 0) {
    /* apt presence: check apt-get binary */
    return access("/usr/bin/apt-get", X_OK) == 0 ? 1 : 0;
  }
  if (strcmp(cap, "online") == 0)    return access("/run/systemd/timesync", F_OK) == 0 ? 1 : 0; /* best-effort */
  if (strcmp(cap, "gui") == 0) {
    const char *d = getenv("DISPLAY");
    const char *w = getenv("WAYLAND_DISPLAY");
    return (d && *d) || (w && *w) ? 1 : 0;
  }
  return 0;
}
