return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").setup({
      defaults = {
        sorting_strategy = "descending",
        layout_config = {
          prompt_position = "bottom",
        },
      },
      pickers = {
        git_files = {
          show_untracked = true,
          disable_devicons = true,
        },
        find_files = {
          hidden = true,
          disable_devicons = true,
        },
      },
    })

    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>.", builtin.resume, {})
    vim.keymap.set("n", "<leader><Space>", builtin.buffers, {})
    vim.keymap.set("n", "<leader>?", function() builtin.diagnostics({ bufnr = 0 }) end, {})

    -- Search.
    vim.keymap.set("n", "<C-p>", builtin.git_files, {})       -- Only Git files
    vim.keymap.set("n", "<leader>fs", builtin.live_grep, {})
    vim.keymap.set("n", "<leader>ff", builtin.find_files, {}) -- All files

    vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    vim.keymap.set("n", "<leader>fk", builtin.keymaps, {})
    vim.keymap.set("n", "<leader>fM", builtin.man_pages, {})
    vim.keymap.set("n", "<leader>fvo", builtin.vim_options, {})
  end,
}
