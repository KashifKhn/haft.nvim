describe("haft.config", function()
  local config = require("haft.config")

  before_each(function()
    config.reset()
  end)

  describe("setup", function()
    it("uses defaults when no opts provided", function()
      config.setup({})
      assert.equals("haft", config.options.haft_path)
      assert.is_true(config.options.detection.enabled)
      assert.is_true(config.options.notifications.enabled)
    end)

    it("merges user options with defaults", function()
      config.setup({ haft_path = "/custom/haft" })
      assert.equals("/custom/haft", config.options.haft_path)
      assert.is_true(config.options.detection.enabled)
    end)

    it("deep merges nested options", function()
      config.setup({
        detection = {
          enabled = false,
        },
      })
      assert.is_false(config.options.detection.enabled)
      assert.is_table(config.options.detection.patterns)
      assert.equals(4, #config.options.detection.patterns)
    end)

    it("preserves user arrays instead of merging", function()
      config.setup({
        detection = {
          patterns = { "custom.yaml" },
        },
      })
      assert.equals(1, #config.options.detection.patterns)
      assert.equals("custom.yaml", config.options.detection.patterns[1])
    end)

    it("handles deeply nested options", function()
      config.setup({
        terminal = {
          float = {
            border = "single",
          },
        },
      })
      assert.equals("single", config.options.terminal.float.border)
      assert.equals(0.8, config.options.terminal.float.width)
      assert.equals("auto", config.options.terminal.type)
    end)
  end)

  describe("get", function()
    it("returns options after setup", function()
      config.setup({ haft_path = "test" })
      local opts = config.get()
      assert.equals("test", opts.haft_path)
    end)

    it("auto-initializes with defaults if not setup", function()
      local opts = config.get()
      assert.equals("haft", opts.haft_path)
    end)
  end)

  describe("reset", function()
    it("clears options", function()
      config.setup({ haft_path = "test" })
      config.reset()
      assert.is_nil(config.options)
    end)
  end)

  describe("get_defaults", function()
    it("returns a copy of defaults", function()
      local defaults = config.get_defaults()
      assert.equals("haft", defaults.haft_path)
      defaults.haft_path = "modified"
      local defaults2 = config.get_defaults()
      assert.equals("haft", defaults2.haft_path)
    end)
  end)
end)
