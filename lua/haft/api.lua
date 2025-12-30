local runner = require("haft.runner")
local notify = require("haft.ui.notify")
local float = require("haft.ui.float")
local detection = require("haft.detection")

local M = {}

---@param data table
---@return string[]
local function format_info(data)
  local lines = {}

  table.insert(lines, "Project Information")
  table.insert(lines, string.rep("─", 40))
  table.insert(lines, "")

  if data.name then
    table.insert(lines, "  Name:           " .. data.name)
  end
  if data.version then
    table.insert(lines, "  Version:        " .. data.version)
  end
  if data.groupId or data.group then
    table.insert(lines, "  Group:          " .. (data.groupId or data.group))
  end
  if data.artifactId or data.artifact then
    table.insert(lines, "  Artifact:       " .. (data.artifactId or data.artifact))
  end
  if data.javaVersion or data.java_version then
    table.insert(lines, "  Java Version:   " .. (data.javaVersion or data.java_version))
  end
  if data.springVersion or data.spring_version then
    table.insert(lines, "  Spring Version: " .. (data.springVersion or data.spring_version))
  end
  if data.buildTool or data.build_tool then
    table.insert(lines, "  Build Tool:     " .. (data.buildTool or data.build_tool))
  end

  if data.dependencies and #data.dependencies > 0 then
    table.insert(lines, "")
    table.insert(lines, "Dependencies (" .. #data.dependencies .. ")")
    table.insert(lines, string.rep("─", 40))
    for _, dep in ipairs(data.dependencies) do
      if type(dep) == "string" then
        table.insert(lines, "  • " .. dep)
      elseif type(dep) == "table" and dep.name then
        local line = "  • " .. dep.name
        if dep.version then
          line = line .. " (" .. dep.version .. ")"
        end
        table.insert(lines, line)
      end
    end
  end

  if data.loc then
    table.insert(lines, "")
    table.insert(lines, "Lines of Code")
    table.insert(lines, string.rep("─", 40))
    if type(data.loc) == "table" then
      for lang, count in pairs(data.loc) do
        table.insert(lines, string.format("  %-12s %d", lang .. ":", count))
      end
    else
      table.insert(lines, "  Total: " .. tostring(data.loc))
    end
  end

  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close")

  return lines
end

---@param data table
---@return string[]
local function format_routes(data)
  local lines = {}

  table.insert(lines, "API Routes")
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "")

  local routes = data.routes or data
  if type(routes) ~= "table" then
    table.insert(lines, "  No routes found")
    return lines
  end

  if #routes == 0 then
    table.insert(lines, "  No routes found")
  else
    for _, route in ipairs(routes) do
      if type(route) == "table" then
        local method = route.method or "GET"
        local path = route.path or route.url or "/"
        local handler = route.handler or route.controller or ""

        local line = string.format("  %-7s %-30s", method, path)
        if handler ~= "" then
          line = line .. " → " .. handler
        end
        table.insert(lines, line)

        if route.file then
          table.insert(lines, "          " .. route.file)
        end
      elseif type(route) == "string" then
        table.insert(lines, "  " .. route)
      end
    end
  end

  table.insert(lines, "")
  table.insert(lines, "Total: " .. #routes .. " routes")
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close")

  return lines
end

---@param data table
---@return string[]
local function format_stats(data)
  local lines = {}

  table.insert(lines, "Code Statistics")
  table.insert(lines, string.rep("─", 50))
  table.insert(lines, "")

  if data.files then
    table.insert(lines, "  Files:          " .. tostring(data.files))
  end
  if data.lines then
    table.insert(lines, "  Lines:          " .. tostring(data.lines))
  end
  if data.code then
    table.insert(lines, "  Code:           " .. tostring(data.code))
  end
  if data.comments then
    table.insert(lines, "  Comments:       " .. tostring(data.comments))
  end
  if data.blanks then
    table.insert(lines, "  Blanks:         " .. tostring(data.blanks))
  end

  if data.languages or data.breakdown then
    table.insert(lines, "")
    table.insert(lines, "By Language")
    table.insert(lines, string.rep("─", 50))

    local langs = data.languages or data.breakdown
    if type(langs) == "table" then
      for lang, stats in pairs(langs) do
        if type(stats) == "table" then
          table.insert(lines, string.format("  %-15s %d files, %d lines", lang, stats.files or 0, stats.lines or 0))
        else
          table.insert(lines, string.format("  %-15s %s", lang, tostring(stats)))
        end
      end
    end
  end

  if data.cocomo then
    table.insert(lines, "")
    table.insert(lines, "COCOMO Estimates")
    table.insert(lines, string.rep("─", 50))
    if data.cocomo.effort then
      table.insert(lines, "  Effort:         " .. tostring(data.cocomo.effort) .. " person-months")
    end
    if data.cocomo.duration then
      table.insert(lines, "  Duration:       " .. tostring(data.cocomo.duration) .. " months")
    end
    if data.cocomo.people then
      table.insert(lines, "  People:         " .. tostring(data.cocomo.people))
    end
    if data.cocomo.cost then
      table.insert(lines, "  Cost:           $" .. tostring(data.cocomo.cost))
    end
  end

  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close")

  return lines
end

function M.info()
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  notify.info("Fetching project info...")

  runner.run({
    args = { "info", "--loc", "--deps" },
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local lines = format_info(result.data)
        float.open(lines, { title = "Haft Info" })
      else
        local lines = vim.split(result.output, "\n")
        float.open(lines, { title = "Haft Info" })
      end
    end,
    on_error = function(result)
      notify.error("Failed to get project info: " .. result.output)
    end,
  })
end

function M.routes()
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  notify.info("Fetching routes...")

  runner.run({
    args = { "routes", "--files" },
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local lines = format_routes(result.data)
        float.open(lines, { title = "Haft Routes" })
      else
        local lines = vim.split(result.output, "\n")
        float.open(lines, { title = "Haft Routes" })
      end
    end,
    on_error = function(result)
      notify.error("Failed to get routes: " .. result.output)
    end,
  })
end

function M.stats()
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  notify.info("Fetching statistics...")

  runner.run({
    args = { "stats", "--cocomo" },
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local lines = format_stats(result.data)
        float.open(lines, { title = "Haft Stats" })
      else
        local lines = vim.split(result.output, "\n")
        float.open(lines, { title = "Haft Stats" })
      end
    end,
    on_error = function(result)
      notify.error("Failed to get stats: " .. result.output)
    end,
  })
end

return M
