local telescope_mod = require("haft.telescope")
local runner = require("haft.runner")
local detection = require("haft.detection")
local notify = require("haft.ui.notify")
local config = require("haft.config")

local M = {}

---@param data table
---@return table[]
local function parse_routes(data)
  local routes = {}
  local raw_routes = data.routes or data or {}

  if type(raw_routes) ~= "table" then
    return routes
  end

  for _, route in ipairs(raw_routes) do
    table.insert(routes, {
      method = route.method or "GET",
      path = route.path or route.endpoint or "",
      handler = route.handler or route.method_name or "",
      controller = route.controller or route.class or "",
      file = route.file or "",
      line = route.line or 0,
    })
  end

  return routes
end

---@param routes table[]
---@param on_select fun(selected: table)
local function show_native_picker(routes, on_select)
  local items = {}
  local lookup = {}

  for _, route in ipairs(routes) do
    local display = string.format("%-7s %s", route.method, route.path)
    table.insert(items, display)
    lookup[display] = route
  end

  vim.ui.select(items, {
    prompt = "Select route:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      on_select(lookup[choice])
    end
  end)
end

---@param routes table[]
---@param on_select fun(selected: table)
local function show_telescope_picker(routes, on_select)
  local ok, _ = pcall(require, "telescope")
  if not ok then
    show_native_picker(routes, on_select)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local cfg = config.get()
  local telescope_opts = cfg.picker.telescope or {}

  local method_colors = {
    GET = "TelescopeResultsIdentifier",
    POST = "TelescopeResultsFunction",
    PUT = "TelescopeResultsConstant",
    PATCH = "TelescopeResultsNumber",
    DELETE = "TelescopeResultsSpecialComment",
  }

  pickers
    .new(telescope_opts, {
      prompt_title = "API Routes",
      finder = finders.new_table({
        results = routes,
        entry_maker = function(entry)
          local display = string.format("%-7s %s", entry.method, entry.path)
          return {
            value = entry,
            display = display,
            ordinal = entry.method .. " " .. entry.path .. " " .. entry.handler .. " " .. entry.controller,
            hl_group = method_colors[entry.method],
          }
        end,
      }),
      sorter = conf.generic_sorter(telescope_opts),
      previewer = require("telescope.previewers").new_buffer_previewer({
        title = "Route Details",
        define_preview = function(self, entry)
          local route = entry.value
          local lines = {
            "Method: " .. route.method,
            "Path: " .. route.path,
            "",
            "Handler:",
            "  Controller: " .. route.controller,
            "  Method: " .. route.handler,
            "",
          }
          if route.file ~= "" then
            table.insert(lines, "Location:")
            table.insert(lines, "  File: " .. route.file)
            if route.line > 0 then
              table.insert(lines, "  Line: " .. route.line)
            end
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        local function select_route()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            on_select(selection.value)
          end
        end

        map("i", "<CR>", select_route)
        map("n", "<CR>", select_route)

        return true
      end,
    })
    :find()
end

---@param on_select fun(selected: table)?
function M.pick(on_select)
  on_select = on_select
    or function(route)
      if route.file and route.file ~= "" then
        vim.cmd("edit " .. route.file)
        if route.line and route.line > 0 then
          vim.api.nvim_win_set_cursor(0, { route.line, 0 })
        end
      else
        notify.info(string.format("%s %s -> %s.%s", route.method, route.path, route.controller, route.handler))
      end
    end

  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  notify.info("Scanning routes...")

  runner.run({
    args = { "routes", "--json", "--files" },
    cwd = root,
    json = true,
    on_success = function(result)
      if not result.data then
        notify.error("Failed to parse routes")
        return
      end

      local data = result.data
      if data.success and data.data then
        data = data.data
      end

      local routes = parse_routes(data)
      if #routes == 0 then
        notify.warn("No routes found in project")
        return
      end

      local provider = telescope_mod.get_provider()
      if provider == "telescope" then
        show_telescope_picker(routes, on_select)
      else
        show_native_picker(routes, on_select)
      end
    end,
    on_error = function(result)
      notify.error("Failed to scan routes: " .. result.output)
    end,
  })
end

telescope_mod.register_picker("routes", M.pick)

return M
