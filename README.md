<div align="center">
  <img src="/logo.png" alt="Logo" title="Logo">
  <h1>popui.nvim</h1>
  <h6>NeoVim UI sweetness.</h6>
</div>

<br/>

## What's `popui` all about?
It's a tiny (currently 466 LoC) UI suite designed to make your NeoVim workflow faster. It currently consists of four components: 
- `ui-overrider`: alternative to NeoVim's default `vim.ui.select` menu
- `input-overrider`: alternative to NeoVim's default `vim.ui.input` prompt
- `diagnostics-navigator`: utility to quickly navigate and jump to LSP diagnostics issues in the current buffer
- `marks-manager`: utility to quickly navigate, jump to or remove (permanently!) uppercase marks  
<br/><br/>
<h3>See it in action below:</h3>
<br/>
<h4>Code action menu popup</h4>

![Snapshot #1](https://i.imgur.com/tjsUiTo.png)
<br/>
<h4>Variable renaming input popup</h4>

![Snapshot #2](https://i.imgur.com/d5COuVp.png)
<br />
<h4>Diagnostics navigator</h4>
(Displays all diagnostic messages for the current buffer. Press `Cr` to jump to the currently highlighted diagnostic coordinates.)

![Snapshot #3](https://i.imgur.com/ZHYi372.png)
<br />
<h4>Marks manager</h4>
(Displays all uppercase marks. Press `Cr` to navigate to a mark's position, press `x` or `d` to permanently delete a mark.)

![Snapshot #4](https://i.imgur.com/dsfOUn1.png)

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
vim.api.nvim_set_keymap("n", ",d", ':lua require"popui.diagnostics-navigator"()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ",m", ':lua require"popui.marks-manager"()<CR>', { noremap = true, silent = true })
```

## Customize border style
```viml
" Available styles: "sharp" | "rounded" | "double"
let g:popui_border_style = "double"
```

## Dependencies
* No dependencies baby!
