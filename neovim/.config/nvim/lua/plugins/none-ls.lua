return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim",
    "nvimtools/none-ls-extras.nvim",
  },
  config = function()
    local null_ls = require("null-ls")

    local diagnostics = null_ls.builtins.diagnostics
    local formatting = null_ls.builtins.formatting
    local sources = {
      -- https://stackoverflow.com/questions/78108133/issue-with-none-ls-configuration-error-with-eslint-d
      require("none-ls.code_actions.eslint").with({
        only_local = "node_modules/.bin",
      }),
      require("none-ls.diagnostics.eslint").with({
        only_local = "node_modules/.bin",
      }),
      formatting.prettier.with({
        prefer_local = "node_modules/.bin",
        extra_filetypes = { "astro", "typescriptreact" },
      }),
      diagnostics.ansiblelint,
      formatting.stylua,
      require("none-ls.formatting.rustfmt"),
    }

    null_ls.setup({
      sources = sources,
    })


    vim.keymap.set('n', '<leader>?', function()
      -- If we find a floating window, close it.
      local found_float = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative ~= '' then
          vim.api.nvim_win_close(win, true)
          found_float = true
        end
      end

      if found_float then
        return
      end

      vim.diagnostic.open_float(nil, { focus = false, scope = 'cursor' })
    end, { desc = 'Toggle Diagnostics' })
  end,
}
