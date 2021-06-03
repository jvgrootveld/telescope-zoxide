local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local utils = require'telescope.utils'

local map_both = function(map, keys, func)
      map("i", keys, func)
      map("n", keys, func)
end

local command = "zoxide query -l"

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

local entry_maker = function(item)
  local items = vim.split(string.gsub(item, '^%s*(.-)%s*$', '%1'), " ")
  local score = 0
  local item_path = item

  if #items > 1 then
    score = tonumber(items[1])
    item_path = items[2]
  end

  return {
    value = item,
    ordinal = item_path,
    display = item,

    z_score = score,
    path = item_path
  }
end

local open_with_command = function (prompt_bufnr, cmd)
  local selection = action_state.get_selected_entry()

  actions.close(prompt_bufnr)
  vim.cmd(cmd .. " " .. selection.path)
end

return function(opts)
  opts = opts or {}

  local cmd = command

  if opts.show_score ~= false then
    cmd = cmd .. "s"
  end

  opts.cmd = utils.get_default(opts.cmd, {vim.o.shell, "-c", cmd})

  pickers.new(opts, {
    prompt_title = "[ Zoxide List ]",

    finder = finders.new_table {
      results = utils.get_os_command_output(opts.cmd),
      entry_maker = entry_maker
    },
    sorter = fuzzy_with_z_score_bias(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd("cd " .. selection.path)
        print("Directory changed to " .. selection.path)
      end)

      map_both(map, "<C-s>", function() open_with_command(prompt_bufnr, "split") end)
      map_both(map, "<C-v>", function() open_with_command(prompt_bufnr, "vsplit") end)
      map_both(map, "<C-e>", function() open_with_command(prompt_bufnr, "edit") end)

      return true
    end,
  }):find()
end
