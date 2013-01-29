package = "mk"

version = "0.1-1"

description = {
  summary = "Kepler base framework",
  detailed = [[
    A simple framework for Kepler applications
  ]],
  license = "MIT/X11",
  homepage = "http://keplerproject.github.com/mk"
}

dependencies = { "wsapi >= 1.6" }

source = {
  url = "http://www.keplerproject.org/files/mk-0.1.tar.gz"
}

build = {
  type = "builtin",
  modules = {
    ["mk"] = "src/mk.lua",
    ["mk.routes"] = "src/mk/routes.lua",
    ["mk.forms"] = "src/mk/forms.lua",
    ["mk.blocks"] = "src/mk/blocks.lua",
    ["mk.util"] = "src/mk/util.lua",
    ["mk.themes"] = "src/mk/themes.lua",
    ["mk.template"] = "src/mk/template.lua",
    ["mk.auth"] = "src/mk/auth.lua",
    ["mk.cache"] = "src/mk/cache.lua",
  },
  copy_directories = { "samples", "doc", "tests" },
}
