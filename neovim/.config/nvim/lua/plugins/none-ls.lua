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
  end,
}
