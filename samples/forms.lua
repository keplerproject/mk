
local mk = require "mk"
local forms = require "mk.forms"
local util = require "mk.util"
local R = require "mk.routes"
local request = require "wsapi.request"
local response = require "wsapi.response"
local cosmo = require "cosmo"
local json = require "json"

local template = (...) or "tests/form_example.tmpl"

local server = mk.new()

local data = {
  title = "Foo",
  body = "bar blaz lorem ipsum",
  published = true,
  section = math.random(3),
  subsection = math.random(3),
  tags = { 2, 4 },
  keywords = { 1, 3 },
  published_at =  "2010-01-25T03:00:00Z",
  detail = {
    { id = 1, name = "Foo" },
    { id = 2, name = "Bar" }
  }
}

function server:getdata(req, res)
  res:content_type("application/json")
  res:write(json.encode(data))
end

function server:postdata(req, res)
  res:content_type("application/json")
  print("post")
  print(req.POST.json)
  local obj = json.decode(req.POST.json)
  print(obj.published == true)
  if obj.published then
    res:write([[{ "message": "There were errors", "fields": { "title": "required field" } }]])
  else
    res:write("{}")
  end
end

function server:getsections(req, res)
  res:content_type("application/json")
  res:write([[{ "list": [ { "id": 1, "name": "Section 1" }, { "id": 2, "name": "Section 2" }, 
		  { "id": 3, "name": "Section 3" } ] }]])
end

function server:gettags(req, res)
  res:content_type("application/json")
  res:write([[{ "list": [ { "id": 1, "name": "tag1" }, { "id": 2, "name": "tag2" }, 
		  { "id": 3, "name": "tag3" }, { "id": 4, "name": "tag4" } ] }]])
end

function server:index(req, res)
  local template = req.env.APP_PATH .. "/" .. (req.GET.template or "sample_form.tmpl") 
  res:write(cosmo.fill(util.readfile(template), { form = forms.form, javascript = forms.javascript,
						css = forms.css, req = req }))
end

server:dispatch_get("index", R"/", server:wrap("index"))
server:dispatch_get("main", R"/main", server:wrap("index"))
server:dispatch_get("get_data", R"/data", server:wrap("getdata"))
server:dispatch_post("post_data", R"/data", server:wrap("postdata"))
server:dispatch_get("get_other", R"/other", server:wrap("getdata"))
server:dispatch_post("post_other", R"/other", server:wrap("postdata"))
server:dispatch_get("sections", R"/sections", server:wrap("getsections"))
server:dispatch_get("tags", R"/tags", server:wrap("gettags"))

return server
