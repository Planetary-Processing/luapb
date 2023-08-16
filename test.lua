local ffi = require "ffi"

local lt = ffi.load("./libtest.so")

ffi.cdef([[
  int32_t getVarintLength(unsigned char bytes[], int num);
]])

local arr = ffi.new("unsigned char[6]", {0x96, 0x96, 0x96, 0x01, 0x95, 0x96})

print(tonumber(lt.getVarintLength(arr, 6)))
