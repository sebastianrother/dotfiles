return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>ot", "<cmd>ObsidianToday<cr>",  desc = "Open Daily Note" },
    { "<leader>fo", "<cmd>ObsidianSearch<cr>", desc = "Search Notes" }
  },
  opts = {
    workspaces = {
      {
        name = "digital_brain",
        path = "~/Documents/digital_brain",
      },
    },

    daily_notes = {
      folder = "02_areas/work/daily_notes",
      template = nil,
    },

    wiki_link_func = function(opts)
      -- only use the ide for the links, don't use the full path
      return string.format("[[%s]]", opts.id)
    end,
    disable_frontmatter = true,
    preferred_link_style = "wiki",
    new_notes_location = "notes_subdir",
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },
    mappings = {
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
    },
    ui = {
      enable = false,
    }
  },
}
