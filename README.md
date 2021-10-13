<div align="center">
  <h1>popui.nvim</h1>
  <h6>NeoVim UI sweetness powered by popfix.</h6>
</div>

<br/>

## What's `popui` all about?
It's a custom UI which overrides neovim's default `vim.ui.select` menu, spawning a floating menu right where your cursor resides.
<br/><br/>
<b>See it in action below:</b>
![Snapshot #1](https://i.imgur.com/XLYgxeo.png)

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
```

## Customize border style
```vim
" Available styles: "sharp" | "rounded" | "double"
let g:popui_border_style = "double"
```

## Dependencies
* [RishabhRD/popfix](https://github.com/RishabhRD/popfix)
