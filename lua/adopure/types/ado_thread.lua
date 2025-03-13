local Path = require("plenary.path")

local M = {}

---@private
---@class adopure.AdoThread : adopure.Thread
local AdoThread = {}
M.AdoThread = AdoThread

---@param pull_request_thread adopure.Thread
---@return adopure.AdoThread
function AdoThread:new(pull_request_thread)
    local o = pull_request_thread
    self.__index = self
    ---@type adopure.AdoThread
    self = setmetatable(o, self) ---@diagnostic disable-line assign-type-mismatch
    self.is_changed = false
    return self
end

---@param extmark vim.api.keyset.get_extmark_item
---@return boolean
function AdoThread:match_mark(extmark)
    return extmark[1] == self.id
end

---@return number bufnr, number extmark_id
function AdoThread:render_reply_thread()
    return require("adopure.render").render_reply_thread(self)
end

---@return string
function AdoThread:format_item()
    return table.concat({
        "[",
        self.id,
        " - ",
        self.status,
        "] ",
        self.comments[1].content,
    })
end

---@return string[]
function AdoThread:preview()
    local pull_request = require("adopure.previews.pull_request")
    local preview_content = {
        "Comment thread: " .. tostring(self.id),
        "Created: " .. pull_request.readable_timestamp(self.publishedDate),
        "Last updated: " .. pull_request.readable_timestamp(self.lastUpdatedDate),
        "Status: " .. (self.status or ""),
        "",
        "Comments:",
    }
    vim.iter(self.comments)
        :filter(function(comment) ---@param comment adopure.Comment
            return not not (comment.content and not comment.isDeleted)
        end)
        :each(function(comment) ---@param comment adopure.Comment
            local title = table.concat(
                { comment.author.displayName, pull_request.readable_timestamp(comment.lastUpdatedDate) },
                " - "
            )
            table.insert(preview_content, title .. ":")
            vim.iter(vim.split(comment.content, "\n")):each(function(line) ---@param line string
                table.insert(preview_content, ">" .. line)
            end)
            table.insert(preview_content, "")
        end)
    return preview_content
end

---@param existing_extmarks vim.api.keyset.get_extmark_item[]
---@param focused_file_path string
---@return boolean
function AdoThread:should_render_extmark(existing_extmarks, focused_file_path)
    if
        focused_file_path == tostring(self:targeted_file_path())
        and self:is_active_thread()
        and (
            not self:is_marked(existing_extmarks)
            or self.is_changed
        )
    then
        return true
    end
    return false
end

---@return Path|nil
function AdoThread:targeted_file_path()
    local context = self:thread_context()
    if not context then
        return nil
    end
    return Path:new(string.sub(context.filePath, 2))
end

---@return adopure.ThreadContext|nil
function AdoThread:thread_context()
    local context = self.threadContext
    if not context or context == vim.NIL then
        return nil
    end
    return context
end

---@return boolean
function AdoThread:is_active_thread()
    if
        not self.isDeleted
        and self:thread_context()
        and self:thread_context().rightFileStart
        and self:has_active_comments()
    then
        return true
    end
    return false
end

---@private
---@param existing_extmarks vim.api.keyset.get_extmark_item[]
function AdoThread:is_marked(existing_extmarks)
    return vim.iter(existing_extmarks):any(function(extmark) ---@param extmark vim.api.keyset.get_extmark_item
        return self:match_mark(extmark)
    end)
end

---@return boolean
function AdoThread:has_active_comments()
    return vim.iter(self.comments):any(function(comment) ---@param comment adopure.Comment
        return not comment.isDeleted
    end)
end

return M
