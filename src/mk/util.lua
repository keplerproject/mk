
local util = {}

function util.loadin(file, env)
  env = env or {}
  local f, err = loadfile(file)
  if not f then
    return nil, err
  else
    setfenv(f, env)
    local ok, err = pcall(f)
    if ok then
      return env
    else
      return nil, err
    end
  end
end

function util.readfile(filename)
  local file, err = io.open(filename, "rb")
  if file then
    local str = file:read("*a")
    file:close()
    return str
  else
    return nil, err
  end
end

function util.tostring(o)
  local out = {}
  if type(o) == "table" then
    out[#out+1] = "{ "
    for k, v in pairs(o) do
      out[#out+1] = "[" .. util.tostring(k) .. "] = " .. util.tostring(v) .. ", "
    end
    out[#out+1] = "}"
  elseif type(o) == "string" then
    out[#out+1] = o:format("%q")
  else
    out[#out+1] = tostring(o)
  end
  return table.concat(out)
end

return util
