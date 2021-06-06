# Telescope Zoxide

An extension for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) that allows you operate [zoxide](https://github.com/ajeetdsouza/zoxide) within Neovim.

## Requirements
[zoxide](https://github.com/ajeetdsouza/zoxide) is required to use this plugin.

## Installation

```vim
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'jvgrootveld/telescope-zoxide'
```

## Setup

You can setup the extension by adding the following to your config:

```lua
require'telescope'.load_extension('zoxide')
```

## Available functions:

### List

With Telescope command

```vim
:Telescope zoxide list
```

In Lua

```lua
require'telescope'.extensions.zoxide.list{}
```

## Example config: 

```lua
vim.api.nvim_set_keymap(
	"n",
	"<leader>cd",
	":lua require'telescope'.extensions.zoxide.list{}<CR>",
	{noremap = true, silent = true}
)
```

## Default mappings:
| Action       | Description                           | Command executed |
|--------------|---------------------------------------|------------------|
| `<CR>`       | Change current directory to selection | `cd <path>`      |
| `<C-s>`      | Open selection in a split             | `split <path>`   |
| `<C-v>`      | Open selection in a vertical split    | `vsplit <path>`  |
| `<C-e>`      | Open selection in current window      | `edit <path>`    |

