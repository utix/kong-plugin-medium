package = "kong-plugin-medium-test"
version = "0.0.1-1"

local pluginName = package:match("^kong%-plugin%-(.+)$")  -- "medium-test"

supported_platforms = {"linux", "macosx"}

description = {
  summary = "Manomano medium test",
  homepage = "https://www.manomano.fr",
}
source = {
  url = "https://github.com/utix/kong-plugin-medium-test",
  tag = "0.0.1"
}


dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
  }
}
