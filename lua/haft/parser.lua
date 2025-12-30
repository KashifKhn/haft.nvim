local M = {}

---@param str string
---@return table?
function M.parse_json(str)
  if not str or str == "" then
    return nil
  end

  local ok, result = pcall(vim.json.decode, str)
  if not ok then
    return nil
  end

  return result
end

---@param data table
---@return string[]
function M.extract_files(data)
  local files = {}

  if type(data) ~= "table" then
    return files
  end

  if data.files and type(data.files) == "table" then
    for _, file in ipairs(data.files) do
      if type(file) == "string" then
        table.insert(files, file)
      elseif type(file) == "table" and file.path then
        table.insert(files, file.path)
      end
    end
  end

  if data.generated and type(data.generated) == "table" then
    for _, file in ipairs(data.generated) do
      if type(file) == "string" then
        table.insert(files, file)
      elseif type(file) == "table" and file.path then
        table.insert(files, file.path)
      end
    end
  end

  return files
end

---@param data table
---@return string?
function M.extract_error(data)
  if type(data) ~= "table" then
    return nil
  end

  if data.error then
    return tostring(data.error)
  end

  if data.message then
    return tostring(data.message)
  end

  return nil
end

---@param data table
---@return table[]
function M.extract_dependencies(data)
  local deps = {}

  if type(data) ~= "table" then
    return deps
  end

  if data.dependencies and type(data.dependencies) == "table" then
    for _, dep in ipairs(data.dependencies) do
      if type(dep) == "string" then
        table.insert(deps, { name = dep })
      elseif type(dep) == "table" then
        table.insert(deps, dep)
      end
    end
  end

  return deps
end

---@param data table
---@return table[]
function M.extract_routes(data)
  local routes = {}

  if type(data) ~= "table" then
    return routes
  end

  if data.routes and type(data.routes) == "table" then
    for _, route in ipairs(data.routes) do
      if type(route) == "table" then
        table.insert(routes, route)
      end
    end
  end

  return routes
end

---@param data table
---@return table?
function M.extract_project_info(data)
  if type(data) ~= "table" then
    return nil
  end

  return {
    name = data.name,
    version = data.version,
    group = data.group or data.groupId,
    artifact = data.artifact or data.artifactId,
    java_version = data.javaVersion or data.java_version,
    spring_version = data.springVersion or data.spring_version,
    build_tool = data.buildTool or data.build_tool,
    dependencies = M.extract_dependencies(data),
  }
end

return M
