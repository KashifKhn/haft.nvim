local runner = require("haft.runner")
local notify = require("haft.ui.notify")
local float = require("haft.ui.float")
local input = require("haft.ui.input")
local detection = require("haft.detection")
local config = require("haft.config")

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

---@param data table
---@return string[]
local function format_generate_result(data)
  local lines = {}

  table.insert(lines, "Generation Results")
  table.insert(lines, string.rep("─", 50))
  table.insert(lines, "")

  local results = data.results or {}
  if #results == 0 then
    table.insert(lines, "  No files generated")
    table.insert(lines, "")
    table.insert(lines, "Press 'q' or <Esc> to close")
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

  table.insert(lines, string.rep("─", 50))
  table.insert(lines, string.format("  Total Generated: %d", data.totalGenerated or 0))
  table.insert(lines, string.format("  Total Skipped:   %d", data.totalSkipped or 0))
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close")

  return lines
end

---@param data table
---@param root string
---@return string[]
local function collect_generated_files(data, root)
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

---@param files string[]
local function add_to_quickfix(files)
  local cfg = config.get()
  if not cfg.quickfix.enabled or #files == 0 then
    return
  end

  local items = {}
  for _, file in ipairs(files) do
    table.insert(items, { filename = file, lnum = 1, col = 1, text = "Generated file" })
  end

  vim.fn.setqflist(items, "r")
  vim.fn.setqflist({}, "a", { title = "Haft Generated Files" })

  if cfg.quickfix.auto_open then
    vim.cmd("copen")
  end
end

---@param files string[]
local function auto_open_files(files)
  local cfg = config.get()
  if not cfg.auto_open.enabled or #files == 0 then
    return
  end

  if cfg.auto_open.strategy == "first" then
    local file = files[1]
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
    end
  elseif cfg.auto_open.strategy == "all" then
    for _, file in ipairs(files) do
      if vim.fn.filereadable(file) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(file))
      end
    end
  end
end

---@param type_name string
---@param cli_cmd string
---@param name string?
local function run_generate(type_name, cli_cmd, name)
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  local function execute(resource_name)
    if not resource_name or resource_name == "" then
      notify.warn("No name provided")
      return
    end

    notify.info("Generating " .. type_name .. ": " .. resource_name .. "...")

    runner.run({
      args = { "generate", cli_cmd, resource_name, "--no-interactive" },
      cwd = root,
      json = true,
      on_success = function(result)
        if result.data then
          local data = unwrap_response(result.data)
          local total = data.totalGenerated or 0

          if total > 0 then
            notify.info(string.format("Generated %d file(s) for %s", total, resource_name))
            local files = collect_generated_files(data, root)
            add_to_quickfix(files)
            auto_open_files(files)
          else
            notify.warn("No files were generated")
          end

          local lines = format_generate_result(data)
          float.open(lines, { title = "Haft Generate " .. type_name:gsub("^%l", string.upper) })
        else
          notify.info("Generation complete")
        end
      end,
      on_error = function(result)
        notify.error("Failed to generate " .. type_name .. ": " .. result.output)
      end,
    })
  end

  if name then
    execute(name)
  else
    input.prompt(type_name:gsub("^%l", string.upper) .. " name: ", {}, execute)
  end
end

---@param name string?
function M.generate_resource(name)
  run_generate("resource", "resource", name)
end

---@param name string?
function M.generate_controller(name)
  run_generate("controller", "controller", name)
end

---@param name string?
function M.generate_service(name)
  run_generate("service", "service", name)
end

---@param name string?
function M.generate_repository(name)
  run_generate("repository", "repository", name)
end

---@param name string?
function M.generate_entity(name)
  run_generate("entity", "entity", name)
end

---@param name string?
function M.generate_dto(name)
  run_generate("dto", "dto", name)
end

