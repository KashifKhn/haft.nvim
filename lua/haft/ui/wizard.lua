local config = require("haft.config")
local notify = require("haft.ui.notify")

local M = {}

---@class WizardStep
---@field name string
---@field prompt string
---@field type string
---@field default string|function|nil
---@field options string[]|function|nil
---@field required boolean|nil
---@field validate function|nil

---@class WizardState
---@field steps WizardStep[]
---@field current number
---@field results table
---@field on_complete function
---@field on_cancel function|nil

local java_versions = { "21", "17", "25" }
local build_tools = { "maven", "gradle", "gradle-kotlin" }
local packaging_types = { "jar", "war" }
local config_formats = { "yaml", "properties" }

local common_deps = {
  { id = "web", name = "Spring Web", desc = "Build web applications with Spring MVC" },
  { id = "data-jpa", name = "Spring Data JPA", desc = "Persist data with JPA and Hibernate" },
  { id = "lombok", name = "Lombok", desc = "Reduce boilerplate code" },
  { id = "validation", name = "Validation", desc = "Bean validation with Hibernate Validator" },
  { id = "devtools", name = "DevTools", desc = "Fast application restarts and LiveReload" },
  { id = "actuator", name = "Actuator", desc = "Production-ready features" },
  { id = "security", name = "Spring Security", desc = "Authentication and access control" },
  { id = "h2", name = "H2 Database", desc = "In-memory database for development" },
  { id = "mysql", name = "MySQL Driver", desc = "MySQL JDBC driver" },
  { id = "postgresql", name = "PostgreSQL Driver", desc = "PostgreSQL JDBC driver" },
}

function M.get_java_versions()
  return java_versions
end

function M.get_build_tools()
  return build_tools
end

function M.get_packaging_types()
  return packaging_types
end

function M.get_config_formats()
  return config_formats
end

function M.get_common_deps()
  return common_deps
end

local function get_default_value(step)
  if type(step.default) == "function" then
    return step.default()
  end
  return step.default
end

local function get_options(step)
  if type(step.options) == "function" then
    return step.options()
  end
  return step.options
end

