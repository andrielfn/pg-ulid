# Postgres ULID extension

This extension enables efficient storage and manipulation of 128-bit [Universal Unique Identifiers (ULIDs)](https://github.com/ulid/spec). It introduces the 'ulid' data type, along with functions, operators, and indexing using hash and btree operator classes.

## Why use this extension?

The ULID specification provides an excellent alternative to UUIDs, offering sortable and timestamp-inclusive 128-bit identifiers. This extension for PostgreSQL offers several benefits over other ULID implementations:

- **Blazing-fast performance:** Implemented in **C**, ensuring high-speed operations.
- **ULID generation:** Built-in support for generating ULIDs using the `gen_ulid()` function.
- **Seamless integration:** Utilizes the **PostgreSQL extension framework**, making installation and usage hassle-free.
- **Efficient storage:** Employs a **binary storage format**, resulting in more efficient storage compared to using TEXT for ULIDs.
- **Native data type:** Introduces the **ULID data type**, enabling the creation of ULID columns.
- **Indexing support:** Enables the creation of indexes on ULID columns for improved query performance.
- **Timestamp casting:** Supports casting ULIDs to timestamps for flexible data manipulation.
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

You can also cast ULIDs to timestamps:

It's also possible to cast the ULIDs to a timestamp:

```sql
SELECT '01H588JF7X0005PX34XGNZBBGV'::ulid::timestamp;
SELECT ulid_to_timestamp('01H588JF7X0005PX34XGNZBBGV');
SELECT id, id::timestamp FROM users;
```

And a timestamp to an ULID:

```sql
SELECT '2023-11-16 19:30:15'::timestamp::ulid;
SELECT timestamp_to_ulid('2023-11-16 19:30:15');
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
Function Scan on generate_series  (cost=0.00..12500.00 rows=1000000 width=20) (actual time=60.599..466.261 rows=1000000 loops=1)
Planning Time: 0.594 ms
Execution Time: 486.315 ms
(3 rows)
```

And now ULIDs:

```sql
EXPLAIN ANALYZE SELECT gen_ulid(), * FROM generate_series(1, 1000000);
                                                            QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
Function Scan on generate_series  (cost=0.00..12500.00 rows=1000000 width=20) (actual time=95.891..704.558 rows=1000000 loops=1)
Planning Time: 0.125 ms
Execution Time: 724.032 ms
(3 rows)
```

As we can see generating ULIDs is slower than generating UUIDs, however, the difference is not that big, and the ULID generation algorithm is still very fast.

## License

This software is distributed under the terms of the MIT License. See the [LICENSE](LICENSE) file for more details.
