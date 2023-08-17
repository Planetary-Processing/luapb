#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct {
  unsigned char *arr;
  int length;
} byte_array;

int32_t getVarintLength(unsigned char bytes[], int num) {
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
    x += (bytes[i] & 0x7f) << (i*8 - i);
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
