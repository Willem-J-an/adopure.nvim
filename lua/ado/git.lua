local M = {}
local Job = require("plenary.job")
local Path = require("plenary.path")
local Utils = require("lua.ado.utils")
--
---Get git repository name
---@return string Repository name
function M.get_repo_name()
	local get_git_repo_job = Job:new({
		command = "git",
		args = { "rev-parse", "--show-toplevel" },
		cwd = ".",
	})
	get_git_repo_job:start()

	local repository_path = Path:new(Utils.await_result(get_git_repo_job))
	local path_parts = vim.split(repository_path.filename, repository_path.path.sep)
	return path_parts[#path_parts]
end

return M
