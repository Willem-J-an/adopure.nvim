# adopure.nvim

The plugin provides an opinionated workflow to interact with Azure DevOps Pull Requests.

## Installation

- Requires Neovim >= 0.10
- Installation using lazy:
``` lua
{
    "Willem-J-an/adopure.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim"
    },
    config = function()
        vim.g.adopure = {}
    end,
}
```
- Available on luarocks:
```
luarocks install adopure.nvim
```

For all available config options see:
:h adopure.config.meta

## Usage
```
:AdoPure    [ load ] [ context | threads ] [ opts ]
            [ open ] [ quickfix | thread_picker | new_thread | existing_thread ] [ opts ]
            [ submit ] [ comment | vote | thread_status ] [ opts ]
```

command | subcommand | description
--      | --                | --
load    | <i>               | Loads specified argument into state.
<i>     | context           | Load open pull requests; prompt user to pick one.
<i>     | threads           | Fetch comment threads from Azure DevOps.
open    | <i>               | Opens specified argument in the editor.
<i>     | quickfix          | Open comment threads in quickfix window.
<i>     | thread_picker     | Open a picker with all comment threads.
<i>     | new_thread        | Opens a window to write a comment on code selection.
<i>     | existing_thread   | Opens a window with an existing comment thread.
submit  | <i>               | Submits specified argument to Azure DevOps.
<i>     | comment           | Submit new comment or reply; must be in new_thread or existing_thread window.
<i>     | vote              | Submit a new vote on the pull request.
<i>     | thread_status     | Submit a thread_status change; must be in existing_thread window.

## Suggested keymaps
``` lua
local function set_keymap(keymap, command)
    vim.keymap.set({ "n", "v" }, keymap, function()
        vim.cmd(":" .. command)
    end, { desc = command })
end
set_keymap("<leader>alc", "AdoPure load context")
set_keymap("<leader>alt", "AdoPure load threads")
set_keymap("<leader>aoq", "AdoPure open quickfix")
set_keymap("<leader>aot", "AdoPure open thread_picker")
set_keymap("<leader>aon", "AdoPure open new_thread")
set_keymap("<leader>aoe", "AdoPure open existing_thread")
set_keymap("<leader>asc", "AdoPure submit comment")
set_keymap("<leader>asv", "AdoPure submit vote")
set_keymap("<leader>ast", "AdoPure submit thread_status")
```
