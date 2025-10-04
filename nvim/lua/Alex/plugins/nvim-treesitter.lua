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
				fg = "#FFFFFF",
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
				darkgreen = "#2B6631",
				-- Xcode_Dark (CLion) aligned colors for C/C++
				oc_keyword = "#fc5fa3",
				oc_directive = "#f6991e",
				oc_function_call = "#87f8eb",
				oc_function_decl = "#35dffd",
				oc_header_path = "#f61d06",
				oc_namespace = "#a646ff",
				oc_number = "#38f684",
				oc_parameter = "#4cc9d9",
				oc_string = "#f14838",
				oc_struct_field = "#47a4e7",
				oc_type_name = "#5dd8ff",
				oc_type_reference = "#d0a8ff",
				oc_identifier = "#67b7a4",
				default_constant = "#a167e6",
				oc_line_comment = "#6a6a6a",
				oc_macro_name = "#ffd500",
			}

			-- Tree-sitter specific highlights for C++

			vim.api.nvim_set_hl(0, "PreProc", { fg = colors.oc_directive })

			vim.api.nvim_set_hl(0, "@variable.cpp", { fg = colors.oc_identifier })
			vim.api.nvim_set_hl(0, "@function.cpp", { fg = colors.oc_function_decl })
			vim.api.nvim_set_hl(0, "@function.call.cpp", { fg = colors.oc_function_call })
			vim.api.nvim_set_hl(0, "@method.cpp", { fg = colors.oc_function_call })
			vim.api.nvim_set_hl(0, "@field.cpp", { fg = colors.oc_struct_field })
			vim.api.nvim_set_hl(0, "@property.cpp", { fg = colors.oc_struct_field })
			vim.api.nvim_set_hl(0, "@lsp.type.property.cpp", { fg = colors.oc_struct_field })
			vim.api.nvim_set_hl(0, "@constructor.cpp", { fg = colors.oc_type_reference })

			vim.api.nvim_set_hl(0, "@keyword.cpp", { fg = colors.oc_keyword, bold = true })
			vim.api.nvim_set_hl(0, "@keyword.import.cpp", { fg = colors.oc_keyword })
			vim.api.nvim_set_hl(0, "@keyword.function.cpp", { fg = colors.oc_keyword })
			vim.api.nvim_set_hl(0, "@keyword.operator.cpp", { fg = colors.oc_keyword })
			vim.api.nvim_set_hl(0, "@keyword.return.cpp", { fg = colors.oc_keyword, bold = true })
			vim.api.nvim_set_hl(0, "@keyword.type.cpp", { fg = colors.oc_keyword })

			vim.api.nvim_set_hl(0, "@type.cpp", { fg = colors.oc_type_name })
			vim.api.nvim_set_hl(0, "@type.builtin.cpp", { fg = colors.oc_keyword, italic = true })
			vim.api.nvim_set_hl(0, "@include.cpp", { fg = colors.oc_directive })
			vim.api.nvim_set_hl(0, "@include.identifier.cpp", { fg = colors.oc_header_path })

			vim.api.nvim_set_hl(0, "@constant.cpp", { fg = colors.default_constant })
			vim.api.nvim_set_hl(0, "@constant.builtin.cpp", { fg = colors.default_constant, bold = true })
			vim.api.nvim_set_hl(0, "@constant.macro.cpp", { fg = colors.oc_macro_name })

			vim.api.nvim_set_hl(0, "@string.cpp", { fg = colors.oc_string })
			vim.api.nvim_set_hl(0, "@number.cpp", { fg = colors.oc_number })
			vim.api.nvim_set_hl(0, "@boolean.cpp", { fg = colors.default_constant, italic = true })

			vim.api.nvim_set_hl(0, "@operator.cpp", { fg = colors.fg })
			vim.api.nvim_set_hl(0, "@namespace.cpp", { fg = colors.oc_namespace, italic = true })
			vim.api.nvim_set_hl(0, "@parameter.cpp", { fg = colors.oc_parameter, italic = true })

			vim.api.nvim_set_hl(0, "@comment.cpp", { fg = colors.oc_line_comment, italic = true })
			vim.api.nvim_set_hl(0, "@preprocessor.cpp", { fg = colors.oc_directive })
			vim.api.nvim_set_hl(0, "@punctuation.bracket.cpp", { fg = colors.fg })
			vim.api.nvim_set_hl(0, "@punctuation.delimiter.cpp", { fg = colors.fg })

			-- LSP semantic token groups (clangd) to avoid later overrides
			vim.api.nvim_set_hl(0, "@lsp.type.variable", { fg = colors.oc_identifier })
			vim.api.nvim_set_hl(0, "@lsp.type.parameter", { fg = colors.oc_parameter, italic = true })
			vim.api.nvim_set_hl(0, "@lsp.type.function", { fg = colors.oc_function_call })
			vim.api.nvim_set_hl(0, "@lsp.type.method", { fg = colors.oc_function_call })
			vim.api.nvim_set_hl(0, "@lsp.type.property", { fg = colors.oc_struct_field })
			vim.api.nvim_set_hl(0, "@lsp.type.field", { fg = colors.oc_struct_field })
			vim.api.nvim_set_hl(0, "@lsp.type.macro", { fg = colors.oc_macro_name })
			vim.api.nvim_set_hl(0, "@lsp.type.namespace", { fg = colors.oc_namespace, italic = true })
			vim.api.nvim_set_hl(0, "@lsp.type.class", { fg = colors.oc_type_name })
			vim.api.nvim_set_hl(0, "@lsp.type.struct", { fg = colors.oc_type_name })
			vim.api.nvim_set_hl(0, "@lsp.type.enum", { fg = colors.oc_type_name })
			vim.api.nvim_set_hl(0, "@lsp.type.type", { fg = colors.oc_keyword })
			vim.api.nvim_set_hl(0, "@lsp.type.keyword", { fg = colors.oc_keyword, italic = true })
			vim.api.nvim_set_hl(0, "@lsp.type.typeParameter", { fg = colors.oc_type_reference })

			-- STL specifics
			vim.api.nvim_set_hl(0, "@type.qualifier.cpp", { fg = colors.oc_keyword, italic = true }) -- const, static, etc.
			vim.api.nvim_set_hl(0, "@storageclass.cpp", { fg = colors.oc_keyword, italic = true }) -- auto, register, etc.
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

		-- Re-apply after colorscheme or LSP attach (to prevent overrides)
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				setup_cpp_highlights()
			end,
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local buf = args.buf
				if vim.bo[buf].filetype == "cpp" then
					setup_cpp_highlights()
				end
			end,
		})
	end,
}
