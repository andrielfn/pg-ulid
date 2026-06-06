MODULE_big = ulid
OBJS = ulid.o

EXTENSION = ulid
DATA = ulid--0.0.1.sql
MODULES = ulid

# pg_regress configuration
REGRESS = generation parsing timestamp operators indexing uuid
REGRESS_OPTS = --inputdir=test --outputdir=test

PG_CONFIG ?= pg_config

CFLAGS=`$(PG_CONFIG) --includedir-server`
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
