return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local treesitter = require("nvim-treesitter.configs")
		-- configure treesitter
		treesitter.setup({ -- enable syntax highlighting
			highlight = {
				enable = true,
				disable = {},
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = false },
			autotag = {
				enable = true,
			},
			-- ensure these parsers are installed
			ensure_installed = {
				"json",
				"javascript",
				"tsx",
				"yaml",
				"html",
				"css",
				"prisma",
				"markdown",
				"markdown_inline",
				"svelte",
				"graphql",
				"bash",
				"lua",
				"vim",
				"dockerfile",
				"gitignore",
				"query",
				"cpp",
				"cmake",
				"python",
			},
			sync_install = false,
			auto_install = true,
			ignore_install = {},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			modules = {},
		})

		-- Custom C++ syntax highlighting setup
		local function setup_cpp_highlights()
			local colors = {
				bg = "#1E1E2E",
				fg = "#D9E0EE",
				red = "#FF0000",
				green = "#ABE9B3",
				yellow = "#FAE3B0",
				blue = "#96CDFB",
				magenta = "#DDB6F2",
				cyan = "#89DCEB",
				orange = "#F6991E",
				purple = "#C9CBFF",
				darkerpurple = "A65FFC",
				pink = "#FC5FD0",
				neongreen = "#23F108",
				grey = "#6A6A6A",
				white = "#FFFFFF",
			}

			-- Tree-sitter specific highlights for C++

			vim.api.nvim_set_hl(0, "PreProc", { fg = colors.orange })

			vim.api.nvim_set_hl(0, "@variable.cpp", { fg = colors.orange })
			vim.api.nvim_set_hl(0, "@function.cpp", { fg = colors.blue, bold = true })
			vim.api.nvim_set_hl(0, "@function.call.cpp", { fg = colors.cyan })
			vim.api.nvim_set_hl(0, "@method.cpp", { fg = colors.blue })
			vim.api.nvim_set_hl(0, "@field.cpp", { fg = colors.cyan })
			vim.api.nvim_set_hl(0, "@property.cpp", { fg = colors.neongreen })
			vim.api.nvim_set_hl(0, "@lsp.type.property.cpp", { fg = colors.neongreen })
			vim.api.nvim_set_hl(0, "@constructor.cpp", { fg = colors.magenta })

			vim.api.nvim_set_hl(0, "@keyword.cpp", { fg = colors.red })
			vim.api.nvim_set_hl(0, "keyword.import.cpp", { fg = colors.orange })
			vim.api.nvim_set_hl(0, "@keyword.function.cpp", { fg = colors.pink })
			vim.api.nvim_set_hl(0, "@keyword.operator.cpp", { fg = colors.red })
			vim.api.nvim_set_hl(0, "@keyword.return.cpp", { fg = colors.pink, bold = true })
			vim.api.nvim_set_hl(0, "@keyword.type.cpp", { fg = colors.pink })

			vim.api.nvim_set_hl(0, "@type.cpp", { fg = colors.yellow })
			vim.api.nvim_set_hl(0, "@type.builtin.cpp", { fg = colors.pink, italic = true })
			vim.api.nvim_set_hl(0, "@include.cpp", { fg = colors.purple })
			vim.api.nvim_set_hl(0, "@include.identifier.cpp", { fg = colors.purple })

			vim.api.nvim_set_hl(0, "@constant.cpp", { fg = colors.orange })
			vim.api.nvim_set_hl(0, "@constant.builtin.cpp", { fg = colors.orange, bold = true })
			vim.api.nvim_set_hl(0, "@constant.macro.cpp", { fg = colors.orange, italic = true })

			vim.api.nvim_set_hl(0, "@string.cpp", { fg = colors.red })
			vim.api.nvim_set_hl(0, "@number.cpp", { fg = colors.white })
			vim.api.nvim_set_hl(0, "@boolean.cpp", { fg = colors.orange, italic = true })

			vim.api.nvim_set_hl(0, "@operator.cpp", { fg = colors.fg })
			vim.api.nvim_set_hl(0, "@namespace.cpp", { fg = colors.purple, italic = true })
			vim.api.nvim_set_hl(0, "@parameter.cpp", { fg = colors.fg, italic = true })

			vim.api.nvim_set_hl(0, "@comment.cpp", { fg = colors.grey, italic = true })
			vim.api.nvim_set_hl(0, "@preprocessor.cpp", { fg = colors.purple })
			vim.api.nvim_set_hl(0, "@punctuation.bracket.cpp", { fg = colors.fg })
			vim.api.nvim_set_hl(0, "@punctuation.delimiter.cpp", { fg = colors.fg })

			-- STL specifics
			vim.api.nvim_set_hl(0, "@type.qualifier.cpp", { fg = colors.red, italic = true }) -- const, static, etc.
			vim.api.nvim_set_hl(0, "@storageclass.cpp", { fg = colors.red, italic = true }) -- auto, register, etc.
		end

		-- Create an autocmd to apply the highlights when opening C++ files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "cpp",
			callback = function()
				setup_cpp_highlights()
			end,
		})

		-- Optionally add a command to refresh the highlights manually
		vim.api.nvim_create_user_command("RefreshCppHighlights", function()
			setup_cpp_highlights()
			print("C++ highlighting refreshed")
		end, {})
	end,
}
