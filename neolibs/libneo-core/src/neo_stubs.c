/* libneo — reserved stubs for modules shipped as headers only in this release.
 * Each returns NEO_ERR_UNIMPLEMENTED so bindings can detect availability. */
#define _GNU_SOURCE
#include "neo_gui.h"
#include "neo_ai.h"
#include "neo_security.h"
#include "neo_hardware.h"

neo_err_t neo_gui_init(void)        { return NEO_ERR_UNIMPLEMENTED; }
neo_err_t neo_ai_init(void)         { return NEO_ERR_UNIMPLEMENTED; }
neo_err_t neo_security_init(void)   { return NEO_ERR_UNIMPLEMENTED; }
neo_err_t neo_hardware_init(void)   { return NEO_ERR_UNIMPLEMENTED; }
