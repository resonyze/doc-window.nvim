# doc-window.nvim

A plugin to display hover info you get from lsp in a separate buffer.

Use case: If you want the hover information to persist.

As picked up by lazy.nvim:

```
  {
    dir = "/home/vector/plugins/doc-window.nvim",
    config = function()
      local dw = require("doc-window")

      vim.keymap.set({ 'n', 'i' }, '<M-i>',
        function()
          dw.display_doc({ tag = false, sig = false })
        end,
        { desc = "textDocument/hover under cursor" })

      vim.keymap.set({ 'n', 'i' }, '<M-u>',
        function()
          dw.display_doc({ tag = true, sig = false })
        end,
        { desc = "textDocument/hover of nearest tag" })

      vim.keymap.set({ 'n', 'i' }, '<M-n>',
        function()
          dw.display_doc({ tag = false, sig = true })
        end,
        { desc = "textDocument/signatureHelp under cursor" })
    end
  },

```

## Warning

This plugin was made for personal use. It works for me, for now. Its probably not ready for publishing but I'm
doing it anyway.

## Screnshots

![Screenshot](https://raw.githubusercontent.com/resonyze/doc-window.nvim/master/screenshots/1691402880.png) 
