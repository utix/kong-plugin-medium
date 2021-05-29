local typedefs = require "kong.db.schema.typedefs"
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

return {
  name = plugin_name,
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
      type = "record",
      fields = {
        { header_name = typedefs.header_name },
        { header_allow = {
          type = "array",
          elements = { type = "string" },
          default = {}
        }},
        { header_deny = {
          type = "array",
          elements = { type = "string" },
          default = {}
        }},
        -- For CDN the ip is in general into the true-client-ip header
        { ip_source = {
          type = "string",
          default = "forwarded_ip",
          one_of = {"connection", "forwarded_ip", "header"},
        } },
        { ip_header_source = typedefs.header_name },

        { ip_allow = { type = "array", elements = typedefs.ip_or_cidr, },},
        { ip_deny =  { type = "array", elements = typedefs.ip_or_cidr, },},

        -- Header to flag query
        { mark_header = typedefs.header_name },
        -- deny and all mode will not block the query just flag it
        { mark_action = { type = "string", default = "none", one_of = {"none", "allow", "deny", "all"}, } },
      },
    } },
  },
  entity_checks = {
    { conditional = {
      if_field = "config.mark_action", if_match = { ne = "none" },
      then_field = "config.mark_header", then_match = { required = true },
    } },
  },
}
