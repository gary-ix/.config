

-- Load Vim-Plug and plugins
vim.cmd([[
  call plug#begin('~/.local/share/nvim/plugged')

  " Add your plugins here
  Plug 'ThePrimeagen/vim-be-good'

  call plug#end()
]])

-- Remap navigation keys from hjkl to jkl;
-- local opts = { noremap = true, silent = true }

-- Normal mode mappings
-- vim.keymap.set('n', 'j', 'h', opts)
-- vim.keymap.set('n', 'k', 'j', opts)
-- vim.keymap.set('n', 'l', 'k', opts)
-- vim.keymap.set('n', ';', 'l', opts)

-- Visual mode mappings
-- vim.keymap.set('v', 'j', 'h', opts)
-- vim.keymap.set('v', 'k', 'j', opts)
-- vim.keymap.set('v', 'l', 'k', opts)
-- vim.keymap.set('v', ';', 'l', opts)

vim.opt.relativenumber = true