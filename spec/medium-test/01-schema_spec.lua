local PLUGIN_NAME = "medium-test"
local schema_def = require("kong.plugins."..PLUGIN_NAME..".schema")
local v = require("spec.helpers").validate_plugin_config_schema


describe("Plugin: " .. PLUGIN_NAME .. " (schema), ", function()
  it("minimal conf validates", function()
    assert(v({ }, schema_def))
  end)
end)
