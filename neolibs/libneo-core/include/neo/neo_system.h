#ifndef NEOLIB_NEO_SYSTEM_H
#define NEOLIB_NEO_SYSTEM_H
#include "neo.h"

/* neo_system_status  — fill a neo_syssum_t snapshot (NeoCore System API). */
neo_err_t neo_system_status(neo_syssum_t *out);

/* neo_system_info  — kernel/arch/hostname/os/version strings (caller buffers). */
neo_err_t neo_system_info(char kernel[64], char arch[32], char host[64],
                          char os[128], char ver[32]);

/* neo_system_service_active — 1 if unit active, 0 inactive, <0 error. */
int neo_system_service_active(const char *unit);

#endif /* NEOLIB_NEO_SYSTEM_H */
