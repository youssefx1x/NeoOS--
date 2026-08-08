/* libneo-system — System API: status/info/services. */
#define _GNU_SOURCE
#include "neo_system.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/statfs.h>

static char __disk_fs[64];
static char __disk_mnt[128];

static void _loadavg(neo_loadavg_t *l) {
  FILE *f = fopen("/proc/loadavg", "r");
  if (f) {
    if (fscanf(f, "%lf %lf %lf %*d/%*d %*d",
               &l->load1, &l->load5, &l->load15) == 3) {}
    fclose(f);
  } else {
    l->load1 = l->load5 = l->load15 = 0.0;
  }
  FILE *u = fopen("/proc/uptime", "r");
  double up = 0.0;
  if (u) { fscanf(u, "%lf", &up); fclose(u); }
  l->uptime_seconds = (unsigned long)up;
}

static void _meminfo(neo_meminfo_t *m) {
  FILE *f = fopen("/proc/meminfo", "r");
  unsigned long total = 0, avail = 0, free_ = 0;
  char key[32]; unsigned long v;
  if (f) {
    while (fscanf(f, "%31[^:]: %lu", key, &v) == 2) {
      if (strcmp(key, "MemTotal") == 0) total = v;
      else if (strcmp(key, "MemAvailable") == 0) avail = v;
      else if (strcmp(key, "MemFree") == 0) free_ = v;
    }
    fclose(f);
  }
  m->total_bytes = total * 1024;
  m->avail_bytes = avail ? avail * 1024 : free_ * 1024;
  m->free_bytes  = free_ * 1024;
}

static void _disk(neo_diskinfo_t *d, const char *path) {
  struct statfs st;
  if (statfs(path, &st) == 0 && st.f_blocks > 0) {
    unsigned long bs = (unsigned long)st.f_bsize;
    d->total_bytes  = (unsigned long)st.f_blocks * bs;
    d->used_bytes   = ((unsigned long)st.f_blocks - (unsigned long)st.f_bfree) * bs;
    d->avail_bytes  = (unsigned long)st.f_bavail * bs;
    strncpy(__disk_mnt, path, sizeof(__disk_mnt) - 1);
    __disk_mnt[sizeof(__disk_mnt) - 1] = '\0';
    snprintf(__disk_fs, sizeof(__disk_fs), "root");
    d->filesystem = __disk_fs;
    d->mountpoint = __disk_mnt;
    return;
  }
  memset(d, 0, sizeof(*d));
  d->filesystem = "";
  d->mountpoint = path;
}

static void _default_iface(neo_netiface_t *n) {
  memset(n, 0, sizeof(*n));
  FILE *f = fopen("/proc/net/route", "r");
  char line[256];
  n->iface[0] = '\0';
  if (f) {
    while (fgets(line, sizeof(line), f)) {
      /* column 0 = iface, column 1 = Destination; "00000000" = default route */
      char iface[16], dest[16];
      if (sscanf(line, "%15s %15s", iface, dest) == 2 &&
          strcmp(dest, "00000000") == 0) {
        size_t il = strlen(iface);
        if (il >= sizeof(n->iface) - 1) il = sizeof(n->iface) - 2;
        memcpy(n->iface, iface, il);
        n->iface[il] = '\0';
        break;
      }
    }
    fclose(f);
  }
  if (n->iface[0]) {
    char p[256];
    snprintf(p, sizeof(p), "/sys/class/net/%s/address", n->iface);
    FILE *g = fopen(p, "r");
    if (g) { fgets(n->mac, sizeof(n->mac), g); fclose(g); }
    /* ipv4 via `ip` if available */
    FILE *ip = popen("ip -o -4 addr show dev %s 2>/dev/null | awk '{print $4}'", n->iface);
    if (ip) {
      char buf[64];
      if (fgets(buf, sizeof(buf), ip)) {
        /* buf like "10.0.0.4/24"; take prefix before '/' */
        char *s = strpbrk(buf, "/"); if (s) *s = '\0';
        buf[strcspn(buf, "\n")] = '\0';
        /* strip trailing spaces */
        char *p2 = buf; while (*p2 == ' ') p2++;
        size_t vlen = strlen(p2);
        if (vlen >= sizeof(n->ipv4) - 1) vlen = sizeof(n->ipv4) - 2;
        memcpy(n->ipv4, p2, vlen);
        n->ipv4[vlen] = '\0';
      }
      pclose(ip);
    }
    n->up = 1;
  }
}

neo_err_t neo_system_status(neo_syssum_t *out) {
  if (!out) return NEO_ERR_INVAL;
  memset(out, 0, sizeof(*out));
  out->api = neo_api_version();
  _loadavg(&out->loadavg);
  _meminfo(&out->mem);
  _disk(&out->disk, "/");
  _default_iface(&out->net);
  FILE *who = popen("who 2>/dev/null | wc -l", "r");
  if (who) { int u = 0; fscanf(who, "%d", &u); out->users_logged = u; pclose(who); }
  out->caps_root    = neo_cap_has("root");
  out->caps_apt     = neo_cap_has("apt");
  out->caps_systemd = neo_cap_has("systemd");
  out->caps_online  = neo_cap_has("online");
  return NEO_OK;
}

neo_err_t neo_system_info(char kernel[64], char arch[32], char host[64],
                          char os[128], char ver[32]) {
  struct utsname u;
  if (uname(&u) == 0) {
    snprintf(kernel, 64, "%s", u.release);
    snprintf(arch, 32, "%s", u.machine);
  } else {
    snprintf(kernel, 64, "%s", "unknown");
    snprintf(arch, 32, "%s", "unknown");
  }
  FILE *h = fopen("/proc/sys/kernel/hostname", "r");
  if (h) { fgets(host, 64, h); host[strcspn(host, "\n")] = '\0'; fclose(h); }
  if (host[0] == '\0') gethostname(host, 64);

  FILE *o = fopen("/etc/os-release", "r");
  os[0] = ver[0] = '\0';
  if (o) {
    char line[256];
    while (fgets(line, sizeof(line), o)) {
      char *k = strndup(line, strcspn(line, "="));
      char *v = line + strcspn(line, "=\n") + 1;
      v[strcspn(v, "\n")] = '\0';
      if (strcmp(k, "PRETTY_NAME") == 0) { /* strip surrounding quotes */
        char *q = v; while (*q == '"') q++; char *e = q + strlen(q);
        while (e > q && *(e-1) == '"') *--e = '\0';
        snprintf(os, 128, "%s", q);
      } else if (strcmp(k, "VERSION_ID") == 0) snprintf(ver, 32, "%s", v);
      free(k);
    }
    fclose(o);
  }
  if (os[0] == '\0') snprintf(os, 128, "NeoOS");
  return NEO_OK;
}

int neo_system_service_active(const char *unit) {
  if (!unit) return -1;
  /* Requires systemd; otherwise we cannot introspect units natively. */
  if (!neo_cap_has("systemd")) return -1;
  char cmd[256];
  snprintf(cmd, sizeof(cmd), "systemctl is-active '%s' 2>/dev/null", unit);
  FILE *f = popen(cmd, "r");
  if (!f) return -1;
  char buf[32]; int rc = -1;
  if (fgets(buf, sizeof(buf), f)) {
    buf[strcspn(buf, "\n")] = '\0';
    rc = (strcmp(buf, "active") == 0) ? 1 : 0;
  }
  pclose(f);
  return rc;
}
