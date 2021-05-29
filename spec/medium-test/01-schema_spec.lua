local PLUGIN_NAME = "medium-test"
local schema_def = require("kong.plugins."..PLUGIN_NAME..".schema")
local v = require("spec.helpers").validate_plugin_config_schema


describe("Plugin: " .. PLUGIN_NAME .. " (schema), ", function()
  it("minimal conf validates", function()
    assert(v({ }, schema_def))
  end)
  it("full conf validates", function()
    assert(v({
      header_name = "foo",
      header_allow = { "allow" },
      header_deny= { "deny" },
      mark_header = "x-mark",
      mark_action = "all",
    }, schema_def))
  end)
  describe("Errors", function()
    it("mark_action invalid value", function()
      local config = { mark_action = "foo" }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.same({
        mark_action = 'expected one of: none, allow, deny, all'
      }, err.config)
    end)
    it("mark_action without mark_header", function()
      local config = { mark_action = "all" }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.same({
        mark_header = 'required field missing'
      }, err.config)
    end)
  end)

end)
