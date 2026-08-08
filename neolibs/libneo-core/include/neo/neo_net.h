#ifndef NEOLIB_NEO_NET_H
#define NEOLIB_NEO_NET_H
#include "neo.h"

/* neo_net_default_iface — name of the default-route interface into buf. */
neo_err_t neo_net_default_iface(char *buf, size_t len);

/* neo_net_ipv4 — primary IPv4 (dotted-quad) of iface into buf. */
neo_err_t neo_net_ipv4(const char *iface, char *buf, size_t len);

/* neo_net_interfaces — fill up to `cap` neo_netiface_t entries, return count. */
int neo_net_interfaces(neo_netiface_t *out, int cap);

#endif /* NEOLIB_NEO_NET_H */
