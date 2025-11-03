local function close_hidden_buffers()
  require('close_buffers').delete({ type = 'hidden' })
end

local function close_current_buffer()
  require('close_buffers').delete({ type = 'this' })
end

return {
  close_hidden_buffers = close_hidden_buffers,
  close_current_buffer = close_current_buffer,
}
