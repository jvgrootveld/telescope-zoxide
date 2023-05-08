local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugin requires nvim-telescope/telescope.nvim')
end

return telescope.register_extension {
  setup = require("telescope._extensions.zoxide.config").setup,
  exports = {
    list = require("telescope._extensions.zoxide.list")
  }
}
