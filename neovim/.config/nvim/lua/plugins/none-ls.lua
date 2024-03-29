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
      formatting.black.with({
        only_local = "venv/bin",
      }),
      diagnostics.mypy.with({
        only_local = "venv/bin",
      }),
      diagnostics.ansiblelint,
      formatting.stylua,
      require("none-ls.formatting.rustfmt"),
    }

    -- Format on save.
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Formatting-on-save#code
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
    local on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end
    end

    null_ls.setup({
      on_attach = on_attach,
      sources = sources,
    })
  end,
}
