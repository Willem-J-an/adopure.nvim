vim.api.nvim_create_user_command("AdoPure", function(opts)
    require("ado").ado_pure(opts)
end, {
    nargs = "*",
    range = true,
    desc = "Azure DevOps Pull Request command.",
    complete = function(arg_lead, cmdline, _)
        return require("ado").auto_completer(arg_lead, cmdline, _)
    end,
})
