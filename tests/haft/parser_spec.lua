describe("haft.parser", function()
  local parser = require("haft.parser")

  describe("parse_json", function()
    it("parses valid JSON", function()
      local result = parser.parse_json('{"name": "test", "version": "1.0.0"}')
      assert.is_table(result)
      assert.equals("test", result.name)
      assert.equals("1.0.0", result.version)
    end)

    it("returns nil for invalid JSON", function()
      local result = parser.parse_json("not json")
      assert.is_nil(result)
    end)

    it("returns nil for empty string", function()
      local result = parser.parse_json("")
      assert.is_nil(result)
    end)

    it("returns nil for nil input", function()
      local result = parser.parse_json(nil)
      assert.is_nil(result)
    end)

    it("parses arrays", function()
      local result = parser.parse_json('[1, 2, 3]')
      assert.is_table(result)
      assert.equals(3, #result)
    end)
  end)

  describe("extract_files", function()
    it("extracts files from files array", function()
      local data = { files = { "src/Main.java", "src/Test.java" } }
      local files = parser.extract_files(data)
      assert.equals(2, #files)
      assert.equals("src/Main.java", files[1])
    end)

    it("extracts files from generated array", function()
      local data = { generated = { "src/Generated.java" } }
      local files = parser.extract_files(data)
      assert.equals(1, #files)
      assert.equals("src/Generated.java", files[1])
    end)

    it("extracts files from object format", function()
      local data = { files = { { path = "src/Main.java" }, { path = "src/Test.java" } } }
      local files = parser.extract_files(data)
      assert.equals(2, #files)
      assert.equals("src/Main.java", files[1])
    end)

    it("returns empty array for invalid input", function()
      local files = parser.extract_files(nil)
      assert.equals(0, #files)
    end)

    it("returns empty array for missing files key", function()
      local files = parser.extract_files({ name = "test" })
      assert.equals(0, #files)
    end)
  end)

  describe("extract_error", function()
    it("extracts error message", function()
      local data = { error = "Something went wrong" }
      local err = parser.extract_error(data)
      assert.equals("Something went wrong", err)
    end)

    it("extracts message as fallback", function()
      local data = { message = "Error message" }
      local err = parser.extract_error(data)
      assert.equals("Error message", err)
    end)

    it("returns nil for no error", function()
      local data = { success = true }
      local err = parser.extract_error(data)
      assert.is_nil(err)
    end)

    it("returns nil for invalid input", function()
      local err = parser.extract_error(nil)
      assert.is_nil(err)
    end)
  end)

  describe("extract_dependencies", function()
    it("extracts string dependencies", function()
      local data = { dependencies = { "spring-web", "spring-data-jpa" } }
      local deps = parser.extract_dependencies(data)
      assert.equals(2, #deps)
      assert.equals("spring-web", deps[1].name)
    end)

    it("extracts object dependencies", function()
      local data = { dependencies = { { name = "spring-web", version = "3.0.0" } } }
      local deps = parser.extract_dependencies(data)
      assert.equals(1, #deps)
      assert.equals("spring-web", deps[1].name)
      assert.equals("3.0.0", deps[1].version)
    end)

    it("returns empty array for missing dependencies", function()
      local deps = parser.extract_dependencies({ name = "test" })
      assert.equals(0, #deps)
    end)
  end)

  describe("extract_routes", function()
    it("extracts routes", function()
      local data = {
        routes = {
          { method = "GET", path = "/api/users" },
          { method = "POST", path = "/api/users" },
        },
      }
      local routes = parser.extract_routes(data)
      assert.equals(2, #routes)
      assert.equals("GET", routes[1].method)
      assert.equals("/api/users", routes[1].path)
    end)

    it("returns empty array for missing routes", function()
      local routes = parser.extract_routes({ name = "test" })
      assert.equals(0, #routes)
    end)
  end)

  describe("extract_project_info", function()
    it("extracts project info", function()
      local data = {
        name = "my-app",
        version = "1.0.0",
        groupId = "com.example",
        artifactId = "my-app",
        javaVersion = "17",
        springVersion = "3.2.0",
        buildTool = "maven",
      }
      local info = parser.extract_project_info(data)
      assert.equals("my-app", info.name)
      assert.equals("1.0.0", info.version)
      assert.equals("com.example", info.group)
      assert.equals("my-app", info.artifact)
      assert.equals("17", info.java_version)
      assert.equals("3.2.0", info.spring_version)
      assert.equals("maven", info.build_tool)
    end)

    it("handles alternative field names", function()
      local data = {
        name = "my-app",
        group = "com.example",
        artifact = "my-app",
        java_version = "17",
        spring_version = "3.2.0",
        build_tool = "gradle",
      }
      local info = parser.extract_project_info(data)
      assert.equals("com.example", info.group)
      assert.equals("17", info.java_version)
      assert.equals("gradle", info.build_tool)
    end)

    it("returns nil for invalid input", function()
      local info = parser.extract_project_info(nil)
      assert.is_nil(info)
    end)
  end)
end)
