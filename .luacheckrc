---@diagnostic disable-next-line lowercase-global
std = "max"
globals = { "vim", "describe", "it", "setup", "io" }
read_globals = {
	"setup",
	"io",
	"require",
	"error",
	"table",
	"unpack",
	"pairs",
	"ipairs",
	"setmetatable",
	"assert",
	"tostring",
	"string",
	"type",
	"os",
	"pcall",
	"load",
}
exclude_files = {"lua_modules/*", "spec/submit_spec.lua"}
