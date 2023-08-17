#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct {
  unsigned char *arr;
  int32_t length;
} byte_array;

typedef struct {
  uint64_t wiretype;
  uint64_t fieldnum;
} tag;

typedef struct {
  tag tag;
  byte_array bytes;
  int32_t length;
} record;

typedef struct {
  record *records;
  int32_t num;
} message;

int getVarintLength(unsigned char bytes[], int num) {
  for (int l = 0; l < num; l++) {
    if (bytes[l] >> 7 == 0) {
      return l+1;
    }
  }
  return -1;
};

uint64_t decodeVarint(unsigned char bytes[], int num) {
  uint64_t x = 0;
  for (int i = 0; i < num; i++) {
    x |= (bytes[i] & 0x7f) << (i*8 - i);
  }
  return x;
}

byte_array encodeVarint(uint64_t v) {
  unsigned char bytes[10];
  int i = 0;
  while (v) {
    bytes[i++] = 0x7f & v;
    v = v >> 7;
  }
  int n = i;
  unsigned char *out = malloc(n);
  for (i = 0; i<n; i++){
    out[i] = bytes[i];
    if (i < n-1) {
      out[i] = out[i] | 0x80;
    }
  }
  byte_array b;
  b.arr = out;
  b.length = n;
  return b;
}

tag decodeTag(uint64_t in) {
  tag t;
  t.wiretype = in & 0x7;
  t.fieldnum = in >> 3;
  return t;
}

uint64_t encodeTag(uint64_t fieldnum, uint64_t wiretype) {
  return (fieldnum << 3) | wiretype;
}

record decodeRecord(unsigned char bytes[], int num) {
  record r;
  int l = getVarintLength(bytes, num);
  uint64_t ti = decodeVarint(bytes, l);
  tag t = decodeTag(ti);
  r.tag = t;
  r.length = l;
  int32_t size = 0;
  switch (t.wiretype) {
    case 0:
      size = getVarintLength(bytes+r.length, num-r.length);
      break;
    case 1:
      size = 8;
      break;
    case 2:
      int vil = getVarintLength(bytes+r.length, num-r.length);
      int32_t ti = (int32_t)decodeVarint(bytes+r.length, vil);
      r.length += vil;
      size = ti;
      break;
    case 3:
      break;
    case 4:
      break;
    case 5:
      size = 4;
      break;
  }
  r.bytes = (byte_array){bytes+r.length, size};
  r.length +=size;
  return r;
}
