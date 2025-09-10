local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local ts = vim.treesitter
local sorters = require('telescope.sorters')
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")


local function flatten(t)
  return vim.iter(t):flatten():totable()
end

local function get_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col }
end

function contains_table(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end

local function icontains_str(str, substr)
  if substr == '' or substr == nil then
    return true
  end

  return str:lower():find(substr:lower(), 1, true) ~= nil
end

local function safe_set_cursor(win, bufnr, row, col)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local target_row = math.max(1, math.min(row, line_count))
  local target_col = math.max(0, col or 0)
  vim.api.nvim_win_set_cursor(win, { target_row, 0})
end



local FUNC_TYPE = 'function'
local FUNC_IDENTIFIER = { "function_definition", "function_declaration", "method_definition", "arrow_function" }
local FUNC_ICON  = "\u{f0295}"
local FUNC_HL = '@keyword'

local CLASS_TYPE = 'class'
local CLASS_IDENTIFIER = { "class_declaration", "class_definition" }
local CLASS_ICON = "\u{eb5b}"
local CLASS_HL = 'Constant'

local UNKNOWN_TYPE = 'unknown'
local UNKNOWN_ICON = "\u{eb32}"

local Outline = {}
Outline.walk = function(node, container)
  local bufnr = vim.api.nvim_get_current_buf()
  local node_type = node:type()

  if contains_table(FUNC_IDENTIFIER, node_type) or contains_table(CLASS_IDENTIFIER, node_type) then
    local name_node = node:field("name")[1]
    local body_node = node:field("body")[1]
    local class_name = name_node and vim.treesitter.get_node_text(name_node, bufnr) or "<anonymous>"

    local type =UNKNOWN_TYPE
    if contains_table(FUNC_IDENTIFIER, node_type) then
      type = FUNC_TYPE
    elseif contains_table(CLASS_IDENTIFIER, node_type) then 
      type = CLASS_TYPE
    end
    
    local node_table = {
      type = type,
      name = class_name,
      bufnr = bufnr,
      range = get_range(node),
      nodes = {},
    }
    table.insert(container, node_table)
    if body_node then
      Outline.walk(body_node, node_table.nodes)
    end
    return
  end

  for child in node:iter_children() do
    Outline.walk(child, container)
  end
end

Outline.flatten = function(nodes, level)
  local flat = {}
  for _, node in ipairs(nodes) do
    node.level = level

    local children = {}
    local function collect_names(child_nodes)
      for _, child in ipairs(child_nodes) do
        table.insert(children, child.name)
        if child.nodes and #child.nodes > 0 then
          collect_names(child.nodes)
        end
      end
    end

    if node.nodes and #node.nodes > 0 then
      collect_names(node.nodes)
    end

    node.children = children

    table.insert(flat, node)
    if node.nodes and #node.nodes > 0 then
      local child_flat = Outline.flatten(node.nodes, level + 1)
      for _, cf in ipairs(child_flat) do
        table.insert(flat, cf)
      end
    end
    node.nodes = nil
  end
  return flat
end

Outline.create = function(bufnr)
  local lang = vim.bo[bufnr].filetype
  local parser = ts.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()

  local results = {}
  Outline.walk(root, results)

  return results
end

Outline.filter = function(query, flat_outline)
  results = {}
  for _, flat_outline_node in ipairs(flat_outline) do
    flat_outline_node.name = prompt
    table.insert(results, flat_outline_node) 
  end
  return results
end


Outline.search = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()
  bufnr = vim.api.nvim_get_current_buf()

  results = Outline.create(bufnr)
  results = Outline.flatten(results, 0)

  local finder = finders.new_table(
    {
      results = results,
      entry_maker = function(entry)
        return {
          value = (function() 
            value_table = entry
            search_table = {entry.name}
            if #entry.children > 0 then
              table.insert(search_table, table.concat(entry.children, '--'))
            end
            search_str = table.concat(search_table, '@@')
            value_table.search = search_str
            return value_table
          end)(),
          display = function()
            nesting_table = {}
            for i=0, entry.level - 1, 1 do
              table.insert(nesting_table, '    ') 
            end
            nesting_str = table.concat(nesting_table, '')

            local icon = UNKNOWN_ICON
            if entry.type == FUNC_TYPE then
              icon = FUNC_ICON
              hl_group = FUNC_HL
            elseif entry.type == CLASS_TYPE then
              icon = CLASS_ICON
              hl_group = CLASS_HL
            end

            icon_start_pos = #(nesting_str .. ' ')
            icon_end_pos = icon_start_pos + #icon

            return table.concat({nesting_str, icon, entry.name}, ' '), {{{icon_start_pos, icon_end_pos}, hl_group}}
          end,
          ordinal = 1
        }
      end
    }
  )

  local sorter = sorters.Sorter:new({
    filter_function = function(_, prompt, entry)
      if icontains_str(entry.value.search, prompt) then
        return 1, prompt
      end

      return -1, prompt
    end,
    scoring_function = function()
      return 1
    end
  })

  pickers.new(opts, {
    prompt_title = "Outline",
    finder = finder,
    sorting_strategy = "ascending",
    sorter = sorter,
    attach_mappings = function(_, map)
      local function jump_to_symbol(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.value and selection.value.range then
          local r = selection.value.range
          vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
        end
      end
      map("i", "<CR>", jump_to_symbol)
      map("n", "<CR>", jump_to_symbol)
      return true
    end,
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, _)
        local bufnr = entry.value.bufnr
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        local preview_win = self.state.winid

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_count, false)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", vim.bo[bufnr].filetype)

        local r = entry.value.range
        if not r then
          return nil
        end
        if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
          return nil
        end
        
        -- Ensure the buffer is actually filled before jumping to position
        vim.schedule(function()
          safe_set_cursor(preview_win, bufnr, r.start_row - 1, r.start_col or 0)
        end)
      end,
    }),
  }):find()
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
    })

    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>.", builtin.resume, {})
    vim.keymap.set("n", "<leader><Space>", builtin.buffers, {})

    -- Search.
    vim.keymap.set("n", "<C-p>", builtin.git_files, {})       -- Only Git files
    vim.keymap.set("n", "<leader>fs", multi_search, {})
    vim.keymap.set("n", "<leader>ff", builtin.find_files, {}) -- All files
    vim.keymap.set("n", "<leader>fa", Outline.search, {}) -- Search current outline

    vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    vim.keymap.set("n", "<leader>fk", builtin.keymaps, {})
    vim.keymap.set("n", "<leader>fM", builtin.man_pages, {})
    vim.keymap.set("n", "<leader>fvo", builtin.vim_options, {})
  end,
}
