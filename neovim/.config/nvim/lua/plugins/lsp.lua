return {
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    lazy = true,
    config = false,
    init = function()
      -- Disable automatic setup.
      vim.g.lsp_zero_extend_cmp = 0
      vim.g.lsp_zero_extend_lspconfig = 0
    end,
  },
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = true,
  },

  -- Autocompletion.
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      { "L3MON4D3/LuaSnip" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-buffer" },
    },
    config = function()
      local lsp_zero = require("lsp-zero")
      lsp_zero.extend_cmp()

      local cmp = require("cmp")
      local cmp_action = lsp_zero.cmp_action()

      cmp.setup({
        formatting = lsp_zero.cmp_format(),
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-f>"] = cmp_action.luasnip_jump_forward(),
          ["<C-b>"] = cmp_action.luasnip_jump_backward(),
        }),
      })
    end,
  },

  -- LSP.
  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspInstall", "LspStart" },
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "williamboman/mason-lspconfig.nvim" },
    },
    config = function()
      local lsp_zero = require("lsp-zero")
      lsp_zero.extend_lspconfig()

      lsp_zero.on_attach(function(client, bufnr)
        -- Keybindings.
        lsp_zero.default_keymaps({ buffer = bufnr })

        vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", { buffer = bufnr })
        vim.keymap.set("n", "ds", "<cmd>Telescope lsp_document_symbols<CR>", { buffer = bufnr })
        vim.keymap.set("n", "gh", "<cmd>lua vim.lsp.buf.hover()<CR>", { buffer = bufnr })

        -- Disable tsserver formatting as it conflicts with prettier.
        if client.name == "ts_ls" then
          client.server_capabilities.documentFormattingProvider = false
        end


        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
      end)

      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",
          "lua_ls",
          "pylsp",
          "tailwindcss",
          "astro",
          "gopls",
        },
        handlers = {
          lsp_zero.default_setup,
          lua_ls = function()
            local lua_opts = lsp_zero.nvim_lua_ls()
            require("lspconfig").lua_ls.setup(lua_opts)
          end,
          pylsp = function()
            require("lspconfig").pylsp.setup({
              cmd = (function()
                local cwd = vim.fn.getcwd()
                local cwd_path_parts = vim.split(cwd, "/", { trimempty = true })
                local base_dir = cwd_path_parts[#cwd_path_parts]
                local dockerfile = "~/.config/nvim/docker-lsp/" .. base_dir .. "/Dockerfile"

                if vim.fn.filereadable(vim.fn.expand(dockerfile)) == 1 then
                  return {
                    "docker",
                    "run",
                    "-i",
                    "--name",
                    "lsp-" .. base_dir,
                    "--rm",
                    "--workdir=" .. cwd,
                    "--volume=" .. cwd .. ":" .. cwd,
                    "lsp/" .. base_dir,
                  }
                else
                  return nil
                end
              end)(),
              plugins = {
                black = {
                  enabled = true,
                },
                flake8 = {
                  enabled = true,
                },
                mccabe = {
                  enabled = false,
                },
                pycodestyle = {
                  enabled = false,
                },
                pyflakes = {
                  enabled = false,
                },
                pylsp_mypy = {
                  enabled = false,
                  dmypy = true,
                  report_progress = true,
                  live_mode = false,
                },
                pylint = {
                  enabled = true,
                },
                rope_completion = {
                  enabled = true,
                },
              },
            })
          end,
        },
      })
    end,
  },
}
