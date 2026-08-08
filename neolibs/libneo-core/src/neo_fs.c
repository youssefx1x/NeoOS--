/* libneo-fs — filesystem queries. */
#define _GNU_SOURCE
#include "neo_fs.h"

#include <stdio.h>
#include <string.h>
#include <sys/statfs.h>

neo_err_t neo_fs_usage(const char *path,
                       unsigned long *used, unsigned long *avail,
                       unsigned long *total) {
  if (!path || !used || !avail || !total) return NEO_ERR_INVAL;
  struct statfs st;
  if (statfs(path, &st) != 0) return NEO_ERR_IO;
  unsigned long bs = (unsigned long)st.f_bsize;
  *total = (unsigned long)st.f_blocks * bs;
  *used  = ((unsigned long)st.f_blocks - (unsigned long)st.f_bfree) * bs;
  *avail = (unsigned long)st.f_bavail * bs;
  return NEO_OK;
}

neo_err_t neo_fs_dir_count(const char *path, int *count) {
  if (!path || !count) return NEO_ERR_INVAL;
  int n = 0;
  char cmd[512];
  /* Count regular files + directories (depth 1), excluding . and .. */
  snprintf(cmd, sizeof(cmd),
           "find %s -maxdepth 1 -mindepth 1 2>/dev/null | wc -l", path);
  FILE *f = popen(cmd, "r");
  if (!f) return NEO_ERR_IO;
  if (fscanf(f, "%d", &n) != 1) n = 0;
  pclose(f);
  *count = n;
  return NEO_OK;
}
