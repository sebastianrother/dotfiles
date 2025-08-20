local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

---Flattens nested table
---Replaces deprecated `vim.tbl_flatten`
---@param t table
---@return table Flattened table structure
local function flatten(t)
  return vim.iter(t):flatten():totable()
end

local FORMAT_ARGS = {
  "--color=never",
  "--no-heading",
  "--with-filename",
  "--line-number",
  "--column",
  "--smart-case"
}

local function multi_search(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()


  local finder = finders.new_async_job({
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      local pieces = vim.split(prompt, " -- ", { plain = true })
      print(vim.inspect(pieces))
      local cmd = { "rg" }

      if pieces[1] then
        table.insert(cmd, "-e")
        table.insert(cmd, pieces[1])
      end

      if pieces[2] then
        local additional_args = vim.split(pieces[2], " ", { plain = true })
        table.insert(cmd, additional_args)
      end

      table.insert(cmd, FORMAT_ARGS)

      return flatten(cmd)
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })

  pickers.new(opts, {
    prompt_title = "Multi Search",
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require('telescope.sorters').empty()
  }):find()
end

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
        live_grep = {
          hidden = true,
          disable_devicons = true,
        },
      },
      extensions = {
        aerial = {
          -- Set the width of the first two columns (the second
          -- is relevant only when show_columns is set to 'both')
          col1_width = 4,
          col2_width = 30,
          -- How to format the symbols
          format_symbol = function(symbol_path, filetype)
            if filetype == "json" or filetype == "yaml" then
              return table.concat(symbol_path, ".")
            else
              return symbol_path[#symbol_path]
            end
          end,
          -- Available modes: symbols, lines, both
          show_columns = "symbols",
        },
      },
    })

    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>.", builtin.resume, {})
    vim.keymap.set("n", "<leader><Space>", builtin.buffers, {})

    -- Search.
    vim.keymap.set("n", "<C-p>", builtin.git_files, {})       -- Only Git files
    vim.keymap.set("n", "<leader>fs", multi_search, {})
    vim.keymap.set("n", "<leader>ff", builtin.find_files, {}) -- All files
    vim.keymap.set("n", "<leader>fa", ":Telescope aerial<CR>", {}) -- All files

    vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    vim.keymap.set("n", "<leader>fk", builtin.keymaps, {})
    vim.keymap.set("n", "<leader>fM", builtin.man_pages, {})
    vim.keymap.set("n", "<leader>fvo", builtin.vim_options, {})
  end,
}
