# adopure.nvim

The plugin provides an opinionated workflow to interact with Azure DevOps Pull Requests.

## Installation

- Requires Neovim >= 0.10
- Installation:
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

## Usage
```
:AdoPure    [ load ] [ context | threads ] [ opts ]
            [ open ] [ quickfix | thread_picker | new_thread | existing_thread ] [ opts ]
            [ submit ] [ comment | vote | thread_status ] [ opts ]
```

command | subcommand | description
-- | -- | --
load | " " | Loads specified argument into state.
" " | context | Load open pull requests; prompt user to pick one.
" " | threads | Fetch comment threads from Azure DevOps.
open | " " | Opens specified argument in the editor.
" " | quickfix | Open comment threads in quickfix window.
" " | thread_picker | Open a picker with all comment threads.
" " | new_thread | Opens a window to write a comment on code selection.
" " | existing_thread | Opens a window with an existing comment thread.
submit | " " | Submits specified argument to Azure DevOps.
" " | comment | Submit new comment or reply; must be in new_thread or existing_thread window.
" " | vote | Submit a new vote on the pull request.
" " | thread_status | Submit a thread_status change; must be in existing_thread window.
