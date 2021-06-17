local utils = require('telescope.utils')
local z_utils = require("telescope._extensions.zoxide.utils")

local config = {}

config.defaults = {
  prompt_title = "[ Zoxide List ]",

  -- Zoxide list command with score
  list_command = "zoxide query -ls",
  mappings = {
    default = {
      action = function(selection)
        vim.cmd("cd " .. selection.path)
      end,
      after_action = function(selection)
        print("Directory changed to " .. selection.path)
      end
    },
    ["<C-s>"] = { action = z_utils.create_basic_command("split") },
    ["<C-v>"] = { action = z_utils.create_basic_command("vsplit") },
    ["<C-e>"] = { action = z_utils.create_basic_command("edit") },
  }
}

config.setup = function(user_config)
 local temp_config = {}

 for key, value in pairs(config.defaults) do
   -- Map everything except 'mappings'
   if key ~= "mappings" then
     temp_config[key] = utils.get_default(user_config[key], value)
   end
 end

 -- Map mappings
 local temp_mappings = {}

 -- Copy defaults in temp mapping
 for map_key, map_value in pairs(config.defaults.mappings) do
   for action_key, action_value in pairs(map_value) do
     temp_mappings[map_key] = {
       [action_key] = action_value
     }
   end
 end

 -- Override mapping with user mappings
 user_config.mappings = user_config.mappings or {}
 for map_key, map_value in pairs(user_config.mappings) do
   -- If user mapping is new, just set, else merge
   if temp_mappings[map_key] == nil then
     temp_mappings[map_key] = map_value
   else
     for action_key, action_value in pairs(map_value) do
       temp_mappings[map_key][action_key] = action_value
     end
   end
 end

 -- Set mappings
 temp_config.mappings = temp_mappings

 -- Set new merged config
 config.config = temp_config
end

config.config = config.defaults

return config
