/* tests/test_neo.c — minimal sanity test for the NeoAPI C core. */
#include "neo.h"
#include "neo_system.h"
#include "neo_fs.h"
#include "neo_net.h"
#include "neo_process.h"
#include "neo_package.h"

#include <stdio.h>
#include <string.h>

static int failures = 0;
#define CHECK(cond, msg) do { if (!(cond)) { printf("FAIL: %s\n", msg); failures++; } } while (0)

int main(void) {
  neo_api_version_t v = neo_api_version();
  CHECK(v.major == NEOAPI_VERSION_MAJOR, "api major version");
  CHECK(v.minor == NEOAPI_VERSION_MINOR, "api minor version");
  printf("NeoCore %s / NeoAPI %s\n", neo_version(), v.string);
  CHECK(strcmp(neo_version(), NEOCORE_VERSION_STRING) == 0, "neo_version string");

  CHECK(neo_init(0) == NEO_OK, "neo_init");
  CHECK(neo_cap_has("root") >= 0, "neo_cap_has root");

  neo_syssum_t s;
  CHECK(neo_system_status(&s) == NEO_OK, "neo_system_status");
  printf("  uptime=%lus load1=%.2f mem_total=%lu disk_total=%lu iface=%s\n",
         s.loadavg.uptime_seconds, s.loadavg.load1,
         s.mem.total_bytes, s.disk.total_bytes, s.net.iface);

  char kernel[64] = "", arch[32] = "", host[64] = "", os[128] = "", ver[32] = "";
  CHECK(neo_system_info(kernel, arch, host, os, ver) == NEO_OK, "neo_system_info");
  printf("  kernel=%s arch=%s host=%s os=%s ver=%s\n", kernel, arch, host, os, ver);

  unsigned long used=0, avail=0, total=0;
  CHECK(neo_fs_usage("/", &used, &avail, &total) == NEO_OK, "neo_fs_usage");

  char iface[16] = "";
  CHECK(neo_net_default_iface(iface, sizeof(iface)) == NEO_OK || iface[0] == '\0',
        "neo_net_default_iface");

  neo_procinfo_t procs[5];
  int n = neo_process_top(procs, 5);
  printf("  top procs sampled: %d\n", n);

  CHECK(neo_package_init() == NEO_ERR_UNIMPLEMENTED, "neo_package_init stub");

  if (failures == 0) { printf("ALL CHECKS PASSED\n"); return 0; }
  printf("%d CHECK(S) FAILED\n", failures);
  return 1;
}
