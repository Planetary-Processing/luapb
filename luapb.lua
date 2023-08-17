require "utils"

local bit = require "bit64"

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
  table.sort(bytes, function(i, j) return i > j end)
  for i=1,#bytes-1 do
    bytes[i] = bit.bor(0x80, bytes[i])
  end
  return bytes
end

local function decodeVarint(bytes)
  local x = 0
  for i,b in ipairs(bytes) do
    b = bit.band(b, 0x7f) * math.pow(2, (i-1) * 8 - (i-1))
    x = x + b
  end
  return x
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
      outraw[fieldnum],msg = split(msg, 8)
    elseif wiretype == 2 then -- LEN
      tmp,msg = split(msg, getVarintLength(msg))
      outraw[fieldnum],msg = split(msg, decodeVarint(tmp))
    elseif wiretype == 5 then -- I32
      tmp,msg = split(msg, 4)
      outraw[fieldnum] = tmp
    end -- 3 and 4 are deprecated, haven't bothered to implement them
  end
  return outraw
end

-- tests
print("tests")
printl(encodeVarint(150ULL))
printl(encodeVarint(0xFFFFFFFFFFFFFFFEULL))
print(decodeVarint({0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01}))
print(decodeVarint({0x96, 0x01}))
printx(encodeTag(1, 0))
print(decodeTag(0x08))
printkv(deserialiseRaw({0x08, 0x96, 0x01}))
printkv(deserialiseRaw({0x08, 0x96, 0x01, 0x12, 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x67}))

-- output
local luapb = {}
return luapb
