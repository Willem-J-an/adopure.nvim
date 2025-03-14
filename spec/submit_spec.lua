local assert = require("luassert.assert")

describe("submit command", function()
    local function get_secret_value()
        local secret = os.getenv("AZURE_DEVOPS_EXT_PAT")
        if secret then
            return secret
        end
        local handle = io.popen("pass show AZURE_DEVOPS_EXT_PAT_ADOPURE")
        if not handle then
            error("Handle not nil;")
        end
        return handle:read()
    end

    setup(function()
        local secret = get_secret_value()
        vim.g.adopure = { pat_token = secret } ---@diagnostic disable-line: inject-field
    end)

    local expect_message = "This will be the written comment in the PR!"
    local real_nvim_get_current_buf = vim.api.nvim_get_current_buf
    local real_nvim_buf_get_lines = vim.api.nvim_buf_get_lines
    local real_vim_ui_select = vim.ui.select

    local function mock_functions()
        vim.api.nvim_get_current_buf = function() ---@diagnostic disable-line: duplicate-set-field
            return 1
        end
        vim.api.nvim_buf_get_lines = function() ---@diagnostic disable-line: duplicate-set-field
            return { expect_message }
        end
        ---@param _1 string[]
        ---@param _2 table
        ---@param cb fun(choice: string):nil
        ---@diagnostic disable-next-line: unused-local
        vim.ui.select = function(_1, _2, cb) ---@diagnostic disable-line: duplicate-set-field
            local _, _ = _1, _2
            cb("closed")
        end
    end

    before_each(function()
        local state_manager = require("adopure").load_state_manager()
        state_manager:set_state_by_choice(state_manager.pull_requests[1])
        mock_functions()
    end)

    local function create_comment()
        local thread_context = {
            filePath = "/tests/pr-test-file.md",
            leftFileStart = nil,
            leftFileEnd = nil,
            rightFileStart = { line = 3, offset = 2 },
            rightFileEnd = { line = 3, offset = 9 },
        }
        local comment_creation = require("adopure.types.comment_create").CommentCreation:new(1, 10000, thread_context)
        local state = require("adopure").get_loaded_state()
        table.insert(state.comment_creations, comment_creation)
        state:submit_comment({})
    end

    it("can submit a comment", function()
        create_comment()
        local state = require("adopure").get_loaded_state()
        ---@type adopure.Thread
        local thread = vim.iter(state.pull_request_threads):find(function(thread) ---@param thread adopure.AdoThread
            return thread.comments[1].commentType == "text"
        end)
        assert.are.same(expect_message, thread.comments[1].content)
    end)

    it("can submit a reply", function()
        create_comment()
        local state = require("adopure").get_loaded_state()
        state:submit_comment({})
        assert.are.same(2, #state.pull_request_threads[1].comments)
    end)

    it("can submit a thread status change", function()
        create_comment()
        local state = require("adopure").get_loaded_state()
        state:update_thread({ target = "update_status" })
        assert.are.same("closed", state.pull_request_threads[1].status)
    end)

    it("can submit a pull request vote", function()
        local state = require("adopure").get_loaded_state()
        ---@diagnostic disable-next-line: unused-local
        vim.ui.select = function(_1, _2, cb) ---@diagnostic disable-line: duplicate-set-field
            local _, _ = _1, _2
            cb("approved")
        end
        require("adopure.review").submit_vote(state, {})
        assert.are.same(10, state.active_pull_request.reviewers[1].vote)
        vim.ui.select = function(_1, _2, cb) ---@diagnostic disable-line: duplicate-set-field
            local _, _ = _1, _2
            cb("no vote")
        end
        require("adopure.review").submit_vote(state, {})
    end)

    local function unmock_functions()
        vim.api.nvim_get_current_buf = real_nvim_get_current_buf
        vim.api.nvim_buf_get_lines = real_nvim_buf_get_lines
        vim.ui.select = real_vim_ui_select
    end

    after_each(function()
        local state = require("adopure").get_loaded_state()
        for _, thread in pairs(state.pull_request_threads) do
            for _, comment in pairs(thread.comments) do
                local _, err =
                    require("adopure.api").delete_pull_request_comment(state.active_pull_request, thread, comment.id)
                if err then
                    error(err)
                end
            end
        end
        unmock_functions()
    end)
end)
