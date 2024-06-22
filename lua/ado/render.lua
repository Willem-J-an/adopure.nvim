local M = {}
local buffer_counter = 0

local namespace = vim.api.nvim_create_namespace("adopure-render")

local function rightsize_window()
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
---@param bufname string
---@return number bufnr
local function open_new_split(bufname)
    vim.cmd("below new " .. bufname)
    vim.api.nvim_buf_set_option(0, 'buftype', 'nofile')
    buffer_counter = buffer_counter + 1
    vim.cmd(":setlocal wrap")

    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        buffer = 0,
        callback = function()
            rightsize_window()
        end,
    })

    return vim.api.nvim_get_current_buf()
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

---@param new_bufname string
---@return number bufnr
local function convert_ado_window(new_bufname)
    local bufnr = vim.api.nvim_get_current_buf()
    for _, extmark in pairs(vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})) do
        local extmark_id = extmark[1]
        vim.api.nvim_buf_del_extmark(bufnr, namespace, extmark_id)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, {})

    vim.api.nvim_buf_set_name(0, new_bufname)
    return bufnr
end

---@param new_bufname string
---@return number bufnr
local function new_or_convert_window(new_bufname)
    if vim.api.nvim_buf_get_name(0):find("%[adopure %- new %-") then
        return convert_ado_window(new_bufname)
    end
    return open_new_split(new_bufname)
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
---@param pull_request_thread Thread
---@return number, number: bufnr, mark_id
function M.render_reply_thread(pull_request_thread)
    local bufnr = new_or_convert_window("[adopure - thread - " .. pull_request_thread.id .. "]")
    local lines = {
        { { "Comment thread: ", "@text.strong" }, { tostring(pull_request_thread.id), "@text.reference" } },
        {
            { "Status: ", "@text.strong" },
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
    rightsize_window()
    return bufnr, mark_id
end

---Render new pull request thread
---@param selection string[]
---@return number, number: bufnr, mark_id
function M.render_new_thread(selection)
    local bufnr = open_new_split("[adopure - new - " .. buffer_counter .. "]")
    local lines = {
        { { "Comment thread: ", "@text.strong" }, { "<new>", "@text.reference" } },
        { { "Status: ", "@text.strong" }, { "<new>", "@text.reference" } },
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
    rightsize_window()
    vim.cmd(":startinsert")
    return bufnr, mark_id
end

return M
