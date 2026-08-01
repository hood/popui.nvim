<div align="center">
  <img src="/logo.png" alt="Logo" title="Logo">
  <h1>popui.nvim</h1>
  <h6>NeoVim UI sweetness.</h6>
</div>

<br/>

## What's `popui` all about?
It's a tiny (currently 910 LoC) UI suite designed to make your NeoVim workflow faster. It currently consists of six components: 
- `ui-overrider`: alternative to NeoVim's default `vim.ui.select` menu
- `input-overrider`: alternative to NeoVim's default `vim.ui.input` prompt
- `buffers-manager`: utility to quickly switch to, split-open or close open buffers
- `diagnostics-navigator`: utility to quickly navigate and jump to LSP diagnostics issues in the current buffer
- `marks-manager`: utility to quickly navigate, jump to or remove (permanently!) uppercase marks  
- `references-navigator`: utility to quickly navigate and jump to project-wide references to the symbol under the cursor
<br/><br/>
<h3>See it in action below:</h3>
<br/>
<h4>Code action menu popup</h4>

![Snapshot #1](https://i.imgur.com/tjsUiTo.png)
<br/>
<h4>Variable renaming input popup</h4>

![Snapshot #2](https://i.imgur.com/d5COuVp.png)
<br />
<h4>Buffers manager</h4>
(Displays all open buffers. The first nine are bound to a number, shown on the left of their name.)

| Key | Action |
| --- | --- |
| `Cr` | open the highlighted buffer |
| `C-v` | open the highlighted buffer in a split to the right |
| `C-s` (or `C-x`) | open the highlighted buffer in a split below |
| `x` or `d` | close the highlighted buffer (refused if it has unsaved changes) |
| `<number>` | open that buffer straight away, without navigating the list |
| `v<number>` | open that buffer in a split to the right |
| `s<number>` | open that buffer in a split below |

```
┌───────────────────────────────┐
│1  lua/popui/core.lua          │
│2  lua/popui/marks-manager.lua │
│3  README.md                   │
│4  [No Name]                   │
└───────────────────────────────┘
```

Buffers with unsaved changes are marked with `[+]`.
<br />
<h4>Diagnostics navigator</h4>
(Displays all diagnostic messages for the current buffer. Press `Cr` to jump to the currently highlighted diagnostic coordinates.)

![Snapshot #3](https://i.imgur.com/ZHYi372.png)
<br />
<h4>Marks manager</h4>
(Displays all uppercase marks. Press `Cr` to navigate to a mark's position, press `x` or `d` to permanently delete a mark.)

![Snapshot #4](https://i.imgur.com/dsfOUn1.png)
<br />
<h4>References navigator</h4>
(Displays all found references, Press `Cr` to navigate to the reference's position)

![Snapshot #5](https://i.imgur.com/QHryA6w.jpg)

## Installation
```viml
" Using vim-plug
Plug 'hood/popui.nvim'

" Using Vundle
Plugin 'hood/popui.nvim'
```

## Setup
```lua
vim.ui.select = require"popui.ui-overrider"
vim.ui.input = require"popui.input-overrider"
vim.api.nvim_set_keymap("n", ",b", ':lua require"popui.buffers-manager"()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ",d", ':lua require"popui.diagnostics-navigator"()<CR>', { noremap = true, silent = true }) 
vim.api.nvim_set_keymap("n", ",m", ':lua require"popui.marks-manager"()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ",r", ':lua require"popui.references-navigator"()<CR>', { noremap = true, silent = true })
```

## Customize border style
```viml
" Available styles: "sharp" | "rounded" | "double"
let g:popui_border_style = "double"
```

## Customize highlight groups
```vim
hi PopuiCoordinates guifg=#6A1010 ctermfg=Red
hi PopuiDiagnosticsCodes guifg=#777777 ctermfg=Gray
```

## Dependencies
* No dependencies baby!
