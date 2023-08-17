require "utils"

local ffi = require "ffi"

local l = ffi.load("./libluapb.so")

ffi.cdef([[
  typedef struct {
    unsigned char *arr;
    int length;
  } byte_array;

  int32_t getVarintLength(unsigned char bytes[], int num);
  uint64_t decodeVarint(unsigned char bytes[], int num);
  byte_array encodeVarint(uint64_t v);
]])

local arr = ffi.new("unsigned char[2]", {0x96, 0x01})

local bts = l.encodeVarint(150)
for i=0,bts.length-1 do
  print(bts.arr[i])
end
