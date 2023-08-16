local bit = require "bit"

function printx(x)
  print(strx(x))
end

function strx(x)
  return string.sub(bit.tohex(x), -2)
end

function printl(l)
  s = "{"
  for i,x in ipairs(l) do
    s = s .. strx(x)
    if i ~= #l then
      s = s .. ", "
    end
  end
  s = s .. "}"
  print(s)
end

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
  bytes = {}
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

printl(encodeVarint(150))

local function decodeVarint(bytes)
  x = 0
  for i,b in ipairs(bytes) do
    b = bit.lshift(bit.band(b, 0x7f), (i-1) * 8 - (i-1))
    x = bit.bor(x, b)
  end
  return x
end

print(decodeVarint({0x96, 0x01}))

local function encodeTag(fieldnum, wiretype)
  return bit.bor(bit.lshift(fieldnum, 3), wiretype)
end

printx(encodeTag(1, 0))

local function decodeTag(tag)
  return bit.band(tag, 0x3),bit.rshift(tag, 3)
end

print(decodeTag(0x08))
