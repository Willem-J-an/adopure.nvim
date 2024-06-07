local M = {}

---@enum PullRequestVote
M.pull_request_vote = {
    rejected = -10,
    ["waiting for author"] = -5,
    ["no vote"] = 0,
    ["approved with suggestions"] = 5,
    approved = 10,
}
M.vote_icons = {
    rejected = " ",
    ["waiting for author"] = "󱫞 ",
    ["no vote"] = "󰄯 ",
    ["approved with suggestions"] = "󱤧 ",
    approved = "󰄴 ",
}
---Return pull request vote from vote value
---@param vote_value PullRequestVote
---@return string|nil vote, string|nil err
function M.get_vote_from_value(vote_value)
    for vote, value in pairs(M.pull_request_vote) do
        if value == vote_value then
            return vote, nil
        end
    end
    return nil, "No vote found for this value;"
end

local function vote_options()
    local result = {}
    for key, value in pairs(M.pull_request_vote) do
        table.insert(result, key)
    end
    return result
end
---Submit vote of choice on pull request
---@param state AdoState
function M.submit_vote(state)
    vim.ui.select((vote_options()), { prompt = "Select vote;" }, function(vote)
        if not vote then
            vim.notify("No vote chosen;", 2)
            return
        end
        local reviewer, err = require("ado.api").submit_vote(state.active_pull_request, M.pull_request_vote[vote])

        if err or not reviewer then
            error(err or "Expected Reviewer but not nil;")
        end
        -- TODO: Render vote somewhere?
    end)
end

return M
