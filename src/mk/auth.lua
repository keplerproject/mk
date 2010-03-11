
local crypto = require "crypto"
local json = require "json"
local request = require "wsapi.request"
local response = require "wsapi.response"
local util = require "wsapi.util"

local auth = {}

local methods = {}
methods.__index = methods

function auth.new(login_function, login_salt, session_salt, expiration)
  return setmetatable({ login_function = login_function,
			login_salt = login_salt, 
			session_salt = session_salt,
		        expiration = expiration or 3600 }, methods)
end

function methods:login(username, password, expiration)
  local expiration = expiration or (os.time() + self.expiration)
  local salted_password = crypto.hmac.digest("sha1", password, self.login_salt)
  local user, message = self.login_function(username, salted_password)
  if user then
    local res = response.new(nil, headers)
    message = "exp=" .. expiration .. "&data=" .. json.encode(user)
    message = message .. "&digest=" .. crypto.hmac.digest("sha1", message, self.session_salt)
  end
  return user, message
end

function methods:salt_password(password)
  return crypto.hmac.digest("sha1", password, self.login_salt)
end

function methods:logoff(headers)
  local res = response.new(nil, headers)
  res:delete_cookie("mk_auth_user")
end

function methods:authenticate(message)
  local message, digest = message:match("^(.-)&digest=(.*)$")
  if message and digest == crypto.hmac.digest("sha1", message, self.session_salt) then
    local exp, data = message:match("^exp=(.-)&data=(.+)$")
    local expiration, user = tonumber(exp), json.decode(data)
    if os.time() < expiration then
      return user
    else
      return nil, "login expired"
    end
  end
  return nil, "invalid login"
end

function methods:filter(wsapi_app)
  return function (wsapi_env, ...)
	   local message = (";" .. (wsapi_env.HTTP_COOKIE or "")
			  .. ";"):match(";%s*mk_auth_user=(.-)%s*;")
	   if message then
	     message = util.url_decode(message) 
	     wsapi_env.MK_AUTH_USER, wsapi_env.MK_AUTH_ERROR = self:authenticate(message)
	   end
	   return wsapi_app(wsapi_env, ...)
	 end
end

function methods:provider()
  return function (wsapi_env)
	   local req = request.new(wsapi_env)
	   local res = response.new()
	   local data = req.POST.json and json.decode(req.POST.json)
	   if not data then
	     data = { username = req.POST.username, 
		      password = req.POST.password,
		      expiration = tonumber(req.POST.expiration),
		      success = req.POST.success, failure = req.POST.failure }
	   end
	   local expires = data.expiration or (os.time() + self.expiration) -- one hour
	   local user, message = self:login(data.username, data.password, expires)
	   if user then
	     res:set_cookie("mk_auth_user", { value = message, expires = expires })
	     return res:redirect(data.success)
	   else
	     res:delete_cookie("mk_auth_user")
	     return res:redirect(data.failure .. "?message=" .. util.url_encode(message))
	   end
	 end
end

return auth
