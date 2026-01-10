CREATE EXTENSION ulid;

-- Round-trip parsing (parse -> output -> same string)
SELECT '01H539HMN700009Y99Q81VWK04'::ulid::text = '01H539HMN700009Y99Q81VWK04' AS roundtrip;

-- Case-insensitive input (output is always uppercase)
SELECT '01h539hmn700009y99q81vwk04'::ulid::text = '01H539HMN700009Y99Q81VWK04' AS lowercase_input;
SELECT '01H539hmn700009Y99q81VWK04'::ulid::text = '01H539HMN700009Y99Q81VWK04' AS mixedcase_input;

-- Invalid characters rejected (I, L, O, U are not in ULID alphabet)
SELECT '01H539HMNI00009Y99Q81VWK04'::ulid;
SELECT '01H539HMNL00009Y99Q81VWK04'::ulid;
SELECT '01H539HMNO00009Y99Q81VWK04'::ulid;
SELECT '01H539HMNU00009Y99Q81VWK04'::ulid;

-- Invalid length rejected
SELECT '01H539HMN7'::ulid;
SELECT '01H539HMN700009Y99Q81VWK04XX'::ulid;
