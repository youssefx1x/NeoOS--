/* libneo-net — networking introspection. */
#define _GNU_SOURCE
#include "neo_net.h"

#include <stdio.h>
#include <string.h>

neo_err_t neo_net_default_iface(char *buf, size_t len) {
  if (!buf || !len) return NEO_ERR_INVAL;
  FILE *f = fopen("/proc/net/route", "r");
  char line[256];
  buf[0] = '\0';
  if (!f) return NEO_ERR_IO;
  while (fgets(line, sizeof(line), f)) {
    char iface[16], dest[16];
    if (sscanf(line, "%15s %15s", iface, dest) == 2 &&
        strcmp(dest, "00000000") == 0) {
      snprintf(buf, len, "%s", iface);
      fclose(f);
      return NEO_OK;
    }
  }
  fclose(f);
  return NEO_ERR_NOTFOUND;
}

neo_err_t neo_net_ipv4(const char *iface, char *buf, size_t len) {
  if (!iface || !buf || !len) return NEO_ERR_INVAL;
  char cmd[256];
  snprintf(cmd, sizeof(cmd),
           "ip -o -4 addr show dev %s 2>/dev/null | awk '{print $4}' | head -1",
           iface);
  FILE *f = popen(cmd, "r");
  if (!f) return NEO_ERR_IO;
  char out[64];
  int got = fgets(out, sizeof(out), f) ? 1 : 0;
  pclose(f);
  if (!got) { buf[0] = '\0'; return NEO_ERR_NOTFOUND; }
  out[strcspn(out, "\n")] = '\0';
  char *slash = strpbrk(out, "/"); if (slash) *slash = '\0';
  char *p = out; while (*p == ' ') p++;
  snprintf(buf, len, "%s", p);
  return NEO_OK;
}

int neo_net_interfaces(neo_netiface_t *out, int cap) {
  if (!out || cap <= 0) return 0;
  FILE *f = fopen("/proc/net/route", "r");
  if (!f) return 0;
  char line[256]; int i = 0;
  while (fgets(line, sizeof(line), f) && i < cap) {
    char iface[16];
    if (sscanf(line, "%15s", iface) != 1 || iface[0] == '\0') continue;
    /* skip the header line "Iface" */
    if (strcmp(iface, "Iface") == 0) continue;
    memset(&out[i], 0, sizeof(out[i]));
    size_t ilen = strlen(iface);
    if (ilen >= sizeof(out[i].iface)) ilen = sizeof(out[i].iface) - 1;
    memcpy(out[i].iface, iface, ilen);
    out[i].iface[ilen] = '\0';
    /* mac */
    char p[256];
    snprintf(p, sizeof(p), "/sys/class/net/%s/address", iface);
    FILE *g = fopen(p, "r");
    if (g) { fgets(out[i].mac, sizeof(out[i].mac), g); fclose(g); out[i].up = 1; }
    /* ipv4 */
    if (neo_net_ipv4(iface, out[i].ipv4, sizeof(out[i].ipv4)) == NEO_OK) out[i].up = 1;
    i++;
  }
  fclose(f);
  return i;
}
