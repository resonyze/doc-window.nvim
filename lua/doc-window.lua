local ts_utils = require 'nvim-treesitter.ts_utils'

local M = {}

M.request = function(method, params, handler)
  vim.validate({
    method = { method, 's' },
    handler = { handler, 'f', true },
  })
  return vim.lsp.buf_request(0, method, params, handler)
end

M.get_tag_position = function()
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
  local bufno = vim.api.nvim_get_current_buf()
  local winid = vim.fn.bufwinid('_output' .. bufno)

  if winid < 0 then
    M.display_doc({ tag = false, sig = false })
    return
  end

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
  local bufno = vim.api.nvim_get_current_buf()
  local winid = vim.fn.bufwinid('_output' .. bufno)

  if winid < 0 then
    M.display_doc({ tag = false, sig = false })
    return
  end

  vim.api.nvim_win_call(winid, M._scroll_up)
end

M.lsp_callback = function(err, result, ctx)
  local bufnr = vim.fn.bufnr('^_output$')
  local winid = vim.fn.bufwinid('^_output$')
  if err then
    print("Error:", err)
    return
  end

  local response_text = result and result.contents.value or "No hover information"

  local command = { "fmt", "-w", "1000" }

  local job_id = vim.fn.jobstart(
    command,
    {
      on_stdout = function(_, data)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(data, "\n"))
      end,
      stdout_buffered = true,
      stderr = true,
    }
  )

  vim.fn.chansend(job_id, response_text)
  vim.fn.chanclose(job_id, "stdin")
  vim.fn.jobwait({ job_id }, "w")


  -- if not result then
  --   local match = false
  --   local cn = ts_utils.get_node_at_cursor(0)
  --   while cn ~= nil do
  --     if cn:type() == "selector" and cn:prev_sibling():type() == "identifier" then
  --       match = true
  --       break
  --     end
  --     cn = cn:parent()
  --   end
  --
  --   if match == true then
  --     cn = cn:prev_sibling()
  --     local start_row, start_col = cn:start()
  --     M.request('textDocument/hover', { line = start_row, character = start_col }, M.lsp_callback)
  --     return
  --   end
  --
  -- else
  --   local response_text = result.contents.value
  --   vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(response_text, "\n"))
  -- end

  if winid > 0 then
    vim.api.nvim_win_set_cursor(winid, { 1, 1 })
  end
end

M.display_doc = function(options)
  -- local bufnr = vim.fn.bufnr('^_output$')
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.fn.bufwinid('^_output' .. bufnr .. '$')
  local winnr = vim.fn.bufwinnr('^_output' .. bufnr .. '$')
  if winnr < 0 then
    local curwin = vim.api.nvim_get_current_win()
    local height = vim.api.nvim_win_get_height(curwin) * 5
    local width = vim.api.nvim_win_get_width(curwin) * 2

    if height > width then
      vim.api.nvim_command('bel 10new _output' .. bufnr)
    else
      vim.api.nvim_command('vnew _output' .. bufnr)
    end

    -- vim.api.nvim_command('bel 10new _output')
    vim.cmd('setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile wrap linebreak winfixheight')
    vim.api.nvim_set_current_win(curwin)
  end

  bufnr = vim.fn.bufnr('^_output' .. bufnr .. '$')
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')

  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  local position, request, callback

  if options.tag == true then
    position = M.get_tag_position()
  else
    position = { line = cursor_pos[1] - 1, character = cursor_pos[2] }
  end

  if options.sig == true then
    request = "textDocument/signatureHelp"
    callback = function(err, result, ctx)
      if err then
        print("Error:", err)
        return
      end

      local response_text = result and
          "```dart\n" .. string.gsub(result.signatures[1].label, ',', ',\n') .. "\n```"
          or "No signature help"

      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(response_text, "\n"))
    end
  else
    request = "textDocument/hover"
    callback = function(err, result, ctx)
      if err then
        print("Error:", err)
        return
      end


      local response_text = result and result.contents.value or "No hover information"
      local code_block = vim.split(response_text:match("```.-```"), "\n")
      response_text = response_text:gsub("```.-```", "")

      local command = { "fmt", "-w", "1000" }

      local job_id = vim.fn.jobstart(
        command,
        {
          on_stdout = function(_, data)
            for _, value in ipairs(data) do
              table.insert(code_block, value)
            end
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, code_block)
          end,
          stdout_buffered = true,
          stderr = true,
        }
      )

      vim.fn.chansend(job_id, response_text)
      vim.fn.chanclose(job_id, "stdin")
    end
  end

  local paramss = {
    textDocument = vim.lsp.util.make_text_document_params(0),
    -- position = { line = cursor_pos[1] - 1, character = cursor_pos[2] }
    position = position
  }

  M.request(request, paramss, callback)
  if winid > 0 then
    vim.api.nvim_win_set_cursor(winid, { 1, 1 })
  end
end

return M
