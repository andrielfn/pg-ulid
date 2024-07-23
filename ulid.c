#include <string.h>
#include <time.h>
#include <stdint.h>

#include "postgres.h"
#include "access/hash.h"
#include "access/htup.h"
#include "fmgr.h"
#include "lib/stringinfo.h"
#include "libpq/pqformat.h"

#include "utils/timestamp.h"

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

#define ULID_TIMESTAMP_LENGTH 6
#define ULID_RANDOM_LENGTH 10

struct ulid {
  uint8_t data[ULID_TIMESTAMP_LENGTH + ULID_RANDOM_LENGTH];
};

static const char *Encoding = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
static const uint64_t EpochMillis = 946684800000;

// Function prototypes
PG_FUNCTION_INFO_V1(gen_ulid);
Datum gen_ulid(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_to_timestamp);
Datum ulid_to_timestamp(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(timestamp_to_ulid);
Datum timestamp_to_ulid(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_in);
Datum ulid_in(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_out);
Datum ulid_out(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_eq);
Datum ulid_eq(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_neq);
Datum ulid_neq(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_leq);
Datum ulid_leq(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_lt);
Datum ulid_lt(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_geq);
Datum ulid_geq(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_gt);
Datum ulid_gt(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_cmp);
Datum ulid_cmp(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_recv);
Datum ulid_recv(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_send);
Datum ulid_send(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(ulid_hash);
Datum ulid_hash(PG_FUNCTION_ARGS);

// For debugging
// elog(NOTICE, "Timestamp -----> %lld", ulid->timestamp);
// elog(NOTICE, "Randomness -----> %lld", ulid->randomness);

__inline__ static void generate_ulid(struct ulid *ulid) {
  struct timespec tp;
  uint64_t timestamp;

  // Get the current time using CLOCK_REALTIME
  // CLOCK_REALTIME represents the system's best-guess as to the current
  // wall-clock, time-of-day time. It measures the amount of time (in seconds
  // and nanoseconds) since the Epoch (January 1, 1970). The time is returned
  // in the struct timespec format.
  clock_gettime(CLOCK_REALTIME, &tp);

  // Convert the time to milliseconds and store it in a 64-bit unsigned
  // integer The time is represented as the number of milliseconds since the
  // Unix epoch (January 1, 1970). We multiply the number of seconds by 1000
  // to convert it to milliseconds. We add the number of nanoseconds divided
  // by 1,000,000 to get the remaining milliseconds. This gives us a 64-bit
  // integer representing the current time in milliseconds.
  timestamp = (uint64_t)tp.tv_sec * 1000 + tp.tv_nsec / 1000000;

  // Encode the lower 6 bytes of the timestamp in the first six bytes of the
  // ULID data. The reason for encoding the lower 6 bytes of the timestamp is
  // to reduce the size of the ULID representation. Since a ULID uses a
  // base32 encoding scheme, each character represents 5 bits of information.
  // By encoding only the lower 6 bytes (48 bits) of the timestamp instead of
  // all 8 bytes (64 bits), the resulting ULID will be 2 characters shorter
  // (6 characters instead of 8 characters). This reduces the length of the
  // ULID string and saves storage space.
  ulid->data[0] = (uint8_t)(timestamp >> 40);
  ulid->data[1] = (uint8_t)(timestamp >> 32);
  ulid->data[2] = (uint8_t)(timestamp >> 24);
  ulid->data[3] = (uint8_t)(timestamp >> 16);
  ulid->data[4] = (uint8_t)(timestamp >> 8);
  ulid->data[5] = (uint8_t)(timestamp);

  // This code generates a 80-bit random number using the pg_strong_random
  // function. The pg_strong_random function generates a cryptographically
  // strong random number using the operating system's random number
  // generator. The generated number is stored in the 'random' part of
  // the ulid, which are the last 10 bytes of the ulid->data array.
  // The first byte of randomness starts directly after the timestamp.
  // The data array is a 16-byte array, so the 10 bytes (80 bits) of
  // randomness start at the 7th byte (index 6 == ULID_TIMESTAMP_LENGTH)
  // of the array.
  pg_strong_random(&(ulid->data[ULID_TIMESTAMP_LENGTH]), ULID_RANDOM_LENGTH);

  // Set the most significant bit of the first entropy byte to 0
  ulid->data[ULID_TIMESTAMP_LENGTH] &= 0x7F;
}

__inline__ static void ulid_to_string(const struct ulid *ulid, char *str) {
  // Extract the ULID data
  const uint8_t *data = ulid->data;

  // Encode the timestamp portion
  str[0] = Encoding[(data[0] & 0xE0) >> 5];
  str[1] = Encoding[data[0] & 0x1F];
  str[2] = Encoding[(data[1] & 0xF8) >> 3];
  str[3] = Encoding[((data[1] & 0x07) << 2) | ((data[2] & 0xC0) >> 6)];
  str[4] = Encoding[(data[2] & 0x3E) >> 1];
  str[5] = Encoding[((data[2] & 0x01) << 4) | ((data[3] & 0xF0) >> 4)];
  str[6] = Encoding[((data[3] & 0x0F) << 1) | ((data[4] & 0x80) >> 7)];
  str[7] = Encoding[(data[4] & 0x7C) >> 2];
  str[8] = Encoding[((data[4] & 0x03) << 3) | ((data[5] & 0xE0) >> 5)];
  str[9] = Encoding[data[5] & 0x1F];

  // Encode the randomness portion
  str[10] = Encoding[(data[6] & 0xF8) >> 3];
  str[11] = Encoding[((data[6] & 0x07) << 2) | ((data[7] & 0xC0) >> 6)];
  str[12] = Encoding[(data[7] & 0x3E) >> 1];
  str[13] = Encoding[((data[7] & 0x01) << 4) | ((data[8] & 0xF0) >> 4)];
  str[14] = Encoding[((data[8] & 0x0F) << 1) | ((data[9] & 0x80) >> 7)];
  str[15] = Encoding[(data[9] & 0x7C) >> 2];
  str[16] = Encoding[((data[9] & 0x03) << 3) | ((data[10] & 0xE0) >> 5)];
  str[17] = Encoding[data[10] & 0x1F];
  str[18] = Encoding[(data[11] & 0xF8) >> 3];
  str[19] = Encoding[((data[11] & 0x07) << 2) | ((data[12] & 0xC0) >> 6)];
  str[20] = Encoding[(data[12] & 0x3E) >> 1];
  str[21] = Encoding[((data[12] & 0x01) << 4) | ((data[13] & 0xF0) >> 4)];
  str[22] = Encoding[((data[13] & 0x0F) << 1) | ((data[14] & 0x80) >> 7)];
  str[23] = Encoding[(data[14] & 0x7C) >> 2];
  str[24] = Encoding[((data[14] & 0x03) << 3) | ((data[15] & 0xE0) >> 5)];
  str[25] = Encoding[data[15] & 0x1F];

  str[26] = '\0';
}

// Function to generate a ULID
Datum gen_ulid(PG_FUNCTION_ARGS) {
  struct ulid *ulid = (struct ulid *)palloc(sizeof(struct ulid));
  generate_ulid(ulid);
  PG_RETURN_POINTER(ulid);
}

// Function to convert ULID to timestamp
Datum ulid_to_timestamp(PG_FUNCTION_ARGS) {
  struct ulid *ulid = (struct ulid *)PG_GETARG_POINTER(0);
  TimestampTz ts;

  uint64_t timestamp = 0;

  // Extract the timestamp from the ULID data
  const uint8_t *data = ulid->data;

  timestamp |= (uint64_t)data[0] << 40;
  timestamp |= (uint64_t)data[1] << 32;
  timestamp |= (uint64_t)data[2] << 24;
  timestamp |= (uint64_t)data[3] << 16;
  timestamp |= (uint64_t)data[4] << 8;
  timestamp |= (uint64_t)data[5];

  // Subtract the epoch time in milliseconds for January 1, 2000, at 00:00:00 UTC
  // from the timestamp to get the number of milliseconds since that epoch time.
  // The resulting value is then multiplied by 1000 to convert it to seconds.
  ts = (((TimestampTz)timestamp) - EpochMillis) * 1000;

  PG_RETURN_TIMESTAMPTZ(ts);
}

Datum timestamp_to_ulid(PG_FUNCTION_ARGS) {
    TimestampTz ts = PG_GETARG_TIMESTAMPTZ(0);
    struct ulid *ulid = (struct ulid *)palloc(sizeof(struct ulid));

    // Convert the timestamp to milliseconds
    uint64_t timestamp = (uint64_t)(ts / 1000) + EpochMillis;

    // Encode the timestamp in ULID format
    ulid->data[0] = (uint8_t)(timestamp >> 40);
    ulid->data[1] = (uint8_t)(timestamp >> 32);
    ulid->data[2] = (uint8_t)(timestamp >> 24);
    ulid->data[3] = (uint8_t)(timestamp >> 16);
    ulid->data[4] = (uint8_t)(timestamp >> 8);
    ulid->data[5] = (uint8_t)timestamp;

    // Generate random bytes for the randomness part (similar to generate_ulid)
    pg_strong_random(&(ulid->data[ULID_TIMESTAMP_LENGTH]), ULID_RANDOM_LENGTH);
    ulid->data[ULID_TIMESTAMP_LENGTH] &= 0x7F;
    PG_RETURN_POINTER(ulid);
}

// Helper function to decode a ULID character to its corresponding value
static inline uint8_t decodeULIDChar(const char c) {
  const char *pos = strchr(Encoding, c);
  if (pos == NULL) {
    ereport(ERROR, (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION), errmsg("Invalid ULID: invalid character")));
  }
  return (uint8_t)(pos - Encoding);
}

// Helper function to decode a ULID string to its binary representation.
static void decodeULIDString(const char *ulid_str, uint8_t *data) {
  data[0] = (decodeULIDChar(ulid_str[0]) << 5) | decodeULIDChar(ulid_str[1]);
  data[1] = (decodeULIDChar(ulid_str[2]) << 3) | (decodeULIDChar(ulid_str[3]) >> 2);
  data[2] = (decodeULIDChar(ulid_str[3]) << 6) | (decodeULIDChar(ulid_str[4]) << 1) | (decodeULIDChar(ulid_str[5]) >> 4);
  data[3] = (decodeULIDChar(ulid_str[5]) << 4) | (decodeULIDChar(ulid_str[6]) >> 1);
  data[4] = (decodeULIDChar(ulid_str[6]) << 7) | (decodeULIDChar(ulid_str[7]) << 2) | (decodeULIDChar(ulid_str[8]) >> 3);
  data[5] = (decodeULIDChar(ulid_str[8]) << 5) | decodeULIDChar(ulid_str[9]);
  data[6] = (decodeULIDChar(ulid_str[10]) << 3) | (decodeULIDChar(ulid_str[11]) >> 2);
  data[7] = (decodeULIDChar(ulid_str[11]) << 6) | (decodeULIDChar(ulid_str[12]) << 1) | (decodeULIDChar(ulid_str[13]) >> 4);
  data[8] = (decodeULIDChar(ulid_str[13]) << 4) | (decodeULIDChar(ulid_str[14]) >> 1);
  data[9] = (decodeULIDChar(ulid_str[14]) << 7) | (decodeULIDChar(ulid_str[15]) << 2) | (decodeULIDChar(ulid_str[16]) >> 3);
  data[10] = (decodeULIDChar(ulid_str[16]) << 5) | decodeULIDChar(ulid_str[17]);
  data[11] = (decodeULIDChar(ulid_str[18]) << 3) | (decodeULIDChar(ulid_str[19]) >> 2);
  data[12] = (decodeULIDChar(ulid_str[19]) << 6) | (decodeULIDChar(ulid_str[20]) << 1) | (decodeULIDChar(ulid_str[21]) >> 4);
  data[13] = (decodeULIDChar(ulid_str[21]) << 4) | (decodeULIDChar(ulid_str[22]) >> 1);
  data[14] = (decodeULIDChar(ulid_str[22]) << 7) | (decodeULIDChar(ulid_str[23]) << 2) | (decodeULIDChar(ulid_str[24]) >> 3);
  data[15] = (decodeULIDChar(ulid_str[24]) << 5) | decodeULIDChar(ulid_str[25]);
}

Datum ulid_in(PG_FUNCTION_ARGS) {
  char *ulid_str = PG_GETARG_CSTRING(0);
  struct ulid *ulid = (struct ulid *)palloc(sizeof(struct ulid));

  if (strlen(ulid_str) != 26) {
    ereport(ERROR, (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION), errmsg("Invalid ULID: incorrect size")));
  }

  decodeULIDString(ulid_str, ulid->data);

  PG_RETURN_POINTER(ulid);
}

