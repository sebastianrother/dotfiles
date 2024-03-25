return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("lualine").setup({
      options = {
        theme = "auto",
        section_separators = '',
        component_separators = ''
      },
      sections = {
        lualine_a = { "filename" },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = {},
        lualine_x = {},
        lualine_y = { 'filetype' },
        lualine_z = { 'location' }
      },
    })
  end,
}
