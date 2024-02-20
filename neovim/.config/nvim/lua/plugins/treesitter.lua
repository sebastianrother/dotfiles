return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "markdown", "markdown_inline", "jsonc" }, -- Allows for obsidian highlighting
      sync_install = false,
      auto_install = true,
      highlight = { enable = true },
    })
  end,
}
