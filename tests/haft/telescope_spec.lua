describe("haft.telescope", function()
  local telescope_mod

  before_each(function()
    package.loaded["haft.telescope"] = nil
    package.loaded["haft.config"] = nil

    local config = require("haft.config")
    config.reset()
    config.setup({})

    telescope_mod = require("haft.telescope")
  end)

  describe("module structure", function()
    it("has is_telescope_available function", function()
      assert.is_function(telescope_mod.is_telescope_available)
    end)

    it("has get_provider function", function()
      assert.is_function(telescope_mod.get_provider)
    end)

    it("has register_picker function", function()
      assert.is_function(telescope_mod.register_picker)
    end)

    it("has get_picker function", function()
      assert.is_function(telescope_mod.get_picker)
    end)

    it("has setup function", function()
      assert.is_function(telescope_mod.setup)
    end)
  end)

  describe("picker registration", function()
    it("can register and retrieve a picker", function()
      local test_picker = function()
        return "test"
      end

      telescope_mod.register_picker("test", test_picker)
      local retrieved = telescope_mod.get_picker("test")

      assert.is_function(retrieved)
      assert.equals("test", retrieved())
    end)

    it("returns nil for unregistered picker", function()
      local retrieved = telescope_mod.get_picker("nonexistent")
      assert.is_nil(retrieved)
    end)
  end)

  describe("provider selection", function()
    it("returns native when provider is set to native", function()
      package.loaded["haft.config"] = nil
      local config = require("haft.config")
      config.reset()
      config.setup({ picker = { provider = "native" } })

      package.loaded["haft.telescope"] = nil
      telescope_mod = require("haft.telescope")

      local provider = telescope_mod.get_provider()
      assert.equals("native", provider)
    end)
  end)
end)

