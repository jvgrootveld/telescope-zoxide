local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local entry_display = require('telescope.pickers.entry_display')
local utils = require('telescope.utils')

local z_config = require("telescope._extensions.zoxide.config")

local map_both = function(map, keys, func)
      map("i", keys, func)
      map("n", keys, func)
end

-- Copied unexported highlighter from telescope/sorters.lua
local ngram_highlighter = function(ngram_len, prompt, display)
  local highlights = {}
  display = display:lower()

  for disp_index = 1, #display do
    local char = display:sub(disp_index, disp_index + ngram_len - 1)
    if prompt:find(char, 1, true) then
      table.insert(highlights, {
        start = disp_index,
        finish = disp_index + ngram_len - 1
      })
    end
  end

  return highlights
end

local fuzzy_with_z_score_bias = function(opts)
  opts = opts or {}
  opts.ngram_len = 2

  local fuzzy_sorter = sorters.get_generic_fuzzy_sorter(opts)

  return sorters.Sorter:new {
    highlighter = opts.highlighter or function(_, prompt, display)
      return ngram_highlighter(opts.ngram_len, prompt, display)
    end,
    scoring_function = function(_, prompt, _, entry)
      local base_score = fuzzy_sorter:score(
        prompt,
        entry,
        function(val) return val end,
        function() return -1 end
      )

      if base_score == -1 then
        return -1
      end

      if base_score == 0 then
        return -entry.z_score
      else
        return math.min(math.pow(entry.index, 0.25), 2) * base_score
      end
    end
  }
end

local entry_maker = function(opts)
  opts = opts or {}

  return function(item)
    local trimmed = string.gsub(item, '^%s*(.-)%s*$', '%1')
    local item_path = string.gsub(trimmed, '^[^%s]* (.*)$', '%1')
    local score = tonumber(string.gsub(trimmed, '^([^%s]*) .*$', '%1'), 10)

    local display_items = {
      { remaining = true },
    }

    local show_score = z_config.get_config().show_score
    local score_width = 0
    if show_score then
      score_width = 7
      table.insert(display_items, 1, { width = score_width, right_justify = true })
    end

    local displayer = entry_display.create({
      separator = " ",
      items = display_items,
    })

    local make_display = function()
      opts.__prefix = score_width
      local display_path, path_style = utils.transform_path(opts, item_path)
      if show_score then
        return displayer {
          { ("%.2f"):format(score), "TelescopeResultsNumber" },
          {
            display_path,
            function()
              return path_style
            end,
          },
        }
      else
        return displayer {
          {
            display_path,
            function()
              return path_style
            end,
          },
        }
      end
    end

    return {
      value = item_path,
      ordinal = item_path,
      display = make_display,
      z_score = score,
      path = item_path
    }
  end
end

local create_mapping = function(prompt_bufnr, mapping_config)
  return function()
    local selection = action_state.get_selected_entry()
    if mapping_config.before_action ~= nil then
      mapping_config.before_action(selection)
    end

    -- Close Telescope window
    actions._close(prompt_bufnr, mapping_config.keepinsert or false)

    mapping_config.action(selection)

    if mapping_config.after_action ~= nil then
      mapping_config.after_action(selection)
    end
  end
end

return function(opts)
  opts = opts or {}

  local cmd = z_config.get_config().list_command
  local shell_arg = "-c"
  if vim.o.shell == "cmd.exe" then
    shell_arg = "/c"
  end
  opts.cmd = vim.F.if_nil(opts.cmd, {vim.o.shell, shell_arg, cmd})
  opts.path_display = vim.F.if_nil(opts.path_display, z_config.get_config().path_display)

  pickers.new(opts, {
    prompt_title = z_config.get_config().prompt_title,
    previewer = require("telescope.previewers.buffer_previewer").cat.new(opts),

    finder = finders.new_table {
      results = utils.get_os_command_output(opts.cmd),
      entry_maker = entry_maker(opts)
    },
    sorter = fuzzy_with_z_score_bias(opts),
    previewer = z_config.get_config().previewer,
    attach_mappings = function(prompt_bufnr, map)
      local mappings = z_config.get_config().mappings

      -- Set default mapping '<cr>'
      actions.select_default:replace(create_mapping(prompt_bufnr, mappings.default))

      -- Add extra mappings
      for mapping_key, mapping_config in pairs(mappings) do
        if mapping_key ~= "default" then
          map_both(map, mapping_key, create_mapping(prompt_bufnr, mapping_config))
        end
      end

      return true
    end,
  }):find()
end
