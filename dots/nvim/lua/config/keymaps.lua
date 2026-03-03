-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Keep cursor centered while navigating
map("n", "j", "jzz", { noremap = true })
map("n", "k", "kzz", { noremap = true })
map("n", "G", "Gzz", { noremap = true })
map("n", "gg", "ggzz", { noremap = true })
map("n", "<C-d>", "<C-d>zz", { noremap = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true })
map("n", "n", "nzz", { noremap = true })
map("n", "N", "Nzz", { noremap = true })
