<div align="center">
  <img src="/logo.png" alt="Logo" title="Logo">
  <h1>popui.nvim</h1>
  <h6>NeoVim UI sweetness.</h6>
</div>

<br/>

## What's `popui` all about?
It's collection of custom UI utilities to make your NeoVim workflow faster. It consists of two (`ui-overrider`, `input-overrider`) utilities which override neovim's default `vim.ui.select` menu and `vim.ui.input` prompt, spawning a floating menu right where your cursor resides, and a `diagnostics-navigator` utility to quickly navigate (and jump to) LSP diagnostics issues in the current buffer.
<br/><br/>
<h3>See it in action below:</h3>
<br/>
<h4>Code action menu popup</h4>

![Snapshot #1](https://i.imgur.com/ZKRBssU.png)
<br/>
<h4>Variable renaming input popup</h4>

![Snapshot #2](https://i.imgur.com/G4tkHhK.png)
<br />
<h4>Diagnostics navigator</h4>

![Snapshot #3](https://i.imgur.com/Ny0TfXz.png)

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
```
```vim
nnoremap ,d :lua require'popui.diagnostics-navigator'()<CR>
```

## Customize border style
```vim
" Available styles: "sharp" | "rounded" | "double"
let g:popui_border_style = "double"
```

## Dependencies
* No dependencies baby!
