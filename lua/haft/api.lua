local runner = require("haft.runner")
local notify = require("haft.ui.notify")
local float = require("haft.ui.float")
local detection = require("haft.detection")

local M = {}

---@param data table
---@return table
local function unwrap_response(data)
  if data and data.success and data.data then
    return data.data
  end
  return data or {}
end

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
  if data.springBootVersion or data.springVersion or data.spring_version then
    table.insert(lines, "  Spring Version: " .. (data.springBootVersion or data.springVersion or data.spring_version))
  end
  if data.buildTool or data.build_tool then
    table.insert(lines, "  Build Tool:     " .. (data.buildTool or data.build_tool))
  end
  if data.description then
    table.insert(lines, "  Description:    " .. data.description)
  end

  if data.dependencies then
    table.insert(lines, "")
    table.insert(lines, "Dependencies")
    table.insert(lines, string.rep("─", 40))
    if type(data.dependencies) == "table" then
      if data.dependencies.total then
        table.insert(lines, "  Total:           " .. tostring(data.dependencies.total))
      end
      if data.dependencies.springStarters then
        table.insert(lines, "  Spring Starters: " .. tostring(data.dependencies.springStarters))
      end
      if data.dependencies.springLibraries then
        table.insert(lines, "  Spring Libs:     " .. tostring(data.dependencies.springLibraries))
      end
      if data.dependencies.testDependencies then
        table.insert(lines, "  Test Deps:       " .. tostring(data.dependencies.testDependencies))
      end
    end
  end

  if data.features then
    table.insert(lines, "")
    table.insert(lines, "Features")
    table.insert(lines, string.rep("─", 40))
    local feature_names = {
      hasWeb = "Web",
      hasJpa = "JPA",
      hasLombok = "Lombok",
      hasValidation = "Validation",
      hasMapStruct = "MapStruct",
      hasSecurity = "Security",
      hasActuator = "Actuator",
      hasDevTools = "DevTools",
    }
    for key, name in pairs(feature_names) do
      if data.features[key] ~= nil then
        local status = data.features[key] and "✓" or "✗"
        table.insert(lines, "  " .. status .. " " .. name)
      end
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
  table.insert(lines, string.rep("─", 70))
  table.insert(lines, "")

  local routes = data.routes or data
  if type(routes) ~= "table" or #routes == 0 then
    table.insert(lines, "  No routes found")
    table.insert(lines, "")
    table.insert(lines, "Press 'q' or <Esc> to close")
    return lines
  end

  for _, route in ipairs(routes) do
    if type(route) == "table" then
      local method = route.method or "GET"
      local path = route.path or route.url or "/"
      local controller = route.controller or ""
      local handler = route.handler or ""

      local line = string.format("  %-7s %s", method, path)
      table.insert(lines, line)

      if controller ~= "" or handler ~= "" then
        local detail = "         → " .. controller
        if handler ~= "" then
          detail = detail .. "." .. handler .. "()"
        end
        table.insert(lines, detail)
      end

      if route.file then
        local file = route.file:gsub("src/main/java/", "")
        table.insert(lines, "         " .. file .. ":" .. (route.line or ""))
      end
      table.insert(lines, "")
    end
  end

  table.insert(lines, string.rep("─", 70))
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
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "")

  local languages = data.languages or {}
  if #languages == 0 then
    table.insert(lines, "  No statistics found")
    table.insert(lines, "")
    table.insert(lines, "Press 'q' or <Esc> to close")
    return lines
  end

  local total_files = 0
  local total_lines = 0
  local total_code = 0
  local total_comments = 0
  local total_blanks = 0

  table.insert(lines, string.format("  %-15s %8s %10s %10s %10s", "Language", "Files", "Code", "Comments", "Blanks"))
  table.insert(lines, "  " .. string.rep("─", 55))

  for _, lang in ipairs(languages) do
    if type(lang) == "table" and lang.name then
      table.insert(
        lines,
        string.format(
          "  %-15s %8d %10d %10d %10d",
          lang.name,
          lang.files or 0,
          lang.code or 0,
          lang.comments or 0,
          lang.blanks or 0
        )
      )
      total_files = total_files + (lang.files or 0)
      total_lines = total_lines + (lang.lines or 0)
      total_code = total_code + (lang.code or 0)
      total_comments = total_comments + (lang.comments or 0)
      total_blanks = total_blanks + (lang.blanks or 0)
    end
  end

  table.insert(lines, "  " .. string.rep("─", 55))
  table.insert(
    lines,
    string.format("  %-15s %8d %10d %10d %10d", "TOTAL", total_files, total_code, total_comments, total_blanks)
  )

  table.insert(lines, "")
  table.insert(lines, "Summary")
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "  Total Files:    " .. total_files)
  table.insert(lines, "  Total Lines:    " .. total_lines)
  table.insert(lines, "  Code Lines:     " .. total_code)
  table.insert(lines, "  Comments:       " .. total_comments)
  table.insert(lines, "  Blank Lines:    " .. total_blanks)

  if data.cocomo then
    table.insert(lines, "")
    table.insert(lines, "COCOMO Estimates")
    table.insert(lines, string.rep("─", 60))
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
    args = { "info" },
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local data = unwrap_response(result.data)
        local lines = format_info(data)
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
    args = { "routes" },
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local data = unwrap_response(result.data)
        local lines = format_routes(data)
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
    args = { "stats" },
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local data = unwrap_response(result.data)
        local lines = format_stats(data)
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
