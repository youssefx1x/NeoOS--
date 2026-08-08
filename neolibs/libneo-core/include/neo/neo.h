#ifndef NEOLIB_NEO_H
#define NEOLIB_NEO_H

/* NeoLIBs — libneo core.
 *
 * Stable C ABI for the NeoOS NeoAPI. The on-disk ABI is stable from NeoAPI 1.0;
 * additions are strictly append-only. Symbol versioning is declared by
 * NEOAPI_VERSION_MAJOR/MINOR/MICRO below.
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

/* ---- NeoAPI version (matches the version string shipped in os-release) ---- */
#define NEOAPI_VERSION_MAJOR 1
#define NEOAPI_VERSION_MINOR 1
#define NEOAPI_VERSION_MICRO 0
#define NEOAPI_VERSION_STRING "1.1.0"
#define NEOCORE_VERSION_STRING "NeoOS 1.1.0 Stable"

/* ---- Error codes ---- */
typedef enum {
  NEO_OK              = 0,
  NEO_ERR             = 1,   /* generic failure              */
  NEO_ERR_UNIMPLEMENTED = 2, /* module/function not built    */
  NEO_ERR_NOMEM       = 3,
  NEO_ERR_IO          = 4,
  NEO_ERR_INVAL       = 5,
  NEO_ERR_NOTFOUND    = 6
} neo_err_t;

typedef struct {
  int  major;
  int  minor;
  int  micro;
  const char *tag;        /* e.g. "stable"                  */
  const char *string;     /* e.g. "1.1.0"                   */
} neo_api_version_t;

/* ---- Core: version / logging / init / capabilities ---- */
const char          *neo_version(void);          /* NEOCORE_VERSION_STRING              */
neo_api_version_t    neo_api_version(void);        /* structured NeoAPI version           */
const char          *neo_strerror(neo_err_t e);    /* stable error strings                */
neo_err_t            neo_init(unsigned flags);    /* flags: 0 reserved                   */
void                 neo_log(int level, const char *msg); /* 0=err 1=warn 2=info 3=debug   */
int                  neo_cap_has(const char *cap); /* 1 if the named capability is present */

/* ---- Common data types shared by the modules ---- */
typedef struct {
  double load1;
  double load5;
  double load15;
  unsigned long uptime_seconds;
} neo_loadavg_t;

typedef struct {
  unsigned long total_bytes;
  unsigned long avail_bytes;
  unsigned long free_bytes;
} neo_meminfo_t;

typedef struct {
  unsigned long total_bytes;
  unsigned long used_bytes;
  unsigned long avail_bytes;
  const char   *filesystem;   /* device, e.g. "/dev/root"    */
  const char   *mountpoint;   /* e.g. "/"                    */
} neo_diskinfo_t;

typedef struct {
  char iface[16];            /* interface name               */
  char ipv4[16];             /* dotted quad                */
  char mac[18];              /* aa:bb:...                    */
  int  up;                   /* 1 = carrier/interface up     */
} neo_netiface_t;

typedef struct {
  int    pid;
  int    ppid;
  int    uid;
  double cpu_percent;
  unsigned long rss_kb;
  char   comm[64];
} neo_procinfo_t;

/* A combined system snapshot — the basis of `neo system status`. */
typedef struct {
  neo_api_version_t api;
  neo_loadavg_t     loadavg;
  neo_meminfo_t     mem;
  neo_diskinfo_t    disk;          /* root filesystem            */
  neo_netiface_t    net;           /* default route iface        */
  int               users_logged;
  int               caps_root;
  int               caps_apt;
  int               caps_systemd;
  int               caps_online;
} neo_syssum_t;

#ifdef __cplusplus
}
#endif
#endif /* NEOLIB_NEO_H */
