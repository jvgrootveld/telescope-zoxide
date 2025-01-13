local builtin = require("telescope.builtin")
local utils = require("telescope.utils")
local z_utils = require("telescope._extensions.zoxide.utils")

local truncate = require("plenary.strings").truncate
local get_status = require("telescope.state").get_status

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
  },

  show_score = true,
  -- See `:help telescope.defaults.path_display`
  path_display = function(opts, path)
    local transformed_path = vim.trim(path)
    -- Replace home with ~
    local home = (vim.uv or vim.loop).os_homedir()
    transformed_path = home and transformed_path:gsub("^" .. vim.pesc(home), "~") or transformed_path
    -- Truncate
    local calc_result_length = function(truncate_len)
      local status = get_status(vim.api.nvim_get_current_buf())
      -- Compatibility with telescope.nvim 0.1.4
      local results_win = vim.tbl_get(status, "layout", "results", "winid") or status.results_win
      local len = vim.api.nvim_win_get_width(results_win) - status.picker.selection_caret:len() - 2
      return type(truncate_len) == "number" and len - truncate_len or len
    end
    local truncate_len = nil
    if opts.__length == nil then
      opts.__length = calc_result_length(truncate_len)
    end
    if opts.__prefix == nil then
      opts.__prefix = 0
    end
    transformed_path = truncate(transformed_path, opts.__length - opts.__prefix, nil, -1)
    -- Dim parent directories
    local tail = utils.path_tail(path)
    local path_style = {
      { { 0, #transformed_path - #tail }, "Comment" },
    }
    return transformed_path, path_style
  end,
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
