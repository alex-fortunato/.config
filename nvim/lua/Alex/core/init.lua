require("Alex.core.options")
require("Alex.core.keymaps")
require("Alex.lazy")
vim.api.nvim_create_user_command("CheckActiveLSP", function()
	local active_clients = vim.lsp.get_active_clients()
	local output = { "Active LSP Servers:" }

	for _, client in ipairs(active_clients) do
		table.insert(output, client.name .. " (id: " .. client.id .. ")")
	end

	if #active_clients == 0 then
		table.insert(output, "No active LSP servers found")
	end

	vim.notify(table.concat(output, "\n"), vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("StopAllLSP", function()
	-- Get all active clients
	local active_clients = vim.lsp.get_active_clients()

	-- Stop each client
	for _, client in ipairs(active_clients) do
		vim.lsp.stop_client(client.id, true)
		vim.notify("Stopped LSP: " .. client.name, vim.log.levels.INFO)
	end

	-- Clear diagnostics
	vim.diagnostic.reset()

	vim.notify("All LSP clients stopped and diagnostics cleared", vim.log.levels.INFO)
end, {})
