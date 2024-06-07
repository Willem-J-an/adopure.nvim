---@class adopure.InternalConfig
---@field pat_token string|nil
local InternalConfig = {}
function InternalConfig:new()
    local default_config = {
        pat_token = os.getenv("AZURE_DEVOPS_EXT_PAT"),
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
    return require("b64").enc(":" .. self.pat_token)
end

local config = InternalConfig:new()
return config
