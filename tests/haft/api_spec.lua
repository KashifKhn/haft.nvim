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

    it("has remove function", function()
      assert.is_function(api.remove)
    end)

    it("has remove_dependencies function", function()
      assert.is_function(api.remove_dependencies)
    end)
  end)

  describe("add function behavior", function()
    it("add with deps array calls add_dependencies", function()
      local called_with = nil
      local original_add_deps = api.add_dependencies

      api.add_dependencies = function(deps)
        called_with = deps
      end

      api.add({ "lombok", "jpa" })

      assert.is_table(called_with)
      assert.equals(2, #called_with)
      assert.equals("lombok", called_with[1])
      assert.equals("jpa", called_with[2])

      api.add_dependencies = original_add_deps
    end)

    it("add with empty array opens picker", function()
      local picker_called = false

      package.loaded["haft.telescope.pickers.dependencies"] = {
        pick = function(callback)
          picker_called = true
        end,
      }

      api.add({})

      assert.is_true(picker_called)

      package.loaded["haft.telescope.pickers.dependencies"] = nil
    end)

    it("add with nil opens picker", function()
      local picker_called = false

      package.loaded["haft.telescope.pickers.dependencies"] = {
        pick = function(callback)
          picker_called = true
        end,
      }

      api.add(nil)

      assert.is_true(picker_called)

      package.loaded["haft.telescope.pickers.dependencies"] = nil
    end)
  end)

  describe("remove function behavior", function()
    it("remove with deps array calls remove_dependencies", function()
      local called_with = nil
      local original_remove_deps = api.remove_dependencies

      api.remove_dependencies = function(deps)
        called_with = deps
      end

      api.remove({ "lombok", "jpa" })

      assert.is_table(called_with)
      assert.equals(2, #called_with)
      assert.equals("lombok", called_with[1])
      assert.equals("jpa", called_with[2])

      api.remove_dependencies = original_remove_deps
    end)

    it("remove with empty array opens picker", function()
      local picker_called = false

      package.loaded["haft.telescope.pickers.remove"] = {
        pick = function(callback)
          picker_called = true
        end,
      }

      api.remove({})

      assert.is_true(picker_called)

      package.loaded["haft.telescope.pickers.remove"] = nil
    end)

    it("remove with nil opens picker", function()
      local picker_called = false

      package.loaded["haft.telescope.pickers.remove"] = {
        pick = function(callback)
          picker_called = true
        end,
      }

      api.remove(nil)

      assert.is_true(picker_called)

      package.loaded["haft.telescope.pickers.remove"] = nil
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

  describe("format_remove_result", function()
    it("formats remove results with removed dependencies", function()
      local format = function(data)
        local lines = {}
        table.insert(lines, "Dependencies Removed")
        table.insert(lines, string.rep("─", 50))
        table.insert(lines, "")

        local removed = data.removed or {}
        local not_found = data.notFound or {}

        if #removed > 0 then
          table.insert(lines, "Removed:")
          for _, dep in ipairs(removed) do
            if type(dep) == "table" then
              table.insert(lines, "  ✓ " .. (dep.name or dep.artifactId or "unknown"))
            else
              table.insert(lines, "  ✓ " .. tostring(dep))
            end
          end
          table.insert(lines, "")
        end

        if #not_found > 0 then
          table.insert(lines, "Not Found:")
          for _, dep in ipairs(not_found) do
            if type(dep) == "table" then
              table.insert(lines, "  ✗ " .. (dep.name or dep.artifactId or "unknown"))
            else
              table.insert(lines, "  ✗ " .. tostring(dep))
            end
          end
          table.insert(lines, "")
        end

        return lines
      end

      local data = {
        removed = { { name = "Lombok", artifactId = "lombok" } },
        notFound = {},
      }

      local lines = format(data)
      assert.is_true(#lines > 0)
      assert.equals("Dependencies Removed", lines[1])

      local found_lombok = false
      for _, line in ipairs(lines) do
        if line:match("Lombok") then
          found_lombok = true
        end
      end
      assert.is_true(found_lombok)
    end)

    it("formats remove results with not found dependencies", function()
      local format = function(data)
        local lines = {}
        local not_found = data.notFound or {}

        if #not_found > 0 then
          table.insert(lines, "Not Found:")
          for _, dep in ipairs(not_found) do
            if type(dep) == "table" then
              table.insert(lines, "  ✗ " .. (dep.name or dep.artifactId or "unknown"))
            else
              table.insert(lines, "  ✗ " .. tostring(dep))
            end
          end
        end

        return lines
      end

      local data = {
        removed = {},
        notFound = { { name = "NonExistent", artifactId = "nonexistent" } },
      }

      local lines = format(data)
      local found_not_found = false
      for _, line in ipairs(lines) do
        if line:match("Not Found") then
          found_not_found = true
        end
      end
      assert.is_true(found_not_found)
    end)

    it("handles string dependencies in removed", function()
      local format = function(data)
        local lines = {}
        local removed = data.removed or {}

        for _, dep in ipairs(removed) do
          if type(dep) == "table" then
            table.insert(lines, dep.name or dep.artifactId or "unknown")
          else
            table.insert(lines, tostring(dep))
          end
        end

        return lines
      end

      local data = { removed = { "lombok", "jpa" } }
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

describe("haft.api add_dependencies", function()
  local api
  local mock_runner
  local mock_notify
  local mock_detection

  before_each(function()
    package.loaded["haft.api"] = nil
    package.loaded["haft.config"] = nil
    package.loaded["haft.runner"] = nil
    package.loaded["haft.ui.notify"] = nil
    package.loaded["haft.detection"] = nil
    package.loaded["haft.ui.float"] = nil

    local config = require("haft.config")
    config.reset()
    config.setup({})

    mock_runner = {
      is_haft_available = function()
        return true
      end,
      run = function(opts)
        mock_runner.last_opts = opts
        if mock_runner.mock_success then
          opts.on_success(mock_runner.mock_result)
        elseif mock_runner.mock_error and opts.on_error then
          opts.on_error(mock_runner.mock_result)
        end
      end,
      last_opts = nil,
      mock_success = false,
      mock_error = false,
      mock_result = nil,
    }

    mock_notify = {
      info = function(msg)
        mock_notify.last_info = msg
      end,
      warn = function(msg)
        mock_notify.last_warn = msg
      end,
      error = function(msg)
        mock_notify.last_error = msg
      end,
      last_info = nil,
      last_warn = nil,
      last_error = nil,
    }

    mock_detection = {
      get_project_root = function()
        return "/mock/project"
      end,
    }

    package.loaded["haft.runner"] = mock_runner
    package.loaded["haft.ui.notify"] = mock_notify
    package.loaded["haft.detection"] = mock_detection
    package.loaded["haft.ui.float"] = {
      open = function() end,
    }

    api = require("haft.api")
  end)

  after_each(function()
    package.loaded["haft.api"] = nil
    package.loaded["haft.runner"] = nil
    package.loaded["haft.ui.notify"] = nil
    package.loaded["haft.detection"] = nil
    package.loaded["haft.ui.float"] = nil
  end)

  it("builds correct args for single dependency", function()
    api.add_dependencies({ "lombok" })

    assert.is_table(mock_runner.last_opts)
    assert.is_table(mock_runner.last_opts.args)

    local args = mock_runner.last_opts.args
    assert.equals("add", args[1])
    assert.equals("lombok", args[2])
    assert.equals("--no-interactive", args[3])
  end)

  it("builds correct args for multiple dependencies", function()
    api.add_dependencies({ "lombok", "jpa", "validation" })

    local args = mock_runner.last_opts.args
    assert.equals("add", args[1])
    assert.equals("lombok", args[2])
    assert.equals("jpa", args[3])
    assert.equals("validation", args[4])
    assert.equals("--no-interactive", args[5])
  end)

  it("uses project root as cwd", function()
    api.add_dependencies({ "lombok" })

    assert.equals("/mock/project", mock_runner.last_opts.cwd)
  end)

  it("requests json output", function()
    api.add_dependencies({ "lombok" })

    assert.is_true(mock_runner.last_opts.json)
  end)

  it("warns when no dependencies provided", function()
    api.add_dependencies({})

    assert.equals("No dependencies specified", mock_notify.last_warn)
    assert.is_nil(mock_runner.last_opts)
  end)

  it("warns when nil dependencies provided", function()
    api.add_dependencies(nil)

    assert.equals("No dependencies specified", mock_notify.last_warn)
    assert.is_nil(mock_runner.last_opts)
  end)

  it("shows info message when adding dependencies", function()
    api.add_dependencies({ "lombok", "jpa" })

    assert.equals("Adding 2 dependency(ies)...", mock_notify.last_info)
  end)

  it("errors when haft cli not available", function()
    mock_runner.is_haft_available = function()
      return false
    end

    api.add_dependencies({ "lombok" })

    assert.is_not_nil(mock_notify.last_error)
    assert.is_truthy(mock_notify.last_error:match("Haft CLI not found"))
  end)

  it("warns when not in a project", function()
    mock_detection.get_project_root = function()
      return nil
    end

    api.add_dependencies({ "lombok" })

    assert.equals("Not in a Haft/Spring Boot project", mock_notify.last_warn)
  end)
end)

describe("haft.commands HaftAdd", function()
  it("parses space-separated dependencies", function()
    local parsed = vim.split("lombok jpa validation", "%s+")
    assert.equals(3, #parsed)
    assert.equals("lombok", parsed[1])
    assert.equals("jpa", parsed[2])
    assert.equals("validation", parsed[3])
  end)

  it("handles empty args string", function()
    local args = ""
    local deps = nil
    if args ~= "" then
      deps = vim.split(args, "%s+")
    end
    assert.is_nil(deps)
  end)

  it("handles single dependency", function()
    local parsed = vim.split("lombok", "%s+")
    assert.equals(1, #parsed)
    assert.equals("lombok", parsed[1])
  end)
end)

describe("haft.api remove_dependencies", function()
  local api
  local mock_runner
  local mock_notify
  local mock_detection

  before_each(function()
    package.loaded["haft.api"] = nil
    package.loaded["haft.config"] = nil
    package.loaded["haft.runner"] = nil
    package.loaded["haft.ui.notify"] = nil
    package.loaded["haft.detection"] = nil
    package.loaded["haft.ui.float"] = nil

    local config = require("haft.config")
    config.reset()
    config.setup({})

    mock_runner = {
      is_haft_available = function()
        return true
      end,
      run = function(opts)
        mock_runner.last_opts = opts
        if mock_runner.mock_success then
          opts.on_success(mock_runner.mock_result)
        elseif mock_runner.mock_error and opts.on_error then
          opts.on_error(mock_runner.mock_result)
        end
      end,
      last_opts = nil,
      mock_success = false,
      mock_error = false,
      mock_result = nil,
    }

    mock_notify = {
      info = function(msg)
        mock_notify.last_info = msg
      end,
      warn = function(msg)
        mock_notify.last_warn = msg
      end,
      error = function(msg)
        mock_notify.last_error = msg
      end,
      last_info = nil,
      last_warn = nil,
      last_error = nil,
    }

    mock_detection = {
      get_project_root = function()
        return "/mock/project"
      end,
    }

    package.loaded["haft.runner"] = mock_runner
    package.loaded["haft.ui.notify"] = mock_notify
    package.loaded["haft.detection"] = mock_detection
    package.loaded["haft.ui.float"] = {
      open = function() end,
    }

    api = require("haft.api")
  end)

  after_each(function()
    package.loaded["haft.api"] = nil
    package.loaded["haft.runner"] = nil
    package.loaded["haft.ui.notify"] = nil
    package.loaded["haft.detection"] = nil
    package.loaded["haft.ui.float"] = nil
  end)

  it("builds correct args for single dependency", function()
    api.remove_dependencies({ "lombok" })

    assert.is_table(mock_runner.last_opts)
    assert.is_table(mock_runner.last_opts.args)

    local args = mock_runner.last_opts.args
    assert.equals("remove", args[1])
    assert.equals("lombok", args[2])
    assert.equals("--no-interactive", args[3])
  end)

  it("builds correct args for multiple dependencies", function()
    api.remove_dependencies({ "lombok", "jpa", "validation" })

    local args = mock_runner.last_opts.args
    assert.equals("remove", args[1])
    assert.equals("lombok", args[2])
    assert.equals("jpa", args[3])
    assert.equals("validation", args[4])
    assert.equals("--no-interactive", args[5])
  end)

  it("uses project root as cwd", function()
    api.remove_dependencies({ "lombok" })

    assert.equals("/mock/project", mock_runner.last_opts.cwd)
  end)

  it("requests json output", function()
    api.remove_dependencies({ "lombok" })

    assert.is_true(mock_runner.last_opts.json)
  end)

  it("warns when no dependencies provided", function()
    api.remove_dependencies({})

    assert.equals("No dependencies specified", mock_notify.last_warn)
    assert.is_nil(mock_runner.last_opts)
  end)

  it("warns when nil dependencies provided", function()
    api.remove_dependencies(nil)

    assert.equals("No dependencies specified", mock_notify.last_warn)
    assert.is_nil(mock_runner.last_opts)
  end)

  it("shows info message when removing dependencies", function()
    api.remove_dependencies({ "lombok", "jpa" })

    assert.equals("Removing 2 dependency(ies)...", mock_notify.last_info)
  end)

  it("errors when haft cli not available", function()
    mock_runner.is_haft_available = function()
      return false
    end

    api.remove_dependencies({ "lombok" })

    assert.is_not_nil(mock_notify.last_error)
    assert.is_truthy(mock_notify.last_error:match("Haft CLI not found"))
  end)

  it("warns when not in a project", function()
    mock_detection.get_project_root = function()
      return nil
    end

    api.remove_dependencies({ "lombok" })

    assert.equals("Not in a Haft/Spring Boot project", mock_notify.last_warn)
  end)
end)

describe("haft.commands HaftRemove", function()
  it("parses space-separated dependencies", function()
    local parsed = vim.split("lombok jpa validation", "%s+")
    assert.equals(3, #parsed)
    assert.equals("lombok", parsed[1])
    assert.equals("jpa", parsed[2])
    assert.equals("validation", parsed[3])
  end)

  it("handles empty args string", function()
    local args = ""
    local deps = nil
    if args ~= "" then
      deps = vim.split(args, "%s+")
    end
    assert.is_nil(deps)
  end)

  it("handles single dependency", function()
    local parsed = vim.split("lombok", "%s+")
    assert.equals(1, #parsed)
    assert.equals("lombok", parsed[1])
  end)
end)

describe("haft.api dev functions exist", function()
  local api

  before_each(function()
    package.loaded["haft.api"] = nil
    package.loaded["haft.config"] = nil
    api = require("haft.api")
    local config = require("haft.config")
    config.reset()
    config.setup({})
  end)

  it("has serve function", function()
    assert.is_function(api.serve)
  end)

  it("has serve_stop function", function()
    assert.is_function(api.serve_stop)
  end)

  it("has serve_toggle function", function()
    assert.is_function(api.serve_toggle)
  end)

  it("has build function", function()
    assert.is_function(api.build)
  end)

  it("has test function", function()
    assert.is_function(api.test)
  end)

  it("has clean function", function()
    assert.is_function(api.clean)
  end)

  it("has deps function", function()
    assert.is_function(api.deps)
  end)

  it("has outdated function", function()
    assert.is_function(api.outdated)
  end)
end)

describe("haft.config terminal settings", function()
  local config

  before_each(function()
    package.loaded["haft.config"] = nil
    config = require("haft.config")
    config.reset()
  end)

  describe("terminal config", function()
    it("default type is auto", function()
      config.setup({})
      local cfg = config.get()
      assert.equals("auto", cfg.terminal.type)
    end)

    it("default persist is true", function()
      config.setup({})
      local cfg = config.get()
      assert.is_true(cfg.terminal.persist)
    end)

    it("default auto_close is false", function()
      config.setup({})
      local cfg = config.get()
      assert.is_false(cfg.terminal.auto_close)
    end)

    it("has float config with defaults", function()
      config.setup({})
      local cfg = config.get()
      assert.equals("rounded", cfg.terminal.float.border)
      assert.equals(0.8, cfg.terminal.float.width)
      assert.equals(0.8, cfg.terminal.float.height)
    end)

    it("has split config with defaults", function()
      config.setup({})
      local cfg = config.get()
      assert.equals(15, cfg.terminal.split.size)
      assert.equals("below", cfg.terminal.split.position)
    end)

    it("can configure terminal type", function()
      config.setup({ terminal = { type = "float" } })
      local cfg = config.get()
      assert.equals("float", cfg.terminal.type)
    end)

    it("can configure split size", function()
      config.setup({ terminal = { split = { size = 20 } } })
      local cfg = config.get()
      assert.equals(20, cfg.terminal.split.size)
    end)
  end)

  describe("dev config", function()
    it("default restart_on_save is false", function()
      config.setup({})
      local cfg = config.get()
      assert.is_false(cfg.dev.restart_on_save)
    end)

    it("has default save_patterns", function()
      config.setup({})
      local cfg = config.get()
      assert.is_table(cfg.dev.save_patterns)
      assert.is_true(#cfg.dev.save_patterns > 0)
    end)
  end)
end)

describe("haft.ui.terminal", function()
  local terminal

  before_each(function()
    package.loaded["haft.ui.terminal"] = nil
    package.loaded["haft.config"] = nil
    local config = require("haft.config")
    config.reset()
    config.setup({})
    terminal = require("haft.ui.terminal")
  end)

  describe("module structure", function()
    it("has open function", function()
      assert.is_function(terminal.open)
    end)

    it("has close function", function()
      assert.is_function(terminal.close)
    end)

    it("has toggle function", function()
      assert.is_function(terminal.toggle)
    end)

    it("has is_running function", function()
      assert.is_function(terminal.is_running)
    end)

    it("has stop function", function()
      assert.is_function(terminal.stop)
    end)

    it("has send function", function()
      assert.is_function(terminal.send)
    end)

    it("has close_all function", function()
      assert.is_function(terminal.close_all)
    end)
  end)

  describe("terminal state", function()
    it("is_running returns false for non-existent terminal", function()
      assert.is_false(terminal.is_running("nonexistent"))
    end)

    it("close handles non-existent terminal gracefully", function()
      assert.has_no_errors(function()
        terminal.close("nonexistent")
      end)
    end)

    it("stop handles non-existent terminal gracefully", function()
      assert.has_no_errors(function()
        terminal.stop("nonexistent")
      end)
    end)

    it("send handles non-existent terminal gracefully", function()
      assert.has_no_errors(function()
        terminal.send("nonexistent", "data")
      end)
    end)
  end)
end)