Datum ulid_out(PG_FUNCTION_ARGS) {
  struct ulid *ulid = (struct ulid *)PG_GETARG_POINTER(0);
  char *ulid_str = palloc(17);

  ulid_to_string(ulid, ulid_str);

  PG_RETURN_CSTRING(ulid_str);
}

Datum ulid_eq(PG_FUNCTION_ARGS) {
  struct ulid *ulid1 = (struct ulid *)PG_GETARG_POINTER(0);
  struct ulid *ulid2 = (struct ulid *)PG_GETARG_POINTER(1);

  int r = memcmp(ulid1->data, ulid2->data, sizeof(ulid1->data));

  PG_RETURN_BOOL(r == 0);
}

Datum ulid_neq(PG_FUNCTION_ARGS) {
  struct ulid *ulid1 = (struct ulid *)PG_GETARG_POINTER(0);
  struct ulid *ulid2 = (struct ulid *)PG_GETARG_POINTER(1);

  int r = memcmp(ulid1->data, ulid2->data, sizeof(ulid1->data));

  PG_RETURN_BOOL(r != 0);
}

Datum ulid_leq(PG_FUNCTION_ARGS) {
  struct ulid *ulid1 = (struct ulid *)PG_GETARG_POINTER(0);
  struct ulid *ulid2 = (struct ulid *)PG_GETARG_POINTER(1);

  int r = memcmp(ulid1->data, ulid2->data, sizeof(ulid1->data));

  PG_RETURN_BOOL(r <= 0);
}

