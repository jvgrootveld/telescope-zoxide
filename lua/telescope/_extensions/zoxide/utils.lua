local utils = {}

utils.create_basic_command = function(command)
  return function(selection)
    vim.cmd[command](selection.path)
  end
end

return utils
