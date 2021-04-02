local BasePlugin = require "kong.plugins.base_plugin"
local CustomHandler = BasePlugin:extend()


function CustomHandler:access(conf)
  CustomHandler.super.access(self)
end


return CustomHandler
