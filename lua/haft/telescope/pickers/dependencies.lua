local telescope_mod = require("haft.telescope")
local runner = require("haft.runner")
local detection = require("haft.detection")
local notify = require("haft.ui.notify")
local config = require("haft.config")

local M = {}

---@param data table
---@return table[]
local function parse_dependencies(data)
  local deps = {}
  local categories = data.categories or {}

  for _, category in ipairs(categories) do
    local cat_name = category.name or "Other"
    local cat_deps = category.dependencies or {}

    for _, dep in ipairs(cat_deps) do
      table.insert(deps, {
        shortcut = dep.shortcut or "",
        name = dep.name or dep.shortcut or "",
        description = dep.description or "",
        category = cat_name,
        groupId = dep.groupId or "",
        artifactId = dep.artifactId or "",
      })
    end
  end

  return deps
end

---@param deps table[]
---@param on_select fun(selected: table[])
local function show_native_picker(deps, on_select)
  local items = {}
  local lookup = {}

  for _, dep in ipairs(deps) do
    local display = string.format("[%s] %s - %s", dep.category, dep.name, dep.description)
    table.insert(items, display)
    lookup[display] = dep
  end

  vim.ui.select(items, {
    prompt = "Select dependency to add:",
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
      prompt_title = "Add Dependency",
      finder = finders.new_table({
        results = deps,
        entry_maker = function(entry)
          local display = string.format("[%s] %s", entry.category, entry.name)
          return {
            value = entry,
            display = display,
            ordinal = entry.shortcut .. " " .. entry.name .. " " .. entry.description .. " " .. entry.category,
          }
        end,
      }),
      sorter = conf.generic_sorter(telescope_opts),
      previewer = require("telescope.previewers").new_buffer_previewer({
        title = "Dependency Info",
        define_preview = function(self, entry)
          local dep = entry.value
          local lines = {
            "Name: " .. dep.name,
            "Shortcut: " .. dep.shortcut,
            "Category: " .. dep.category,
            "",
            "Description:",
            dep.description,
            "",
            "Maven Coordinates:",
            "  Group ID: " .. dep.groupId,
            "  Artifact ID: " .. dep.artifactId,
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

  notify.info("Loading dependencies...")

  runner.run({
    args = { "add", "--list" },
    cwd = root,
    json = true,
    on_success = function(result)
      if not result.data then
        notify.error("Failed to parse dependency list")
        return
      end

      local data = result.data
      if data.success and data.data then
        data = data.data
      end

      local deps = parse_dependencies(data)
      if #deps == 0 then
        notify.warn("No dependencies found in catalog")
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

telescope_mod.register_picker("dependencies", M.pick)

return M
