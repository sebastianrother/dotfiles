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

    completion = {
      nvim_cmp = true,
      min_chars = 2,
      new_notes_location = "notes_subdir",
      preferred_link_style = "wiki",
      prepend_note_id = false,
      prepend_note_path = false,
      use_path_only = true,
    },

    disable_frontmatter = true,
  },
}
