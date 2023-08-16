#include <stdint.h>

int32_t getVarintLength(unsigned char bytes[], int num) {
  for (int l = 0; l < num; l++) {
    if (bytes[l] >> 7 == 0) {
      return l+1;
    }
  }
  return -1;
};
