local M = {}
local function check_pat_token()
    local ok, response = pcall(function()
        return require("adopure.config.internal"):access_token()
    end)
    if not ok then
        vim.health.error(tostring(response))
        return false
    end
    vim.health.ok("Pat token present;")
    return true
end
local function check_context()
    local context_ok, context = pcall(function()
        return require("adopure.state").AdoContext:new()
    end)
    if not context_ok then
        vim.health.error(tostring(context))
        return false
    end
    local assert_ok, response = pcall(
        assert,
        context.organization_url and context.project_name and context.repository_name,
        "Able to load context from git remote"
    )
    if not assert_ok then
        vim.health.error(tostring(response))
        return false
    end
    vim.health.ok("Ado context succesfully loaded;")
    return true
end
local function check_token_in_context()
    local context = require("adopure.state").AdoContext:new()
    local ok, repository = pcall(require("adopure.api").get_repository, context)
    if not ok or not repository then
        vim.health.error(tostring(repository or "No repository found with pat_token in this context;"))
        return false
    end
    vim.health.ok("Found repository with context and pat token;")
    return true
end

local function check_dependency(dependency)
    local ok, _ = pcall(require, dependency)
    if not ok then
        vim.health.error("Missing dependency: " .. dependency)
        return
    end
    vim.health.ok("Installed dependency: " .. dependency)
end

function M.check()
    vim.health.start("adopure.nvim")
    for _, check in ipairs({ check_pat_token, check_context, check_token_in_context }) do
        local pass = check()
        if not pass then
            return
        end
    end
    for _, dependency in ipairs({ "telescope", "plenary" }) do
        check_dependency(dependency)
    end
end
return M
