#ifndef NEOLIB_NEO_FS_H
#define NEOLIB_NEO_FS_H
#include "neo.h"

/* neo_fs_usage — bytes used/available/total for a path's filesystem. */
neo_err_t neo_fs_usage(const char *path,
                       unsigned long *used, unsigned long *avail,
                       unsigned long *total);

/* neo_fs_dir_count — count regular entries under path (depth 1). */
neo_err_t neo_fs_dir_count(const char *path, int *count);

#endif /* NEOLIB_NEO_FS_H */
