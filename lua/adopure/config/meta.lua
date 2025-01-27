---@mod adopure.config.meta
---@brief [[
---The plugin is configured by assigning an adopure.Config table to vim.g.adopure.
--->lua
--- vim.g.adopure = {}
---<
---There is no mechanism built-in to securely load secrets.
---If you have a cli command that will produce the secret, consider doing something like this:
--->lua
--- local nio = require("nio")
--- nio.run(function()
---     local secret_job = nio.process.run({ cmd = "pass", args = { "show", "my_pat_token_secret_name"} })
---     vim.g.adopure = { pat_token = secret_job.stdout.read():sub(1, -2) }
--- end)
---<
---Alternatively, you can set it as environment variable.
---@brief ]]
---
---@class adopure.Highlights
---@field active? string Highlight for lines with active comments.
---@field active_sign? string Highlight for sign indicating active comments.
---@field inactive? string Highlight for lines with inactive comments.
---@field inactive_sign? string Highlight for sign indicating in active comments.

---@class adopure.Config
---If not provided, attempt to use AZURE_DEVOPS_EXT_PAT environment variable.
---If no environment variable is set, and no config is provided, the plugin will not work.
---@field pat_token? string Personal Access Token to access Azure DevOps.
---@field hl_groups? adopure.Highlights Highlight groups to apply.
---List with preferred remotes to extract Azure DevOps context from.
---Remotes are elected among the following options:
---1. Any remote in this list can be picked, non-deterministically.
---2. Any Azure DevOps remote.
---3. Any remote. If the remote is not an Azure DevOps remote, the plugin will not work.
---@field preferred_remotes? string[]
---@field filter_my_pull_requests? boolean Fetches only pull requests assigned to me, my team or created by me.

local config = {}

---@type adopure.Config | fun():adopure.Config | nil
vim.g.adopure = vim.g.adopure

return config
