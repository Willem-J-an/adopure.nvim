rockspec_format = "3.0"
package = "adopure.nvim"
version = "0.0.1-1"
source = {
	url = "git+https://github.com/Willem-J-an/ado.nvim",
}
dependencies = {
	"plenary.nvim",
	"telescope.nvim",
}
test_dependencies = {
	"nlua",
	"plenary.nvim",
	"telescope.nvim",
}
build = {
	type = "builtin",
	copy_directories = {
		"plugin",
	},
}
