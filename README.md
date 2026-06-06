# Postgres ULID extension

This extension enables efficient storage and manipulation of 128-bit [Universal Unique Identifiers (ULIDs)](https://github.com/ulid/spec). It introduces the 'ulid' data type, along with functions, operators, and indexing using hash and btree operator classes.

## Why use this extension?

The ULID specification provides an excellent alternative to UUIDs, offering sortable and timestamp-inclusive 128-bit identifiers. This extension for PostgreSQL offers several benefits over other ULID implementations:

- **Blazing-fast performance:** Implemented in **C**, ensuring high-speed operations.
- **ULID generation:** Built-in support for generating ULIDs using the `gen_ulid()` function.
- **Monotonic generation:** `gen_ulid()` is monotonic within each millisecond — IDs minted in the same millisecond from one connection are strictly increasing, never colliding, preserving sort order under heavy insert load.
- **Seamless integration:** Utilizes the **PostgreSQL extension framework**, making installation and usage hassle-free.
- **Efficient storage:** Employs a **binary storage format**, resulting in more efficient storage compared to using TEXT for ULIDs.
- **Native data type:** Introduces the **ULID data type**, enabling the creation of ULID columns.
- **Indexing support:** Enables the creation of indexes on ULID columns for improved query performance.
- **Timestamp casting:** Supports casting ULIDs to timestamps for flexible data manipulation.
- **UUID casting:** Casts losslessly between `ulid` and the native `uuid` type, making it easy to migrate existing UUID columns.
- **ULID operators:** Provides a set of operators specifically designed for ULID columns, facilitating query operations.
- **Optimized performance:** Demonstrates superior performance compared to most other ULID implementations.

## Installation

Installing this is very simple, all you need to do is this:

```sh
make install
```

## Usage

Start by creating the extension:

```sql
CREATE EXTENSION ulid;
```

Next, create a table with a column of type `ulid`:

```sql
CREATE TABLE users (
  id ulid NOT NULL DEFAULT gen_ulid() PRIMARY KEY,
  name text NOT NULL
);
```

Insert data into the table as you would with any other data type:

```sql
INSERT INTO users (name) VALUES ('John Doe');
INSERT INTO users (id, name) VALUES (gen_ulid(), 'Jane Doe');
INSERT INTO users (id, name) VALUES ('01H588JF7X0005PX34XGNZBBGV', 'Bob Doe');
```

Perform queries on the `ulid` column:

```sql
SELECT * FROM users where id = '01H588JF7X0005PX74XGNZBBGV';
```

The `ulid` data type behaves just like any other data type.

`gen_ulid()` is **monotonic**: when multiple ULIDs are generated within the same
millisecond on a connection, the random component is incremented rather than
redrawn, so the values are strictly increasing and guaranteed distinct. This
keeps inserts in sort order even under high throughput. The guarantee is
per-connection (the generator state is local to each backend), which matches how
database-side ULID generators behave.

A ULID embeds a creation time, which you can extract by casting to a timestamp.
Because a ULID encodes an absolute UTC instant, the **`timestamptz`** casts are
recommended — they respect the session time zone and round-trip the instant
exactly:

```sql
SELECT '01H588JF7X0005PX34XGNZBBGV'::ulid::timestamptz;
SELECT ulid_to_timestamptz('01H588JF7X0005PX34XGNZBBGV');
SELECT id, id::timestamptz FROM users;

-- and the other direction (now() is a timestamptz)
SELECT now()::ulid;
SELECT '2023-11-16 19:30:15+00'::timestamptz::ulid;
SELECT timestamptz_to_ulid('2023-11-16 19:30:15+00');
```

Plain `timestamp` (without time zone) casts are also available for backward
compatibility; they treat the value as UTC wall-clock and ignore the session
time zone:

```sql
SELECT '01H588JF7X0005PX34XGNZBBGV'::ulid::timestamp;
SELECT '2023-11-16 19:30:15'::timestamp::ulid;
```

You can also cast between `ulid` and the native `uuid` type. A ULID and a UUID
are both 128-bit values with the same binary layout, so the conversion is exact
and lossless in both directions:

```sql
SELECT '01H588JF7X0005PX34XGNZBBGV'::ulid::uuid;
SELECT 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid::ulid;
```

These casts are defined as `ASSIGNMENT`, so a `ulid` value can be inserted
directly into a `uuid` column (and vice versa) without an explicit cast — handy
when migrating an existing `uuid` column to `ulid`:

```sql
CREATE TABLE legacy (id uuid PRIMARY KEY);

-- a ulid value is converted to uuid automatically on insert
INSERT INTO legacy (id) VALUES (gen_ulid());
```

> Note: `uuid` → `ulid` is a pure byte reinterpretation. The leading 48 bits of
> a UUID are only a meaningful ULID timestamp if the UUID actually encodes one
> (e.g. a UUIDv4 will decode to an arbitrary timestamp), but the bytes are always
> preserved exactly on round-trip.

For raw access you can also cast a ULID to and from `bytea` — the 16 raw
big-endian bytes. These casts are **explicit only** (no implicit/assignment
coercion), and `bytea → ulid` requires exactly 16 bytes:

```sql
SELECT '01H588JF7X0005PX34XGNZBBGV'::ulid::bytea;
SELECT '\x01894698d2a7000004f929ba03be4c04'::bytea::ulid;
```

For a more practical example, check out the [IDtools](https://idtools.co/ulid) for ULID generation and decoding.

## Benchmark

Let's first compare the space required to store ULIDs in a plain TEXT column versus the ulid data type:

```sql
CREATE TABLE test_ulid    (id ulid PRIMARY KEY);
CREATE TABLE test_text    (id varchar(26) PRIMARY KEY);

INSERT INTO test_ulid SELECT gen_ulid() FROM generate_series(1,1000000);
INSERT INTO test_text SELECT gen_ulid() FROM generate_series(1,1000000);

SELECT
  relname,
  (pg_relation_size(oid) / 1024) AS relation_size_kB,
  (pg_total_relation_size(oid) / 1024) AS total_size_kB
FROM pg_class
WHERE relname LIKE 'test_%';

    relname     | relation_size_kb | total_size_kb
----------------+------------------+---------------
test_text      |            58824 |        126672
test_text_pkey |            67816 |         67816
test_ulid      |            43248 |         81624
test_ulid_pkey |            38344 |         38344
(4 rows)
```

As we can see the `ulid` data type requires less space than a plain TEXT column. This is because the ULID data type is stored as a 128-bit integer, while the TEXT column requires 32 bytes per ULID.

Another simple benchmark we can do is to compare the time required to generate 1 million UUIDs v4 and ULIDs. Let's start with UUIDs:


```sql
EXPLAIN ANALYZE SELECT uuid_generate_v4(), * FROM generate_series(1, 1000000);
                                                        QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
Function Scan on generate_series  (cost=0.00..12500.00 rows=1000000 width=20) (actual time=102.086..731.433 rows=1000000 loops=1)
Planning Time: 0.123 ms
Execution Time: 756.309 ms
(3 rows)
```

And now ULIDs:

```sql
tests=# EXPLAIN ANALYZE SELECT gen_ulid(), * FROM generate_series(1, 1000000);
                                                            QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
Function Scan on generate_series  (cost=0.00..12500.00 rows=1000000 width=20) (actual time=89.976..545.106 rows=1000000 loops=1)
Planning Time: 0.197 ms
Execution Time: 569.543 ms
(3 rows)
```

As we can see generating ULIDs is even faster than generating UUIDs, however, the difference is not that big.

_Reference machine: MacBook M1 Max 2021 running postgresql 14.11_

## License

This software is distributed under the terms of the MIT License. See the [LICENSE](LICENSE) file for more details.