Datum ulid_lt(PG_FUNCTION_ARGS) {
  struct ulid *ulid1 = (struct ulid *)PG_GETARG_POINTER(0);
  struct ulid *ulid2 = (struct ulid *)PG_GETARG_POINTER(1);

  int r = memcmp(ulid1->data, ulid2->data, sizeof(ulid1->data));

  PG_RETURN_BOOL(r < 0);
}

Datum ulid_geq(PG_FUNCTION_ARGS) {
  struct ulid *ulid1 = (struct ulid *)PG_GETARG_POINTER(0);
  struct ulid *ulid2 = (struct ulid *)PG_GETARG_POINTER(1);

  int r = memcmp(ulid1->data, ulid2->data, sizeof(ulid1->data));

  PG_RETURN_BOOL(r >= 0);
}

Datum ulid_gt(PG_FUNCTION_ARGS) {
  struct ulid *ulid1 = (struct ulid *)PG_GETARG_POINTER(0);
  struct ulid *ulid2 = (struct ulid *)PG_GETARG_POINTER(1);

  int r = memcmp(ulid1->data, ulid2->data, sizeof(ulid1->data));

  PG_RETURN_BOOL(r > 0);
}

Datum ulid_cmp(PG_FUNCTION_ARGS) {
  struct ulid *ulid1 = (struct ulid *)PG_GETARG_POINTER(0);
  struct ulid *ulid2 = (struct ulid *)PG_GETARG_POINTER(1);

  int r = memcmp(ulid1->data, ulid2->data, sizeof(ulid1->data));

  PG_RETURN_INT32(r);
}

Datum ulid_recv(PG_FUNCTION_ARGS) {
  StringInfo buf = (StringInfo)PG_GETARG_POINTER(0);
  struct ulid *ulid = (struct ulid *)palloc(sizeof(struct ulid));

  memcpy(ulid->data, pq_getmsgbytes(buf, sizeof(ulid->data)), sizeof(ulid->data));

  PG_RETURN_POINTER(ulid);
}

Datum ulid_send(PG_FUNCTION_ARGS) {
  struct ulid *ulid = (struct ulid *)PG_GETARG_POINTER(0);
  StringInfoData buf;

  pq_begintypsend(&buf);
  pq_sendbytes(&buf, (char *)ulid->data, sizeof(ulid->data));

  PG_RETURN_BYTEA_P(pq_endtypsend(&buf));
}

Datum ulid_hash(PG_FUNCTION_ARGS) {
  struct ulid *ulid = (struct ulid *)PG_GETARG_POINTER(0);
  Datum result = hash_any(ulid->data, sizeof(ulid->data));
  PG_RETURN_DATUM(result);
}
