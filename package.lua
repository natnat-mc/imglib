return {
	name = "imglib",
	version = "0.0.1",
	description = "An image organization tool",
	tags = { "luvit", "sqlite", "moonscript", "mooncake" },
	license = "MIT",
	author = { name = "Nathan DECHER", email = "nathan.decher@gmail.com" },
	homepage = "https://github.com/natnat-mc/imglib",
	dependencies = { "cyrilis/mooncake@v0.1.11", "natnat-mc/lsqlite3", "natnat-mc/jsonstream" },
	files = {
		"**.lua",
		"**.sql",
		"!test*"
	}
}
