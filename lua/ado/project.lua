local M = {}
local Api = require("lua.ado.api")
local Path = require("plenary.path")

---Set project_name in cache file;
---@param project_cache_path Path
---@return string project_name, string err
local function set_project_name_cache(project_cache_path)
    local projects, err = Api.get_projects()
    if err ~= "" then
        return "", err
    end
    project_cache_path:touch({ parents = true })

    local project_names = {}
    for _, project in pairs(projects) do
        table.insert(project_names, project.name)
    end
    vim.ui.select(project_names, { prompt = "Select Azure DevOps project to target;" }, function(project_name)
        project_cache_path:write("project_name=" .. project_name, "w")
        vim.notify("project_name stored in cache: " .. project_name)
    end)
end
---Get project name from cache or select correct one;
---@return string|nil project_name
function M.get_project_name(repository_name)
    local project_cache_path = Path:new(vim.fn.stdpath("cache"), "ado.nvim", repository_name)
    if project_cache_path:exists() then
        return vim.split(project_cache_path:read(), "project_name=")[2]
    end

    set_project_name_cache(project_cache_path)
end

return M
