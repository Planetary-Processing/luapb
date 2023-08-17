require "utils"

local ffi = require "ffi"

local pp = ffi.load("./libluapb.so")

ffi.cdef([[
  typedef struct {
    unsigned char *arr;
    int length;
  } byte_array;

  int32_t getVarintLength(unsigned char bytes[], int num);
  uint64_t decodeVarint(unsigned char bytes[], int num);
  byte_array encodeVarint(uint64_t v);
]])

-- test decodeVarint
print(tonumber(pp.decodeVarint(ffi.new("unsigned char[2]", {0x96, 0x01}), 2))) -- should be 150
print(tonumber(ffi.cast("int64_t", pp.decodeVarint(ffi.new("unsigned char[10]", {0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01}), 10)))) -- should be -2 (casted for easy reading)

-- test encodeVarint
printl(arrToTable(pp.encodeVarint(150))) -- should be {96, 01}
printl(arrToTable(pp.encodeVarint(0xFFFFFFFFFFFFFFFEULL))) -- should be {fe, ff, ff, ff, ff, ff, ff, ff, ff, 01}

-- test decodeTag
