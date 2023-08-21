-- utils
function strx(x)
  return string.sub(bit.tohex(x), -2)
end

function printx(x)
  print(strx(x))
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

function strkv(l)
  s = "{"
  for k,v in pairs(l) do
    if type(v) == "table" then
      s = s .. "(" .. tostring(k) .. ":" .. strkv(v) .. "), "
    else
      s = s .. "(" .. tostring(k) .. ":" .. tostring(v) .. "), "
    end
  end
  s = s:sub(1, -3)
  s = s .. "}"
  return s
end

function printkv(l)
  print(strkv(l))
end

function bytesToString(bts)
  local out = ""
  for _,v in ipairs(bts) do
    out = out .. string.char(v)
  end
  return out
end

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
