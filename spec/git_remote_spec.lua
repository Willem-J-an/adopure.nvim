local assert = require("luassert.assert")
local plenary_new_job = require("plenary.job").new
local remotes = {
    first_fetch = "first\tgit@ssh.dev.azure.com:v3/first_org/first_project.nvim/first_repo.nvim (fetch)",
    first_push = "first\tgit@ssh.dev.azure.com:v3/first_org/first_project.nvim/first_repo.nvim (push)",
    git_fetch = "origin\tgit@github.com:Willem-J-an/adopure.nvim.git (fetch)",
    git_push = "origin\tgit@github.com:Willem-J-an/adopure.nvim.git (push)",
    second_fetch = "second\thttps://second_org@dev.azure.com/second_org/second_project/_git/second_repo (fetch)",
    second_push = "second\thttps://second_org@dev.azure.com/second_org/second_project/_git/second_repo (push)",
    third_fetch = "third\thttps://dev.azure.com/third_org/third_project/_git/third_repo (fetch)",
    third_push = "third\thttps://dev.azure.com/third_org/third_project/_git/third_repo (push)",
}

describe("get remote config", function()
    ---@param remote_stdout string[]
    local function mock_git_remote(remote_stdout)
        require("plenary.job").new = function(_1, _2) ---@diagnostic disable-line duplicate-set-field
            local _ = _1 and _2
            return {
                start = function(_) end,
                result = function(_)
                    return remote_stdout
                end,
                stderr_result = function(_)
                    return {}
                end,
            }
        end
    end

    it("returns preferred ssh details", function()
        require("adopure.config.internal").preferred_remotes = { "first" }
        mock_git_remote(vim.tbl_values(remotes))
        local organization_url, project_name, repository_name = require("adopure.git").get_remote_config()
        assert.are.same("https://dev.azure.com/first_org/", organization_url)
        assert.are.same("first_project.nvim", project_name)
        assert.are.same("first_repo.nvim", repository_name)
    end)

    it("returns preferred https details with user", function()
        require("adopure.config.internal").preferred_remotes = { "second" }
        mock_git_remote(vim.tbl_values(remotes))
        local organization_url, project_name, repository_name = require("adopure.git").get_remote_config()
        assert.are.same("https://dev.azure.com/second_org/", organization_url)
        assert.are.same("second_project", project_name)
        assert.are.same("second_repo", repository_name)
    end)


    it("returns preferred https details without user", function()
        require("adopure.config.internal").preferred_remotes = { "third" }
        mock_git_remote(vim.tbl_values(remotes))
        local organization_url, project_name, repository_name = require("adopure.git").get_remote_config()
        assert.are.same("https://dev.azure.com/third_org/", organization_url)
        assert.are.same("third_project", project_name)
        assert.are.same("third_repo", repository_name)
    end)

    after_each(function()
        require("plenary.job").new = plenary_new_job
    end)
end)
