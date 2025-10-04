require("Alex.core")
require("Alex.lazy")

-- Copy current filename to system clipboard for use in terminal commands
vim.keymap.set('n', '<leader>cf', function()
  vim.fn.setreg('+', vim.fn.expand('%:t'))
  print('Copied filename: ' .. vim.fn.expand('%:t'))
end, { desc = 'Copy filename to clipboard' })
