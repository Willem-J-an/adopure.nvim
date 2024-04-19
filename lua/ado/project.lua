local M = {}

---URL-encodes the given text
---@param text string
---@return string
local function encode_uri_component(text)
    text = text:gsub("([^A-Za-z0-9%-_.!~*'()])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return text
end

---@param project Project
---@return string project_name
local function format_project_choice(project)
    return project.name
end

---Set project_name in cache file;
---@param project_cache_path Path
---@return string|nil err
local function set_project_name_cache(project_cache_path)
    local projects, err = require("ado.api").get_projects()
    if err then
        return err
    end
    project_cache_path:touch({ parents = true })

    vim.ui.select(
        projects,
        { prompt = "Select Azure DevOps project to target;", format_item = format_project_choice },
        function(project)
            project_cache_path:write("project_name=" .. encode_uri_component(project.name), "w")
            vim.notify("project_name stored in cache: " .. project.name)
        end
    )
end
---Get project name from cache or select correct one;
---@return string|nil project_name, string|nil err
function M.get_project_name(repository_name)
    local project_cache_path = require("plenary.path"):new(vim.fn.stdpath("cache"), "ado.nvim", repository_name)
    if project_cache_path:exists() then
        return vim.split(project_cache_path:read(), "project_name=")[2]
    end
    local err = set_project_name_cache(project_cache_path)
    return err or "No project name set yet;"
end

return M
