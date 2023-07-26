# doc-window.nvim

A plugin to display hover info you get from lsp in a separate buffer.

Use case: If you want the hover information to persist.

As picked up by lazy.nvim:

```
  {
    dir = "/home/vector/plugins/doc-window.nvim",
    config = function()
      local dw = require("doc-window")

      vim.keymap.set({ 'n', 'i' }, '<M-h>',
        function()
          dw.display_doc({ tag = false })
        end,
        { desc = "Display LSP documentation in a window" })

      vim.keymap.set({ 'n', 'i' }, '<M-i>',
        function()
          dw.display_doc({ tag = true })
        end,
        { desc = "Display LSP documentation of closest parent tag node" })

      vim.keymap.set({ 'n', 'i' }, '<M-k>', dw.scroll_up, { desc = "LSP doc window scroll up" })

      vim.keymap.set({ 'n', 'i' }, '<M-j>', dw.scroll_down, { desc = "LSP doc window scroll down" })
    end
  },

```

## Warning

I'm a neovim noob. This plugin was made for personal use. 🙏
