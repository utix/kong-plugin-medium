local PLUGIN_NAME = "medium-test"
local helpers = require "spec.helpers"
local cjson   = require "cjson"

for _, strategy in helpers.each_strategy() do
  describe("Plugin: " .. PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      local route2 = bp.routes:insert({
        hosts = { "test2.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {
          ip_allow = {"10.0.0.1", "10.0.1.0/24"},
          ip_deny  = {"10.1.0.1", "10.1.1.0/24"},
          ip_source = "header",
          ip_header_source = "x-true-client-ip",
          mark_header = "x-limit",
          mark_action = "allow",
          header_name = "x-source",
          header_allow = {"trust"},
          header_deny = {"bad", "vilain"}
        },
      }
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route2.id },
        config = {
          ip_allow = {"10.0.0.1", "10.0.1.0/24"},
          ip_deny  = {"10.1.0.1", "10.1.1.0/24"},
          ip_source = "header",
          ip_header_source = "x-true-client-ip",
          mark_header = "x-limit",
          mark_action = "all",
          header_name = "x-source",
          header_allow = {"trust", "good"},
          header_deny = {"bad"},
        },
      }
      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

    describe("Basic", function()
        it("a request when no headers are matching the header and ip rules", function()
          local res = assert(client:send {
            method  = "GET",
            path    = "/status/200",
            headers = {
              ["Host"] = "test1.com",
            }
          })
          local body = assert.res_status(200, res)
          local json = cjson.decode(body)
          assert.equal(nil, json.headers["x-limit"])
        end)
    end)
    describe("Header", function()
      describe("Allow:", function()
        it("flag a request when it is allowed", function()
          local res = assert(client:send {
            method  = "GET",
            path    = "/status/200",
            headers = {
              ["Host"] = "test1.com",
              ["x-source"] = "trust",
            }
          })
          local body = assert.res_status(200, res)
          local json = cjson.decode(body)
          assert.equal("Allow by header", json.headers["x-limit"])
        end)
      end)

      describe("Deny:", function()
        it("blocks a request when it is denied", function()
          local res = assert(client:send {
            method  = "GET",
            path    = "/status/200",
            headers = {
              ["Host"] = "test1.com",
              ["x-source"] = "vilain",
            }
          })
          local body = assert.res_status(429, res)
          local json = cjson.decode(body)
          assert.same({ message = "Too Many Requests" }, json)
        end)
        it("flags a request when it is denied", function()
          local res = assert(client:send {
            method  = "GET",
            path    = "/status/200",
            headers = {
              ["Host"] = "test2.com",
              ["x-source"] = "bad",
            }
          })
          local body = assert.res_status(200, res)
          local json = cjson.decode(body)
          assert.equal("Block by header", json.headers["x-limit"])
        end)
      end)
    end)
  end)
end
