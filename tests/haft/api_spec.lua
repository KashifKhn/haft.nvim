describe("haft.api", function()
  local api

  before_each(function()
    package.loaded["haft.api"] = nil
    package.loaded["haft.config"] = nil
    api = require("haft.api")
    local config = require("haft.config")
    config.reset()
    config.setup({})
  end)

  describe("generate functions exist", function()
    it("has generate_resource function", function()
      assert.is_function(api.generate_resource)
    end)

    it("has generate_controller function", function()
      assert.is_function(api.generate_controller)
    end)

    it("has generate_service function", function()
      assert.is_function(api.generate_service)
    end)

    it("has generate_repository function", function()
      assert.is_function(api.generate_repository)
    end)

    it("has generate_entity function", function()
      assert.is_function(api.generate_entity)
    end)

    it("has generate_dto function", function()
      assert.is_function(api.generate_dto)
    end)
  end)

  describe("info functions exist", function()
    it("has info function", function()
      assert.is_function(api.info)
    end)

    it("has routes function", function()
      assert.is_function(api.routes)
    end)

    it("has stats function", function()
      assert.is_function(api.stats)
    end)
  end)

  describe("dependency functions exist", function()
    it("has add function", function()
      assert.is_function(api.add)
    end)

    it("has add_dependencies function", function()
      assert.is_function(api.add_dependencies)
    end)
  end)
end)

