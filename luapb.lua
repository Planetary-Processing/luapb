local bit = require "bit64"
local ffi = require "ffi"

ffi.cdef([[
void free(void *ptr);
void* malloc(size_t size);
]])

function split(arr, n)
  l = {}
  r = {}
  for i,x in ipairs(arr) do
    if i <= n then
      table.insert(l, x)
    else
      table.insert(r, x)
    end
  end
  return l,r
end

function copy(t)
  local out = {}
  for k,v in pairs(t) do
    out[k] = v
  end
  return out
end

local casts = {
  uint64= ffi.typeof("uint64_t"),
  uint32=ffi.typeof("uint32_t"),
  int64= ffi.typeof("int64_t"),
  int32= ffi.typeof("int32_t"),
  float= ffi.typeof("float"),
  double= ffi.typeof("double"),
  enum=ffi.typeof("uint64_t"),
  bool=ffi.typeof("uint64_t"),
}

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

local function typeToBytes(typename, typesize)
  return function(v)
    local p = ffi.gc(ffi.C.malloc(typesize), ffi.C.free)
    p = ffi.cast(typename.."*", p)
    p[0] = v
    p = ffi.cast("unsigned char*", p)
    local out = {}
    for i=0,typesize-1 do
      table.insert(out, p[i])
    end
    return out
  end
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
      table.insert(outraw, {field=fieldnum, wiretype=wiretype, data=decodeVarint(tmp)})
    elseif wiretype == 1 then -- I64
      tmp,msg = split(msg, 8)
      table.insert(outraw, {field=fieldnum, wiretype=wiretype, data=tmp})
    elseif wiretype == 2 then -- LEN
      tmp,msg = split(msg, getVarintLength(msg))
      tmp,msg = split(msg, decodeVarint(tmp))
      table.insert(outraw, {field=fieldnum, wiretype=wiretype, data=tmp})
    elseif wiretype == 5 then -- I32
      tmp,msg = split(msg, 4)
      table.insert(outraw, {field=fieldnum, wiretype=wiretype, data=tmp})
    end -- 3 and 4 are deprecated, haven't bothered to implement them
  end
  return outraw
end

function varintToInt32(vi)
  return tonumber(casts.int32(vi))
end

function varintToInt64(vi)
  return tonumber(casts.int64(vi))
end

function varintToUint64(vi)
  return tonumber(vi)
end

function varintToUint32(vi)
  return tonumber(casts.uint32(vi))
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

function stringToBytes(str)
  local bytes = { string.byte(str, 1,-1) }
  return bytes
end

local deserialisers = {
  int64 = varintToInt64,
  int32 = varintToInt32,
  uint64 = varintToUint64,
  uint32 = varintToUint32,
  string = bytesToString,
  double = bytesToDouble,
  float = bytesToFloat,
  bool = varintToBool,
  enum = varingToEnum,
  bytes = function (x) return x end
}

local function decodePacked(msg, t, conv)
  local out = {}
  local tmp
  if t == "int32" or t == "uint32" or t == "int64" or t == "uint64" or t == "bool" or t == "enum" then
    while #msg > 0 do
      tmp,msg = split(msg, getVarintLength(msg))
      table.insert(out, conv(decodeVarint(tmp)))
    end
  elseif t == "double" then
    while #msg > 0 do
      tmp,msg = split(msg, 8)
      table.insert(out, conv(tmp))
    end
  elseif t == "float" then
    while #msg > 0 do
      tmp,msg = split(msg, 4)
      table.insert(out, conv(tmp))
    end
  end
  return out
end

local function deserialise(bytes, proto)
  local out = {}
  local msg = deserialiseRaw(bytes)
  for _,f in ipairs(msg) do
    local t = proto[f.field]
    local c = deserialisers[t.type]
    if t.repeated then
      if not out[t.name] then out[t.name] = {} end
      if f.wiretype == 2 and f.repeated then -- strong packed requirement
        for _,v in ipairs(decodePacked(f.data, t.type, c)) do
          table.insert(out[t.name], v)
        end
      else
        table.insert(out[t.name], c(f.data))
      end
    elseif t.type == "proto" then
      out[t.name] = deserialise(f.data, t.proto)
    elseif t.type == "map" then
      if not out[t.name] then out[t.name] = {} end
      local kv = deserialise(f.data, {[1]={type=t.keytype, name="key"}, [2]={type=t.valuetype, name="value"}})
      out[t.name][kv.key] = kv.value
    else
      out[t.name] = c(f.data)
    end
  end
  return out
end

local serialisers = {
  float=typeToBytes('float', 4),
  double=typeToBytes('double', 8),
  string=stringToBytes
}

local function serialise(msg, proto)
  local out = {}
  for k,v in pairs(msg) do
    local fn
    for i,n in pairs(proto) do
      if n.name == k then
        fn = i
        break
      end
    end
    if fn then
      local f = proto[fn]
      if f.repeated then
        for _,v in ipairs(v) do
          local ff = copy(f)
          ff.repeated = false
          local tmp = serialise({[f.name]=v}, {[fn]=ff})
          for _,b in ipairs(tmp) do
            table.insert(out, b)
          end
        end
      elseif f.type == "map" then
        for k1,v1 in pairs(v) do
          local tmp = serialise({[f.name]={key=k1, value=v1}}, {[fn]={name=f.name, type="proto", proto={[1]={type=f.keytype, name="key"}, [2]={type=f.valuetype, name="value"}}}})
          for _,b in ipairs(tmp) do
            table.insert(out, b)
          end
        end
      else
        local wt
        local payload
        if f.type == "bool" then
          v = v and 0x01 or 0x00
        end
        if f.type == "uint64" or f.type == "uint32" or f.type == "int64" or f.type == "int32" or f.type == "bool" or f.type == "enum" then
          wt = 0
          payload = encodeVarint(casts.uint64(casts[f.type](v)))
        elseif f.type == "float" then
          wt = 5
          payload = serialisers.float(v)
        elseif f.type == "double" then
          wt = 1
          payload = serialisers.double(v)
        elseif f.type == "proto" then
          wt = 2
          local tmp = serialise(v, f.proto)
          payload = encodeVarint(#tmp)
          for _,b in ipairs(tmp) do
            table.insert(payload, b)
          end
        elseif f.type == "string" then
          wt = 2
          local tmp = serialisers.string(v)
          payload = encodeVarint(#tmp)
          for _,b in ipairs(tmp) do
            table.insert(payload, b)
          end
        elseif f.type == "bytes" then
          wt = 2
          payload = encodeVarint(#v)
          for _,b in ipairs(v) do
            table.insert(payload, b)
          end
        end
        if wt then
          table.insert(out, encodeTag(fn, wt))
          for _,b in ipairs(payload) do
            table.insert(out, b)
          end
        end
      end
    end
  end
  return out
end

-- output
local luapb = {serialise=serialise, deserialise=deserialise}
return luapb
