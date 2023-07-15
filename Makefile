MODULE_big = ulid
OBJS = ulid.o

EXTENSION = ulid
DATA = ulid--0.0.1.sql
MODULES = ulid

CFLAGS=`pg_config --includedir-server`

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
