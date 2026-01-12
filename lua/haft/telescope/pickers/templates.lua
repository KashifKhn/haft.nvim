local telescope_mod = require("haft.telescope")
local runner = require("haft.runner")
local notify = require("haft.ui.notify")
local config = require("haft.config")

local M = {}

---@param data table
---@return table[]
local function parse_templates(data)
  local templates = {}
  local raw_templates = data.templates or data or {}

  if type(raw_templates) ~= "table" then
    return templates
  end

  for _, template in ipairs(raw_templates) do
    table.insert(templates, {
      name = template.name or "",
      category = template.category or "other",
      source = template.source or "embedded",
      path = template.path or "",
      description = template.description or "",
      custom = template.source ~= "embedded",
    })
  end

  return templates
end

---@param source string
---@return string
local function source_icon(source)
  if source == "project" then
    return "[P]"
  elseif source == "global" then
    return "[G]"
  else
    return "[E]"
  end
end

---@param templates table[]
---@param on_select fun(selected: table)
local function show_native_picker(templates, on_select)
  local items = {}
  local lookup = {}

  for _, template in ipairs(templates) do
    local display = string.format("%s %-12s %s", source_icon(template.source), template.category, template.name)
    table.insert(items, display)
    lookup[display] = template
  end

  vim.ui.select(items, {
    prompt = "Select template:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      on_select(lookup[choice])
    end
  end)
end

---@param templates table[]
---@param on_select fun(selected: table)
local function show_telescope_picker(templates, on_select)
  local ok, _ = pcall(require, "telescope")
  if not ok then
    show_native_picker(templates, on_select)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  local cfg = config.get()
  local telescope_opts = cfg.picker.telescope or {}

  pickers
    .new(telescope_opts, {
      prompt_title = "Templates",
      finder = finders.new_table({
        results = templates,
        entry_maker = function(entry)
          local icon = source_icon(entry.source)
          local display = string.format("%s %-12s %s", icon, entry.category, entry.name)
          return {
            value = entry,
            display = display,
            ordinal = entry.name .. " " .. entry.category .. " " .. entry.source,
          }
        end,
      }),
      sorter = conf.generic_sorter(telescope_opts),
      previewer = previewers.new_buffer_previewer({
        title = "Template Info",
        define_preview = function(self, entry)
          local template = entry.value
          local source_name = ({
            project = "Project (.haft/templates/)",
            global = "Global (~/.haft/templates/)",
            embedded = "Built-in (embedded)",
          })[template.source] or template.source

          local lines = {
            "Name: " .. template.name,
            "Category: " .. template.category,
            "",
            "Source: " .. source_name,
          }

          if template.path and template.path ~= "" then
            table.insert(lines, "")
            table.insert(lines, "Path:")
            table.insert(lines, "  " .. template.path)
          end

          if template.custom then
            table.insert(lines, "")
            table.insert(lines, "* This template overrides the built-in version")
          end

          table.insert(lines, "")
          table.insert(lines, "Press <CR> to open template file (if custom)")
          table.insert(lines, "Press <C-i> to init this template category")

          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        local function select_template()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            on_select(selection.value)
          end
        end

        local function init_category()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            local template = selection.value
            local api = require("haft.api")
            api.template_init({ category = template.category })
          end
        end

        map("i", "<CR>", select_template)
        map("n", "<CR>", select_template)
        map("i", "<C-i>", init_category)
        map("n", "<C-i>", init_category)

        return true
      end,
    })
    :find()
end

---@param on_select fun(selected: table)?
function M.pick(on_select)
  on_select = on_select
    or function(template)
      if template.path and template.path ~= "" and template.source ~= "embedded" then
        vim.cmd("edit " .. template.path)
      else
        notify.info(string.format("Template: %s (%s) - %s", template.name, template.category, template.source))
      end
    end

  if not runner.is_haft_available() then
    notify.error("Haft CLI not found. Install from: https://github.com/KashifKhn/haft")
    return
  end

  notify.info("Loading templates...")

  runner.run({
    args = { "template", "list", "--json", "--paths" },
    cwd = vim.fn.getcwd(),
    json = true,
    on_success = function(result)
      if not result.data then
        notify.error("Failed to parse template list")
        return
      end

      local data = result.data
      if data.success and data.data then
        data = data.data
      end

      local templates = parse_templates(data)
      if #templates == 0 then
        notify.warn("No templates found")
        return
      end

      local provider = telescope_mod.get_provider()
      if provider == "telescope" then
        show_telescope_picker(templates, on_select)
      else
        show_native_picker(templates, on_select)
      end
    end,
    on_error = function(result)
      notify.error("Failed to load templates: " .. result.output)
    end,
  })
end

telescope_mod.register_picker("templates", M.pick)

return M
