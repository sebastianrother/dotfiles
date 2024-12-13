return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  day_brightness = 0.3,
  config = function()
    vim.cmd.colorscheme("tokyonight-night")
  end,
}
