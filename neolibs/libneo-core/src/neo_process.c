/* libneo-process — process introspection. */
#define _GNU_SOURCE
#include "neo_process.h"

#include <stdio.h>
#include <string.h>

int neo_process_top(neo_procinfo_t *out, int n) {
  if (!out || n <= 0) return 0;
  char cmd[128];
  snprintf(cmd, sizeof(cmd),
           "ps -eo pid,ppid,user:32,%%cpu,%%mem,rss,comm --sort=-%%cpu 2>/dev/null | "
           "head -n %d | tail -n +2", n + 1);
  FILE *f = popen(cmd, "r");
  if (!f) return 0;
  int i = 0;
  char line[512];
  while (fgets(line, sizeof(line), f) && i < n) {
    unsigned int pid = 0, ppid = 0; unsigned long rss = 0;
    double cpu = 0.0, mem = 0.0; char user[48] = ""; char comm[128] = "";
    if (sscanf(line, "%u %u %47s %lf %lf %lu %127[^\n]",
               &pid, &ppid, user, &cpu, &mem, &rss, comm) >= 6) {
      out[i].pid = (int)pid;
      out[i].ppid = (int)ppid;
      out[i].uid = 0;
      out[i].cpu_percent = cpu;
      out[i].rss_kb = rss;
      size_t clen = strlen(comm);
      if (clen >= sizeof(out[i].comm)) clen = sizeof(out[i].comm) - 1;
      memcpy(out[i].comm, comm, clen);
      out[i].comm[clen] = '\0';
      i++;
    }
  }
  pclose(f);
  return i;
}
