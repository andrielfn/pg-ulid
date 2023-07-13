cat test/operations.sql | psql -U postgres tests -e | diff test/operations.sql.out -
cat test/benchmark.sql | psql -U postgres tests -e | diff test/benchmark.sql.out -
