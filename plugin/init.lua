vim.api.nvim_create_user_command("AdoPure", function(opts)
    require("adopure").ado_pure(opts)
end, {
    nargs = "*",
    range = true,
    desc = "Azure DevOps Pull Request command.",
    complete = function(arg_lead, cmdline, _)
        return require("adopure").auto_completer(arg_lead, cmdline, _)
    end,
})
