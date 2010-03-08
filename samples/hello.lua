#!/usr/bin/env wsapi.cgi

local mk = require "mk"
local R = require "mk.routes"
local request = require "wsapi.request"
local response = require "wsapi.response"

local hello = mk.new()

function hello.index(wsapi_env)
  return hello.render_index()
end

function hello.say(wsapi_env, params)
  return hello.render_say(wsapi_env, params.name)
end

hello:dispatch_get("index", R"/", hello.index)
hello:dispatch_get("say", R"/say/:name", hello.say)

function hello.render_layout(inner_html)
  return string.format([[
      <html>
        <head><title>Hello</title></head>
        <body>%s</body>
      </html>
    ]], inner_html)
end

function hello.render_hello()
  return [[<p>Hello World!</p>]]
end

function hello.render_index()
  local res = response.new()
  res:write(hello.render_layout(hello.render_hello()))
  return res:finish()
end

function hello.render_say(wsapi_env, name)
  local req, res = request.new(wsapi_env), response.new()
  res:write(hello.render_layout(hello.render_hello() .. 
				string.format([[<p>%s %s!</p>]], req.params.greeting or "Hello ", name)))
  return res:finish()
end

return hello
