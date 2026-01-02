local telescope_mod = require("haft.telescope")
local runner = require("haft.runner")
local detection = require("haft.detection")
local notify = require("haft.ui.notify")
local config = require("haft.config")

local M = {}

---@param data table
---@return table[]
local function parse_current_dependencies(data)
  local deps = {}
  local dependencies = data.dependencies or {}
  local dep_list = dependencies.list or {}

  for _, dep in ipairs(dep_list) do
    local name = dep.artifactId or ""
    local group = dep.groupId or ""
    local version = dep.version or ""
    local scope = dep.scope or "compile"

    table.insert(deps, {
      artifactId = name,
      groupId = group,
      version = version,
      scope = scope,
      display = group .. ":" .. name,
    })
  end

  return deps
end

---@param deps table[]
---@param on_select fun(selected: table[])
local function show_native_picker(deps, on_select)
  local items = {}
  local lookup = {}

  for _, dep in ipairs(deps) do
    local display = dep.display
    if dep.version ~= "" then
      display = display .. ":" .. dep.version
    end
    if dep.scope ~= "compile" then
      display = display .. " (" .. dep.scope .. ")"
    end
    table.insert(items, display)
    lookup[display] = dep
  end

  vim.ui.select(items, {
    prompt = "Select dependency to remove:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      on_select({ lookup[choice] })
    end
  end)
end

---@param deps table[]
---@param on_select fun(selected: table[])
local function show_telescope_picker(deps, on_select)
  local ok, _ = pcall(require, "telescope")
  if not ok then
    show_native_picker(deps, on_select)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local cfg = config.get()
  local telescope_opts = cfg.picker.telescope or {}

  pickers
    .new(telescope_opts, {
      prompt_title = "Remove Dependency",
      finder = finders.new_table({
        results = deps,
        entry_maker = function(entry)
          local display = entry.artifactId
          if entry.scope ~= "compile" then
            display = display .. " (" .. entry.scope .. ")"
          end
          return {
            value = entry,
            display = display,
            ordinal = entry.artifactId .. " " .. entry.groupId,
          }
        end,
      }),
      sorter = conf.generic_sorter(telescope_opts),
      previewer = require("telescope.previewers").new_buffer_previewer({
        title = "Dependency Info",
        define_preview = function(self, entry)
          local dep = entry.value
          local lines = {
            "Artifact ID: " .. dep.artifactId,
            "Group ID: " .. dep.groupId,
            "",
            "Version: " .. (dep.version ~= "" and dep.version or "managed"),
            "Scope: " .. dep.scope,
            "",
            "Maven Coordinates:",
            "  " .. dep.display .. (dep.version ~= "" and (":" .. dep.version) or ""),
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        local function select_single()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            on_select({ selection.value })
          end
        end

        local function select_multi()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local selections = picker:get_multi_selection()
          actions.close(prompt_bufnr)

          if #selections > 0 then
            local selected = {}
            for _, sel in ipairs(selections) do
              table.insert(selected, sel.value)
            end
            on_select(selected)
          else
            local selection = action_state.get_selected_entry()
            if selection then
              on_select({ selection.value })
            end
          end
        end

        map("i", "<CR>", select_single)
        map("n", "<CR>", select_single)
        map("i", "<C-a>", select_multi)
        map("n", "<C-a>", select_multi)

        return true
      end,
    })
    :find()
end

---@param on_select fun(selected: table[])
function M.pick(on_select)
  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  local root = detection.get_project_root()
  if not root then
    notify.warn("Not in a Haft/Spring Boot project")
    return
  end

  notify.info("Loading current dependencies...")

  runner.run({
    args = { "info", "--deps" },
    cwd = root,
    json = true,
    on_success = function(result)
      if not result.data then
        notify.error("Failed to parse project info")
        return
      end

      local data = result.data
      if data.success and data.data then
        data = data.data
      end

      local deps = parse_current_dependencies(data)
      if #deps == 0 then
        notify.warn("No dependencies found in project")
        return
      end

      local provider = telescope_mod.get_provider()
      if provider == "telescope" then
        show_telescope_picker(deps, on_select)
      else
        show_native_picker(deps, on_select)
      end
    end,
    on_error = function(result)
      notify.error("Failed to load dependencies: " .. result.output)
    end,
  })
end

telescope_mod.register_picker("remove", M.pick)

return M
