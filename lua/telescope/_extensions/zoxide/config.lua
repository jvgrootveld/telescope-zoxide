local builtin = require("telescope.builtin")
local utils = require("telescope.utils")
local z_utils = require("telescope._extensions.zoxide.utils")

local config = {}

local default_config = {
  prompt_title = "[ Zoxide List ]",

  -- Zoxide list command with score
  list_command = "zoxide query -ls",
  mappings = {
    default = {
      action = function(selection)
        vim.cmd.cd(selection.path)
      end,
      after_action = function(selection)
        vim.notify("Directory changed to " .. selection.path)
      end,
    },
    ["<C-s>"] = { action = z_utils.create_basic_command("split") },
    ["<C-v>"] = { action = z_utils.create_basic_command("vsplit") },
    ["<C-e>"] = { action = z_utils.create_basic_command("edit") },
    ["<C-f>"] = {
      keepinsert = true,
      action = function(selection)
        builtin.find_files({ cwd = selection.path })
      end,
    },
    ["<C-t>"] = {
      action = function(selection)
        vim.cmd.tcd(selection.path)
      end,
    },
  }
}

local current_config = default_config

config.get_config = function()
  return current_config
end

config.setup = function(user_config)
  local temp_config = {}

  -- Map everything except 'mappings'
  for key, value in pairs(default_config) do
    if key ~= "mappings" then
      temp_config[key] = vim.F.if_nil(user_config[key], value)
    end
  end

  -- Map mappings
  local temp_mappings = {}

  -- Copy defaults in temp mapping
  for map_key, map_value in pairs(default_config.mappings) do
    for action_key, action_value in pairs(map_value) do
      if temp_mappings[map_key] == nil then
        temp_mappings[map_key] = {}
      end

      temp_mappings[map_key][action_key] = action_value
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
  current_config = temp_config
end

return config
