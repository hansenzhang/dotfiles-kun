return {
  {
    -- Neovim ships the markdown and markdown_inline parsers it needs, so no nvim-treesitter
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = { { 'nvim-mini/mini.icons', opts = {} } },  -- language icons above code blocks
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    -- these need parsers Neovim doesn't ship
    opts = { html = { enabled = false }, latex = { enabled = false }, yaml = { enabled = false } },
  },
}
