# Makefile — builds the NeoLIBs C ABI core (libneo) exposing the NeoAPI.
#
#   make            build libneo.so + static libneo.a
#   make install    install to /usr/lib and /usr/include/neo
#   make check      build + run the C self-test (tests/test_neo.c)
#   make python     (no-op hook) the ctypes binding needs no build
#   make clean

CC     ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -fPIC -Iinclude -Iinclude/neo
AR     ?= ar

LIBNAME = neocore
NEOAPI_VERSION := 1.2.0
SOVERSION := 1

SRC = src/neo_core.c src/neo_system.c src/neo_fs.c src/neo_net.c \
      src/neo_process.c src/neo_package_stub.c src/neo_stubs.c

OBJ = $(SRC:.c=.o)

.PHONY: all install check python clean

all: libneo.so libneo.a libneo.so.$(SOVERSION) libneo.so.$(NEOAPI_VERSION)

libneo.so: $(OBJ)
	$(CC) $(CFLAGS) -shared -Wl,-soname,libneo.so.$(SOVERSION) \
	  -o $@ $(OBJ) -lm

libneo.so.$(SOVERSION): libneo.so
	ln -sf libneo.so $@
libneo.so.$(NEOAPI_VERSION): libneo.so
	ln -sf libneo.so $@

libneo.a: $(OBJ)
	$(AR) rcs $@ $(OBJ)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

install: all
	install -d /usr/lib /usr/include/neo
	install -m 0755 libneo.so /usr/lib/libneo.so
	ln -sf libneo.so /usr/lib/libneo.so.$(NEOAPI_VERSION)
	ln -sf libneo.so.$(NEOAPI_VERSION) /usr/lib/libneo.so.$(SOVERSION)
	cp -r include/neo /usr/include/neo

check: all
	$(CC) $(CFLAGS) -Iinclude tests/test_neo.c -L. -lneo -o tests/test_neo
	LD_LIBRARY_PATH=. ./tests/test_neo

python:
	@python3 -c 'import ctypes,sys; print("ctypes OK", ctypes.__name__)'

clean:
	$(RM) $(OBJ) libneo.so libneo.a libneo.so.$(NEOAPI_VERSION) \
	      libneo.so.$(SOVERSION) libneo.so.1 libneo.so.1.2.0
