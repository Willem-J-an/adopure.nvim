local M = {}

---@param bufnr number
---@param thread adopure.Thread
function M.thread_preview(bufnr, thread)
    local pull_request = require("adopure.previews.pull_request")
    local preview_content = {
        "Comment thread: " .. tostring(thread.id),
        "Created: " .. pull_request.readable_timestamp(thread.publishedDate),
        "Last updated: " .. pull_request.readable_timestamp(thread.lastUpdatedDate),
        "Status: " .. (thread.status or ""),
        "",
        "Comments:",
    }
    for _, comment in ipairs(thread.comments) do
        if not comment.isDeleted and comment.content then
            local title = table.concat(
                { comment.author.displayName, pull_request.readable_timestamp(comment.lastUpdatedDate) },
                " - "
            )
            table.insert(preview_content, title .. ":")
            for _, line in pairs(vim.split(comment.content, "\n")) do
                table.insert(preview_content, '>' .. line)
            end
            table.insert(preview_content, "")
        end
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, preview_content)
    vim.cmd(":setlocal wrap")
    vim.wo.wrap = true
    vim.treesitter.start(bufnr, "markdown")
end

return M
