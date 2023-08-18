require "utils"

local bit = require "bit64"
local ffi = require "ffi"
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

local function bytesToFloat(bytes)
  local sign = 1
  local mantissa = bytes[3] % 128
  for i = 2, 1, -1 do mantissa = mantissa * 256 + bytes[i] end
  if bytes[4] > 127 then sign = -1 end
  local exponent = (bytes[4] % 128) * 2 +
                   math.floor(bytes[3] / 128)
  if exponent == 0 then return 0 end
  mantissa = (math.ldexp(tonumber(mantissa), -23) + 1) * sign
  return math.ldexp(mantissa, exponent - 127)
end

local function bytesToDouble(bytes)
  local sign = 1
  local mantissa = tonumber(bit.band(0x0F, bytes[7]))
  for i = 6, 1, -1 do mantissa = mantissa * 256 + bytes[i] end
  if bytes[8] > 127 then sign = -1 end
  local exponent = (bytes[8] % 128) * 16 +
                   math.floor(tonumber(bit.band(0xF0, bytes[7])) / 16)
  print(bit.tohex(exponent), exponent)
  if exponent == 0 then return 0 end
  mantissa = (math.ldexp(mantissa, -52) + 1) * sign
  print(mantissa)
  return math.ldexp(mantissa, exponent - 1023)
end

local function encodeTag(fieldnum, wiretype)
  return bit.bor(bit.lshift(fieldnum, 3), wiretype)
end

local function decodeTag(tag) --wiretype, fieldnum
  return bit.band(tag, 0x3),bit.rshift(tag, 3)
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
      outraw[fieldnum] = decodeVarint(tmp)
    elseif wiretype == 1 then -- I64
      tmp,msg = split(msg, 8)
      outraw[fieldnum] = decodeIN(tmp)
    elseif wiretype == 2 then -- LEN
      tmp,msg = split(msg, getVarintLength(msg))
      outraw[fieldnum],msg = split(msg, decodeVarint(tmp))
    elseif wiretype == 5 then -- I32
      tmp,msg = split(msg, 4)
      outraw[fieldnum] = decodeIN(tmp)
    end -- 3 and 4 are deprecated, haven't bothered to implement them
  end
  return outraw
end

function varintToInt32(vi)
  tonumber(int32(vi))
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

function i32ToFloat(i32)
  return tonumber(float(i32))
end

function i64ToDouble(i64)
  return tonumber(double(i64))
end

function bytesToString(bts)
  for i,b in ipairs(bts) do
    bts[i] = string.char(b)
  end
  return bts
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
printkv(bytesToString({0x61, 0x62, 0x63}))

-- output
local luapb = {}
return luapb
