local utils = {}

utils.create_basic_command = function(command)
  return function(selection)
    vim.cmd[command](selection.path)
  end
end

utils.print_directory_changed = function()
  return function(selection)
    local config = require("telescope._extensions.zoxide.config").get_config()
    if config.verbose then
      print("Directory changed to " .. selection.path)
    end
  end
end

return utils