describe("haft.telescope.pickers.dependencies", function()
  describe("parse_dependencies helper", function()
    it("parses categories and dependencies", function()
      local parse = function(data)
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

      local data = {
        categories = {
          {
            name = "Web",
            dependencies = {
              {
                shortcut = "web",
                name = "Spring Web",
                description = "Build web applications",
                groupId = "org.springframework.boot",
                artifactId = "spring-boot-starter-web",
              },
            },
          },
          {
            name = "Database",
            dependencies = {
              {
                shortcut = "jpa",
                name = "Spring Data JPA",
                description = "JPA support",
                groupId = "org.springframework.boot",
                artifactId = "spring-boot-starter-data-jpa",
              },
            },
          },
        },
      }

      local deps = parse(data)
      assert.equals(2, #deps)
      assert.equals("web", deps[1].shortcut)
      assert.equals("Spring Web", deps[1].name)
      assert.equals("Web", deps[1].category)
      assert.equals("jpa", deps[2].shortcut)
      assert.equals("Database", deps[2].category)
    end)

    it("handles empty categories", function()
      local parse = function(data)
        local deps = {}
        local categories = data.categories or {}

        for _, category in ipairs(categories) do
          local cat_name = category.name or "Other"
          local cat_deps = category.dependencies or {}

          for _, dep in ipairs(cat_deps) do
            table.insert(deps, {
              shortcut = dep.shortcut or "",
              name = dep.name or dep.shortcut or "",
              category = cat_name,
            })
          end
        end

        return deps
      end

      local data = { categories = {} }
      local deps = parse(data)
      assert.equals(0, #deps)
    end)

    it("handles missing categories key", function()
      local parse = function(data)
        local deps = {}
        local categories = data.categories or {}

        for _, category in ipairs(categories) do
          local cat_deps = category.dependencies or {}
          for _, dep in ipairs(cat_deps) do
            table.insert(deps, dep)
          end
        end

        return deps
      end

      local data = {}
      local deps = parse(data)
      assert.equals(0, #deps)
    end)

    it("uses shortcut as name fallback", function()
      local parse = function(data)
        local deps = {}
        local categories = data.categories or {}

        for _, category in ipairs(categories) do
          local cat_deps = category.dependencies or {}
          for _, dep in ipairs(cat_deps) do
            table.insert(deps, {
              shortcut = dep.shortcut or "",
              name = dep.name or dep.shortcut or "",
            })
          end
        end

        return deps
      end

      local data = {
        categories = {
          {
            name = "Test",
            dependencies = {
              { shortcut = "lombok" },
            },
          },
        },
      }

      local deps = parse(data)
      assert.equals(1, #deps)
      assert.equals("lombok", deps[1].name)
    end)
  end)
end)

describe("haft.config picker settings", function()
  local config

  before_each(function()
    package.loaded["haft.config"] = nil
    config = require("haft.config")
    config.reset()
  end)

  describe("picker config", function()
    it("default provider is auto", function()
      config.setup({})
      local cfg = config.get()
      assert.equals("auto", cfg.picker.provider)
    end)

    it("can be set to telescope", function()
      config.setup({ picker = { provider = "telescope" } })
      local cfg = config.get()
      assert.equals("telescope", cfg.picker.provider)
    end)

    it("can be set to native", function()
      config.setup({ picker = { provider = "native" } })
      local cfg = config.get()
      assert.equals("native", cfg.picker.provider)
    end)

    it("has default telescope theme", function()
      config.setup({})
      local cfg = config.get()
      assert.equals("dropdown", cfg.picker.telescope.theme)
    end)

    it("can configure telescope layout", function()
      config.setup({
        picker = {
          telescope = {
            layout_config = { width = 0.9, height = 0.7 },
          },
        },
      })
      local cfg = config.get()
      assert.equals(0.9, cfg.picker.telescope.layout_config.width)
      assert.equals(0.7, cfg.picker.telescope.layout_config.height)
    end)
  end)
end)

describe("haft.telescope.pickers.remove", function()
  describe("parse_current_dependencies helper", function()
    it("parses dependencies from project info", function()
      local parse = function(data)
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

      local data = {
        dependencies = {
          total = 2,
          list = {
            {
              groupId = "org.projectlombok",
              artifactId = "lombok",
              version = "1.18.30",
              scope = "provided",
            },
            {
              groupId = "org.springframework.boot",
              artifactId = "spring-boot-starter-web",
              version = "",
              scope = "compile",
            },
          },
        },
      }

      local deps = parse(data)
      assert.equals(2, #deps)
      assert.equals("lombok", deps[1].artifactId)
      assert.equals("org.projectlombok", deps[1].groupId)
      assert.equals("1.18.30", deps[1].version)
      assert.equals("provided", deps[1].scope)
      assert.equals("org.projectlombok:lombok", deps[1].display)
      assert.equals("spring-boot-starter-web", deps[2].artifactId)
      assert.equals("compile", deps[2].scope)
    end)

    it("handles empty dependencies list", function()
      local parse = function(data)
        local deps = {}
        local dependencies = data.dependencies or {}
        local dep_list = dependencies.list or {}

        for _, dep in ipairs(dep_list) do
          table.insert(deps, {
            artifactId = dep.artifactId or "",
            groupId = dep.groupId or "",
          })
        end

        return deps
      end

      local data = { dependencies = { list = {} } }
      local deps = parse(data)
      assert.equals(0, #deps)
    end)

    it("handles missing dependencies key", function()
      local parse = function(data)
        local deps = {}
        local dependencies = data.dependencies or {}
        local dep_list = dependencies.list or {}

        for _, dep in ipairs(dep_list) do
          table.insert(deps, dep)
        end

        return deps
      end

      local data = {}
      local deps = parse(data)
      assert.equals(0, #deps)
    end)

    it("uses default scope when not specified", function()
      local parse = function(data)
        local deps = {}
        local dependencies = data.dependencies or {}
        local dep_list = dependencies.list or {}

        for _, dep in ipairs(dep_list) do
          table.insert(deps, {
            artifactId = dep.artifactId or "",
            scope = dep.scope or "compile",
          })
        end

        return deps
      end

      local data = {
        dependencies = {
          list = {
            { artifactId = "lombok" },
          },
        },
      }

      local deps = parse(data)
      assert.equals(1, #deps)
      assert.equals("compile", deps[1].scope)
    end)
  end)
end)

describe("haft.telescope.pickers.routes", function()
  describe("parse_routes helper", function()
    it("parses routes from data", function()
      local parse = function(data)
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

      local data = {
        routes = {
          {
            method = "GET",
            path = "/api/users",
            handler = "getAll",
            controller = "UserController",
            file = "src/main/java/com/example/UserController.java",
            line = 25,
          },
          {
            method = "POST",
            path = "/api/users",
            handler = "create",
            controller = "UserController",
            file = "src/main/java/com/example/UserController.java",
            line = 35,
          },
        },
      }

      local routes = parse(data)
      assert.equals(2, #routes)
      assert.equals("GET", routes[1].method)
      assert.equals("/api/users", routes[1].path)
      assert.equals("getAll", routes[1].handler)
      assert.equals("UserController", routes[1].controller)
      assert.equals(25, routes[1].line)
      assert.equals("POST", routes[2].method)
    end)

    it("handles empty routes", function()
      local parse = function(data)
        local routes = {}
        local raw_routes = data.routes or data or {}

        if type(raw_routes) ~= "table" then
          return routes
        end

        for _, route in ipairs(raw_routes) do
          table.insert(routes, route)
        end

        return routes
      end

      local data = { routes = {} }
      local routes = parse(data)
      assert.equals(0, #routes)
    end)

    it("uses defaults for missing fields", function()
      local parse = function(data)
        local routes = {}
        local raw_routes = data.routes or {}

        for _, route in ipairs(raw_routes) do
          table.insert(routes, {
            method = route.method or "GET",
            path = route.path or "",
            handler = route.handler or "",
            controller = route.controller or "",
            file = route.file or "",
            line = route.line or 0,
          })
        end

        return routes
      end

      local data = {
        routes = {
          { path = "/api/health" },
        },
      }

      local routes = parse(data)
      assert.equals(1, #routes)
      assert.equals("GET", routes[1].method)
      assert.equals("/api/health", routes[1].path)
      assert.equals("", routes[1].handler)
      assert.equals(0, routes[1].line)
    end)
  end)
end)

describe("haft.telescope.pickers.templates", function()
  describe("parse_templates helper", function()
    it("parses templates from data", function()
      local parse = function(data)
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
            custom = template.source ~= "embedded",
          })
        end

        return templates
      end

      local data = {
        templates = {
          {
            name = "controller.tmpl",
            category = "resource",
            source = "embedded",
            path = "",
          },
          {
            name = "service.tmpl",
            category = "resource",
            source = "project",
            path = ".haft/templates/resource/service.tmpl",
          },
        },
      }

      local templates = parse(data)
      assert.equals(2, #templates)
      assert.equals("controller.tmpl", templates[1].name)
      assert.equals("resource", templates[1].category)
      assert.equals("embedded", templates[1].source)
      assert.is_false(templates[1].custom)
      assert.equals("service.tmpl", templates[2].name)
      assert.equals("project", templates[2].source)
      assert.is_true(templates[2].custom)
    end)

    it("handles empty templates", function()
      local parse = function(data)
        local templates = {}
        local raw_templates = data.templates or {}

        for _, template in ipairs(raw_templates) do
          table.insert(templates, template)
        end

        return templates
      end

      local data = { templates = {} }
      local templates = parse(data)
      assert.equals(0, #templates)
    end)

    it("uses defaults for missing fields", function()
      local parse = function(data)
        local templates = {}
        local raw_templates = data.templates or {}

        for _, template in ipairs(raw_templates) do
          table.insert(templates, {
            name = template.name or "",
            category = template.category or "other",
            source = template.source or "embedded",
            path = template.path or "",
          })
        end

        return templates
      end

      local data = {
        templates = {
          { name = "custom.tmpl" },
        },
      }

      local templates = parse(data)
      assert.equals(1, #templates)
      assert.equals("custom.tmpl", templates[1].name)
      assert.equals("other", templates[1].category)
      assert.equals("embedded", templates[1].source)
    end)
  end)

  describe("source_icon helper", function()
    it("returns correct icons for sources", function()
      local source_icon = function(source)
        if source == "project" then
          return "[P]"
        elseif source == "global" then
          return "[G]"
        else
          return "[E]"
        end
      end

      assert.equals("[P]", source_icon("project"))
      assert.equals("[G]", source_icon("global"))
      assert.equals("[E]", source_icon("embedded"))
      assert.equals("[E]", source_icon("unknown"))
    end)
  end)
end)
