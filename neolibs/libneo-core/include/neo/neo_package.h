#ifndef NEOLIB_NEO_PACKAGE_H
#define NEOLIB_NEO_PACKAGE_H
#include "neo.h"

/* NeoPkg 2.0 native bindings (planned). Currently a reserved stub:
 * returns NEO_ERR_UNIMPLEMENTED. The pkg shell frontend remains the source
 * of truth until the native resolver is landed. */
neo_err_t neo_package_init(void);

#endif /* NEOLIB_NEO_PACKAGE_H */
