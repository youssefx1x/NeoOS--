#ifndef NEOLIB_NEO_PROCESS_H
#define NEOLIB_NEO_PROCESS_H
#include "neo.h"

/* neo_process_top — fill up to `n` entries (by CPU) into out; return count. */
int neo_process_top(neo_procinfo_t *out, int n);

#endif /* NEOLIB_NEO_PROCESS_H */
