local M = {}

M.request = function(method, params, handler)
  vim.validate({
    method = { method, 's' },
    handler = { handler, 'f', true },
  })
  return vim.lsp.buf_request(0, method, params, handler)
end

M.get_tag_position = function()
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local winnid = vim.fn.win_getid()

  local cn = ts_utils.get_node_at_cursor(winnid)
  while cn ~= nil and cn:type() ~= "named_argument" do
    cn = cn:parent()
  end

  local start_row, start_col
  if cn ~= nil then
    start_row, start_col = cn:start()
  end

  return { line = start_row, character = start_col }
end

M._scroll_down = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local height = vim.api.nvim_win_get_height(0)

  local increment = 1

  if height > cursor[1] then
    increment = height
  end

  local max_lines = vim.api.nvim_buf_line_count(0)
  local new_row = cursor[1] + increment

  if new_row <= max_lines then
    vim.api.nvim_win_set_cursor(0, { cursor[1] + increment, 0 })
  end
end

M.scroll_down = function()
  local winid = vim.fn.bufwinid('^_output$')
  vim.api.nvim_win_call(winid, M._scroll_down)
end

M._scroll_up = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local height = vim.api.nvim_win_get_height(0)

  local decrement = 1

  if height < cursor[1] then
    decrement = height
  end

  local new_row = cursor[1] - decrement

  if new_row > 0 then
    vim.api.nvim_win_set_cursor(0, { new_row, 0 })
  end
end

M.scroll_up = function()
  local winid = vim.fn.bufwinid('^_output$')
  vim.api.nvim_win_call(winid, M._scroll_up)
end

M.display_doc = function(options)
  local winnr = vim.fn.bufwinnr('^_output$')
  local winid = vim.fn.bufwinid('^_output$')
  if winnr < 0 then
    local curwin = vim.api.nvim_get_current_win()
    vim.api.nvim_command('bel 10new _output')
    vim.cmd('setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap winfixheight')
    vim.api.nvim_set_current_win(curwin)
  end

  local bufnr = vim.fn.bufnr('^_output$')
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')

  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  local position

  if options.tag == true then
    position = M.get_tag_position()
  else
    position = { line = cursor_pos[1] - 1, character = cursor_pos[2] }
  end

  local paramss = {
    textDocument = vim.lsp.util.make_text_document_params(0),
    -- position = { line = cursor_pos[1] - 1, character = cursor_pos[2] }
    position = position
  }


  M.request('textDocument/hover', paramss, function(err, result, ctx)
    if err then
      print("Error:", err)
      return
    end

    -- vim.notify(vim.inspect(result))
    local response_text = result and result.contents.value or "No hover information"
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(response_text, "\n"))

    if winid > 0 then
      vim.api.nvim_win_set_cursor(winid, { 1, 1 })
    end
  end)
end

return M
