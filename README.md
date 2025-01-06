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

```bash
luarocks install adopure.nvim
```

For all available config options see:
:h adopure.config.meta

## Usage

```vimL
:AdoPure    [ load ] [ context | threads ] [ opts ]
            [ open ] [ quickfix | thread_picker | new_thread | existing_thread ] [ opts ]
            [ submit ] [ comment | vote | thread_status | delete_comment | edit_comment ] [ opts ]
```

command | subcommand      | description
--------|-----------------|------------------------------------------------------------------------------
load    | <i>             | Loads specified argument into state.
<i>     | context         | Load open pull requests; prompt user to pick one.
<i>     | threads         | Fetch comment threads from Azure DevOps.
open    | <i>             | Opens specified argument in the editor.
<i>     | quickfix        | Open comment threads in quickfix window.
<i>     | thread_picker   | Open a picker with all comment threads.
<i>     | new_thread      | Opens a window to write a comment on code selection.
<i>     | existing_thread | Opens a window with an existing comment thread.
submit  | <i>             | Submits specified argument to Azure DevOps.
<i>     | comment         | Submit new comment or reply; must be in new_thread or existing_thread window.
<i>     | vote            | Submit a new vote on the pull request.
<i>     | thread_status   | Submit a thread_status change; must be in existing_thread window.
<i>     | delete_comment  | Delete one of your own comments; must be in existing_thread window.
<i>     | edit_comment    | Edit one of your own comments; must be in existing_thread window.

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
set_keymap("<leader>asd", "AdoPure submit delete_comment")
set_keymap("<leader>ase", "AdoPure submit edit_comment")
```

## Showcase

### Load open pull requests

![image](https://github.com/Willem-J-an/adopure.nvim/assets/51120533/b48ef520-66a3-4c80-b17c-86f79f92348c)

### Create comments

![image](https://github.com/Willem-J-an/adopure.nvim/assets/51120533/ee8e4b07-72a6-4e84-b976-30343f0f3d7c)

### Reply, render, vote on comment threads

![image](https://github.com/Willem-J-an/adopure.nvim/assets/51120533/af7e636a-99b3-4a64-80cb-5b4d10ce5d10)

### Load comments into quickfix, render comments in a picker with preview

![image](https://github.com/Willem-J-an/adopure.nvim/assets/51120533/f75cb401-fbfc-446f-8d24-aa33bf67555a)
