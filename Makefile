MODULE_big = ulid
OBJS = ulid.o

EXTENSION = ulid
DATA = ulid--0.0.1.sql
MODULES = ulid

PG_CONFIG ?= pg_config

CFLAGS=`$(PG_CONFIG) --includedir-server`
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
