package = "mk"

version = "scm-1"

description = {
  summary = "Kepler base framework",
  detailed = [[
    A simple framework for Kepler applications
  ]],
  license = "MIT/X11",
  homepage = "http://keplerproject.github.com/mk"
}

dependencies = { "wsapi == cvs" }

source = {
  url = "git://github.com/keplerproject/mk.git"
}

build = {
  type = "builtin",
  modules = {
    ["mk"] = "src/mk.lua",
    ["mk.routes"] = "src/mk/routes.lua",
    ["mk.util"] = "src/mk/util.lua",
    ["mk.themes"] = "src/mk/themes.lua",
    ["mk.template"] = "src/mk/template.lua",
    ["mk.auth"] = "src/mk/auth.lua",
  },
  copy_directories = { "samples", "doc", "tests" },
}