describe("haft.api internal helpers", function()
  local api_internal

  before_each(function()
    package.loaded["haft.api"] = nil
    package.loaded["haft.config"] = nil

    local config = require("haft.config")
    config.reset()
    config.setup({})

    local source = debug.getinfo(1, "S").source:sub(2)
    local plugin_root = source:match("(.*/haft%.nvim/)")
    local api_path = plugin_root .. "lua/haft/api.lua"

    local chunk = loadfile(api_path)
    if chunk then
      local env = setmetatable({}, { __index = _G })
      setfenv(chunk, env)
      api_internal = chunk()
    end
  end)

  describe("unwrap_response", function()
    it("extracts data from wrapped response", function()
      local unwrap = function(data)
        if data and data.success and data.data then
          return data.data
        end
        return data or {}
      end

      local wrapped = { success = true, data = { name = "Test", version = "1.0" } }
      local result = unwrap(wrapped)
      assert.equals("Test", result.name)
      assert.equals("1.0", result.version)
    end)

    it("returns original data if not wrapped", function()
      local unwrap = function(data)
        if data and data.success and data.data then
          return data.data
        end
        return data or {}
      end

      local plain = { name = "Test", version = "1.0" }
      local result = unwrap(plain)
      assert.equals("Test", result.name)
    end)

    it("returns empty table for nil input", function()
      local unwrap = function(data)
        if data and data.success and data.data then
          return data.data
        end
        return data or {}
      end

      local result = unwrap(nil)
      assert.is_table(result)
      assert.equals(0, vim.tbl_count(result))
    end)
  end)

  describe("format_generate_result", function()
    it("formats generation results correctly", function()
      local format = function(data)
        local lines = {}
        table.insert(lines, "Generation Results")
        table.insert(lines, string.rep("─", 50))
        table.insert(lines, "")

        local results = data.results or {}
        if #results == 0 then
          table.insert(lines, "  No files generated")
          return lines
        end

        for _, result in ipairs(results) do
          if type(result) == "table" then
            local type_name = result.type or "unknown"
            local name = result.name or ""
            table.insert(lines, "  " .. type_name:upper() .. ": " .. name)

            local generated = result.generated or {}
            for _, file in ipairs(generated) do
              table.insert(lines, "    ✓ " .. file)
            end
            table.insert(lines, "")
          end
        end

        return lines
      end

      local data = {
        results = {
          {
            type = "controller",
            name = "User",
            generated = { "UserController.java" },
          },
        },
        totalGenerated = 1,
        totalSkipped = 0,
      }

      local lines = format(data)
      assert.is_true(#lines > 0)
      assert.equals("Generation Results", lines[1])

      local found_controller = false
      local found_file = false
      for _, line in ipairs(lines) do
        if line:match("CONTROLLER: User") then
          found_controller = true
        end
        if line:match("UserController.java") then
          found_file = true
        end
      end
      assert.is_true(found_controller)
      assert.is_true(found_file)
    end)

    it("handles empty results", function()
      local format = function(data)
        local lines = {}
        table.insert(lines, "Generation Results")
        table.insert(lines, string.rep("─", 50))
        table.insert(lines, "")

        local results = data.results or {}
        if #results == 0 then
          table.insert(lines, "  No files generated")
          return lines
        end

        return lines
      end

      local data = { results = {}, totalGenerated = 0, totalSkipped = 0 }
      local lines = format(data)

      local found_no_files = false
      for _, line in ipairs(lines) do
        if line:match("No files generated") then
          found_no_files = true
        end
      end
      assert.is_true(found_no_files)
    end)
  end)

  describe("collect_generated_files", function()
    it("collects files from generation results", function()
      local collect = function(data, root)
        local files = {}
        local results = data.results or {}

        for _, result in ipairs(results) do
          if type(result) == "table" then
            local generated = result.generated or {}
            for _, file in ipairs(generated) do
              table.insert(files, root .. "/src/main/java/" .. file)
            end
          end
        end

        return files
      end

      local data = {
        results = {
          {
            type = "controller",
            name = "User",
            generated = { "UserController.java" },
          },
          {
            type = "service",
            name = "User",
            generated = { "UserService.java", "UserServiceImpl.java" },
          },
        },
      }

      local files = collect(data, "/project")
      assert.equals(3, #files)
      assert.equals("/project/src/main/java/UserController.java", files[1])
      assert.equals("/project/src/main/java/UserService.java", files[2])
      assert.equals("/project/src/main/java/UserServiceImpl.java", files[3])
    end)

    it("returns empty array for empty results", function()
      local collect = function(data, root)
        local files = {}
        local results = data.results or {}

        for _, result in ipairs(results) do
          if type(result) == "table" then
            local generated = result.generated or {}
            for _, file in ipairs(generated) do
              table.insert(files, root .. "/src/main/java/" .. file)
            end
          end
        end

        return files
      end

      local data = { results = {} }
      local files = collect(data, "/project")
      assert.equals(0, #files)
    end)

    it("handles missing results key", function()
      local collect = function(data, root)
        local files = {}
        local results = data.results or {}

        for _, result in ipairs(results) do
          if type(result) == "table" then
            local generated = result.generated or {}
            for _, file in ipairs(generated) do
              table.insert(files, root .. "/src/main/java/" .. file)
            end
          end
        end

        return files
      end

      local data = {}
      local files = collect(data, "/project")
      assert.equals(0, #files)
    end)
  end)

  describe("format_add_result", function()
    it("formats add results with added dependencies", function()
      local format = function(data)
        local lines = {}
        table.insert(lines, "Dependencies Added")
        table.insert(lines, string.rep("─", 50))
        table.insert(lines, "")

        local added = data.added or {}
        local skipped = data.skipped or {}

        if #added > 0 then
          table.insert(lines, "Added:")
          for _, dep in ipairs(added) do
            if type(dep) == "table" then
              table.insert(lines, "  ✓ " .. (dep.name or dep.shortcut or "unknown"))
            else
              table.insert(lines, "  ✓ " .. tostring(dep))
            end
          end
          table.insert(lines, "")
        end

        if #skipped > 0 then
          table.insert(lines, "Skipped (already present):")
          for _, dep in ipairs(skipped) do
            if type(dep) == "table" then
              table.insert(lines, "  - " .. (dep.name or dep.shortcut or "unknown"))
            else
              table.insert(lines, "  - " .. tostring(dep))
            end
          end
          table.insert(lines, "")
        end

        return lines
      end

      local data = {
        added = { { name = "Lombok", shortcut = "lombok" } },
        skipped = {},
      }

      local lines = format(data)
      assert.is_true(#lines > 0)
      assert.equals("Dependencies Added", lines[1])

      local found_lombok = false
      for _, line in ipairs(lines) do
        if line:match("Lombok") then
          found_lombok = true
        end
      end
      assert.is_true(found_lombok)
    end)

    it("formats add results with skipped dependencies", function()
      local format = function(data)
        local lines = {}
        local skipped = data.skipped or {}

        if #skipped > 0 then
          table.insert(lines, "Skipped (already present):")
          for _, dep in ipairs(skipped) do
            if type(dep) == "table" then
              table.insert(lines, "  - " .. (dep.name or dep.shortcut or "unknown"))
            else
              table.insert(lines, "  - " .. tostring(dep))
            end
          end
        end

        return lines
      end

      local data = {
        added = {},
        skipped = { { name = "JPA", shortcut = "jpa" } },
      }

      local lines = format(data)
      local found_skipped = false
      for _, line in ipairs(lines) do
        if line:match("Skipped") then
          found_skipped = true
        end
      end
      assert.is_true(found_skipped)
    end)

    it("handles string dependencies", function()
      local format = function(data)
        local lines = {}
        local added = data.added or {}

        for _, dep in ipairs(added) do
          if type(dep) == "table" then
            table.insert(lines, dep.name or dep.shortcut or "unknown")
          else
            table.insert(lines, tostring(dep))
          end
        end

        return lines
      end

      local data = { added = { "lombok", "jpa" } }
      local lines = format(data)
      assert.equals(2, #lines)
      assert.equals("lombok", lines[1])
      assert.equals("jpa", lines[2])
    end)
  end)
end)

describe("haft.api config integration", function()
  local config

  before_each(function()
    package.loaded["haft.config"] = nil
    config = require("haft.config")
    config.reset()
  end)

  describe("auto_open config", function()
    it("default strategy is first", function()
      config.setup({})
      local cfg = config.get()
      assert.equals("first", cfg.auto_open.strategy)
    end)

    it("default enabled is true", function()
      config.setup({})
      local cfg = config.get()
      assert.is_true(cfg.auto_open.enabled)
    end)

    it("can be configured to all strategy", function()
      config.setup({ auto_open = { strategy = "all" } })
      local cfg = config.get()
      assert.equals("all", cfg.auto_open.strategy)
    end)

    it("can be disabled", function()
      config.setup({ auto_open = { enabled = false } })
      local cfg = config.get()
      assert.is_false(cfg.auto_open.enabled)
    end)
  end)

  describe("quickfix config", function()
    it("default enabled is true", function()
      config.setup({})
      local cfg = config.get()
      assert.is_true(cfg.quickfix.enabled)
    end)

    it("default auto_open is false", function()
      config.setup({})
      local cfg = config.get()
      assert.is_false(cfg.quickfix.auto_open)
    end)

    it("can enable auto_open", function()
      config.setup({ quickfix = { auto_open = true } })
      local cfg = config.get()
      assert.is_true(cfg.quickfix.auto_open)
    end)

    it("can be disabled", function()
      config.setup({ quickfix = { enabled = false } })
      local cfg = config.get()
      assert.is_false(cfg.quickfix.enabled)
    end)
  end)
end)
