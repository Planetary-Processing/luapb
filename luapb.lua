require "utils"

local ffi = require "ffi"

local pp = ffi.load("./libluapb.so")

ffi.cdef([[
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

  int getVarintLength(unsigned char bytes[], int num);

  byte_array encodeVarint(uint64_t v);
  uint64_t decodeVarint(unsigned char bytes[], int num);

  uint64_t encodeTag(uint64_t wiretype, uint64_t fieldnum);
  tag decodeTag(uint64_t in);

  record decodeRecord(unsigned char bytes[], int num);
]])

print("decodeVarint")
print(tonumber(pp.decodeVarint(ffi.new("unsigned char[2]", {0x96, 0x01}), 2))) -- should be 150
print(tonumber(ffi.cast("int64_t", pp.decodeVarint(ffi.new("unsigned char[10]", {0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01}), 10)))) -- should be -2 (casted for easy reading)

print("\nencodeVarint")
printl(arrToTable(pp.encodeVarint(150))) -- should be {96, 01}
printl(arrToTable(pp.encodeVarint(0xFFFFFFFFFFFFFFFEULL))) -- should be {fe, ff, ff, ff, ff, ff, ff, ff, ff, 01}

print("\ndecodeTag")
local tag = pp.decodeTag(0x08)
print(tag.fieldnum, tag.wiretype) -- should be 1, 0

print("\nencodeTag")
print(pp.encodeTag(1, 0)) -- should be 8

print("\ndecodeRecord")
local rec = pp.decodeRecord(ffi.new("unsigned char[9]", {0x12, 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x67}), 9)
print(rec.tag.fieldnum, rec.tag.wiretype) -- should be 2, 2
print(rec.length) -- should be 9
print(rec.bytes.length) -- should be 7
printl(arrToTable(rec.bytes)) -- should be {74, 65, 73, 74, 69, 6e, 67}
