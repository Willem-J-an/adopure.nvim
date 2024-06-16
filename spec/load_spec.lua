describe("Load command", function()
    ---@type StateManager|nil
    local state_manager
    local function get_secret_value()
        local secret = os.getenv("AZURE_DEVOPS_EXT_PAT")
        if secret then
            return secret
        end
        local handle = io.popen("pass show AZURE_DEVOPS_EXT_PAT_ADOPURE")
        assert(handle, "Handle not nil;")
        return handle:read()
    end

    setup(function() ---@diagnostic disable-line: undefined-global
        local secret = get_secret_value()
        vim.g.adopure = { pat_token = secret }
    end)

    it("can retrieve PRs", function()
        require("plenary.path")
        state_manager = require("ado").load_state_manager()
        assert.are.same(#state_manager.pull_requests, 1)
    end)

    it("can activate a PR", function()
        state_manager = require("ado").load_state_manager()
        state_manager:set_state_by_choice(state_manager.pull_requests[1])

        assert.are.same(state_manager.state.active_pull_request.title, "Updated pr-test-file.md PR title")
    end)
end)