local function run_step(state)
  local step = state.steps[state.current]
  if not step then
    if state.on_complete then
      state.on_complete(state.results)
    end
    return
  end

  local default = get_default_value(step)
  local step_label = string.format("[%d/%d] ", state.current, #state.steps)

  if step.type == "input" then
    local prompt_opts = {
      prompt = step_label .. step.prompt,
      default = default or "",
    }

    vim.ui.input(prompt_opts, function(value)
      if value == nil then
        if state.on_cancel then
          state.on_cancel()
        end
        return
      end

      if step.required and (value == nil or value == "") then
        notify.warn(step.name .. " is required")
        run_step(state)
        return
      end

      if step.validate and value ~= "" then
        local ok, err = step.validate(value)
        if not ok then
          notify.warn(err or "Invalid input")
          run_step(state)
          return
        end
      end

      state.results[step.name] = value ~= "" and value or default
      state.current = state.current + 1
      run_step(state)
    end)
  elseif step.type == "select" then
    local options = get_options(step)
    local prompt = step_label .. step.prompt

    vim.ui.select(options, { prompt = prompt }, function(choice)
      if choice == nil then
        if state.on_cancel then
          state.on_cancel()
        end
        return
      end

      state.results[step.name] = choice
      state.current = state.current + 1
      run_step(state)
    end)
  elseif step.type == "confirm" then
    local prompt = step_label .. step.prompt

    vim.ui.select({ "Yes", "No" }, { prompt = prompt }, function(choice)
      if choice == nil then
        if state.on_cancel then
          state.on_cancel()
        end
        return
      end

      state.results[step.name] = choice == "Yes"
      state.current = state.current + 1
      run_step(state)
    end)
  elseif step.type == "multiselect" then
    M.multiselect_deps(step, state)
  else
    state.current = state.current + 1
    run_step(state)
  end
end

function M.multiselect_deps(step, state)
  local telescope_ok, _ = pcall(require, "telescope")
  if telescope_ok then
    M.telescope_multiselect(step, state)
  else
    M.native_multiselect(step, state)
  end
end

function M.telescope_multiselect(step, state)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local deps = get_options(step) or common_deps
  local selected = {}

  pickers
    .new({}, {
      prompt_title = step.prompt,
      finder = finders.new_table({
        results = deps,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format("[%s] %s - %s", selected[entry.id] and "x" or " ", entry.name, entry.desc),
            ordinal = entry.name .. " " .. entry.id .. " " .. entry.desc,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function toggle_selection()
          local selection = action_state.get_selected_entry()
          if selection then
            local id = selection.value.id
            selected[id] = not selected[id]
            local picker = action_state.get_current_picker(prompt_bufnr)
            picker:refresh(
              finders.new_table({
                results = deps,
                entry_maker = function(entry)
                  return {
                    value = entry,
                    display = string.format("[%s] %s - %s", selected[entry.id] and "x" or " ", entry.name, entry.desc),
                    ordinal = entry.name .. " " .. entry.id .. " " .. entry.desc,
                  }
                end,
              }),
              { reset_prompt = false }
            )
          end
        end

        map("i", "<Tab>", toggle_selection)
        map("n", "<Tab>", toggle_selection)
        map("i", "<Space>", toggle_selection)
        map("n", "<Space>", toggle_selection)

        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local result = {}
          for id, is_selected in pairs(selected) do
            if is_selected then
              table.insert(result, id)
            end
          end
          state.results[step.name] = result
          state.current = state.current + 1
          run_step(state)
        end)

        return true
      end,
    })
    :find()
end

function M.native_multiselect(step, state)
  local deps = get_options(step) or common_deps
  local selected = {}

  local function show_menu()
    local items = {}
    for _, dep in ipairs(deps) do
      local prefix = selected[dep.id] and "[x]" or "[ ]"
      table.insert(items, string.format("%s %s - %s", prefix, dep.name, dep.desc))
    end
    table.insert(items, "--- Done (confirm selection) ---")

    vim.ui.select(items, { prompt = step.prompt .. " (select to toggle, 'Done' to finish)" }, function(choice, idx)
      if choice == nil then
        if state.on_cancel then
          state.on_cancel()
        end
        return
      end

      if idx == #items then
        local result = {}
        for id, is_selected in pairs(selected) do
          if is_selected then
            table.insert(result, id)
          end
        end
        state.results[step.name] = result
        state.current = state.current + 1
        run_step(state)
      else
        local dep = deps[idx]
        selected[dep.id] = not selected[dep.id]
        show_menu()
      end
    end)
  end

  show_menu()
end

function M.run(steps, on_complete, on_cancel)
  local state = {
    steps = steps,
    current = 1,
    results = {},
    on_complete = on_complete,
    on_cancel = on_cancel or function()
      notify.info("Wizard cancelled")
    end,
  }

  run_step(state)
end

function M.get_init_steps()
  local cfg = config.get()
  local defaults = cfg.init.defaults

  return {
    {
      name = "name",
      prompt = "Project name: ",
      type = "input",
      required = true,
      validate = function(value)
        if value:match("^[a-zA-Z][a-zA-Z0-9_-]*$") then
          return true
        end
        return false, "Name must start with a letter and contain only letters, numbers, dashes, and underscores"
      end,
    },
    {
      name = "group",
      prompt = "Group ID: ",
      type = "input",
      default = defaults.group,
    },
    {
      name = "java",
      prompt = "Java version: ",
      type = "select",
      options = java_versions,
      default = defaults.java,
    },
    {
      name = "build",
      prompt = "Build tool: ",
      type = "select",
      options = build_tools,
      default = defaults.build,
    },
    {
      name = "packaging",
      prompt = "Packaging: ",
      type = "select",
      options = packaging_types,
      default = defaults.packaging,
    },
    {
      name = "config_format",
      prompt = "Config format: ",
      type = "select",
      options = config_formats,
      default = defaults.config_format,
    },
    {
      name = "directory",
      prompt = "Directory (leave empty for current): ",
      type = "input",
      default = ".",
    },
    {
      name = "deps",
      prompt = "Select dependencies (Tab/Space to toggle, Enter to confirm): ",
      type = "multiselect",
      options = common_deps,
    },
  }
end

function M.build_init_command(results)
  local args = { "init", results.name, "--no-interactive", "--json" }

  if results.group and results.group ~= "" then
    table.insert(args, "--group")
    table.insert(args, results.group)
  end

  if results.java then
    table.insert(args, "--java")
    table.insert(args, results.java)
  end

  if results.build then
    table.insert(args, "--build")
    table.insert(args, results.build)
  end

  if results.packaging then
    table.insert(args, "--packaging")
    table.insert(args, results.packaging)
  end

  if results.config_format then
    table.insert(args, "--config")
    table.insert(args, results.config_format)
  end

  if results.directory and results.directory ~= "" and results.directory ~= "." then
    table.insert(args, "--dir")
    table.insert(args, results.directory)
  end

  if results.deps and #results.deps > 0 then
    table.insert(args, "--deps")
    table.insert(args, table.concat(results.deps, ","))
  end

  return args
end

return M
