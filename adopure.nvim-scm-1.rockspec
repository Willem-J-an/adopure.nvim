rockspec_format = "3.0"
package = "adopure.nvim"
version = "scm-1"
source = {
	url = "git+https://github.com/Willem-J-an/adopure.nvim",
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
		"doc",
		"plugin",
	},
}
