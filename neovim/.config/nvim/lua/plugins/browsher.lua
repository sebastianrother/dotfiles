return {
  'claydugo/browsher.nvim',
  event = "VeryLazy",
  config = function()
    -- Specify empty to use below default options
    require('browsher').setup(
      {
        providers = {
          ["github.com"] = {
            url_template = "%s/blob/%s/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d-L%d",
          },
          ["gitlab.com"] = {
            url_template = "%s/-/blob/%s/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d-%d",
          },
          ["git.iwoca.co.uk"] = {
            url_template = "%s/-/blob/%s/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d-%d",
          },
          ["sr.ht"] = {
            url_template = "%s/tree/%s/item/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d",
          },
        },
      }
    )
    
    -- Open from the latest commit, the recommended default operation
    vim.api.nvim_set_keymap('n', '<leader>gl', '<cmd>Browsher commit<CR>', { noremap = true, silent = true, desc = "[G]it [L]ink" })
    vim.api.nvim_set_keymap('v', '<leader>gl', ":'<,'>Browsher commit<CR>gv", { noremap = true, silent = true , desc = "[G]it [L]ink" })
  end
}
