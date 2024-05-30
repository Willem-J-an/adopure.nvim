local M = {}

local namespace = vim.api.nvim_create_namespace("ado")

function M.readable_timestamp(iso_str)
    local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"
    local year, month, day, hour, minute, seconds = iso_str:match(pattern)
    local timestamp = os.time({ year = year, month = month, day = day, hour = hour, min = minute, sec = seconds })
    return os.date("%c", timestamp)
end

local function get_subtitle_table(pull_request)
    return {
        pull_request.createdBy.displayName,
        " request !",
        pull_request.pullRequestId,
        " into ",
        vim.split(pull_request.targetRefName, "refs/heads/")[2],
    }
end
local function get_info_table(pull_request)
    return {
        "Created: ",
        M.readable_timestamp(pull_request.creationDate),
        string.rep(" ", 5) .. "|" .. string.rep(" ", 5),
        "Status: ",
        pull_request.status,
    }
end

---@param info_line string
---@param pull_request PullRequest
---@param subtitle string
---@return string[]
local function get_preview_content(info_line, pull_request, subtitle)
    local preview_content = {
        pull_request.title,
        subtitle,
        info_line,
        "",
        "Description:"
    }
    for _, line in pairs(vim.split(pull_request.description or "", "\n") or {}) do
        table.insert(preview_content, line)
    end
    return preview_content
end

local function line_highlights(bufnr)
    for _, highlight in ipairs({ { 0, "@markup.heading" }, {4, "@markup.heading"} }) do
        vim.api.nvim_buf_set_extmark(bufnr, namespace, highlight[1], 0, { line_hl_group = highlight[2] })
    end
end

---comment
---@param bufnr number
---@param line_number number
---@param line string
---@param line_components string[]
---@param highlight_segments table<number, string>
local function line_segment_highlights(bufnr, line_number, line, line_components, highlight_segments)
    for component_number, hl_group in pairs(highlight_segments) do
        local start, finish =
            string.find(line, tostring(line_components[component_number]):gsub("([-()%.+*?[^$%%])", "%%%1"))
        vim.api.nvim_buf_set_extmark(bufnr, namespace, line_number, start - 1, {
            end_col = finish,
            hl_group = hl_group,
        })
    end
end

local function segment_highlights(bufnr, subtitle, subtitle_table, info_line, info_table)
    local subtitle_segments = { [1] = "@keyword", [3] = "@keyword", [5] = "@keyword" }
    line_segment_highlights(bufnr, 1, subtitle, subtitle_table, subtitle_segments)
    line_segment_highlights(bufnr, 2, info_line, info_table, { [1] = "@markup.heading", [4] = "@markup.heading" })
end

function M.pull_request_preview(bufnr, pull_request)
    local subtitle_table = get_subtitle_table(pull_request)
    local subtitle = table.concat(subtitle_table)

    local info_table = get_info_table(pull_request)
    local info_line = table.concat(info_table)
    local preview_content = get_preview_content(info_line, pull_request, subtitle)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, preview_content)
    line_highlights(bufnr)
    segment_highlights(bufnr, subtitle, subtitle_table, info_line, info_table)

    vim.treesitter.start(bufnr, "markdown")
end

return M
