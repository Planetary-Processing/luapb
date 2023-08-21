require "utils"

local bit = require "bit64"
local ffi = require "ffi"

ffi.cdef([[
void free(void *ptr);
void* malloc(size_t size);
]])

local uint64, uint32, int32, int64, float, double = ffi.typeof("uint64_t"), ffi.typeof("uint32_t"), ffi.typeof("int64_t"), ffi.typeof("int32_t"), ffi.typeof("float"), ffi.typeof("double")

local function getVarintLength(bytes)
  l = 0
  for _,b in ipairs(bytes) do
    l = l + 1
    if bit.rshift(b, 7) == 0 then -- continuation not set
      return l
    end
  end
  return -1
end

local function encodeVarint(varint)
  local bytes = {}
  while varint ~= 0 do
    table.insert(bytes, bit.band(0x7f, varint))
    varint = bit.rshift(varint, 7)
  end
  for i=1,#bytes-1 do
    bytes[i] = bit.bor(0x80, bytes[i])
  end
  return bytes
end

local function decodeVarint(bytes)
  local x = 0ull
  for i,b in ipairs(bytes) do
    b = bit.band(b, 0x7f) * math.pow(2, (i-1) * 8 - (i-1))
    x = x + b
  end
  return x
end

local function floatToBytes(flt)
  local p = ffi.gc(ffi.C.malloc(4), ffi.C.free)
  p = ffi.cast("float*", p)
  p[0] = flt
  p = ffi.cast("unsigned char*", p)
  return {p[0], p[1], p[2], p[3]}
end

local function doubleToBytes(flt)
  local p = ffi.gc(ffi.C.malloc(4), ffi.C.free)
  p = ffi.cast("double*", p)
  p[0] = flt
  p = ffi.cast("unsigned char*", p)
  return {p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]}
end

local function bytesToFloat(bytes)
  local p = ffi.gc(ffi.C.malloc(4), ffi.C.free)
  p = ffi.cast("unsigned char*", p)
  for i=0,3 do
    p[i] = bytes[i+1]
  end
  p = ffi.cast("float*", p)
  return p[0]
end

local function bytesToDouble(bytes)
  local p = ffi.gc(ffi.C.malloc(8), ffi.C.free)
  p = ffi.cast("unsigned char*", p)
  for i=0,7 do
    p[i] = bytes[i+1]
  end
  p = ffi.cast("double*", p)
  return p[0]
end

local function encodeTag(fieldnum, wiretype)
  return bit.bor(bit.lshift(fieldnum, 3), wiretype)
end

local function decodeTag(tag) --wiretype, fieldnum
  local w,f = bit.band(tag, 0x3),bit.rshift(tag, 3)
  return tonumber(w),tonumber(f)
end

local function deserialiseRaw(msg)
  local outraw = {}
  while #msg > 0 do
    local tmp
    tmp,msg = split(msg, getVarintLength(msg))
    local tag = decodeVarint(tmp)
    local wiretype, fieldnum = decodeTag(tag)
    if wiretype == 0 then -- varint
      tmp,msg = split(msg, getVarintLength(msg))
      table.insert(outraw, {field=fieldnum, data=decodeVarint(tmp)})
    elseif wiretype == 1 then -- I64
      tmp,msg = split(msg, 8)
      table.insert(outraw, {field=fieldnum, data=tmp})
    elseif wiretype == 2 then -- LEN
      tmp,msg = split(msg, getVarintLength(msg))
      tmp,msg = split(msg, decodeVarint(tmp))
      table.insert(outraw, {field=fieldnum, data=tmp})
    elseif wiretype == 5 then -- I32
      tmp,msg = split(msg, 4)
      table.insert(outraw, {field=fieldnum, data=tmp})
    end -- 3 and 4 are deprecated, haven't bothered to implement them
  end
  return outraw
end

function varintToInt32(vi)
  return tonumber(int32(vi))
end

function varintToInt64(vi)
  return tonumber(int64(vi))
end

function varintToUint64(vi)
  return tonumber(vi)
end

function varintToUint32(vi)
  return tonumber(uint32(vi))
end

function varintToEnum(vi)
  return varintToInt32(vi)
end

function varintToBool(vi)
  return varintToInt32(vi) > 0
end

function bytesToString(bts)
  local out = ""
  for i,b in ipairs(bts) do
    out = out .. string.char(b)
  end
  return out
end

local converters = {
  int64 = varintToInt64,
  int32 = varintToInt32,
  uint64 = varintToUint64,
  uint32 = varintToUint32,
  string = bytesToString,
  bool = varintToBool,
  enum = varingToEnum
}

function deserialise(bytes, proto)
  local out = {}
  local msg = deserialiseRaw(bytes)
  for _,f in pairs(msg) do
    local t = proto[f.field]
    local c = converters[t.type]
    if t.repeated then
      if not out[t.name] then out[t.name] = {} end
      if t.packed then

      else
        table.insert(out[t.name], c(f.data))
      end
    elseif t.type == "proto" then
      out[t.name] = deserialise(f.data, t.proto)
    elseif t.type == "map" then
      
    else
      out[t.name] = c(f.data)
    end
  end
  return out
end

-- tests
print("===== tests =====")
printl(encodeVarint(150ull))
printl(encodeVarint(0xFFFFFFFFFFFFFFFEull))
print(decodeVarint({0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01}))
print(decodeVarint({0x96, 0x01}))
printx(encodeTag(1, 0))
print(decodeTag(0x08))
printkv(deserialiseRaw({0x08, 0x96, 0x01}))
printkv(deserialiseRaw({0x08, 0x96, 0x01, 0x12, 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x67}))
print(varintToInt64(decodeVarint({0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01})))
print(varintToUint32(decodeVarint({0x96, 0x01})))
print(varintToInt64(decodeVarint({0x96, 0x01})))
print(varintToUint64(decodeVarint({0x96, 0x01})))
print(bytesToFloat({0xcd, 0xcc, 0xdc, 0x40}))
print(bytesToDouble({0xa1, 0xf8, 0x31, 0xe6, 0xd6, 0x1c, 0xc8, 0x40}))
print(bytesToString({0x61, 0x62, 0x63}))
printl(floatToBytes(6.9))
printl(doubleToBytes(12345.67890))
printkv(deserialise({0x08, 0x96, 0x01}, {[1]={type="int32", name="a"}}))
printkv(deserialise({0x22, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x28, 0x01, 0x28, 0x02, 0x28, 0x03}, {[4]={type="string", name="d"}, [5]={type="int32", name="e", repeated=true, packed=false}}))

-- output
local luapb = {}
return luapb
