local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  return
end

return telescope.register_extension({
  setup = function(ext_config, config)
    local haft_telescope = require("haft.telescope")
    haft_telescope.setup()
  end,
  exports = {
    dependencies = function(opts)
      local picker = require("haft.telescope.pickers.dependencies")
      local api = require("haft.api")
      picker.pick(function(selected)
        if selected and #selected > 0 then
          local shortcuts = {}
          for _, dep in ipairs(selected) do
            table.insert(shortcuts, dep.shortcut)
          end
          api.add_dependencies(shortcuts)
        end
      end)
    end,
  },
})
