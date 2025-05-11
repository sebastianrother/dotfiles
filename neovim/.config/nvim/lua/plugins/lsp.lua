vim.lsp.config("pylsp", {
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
  settings = {
    pylsp = {
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
    }
  },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
})

vim.lsp.enable("pylsp")
vim.lsp.enable("ts_ls")
vim.lsp.enable("astro")
vim.lsp.enable("tailwindcss")


vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
    end

    map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
    map("gi", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
    map("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
    map("gh", vim.lsp.buf.hover, "[H]over")

    map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
    map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
    map("<leader>rr", vim.lsp.buf.rename, "Rename symbol")

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Disable tsserver formatting as it conflicts with prettier.
    if client.name == "ts_ls" then
      client.server_capabilities.documentFormattingProvider = false
    end
    --
    -- Format on save.
    if client and client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = event.buf, id = client.id })
        end,
      })
    end

    -- Highlight references on hover.
    if client and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end
})

return {
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
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        completion = { completeopt = "menu,menuone,noinsert" },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "path" },
        },
      })
    end,
  },
}
