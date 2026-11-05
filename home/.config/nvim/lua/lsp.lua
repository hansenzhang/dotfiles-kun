-- Don't preselect or auto-insert the first match while typing; fuzzy-rank candidates.
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'popup', 'fuzzy' }

-- Neovim's defaults cover references (grr), implementation (gri), rename (grn) and hover (K);
-- gd and gy are the only ones it leaves out. No `gr` map: it would make grr/grn wait on timeoutlen.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local function map(lhs, fn, desc)
      vim.keymap.set('n', lhs, fn, { buffer = args.buf, desc = desc })
    end
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      -- Autotrigger only fires on the server's trigger characters (gopls: just "."), so widen it
      -- to every letter to get as-you-type completion.
      local chars = {}
      for c in ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ._'):gmatch('.') do chars[#chars + 1] = c end
      client.server_capabilities.completionProvider.triggerCharacters = chars
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
    map('gd', vim.lsp.buf.definition, 'Go to definition')
    map('gy', vim.lsp.buf.type_definition, 'Go to type definition')
  end,
})

-- Diagnostic float; the lists live in plugins/navigation.lua (<leader>x / <leader>X).
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Line diagnostics' })
