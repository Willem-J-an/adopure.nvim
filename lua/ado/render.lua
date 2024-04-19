local M = {}
BUFFER_NAME = "ado.nvim]"

function M.rightsize_window(namespace)
    local extmarks = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, { details = true })
    local line_count = 0
    for _, extmark in pairs(extmarks) do
        local details = extmark[4]
        if details["virt_lines"] then
            line_count = line_count + #details["virt_lines"]
        end
    end

    if vim.api.nvim_win_get_height(0) < line_count + 2 then
        vim.cmd("horizontal resize " .. line_count + 2)
    end
    vim.fn.winrestview({ topfill = line_count })
end

---Open split window
function M.open_split(namespace)
    local split = require("nui.split")({
        relative = "win",
        position = "bottom",
        size = "25%",
    })
    split:mount()
    vim.cmd(":setlocal wrap")

    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        buffer = 0,
        callback = function()
            M.rightsize_window(namespace)
        end,
    })
end

local function split_long_lines(line)
    local t = {}
    local width = vim.fn.winwidth(0) * 0.9
    for i = 1, #line, width do
        table.insert(t, string.sub(line, i, i + width - 1))
    end
    return t
end

---@param lines table<string, string>[][]
---@param prompt_type string
local function add_prompt_lines(lines, prompt_type)
    for _, prompt in pairs({

        { { "", "@text.literal" } },
        { { "________________", "@text.literal" } },
        { { "Write a " .. prompt_type .. ":", "@text.emphasis" } },
        { { "----------------", "@text.literal" } },
    }) do
        table.insert(lines, prompt)
    end
    return lines
end

local function new_or_clear_ado_window(namespace)
    local bufnr = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_get_name(0):match(BUFFER_NAME .. "$") then
        M.open_split(namespace)
        bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_name(0, "[" .. bufnr .. "-" .. BUFFER_NAME)
    end
    for _, extmark in pairs(vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})) do
        local extmark_id = extmark[1]
        vim.api.nvim_buf_del_extmark(bufnr, namespace, extmark_id)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, {})
    vim.cmd(":startinsert")
    return bufnr
end

local icons = {
    active = " ",
    byDesign = " ",
    closed = " ",
    fixed = " ",
    pending = " ",
    unknown = " ",
    wontFix = "󰅜 ",
}
---Render pull request thread
---@param namespace number
---@param pull_request_thread Thread
---@return number, number: bufnr, mark_id
function M.render_reply_thread(namespace, pull_request_thread)
    local bufnr = new_or_clear_ado_window(namespace)
    local lines = {
        { { "Comment thread: ", "@text.strong" }, { tostring(pull_request_thread.id), "@text.reference" } },
        {
            { "Status: ",                                                                       "@text.strong" },
            { icons[pull_request_thread.status] .. " - [" .. pull_request_thread.status .. "]", "@text.reference" },
        },
        { { "", "@text.literal" } },
        { { "Comments: ", "@text.strong" } },
    }

    for _, comment in ipairs(pull_request_thread.comments) do
        if not comment.isDeleted then
            table.insert(lines, { { comment.author.displayName, "@text.reference" } })
            for _, line_part in pairs(split_long_lines(comment.content)) do
                table.insert(lines, { { line_part, "@text.literal" } })
            end
        end
    end
    lines = add_prompt_lines(lines, "reply")

    local mark_id = vim.api.nvim_buf_set_extmark(0, namespace, 0, 0, {
        id = pull_request_thread.id,
        virt_lines = lines,
        virt_lines_above = true,
    })
    M.rightsize_window(namespace)
    return bufnr, mark_id
end

---Render new pull request thread
---@param namespace number
---@param selection string[]
---@return number, number: bufnr, mark_id
function M.render_new_thread(namespace, selection)
    local bufnr = new_or_clear_ado_window(namespace)
    local lines = {
        { { "Comment thread: ", "@text.strong" }, { "<new>", "@text.reference" } },
        { { "Status: ", "@text.strong" },         { "<new>", "@text.reference" } },
        { { "Selection:", "@text.strong" } },
    }
    for _, selection_line in pairs(selection) do
        table.insert(lines, { { selection_line, "@text.literal" } })
    end
    lines = add_prompt_lines(lines, "comment")

    local mark_id = vim.api.nvim_buf_set_extmark(0, namespace, 0, 0, {
        virt_lines = lines,
        virt_lines_above = true,
    })
    M.rightsize_window(namespace)
    return bufnr, mark_id
end

return M
