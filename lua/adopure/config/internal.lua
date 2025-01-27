---@class adopure.InternalHighlights
---@field active string
---@field active_sign string
---@field inactive string
---@field inactive_sign string

---@class adopure.InternalConfig
---@field pat_token string|nil
---@field hl_groups adopure.InternalHighlights
---@field preferred_remotes string[]
---@field filter_my_pull_requests boolean

local InternalConfig = {}
function InternalConfig:new()
    local default_config = {
        pat_token = os.getenv("AZURE_DEVOPS_EXT_PAT"),
        hl_groups = {
            active = "DiagnosticUnderlineWarn",
            active_sign = "@comment.todo",
            inactive = "DiagnosticUnderlineOk",
            inactive_sign = "@comment.note",
        },
        preferred_remotes = {},
        filter_my_pull_requests = false,
    }
    local user_config = type(vim.g.adopure) == "function" and vim.g.adopure() or vim.g.adopure or {}
    local config = vim.tbl_deep_extend("force", default_config, user_config or {})
    self.__index = self
    self = setmetatable(config, self)
    return self
end

function InternalConfig:access_token()
    local message = table.concat({
        "No pat_token found in config.",
        "Set AZURE_DEVOPS_EXT_PAT environment variable,",
        "or check the docs to find other ways of configuring it.",
    }, " ")
    assert(self.pat_token, message)
    return vim.base64.encode(":" .. self.pat_token)
end

---@param status string
---@return string
---@return string
function InternalConfig:hl_details(status)
    if status == "active" or status == "pending" then
        return self.hl_groups.active, self.hl_groups.active_sign
    end
    return self.hl_groups.inactive, self.hl_groups.inactive_sign
end

local config = InternalConfig:new()
return config