---@param data table
---@return string[]
local function format_add_result(data)
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

  if #added == 0 and #skipped == 0 then
    table.insert(lines, "  No changes made")
    table.insert(lines, "")
  end

  table.insert(lines, string.rep("─", 50))
  table.insert(lines, string.format("  Total Added: %d", #added))
  table.insert(lines, string.format("  Total Skipped: %d", #skipped))
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close")

  return lines
end

---@param deps string[]
function M.add_dependencies(deps)
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  if not deps or #deps == 0 then
    notify.warn("No dependencies specified")
    return
  end

  local args = { "add" }
  for _, dep in ipairs(deps) do
    table.insert(args, dep)
  end
  table.insert(args, "--no-interactive")

  notify.info("Adding " .. #deps .. " dependency(ies)...")

  runner.run({
    args = args,
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local data = unwrap_response(result.data)
        local added = data.added or {}
        notify.info(string.format("Added %d dependency(ies)", #added))
        local lines = format_add_result(data)
        float.open(lines, { title = "Haft Add Dependencies" })
      else
        notify.info("Dependencies added successfully")
      end
    end,
    on_error = function(result)
      notify.error("Failed to add dependencies: " .. result.output)
    end,
  })
end

---@param deps string[]?
function M.add(deps)
  if deps and #deps > 0 then
    M.add_dependencies(deps)
  else
    local ok, picker = pcall(require, "haft.telescope.pickers.dependencies")
    if ok then
      picker.pick(function(selected)
        if selected and #selected > 0 then
          local shortcuts = {}
          for _, dep in ipairs(selected) do
            table.insert(shortcuts, dep.shortcut)
          end
          M.add_dependencies(shortcuts)
        end
      end)
    else
      notify.error("Failed to load dependency picker")
    end
  end
end

---@param data table
---@return string[]
local function format_remove_result(data)
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

  if #removed == 0 and #not_found == 0 then
    table.insert(lines, "  No changes made")
    table.insert(lines, "")
  end

  table.insert(lines, string.rep("─", 50))
  table.insert(lines, string.format("  Total Removed: %d", #removed))
  table.insert(lines, string.format("  Not Found: %d", #not_found))
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close")

  return lines
end

---@param deps string[]
function M.remove_dependencies(deps)
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  if not deps or #deps == 0 then
    notify.warn("No dependencies specified")
    return
  end

  local args = { "remove" }
  for _, dep in ipairs(deps) do
    table.insert(args, dep)
  end
  table.insert(args, "--no-interactive")

  notify.info("Removing " .. #deps .. " dependency(ies)...")

  runner.run({
    args = args,
    cwd = root,
    json = true,
    on_success = function(result)
      if result.data then
        local data = unwrap_response(result.data)
        local removed = data.removed or {}
        notify.info(string.format("Removed %d dependency(ies)", #removed))
        local lines = format_remove_result(data)
        float.open(lines, { title = "Haft Remove Dependencies" })
      else
        notify.info("Dependencies removed successfully")
      end
    end,
    on_error = function(result)
      notify.error("Failed to remove dependencies: " .. result.output)
    end,
  })
end

---@param deps string[]?
function M.remove(deps)
  if deps and #deps > 0 then
    M.remove_dependencies(deps)
  else
    local ok, picker = pcall(require, "haft.telescope.pickers.remove")
    if ok then
      picker.pick(function(selected)
        if selected and #selected > 0 then
          local artifacts = {}
          for _, dep in ipairs(selected) do
            table.insert(artifacts, dep.artifactId)
          end
          M.remove_dependencies(artifacts)
        end
      end)
    else
      notify.error("Failed to load remove picker")
    end
  end
end

local function run_dev_command(cmd, title, terminal_id)
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  local terminal = require("haft.ui.terminal")
  local cfg = config.get()

  terminal.open(terminal_id, {
    cmd = cfg.haft_path,
    args = { "dev", cmd },
    cwd = root,
    title = title,
  })
end

function M.serve()
  run_dev_command("serve", "Haft Dev Server", "haft_serve")
end

function M.serve_stop()
  local terminal = require("haft.ui.terminal")
  if terminal.is_running("haft_serve") then
    terminal.stop("haft_serve")
    notify.info("Dev server stopped")
  else
    notify.warn("Dev server is not running")
  end
end

function M.serve_toggle()
  local terminal = require("haft.ui.terminal")
  terminal.toggle("haft_serve")
end

function M.restart()
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  local terminal = require("haft.ui.terminal")
  if not terminal.is_running("haft_serve") then
    notify.warn("Dev server is not running. Start it with :HaftServe first")
    return
  end

  notify.info("Triggering dev server restart...")

  runner.run({
    args = { "dev", "restart" },
    cwd = root,
    json = false,
    on_success = function(result)
      notify.info("Dev server restart triggered")
    end,
    on_error = function(result)
      notify.error("Failed to trigger restart: " .. result.output)
    end,
  })
end

function M.build()
  run_dev_command("build", "Haft Build", "haft_build")
end

function M.test()
  run_dev_command("test", "Haft Test", "haft_test")
end

function M.clean()
  run_dev_command("clean", "Haft Clean", "haft_clean")
end

function M.deps()
  run_dev_command("deps", "Haft Dependencies", "haft_deps")
end

function M.outdated()
  run_dev_command("outdated", "Haft Outdated", "haft_outdated")
end

return M
