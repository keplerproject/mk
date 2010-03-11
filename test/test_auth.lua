
local auth = require "mk.auth"
local crypto = require "crypto"
local util = require "wsapi.util"

local login_salt = "LOGIN_SALT"
local session_salt = "SESSION_SALT"

local users = {
  mascarenhas = crypto.hmac.digest("sha1", "foobar", login_salt),
  carregal = crypto.hmac.digest("sha1", "baz", login_salt),
}

local function login(user, pass)
  if users[user] == pass then
    return user
  elseif users[user] then
    return nil, "invalid password"
  else
    return nil, "user not found"
  end
end

do
  -- basic login
  local a = auth.new(login, login_salt, session_salt)
  local user, message = a:login("mascarenhas", "foobar")
  assert(user == "mascarenhas")
  assert(a:authenticate(message) == "mascarenhas")
end

do
  -- wrong password
  local a = auth.new(login, login_salt, session_salt)
  local user, message = a:login("mascarenhas", "foo")
  assert(not user)
  assert(message == "invalid password")
end

do
  -- unknown user
  local a = auth.new(login, login_salt, session_salt)
  local user, message = a:login("fabio", "foo")
  assert(not user)
  assert(message == "user not found")
end

do
  -- login expired
  local a = auth.new(login, login_salt, session_salt, 0)
  local user, message = a:login("mascarenhas", "foobar")
  assert(user == "mascarenhas")
  user, message = a:authenticate(message)
  assert(not user)
  assert(message == "login expired")
end

do
  -- try to impersonate user
  local a = auth.new(login, login_salt, session_salt)
  local user, message = a:login("mascarenhas", "foobar")
  assert(user == "mascarenhas")
  message = message:gsub("mascarenhas", "carregal")
  user, message = a:authenticate(message)
  assert(not user)
  assert(message == "invalid login")
end

do
  -- try to change expiration
  local a = auth.new(login, login_salt, session_salt, 0)
  local user, message = a:login("mascarenhas", "foobar")
  assert(user == "mascarenhas")
  message = message:gsub("exp=%d+", "exp=" .. (os.time() + 3600))
  user, message = a:authenticate(message)
  assert(not user)
  assert(message == "invalid login")
end

do
  -- test salt algorithm
  local a = auth.new(login, login_salt, session_salt)
  assert(users["mascarenhas"] == a:salt_password("foobar"))
end

local function make_wsapi_app(user)
  return function (wsapi_env)
	   assert(wsapi_env.REMOTE_USER == (user or ""))
	 end
end

local function make_env_get(qs)
   return {
      REQUEST_METHOD = "GET",
      QUERY_STRING = qs or "",
      CONTENT_LENGTH = 0,
      PATH_INFO = "/",
      SCRIPT_NAME = "",
      CONTENT_TYPE = "x-www-form-urlencoded",
      input = {
         read = function () return nil end
      }
   }
end

local function make_env_post(pd, type, qs)
   pd = pd or ""
   return {
      REQUEST_METHOD = "POST",
      QUERY_STRING = qs or "",
      CONTENT_LENGTH = #pd,
      PATH_INFO = "/",
      CONTENT_TYPE = type or "x-www-form-urlencoded",
      SCRIPT_NAME = "",
      input = {
         post_data = pd,
         current = 1,
         read = function (self, len)
                   if self.current > #self.post_data then return nil end
                   local s = self.post_data:sub(self.current, len)
                   self.current = self.current + len
                   return s
                end
      }
   }
end

do
  -- successful login with json data
  local a = auth.new(login, login_salt, session_salt)
  local env = make_env_post("json=" .. json.encode({ username = "mascarenhas",
						     password = "foobar",
						     success = "/done",
						     failure = "/fail" }))
  local status, headers, res = a:provider()(env)
  assert(status == 302)
  assert(headers["Location"] == "/done")
  local cookie = util.url_decode(headers["Set-Cookie"]:match("mk_auth_user=(.-);"))
  local user, message = a:authenticate(cookie)
  assert(user == "mascarenhas")
end

do
  -- bad login with json data, wrong password
  local a = auth.new(login, login_salt, session_salt)
  local env = make_env_post("json=" .. json.encode({ username = "mascarenhas",
						     password = "foo",
						     success = "/done",
						     failure = "/fail" }))
  local status, headers, res = a:provider()(env)
  assert(status == 302)
  assert(headers["Location"] == "/fail?message=invalid+password")
  assert(headers["Set-Cookie"]:match("mk_auth_user=xxx"))
end

do
  -- bad login with json data, unknown user
  local a = auth.new(login, login_salt, session_salt)
  local env = make_env_post("json=" .. json.encode({ username = "fabio",
						     password = "foo",
						     success = "/done",
						     failure = "/fail" }))
  local status, headers, res = a:provider()(env)
  assert(status == 302)
  assert(headers["Location"] == "/fail?message=user+not+found")
  assert(headers["Set-Cookie"]:match("mk_auth_user=xxx"))
end

do
  -- successful login with regular post data
  local a = auth.new(login, login_salt, session_salt)
  local env = make_env_post("username=mascarenhas&password=foobar&success=/done&failure=/fail")
  local status, headers, res = a:provider()(env)
  assert(status == 302)
  assert(headers["Location"] == "/done")
  local cookie = util.url_decode(headers["Set-Cookie"]:match("mk_auth_user=(.-);"))
  local user, message = a:authenticate(cookie)
  assert(user == "mascarenhas")
end

do
  -- successful authorization
  local a = auth.new(login, login_salt, session_salt)
  local env = make_env_get()
  local user, message = a:login("mascarenhas", "foobar")
  env.HTTP_COOKIE = "mk_auth_user=" .. util.url_encode(message)
  local ok = pcall(a:filter(make_wsapi_app("mascarenhas")), env)
  assert(ok)
end

do
  -- unsuccessful authorization, no cookie
  local a = auth.new(login, login_salt, session_salt)
  local env = make_env_get()
  local ok = pcall(a:filter(make_wsapi_app("mascarenhas")), env)
  assert(not ok)
end

do
  -- unsuccessful authorization, expired cookie
  local a = auth.new(login, login_salt, session_salt, 0)
  local user, message = a:login("mascarenhas", "foobar")
  local env = make_env_get()
  env.HTTP_COOKIE = "mk_auth_user=" .. util.url_encode(message)
  local ok = pcall(a:filter(make_wsapi_app("mascarenhas")), env)
  assert(not ok)
end

do
  -- unsuccessful authorization, forged cookie
  local a = auth.new(login, login_salt, session_salt, 0)
  local user, message = a:login("mascarenhas", "foobar")
  local env = make_env_get()
  env.HTTP_COOKIE = "mk_auth_user=" .. util.url_encode(message:gsub("mascarenhas", "carregal"))
  local ok = pcall(a:filter(make_wsapi_app("carregal")), env)
  assert(not ok)
end
