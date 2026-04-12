local core = require("popui/core")

gitNavigatorState = {
	currentFileName = nil,
	currentCommitIndex = nil,
	allFileCommits = nil,
}

local function isCurrentFileInWorkTree()
	local filePath = vim.api.nvim_exec("echo expand('%:p')", true)

	if filePath == nil or filePath == "" then
		return false
	end

	if string.find(filePath, ".git/") then
		return false
	end

	local lines = vim.api.nvim_exec("!git rev-parse --is-inside-work-tree", true)

	return vim.split(lines, "\n")[3] == "true"
end

-- Returns a list of commit objects: { hash, short_hash, message, author, date }
local function getAllFileCommits()
	local filePath = vim.api.nvim_exec("echo expand('%:p')", true)
	local sep = "\x1f" -- unit separator as field delimiter
	local fmt = "%H" .. sep .. "%h" .. sep .. "%s" .. sep .. "%an" .. sep .. "%ad"
	local raw = vim.fn.systemlist(
		"git log --follow --date=short --pretty=format:" .. vim.fn.shellescape(fmt) .. " -- " .. vim.fn.shellescape(filePath)
	)

	local commits = {}
	for _, line in ipairs(raw) do
		local parts = vim.split(line, sep, { plain = true })
		if #parts == 5 then
			table.insert(commits, {
				hash      = parts[1],
				short_hash = parts[2],
				message   = parts[3],
				author    = parts[4],
				date      = parts[5],
			})
		end
	end
	return commits
end

local function updateGitNavigatorState()
	if not isCurrentFileInWorkTree() then
		return
	end

	gitNavigatorState.currentFileName = vim.api.nvim_exec("echo expand('%:p')", true)
	gitNavigatorState.currentCommitIndex = 1
	gitNavigatorState.allFileCommits = nil -- lazy-load when needed
end

-- Get the current commit hash.
local function getCurrentCommitHash()
	local currentFileHash = vim.api.nvim_exec("!git rev-parse HEAD", true)
	return vim.split(currentFileHash, "\n")[3]
end

local function getPreviousFileRevision(state)
	local allFileCommits = state.allFileCommits
	local currentCommitIndex = state.currentCommitIndex

	if currentCommitIndex >= #allFileCommits then
		return getCurrentCommitHash()
	end

	local newIndex = currentCommitIndex + 1
	gitNavigatorState.currentCommitIndex = newIndex

	return allFileCommits[newIndex]
end

local function getNextFileRevision(state)
	local allFileCommits = state.allFileCommits
	local currentCommitIndex = state.currentCommitIndex

	if currentCommitIndex <= 1 then
		return getCurrentCommitHash()
	end

	local newIndex = currentCommitIndex - 1
	gitNavigatorState.currentCommitIndex = newIndex

	return allFileCommits[newIndex]
end

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		updateGitNavigatorState()
	end,
})

vim.keymap.set("n", "gj", function()
	if not isCurrentFileInWorkTree() then
		print("Not in a git work tree.")
		return
	end

	-- Lazily load hashes for the old-style navigation
	if gitNavigatorState.allFileCommits == nil then
		local commits = getAllFileCommits()
		local hashes = {}
		for _, c in ipairs(commits) do
			table.insert(hashes, c.hash)
		end
		gitNavigatorState.allFileCommits = hashes
	end

	local previousCommitHash = getPreviousFileRevision(gitNavigatorState)
	local currentHash = getCurrentCommitHash()

	if previousCommitHash == currentHash then
		print("No previous commit found.")
		return
	end

	local buffer = vim.api.nvim_get_current_buf()
	vim.api.nvim_exec("Gedit " .. previousCommitHash .. ":" .. gitNavigatorState.currentFileName, true)
	vim.api.nvim_buf_delete(buffer, { force = true })
end, { noremap = true, silent = false })

vim.keymap.set("n", "gk", function()
	if not isCurrentFileInWorkTree() then
		print("Not in a git work tree.")
		return
	end

	if gitNavigatorState.allFileCommits == nil then
		local commits = getAllFileCommits()
		local hashes = {}
		for _, c in ipairs(commits) do
			table.insert(hashes, c.hash)
		end
		gitNavigatorState.allFileCommits = hashes
	end

	local nextCommitHash = getNextFileRevision(gitNavigatorState)
	local currentHash = getCurrentCommitHash()

	if nextCommitHash == currentHash then
		print("No next commit found.")
		return
	end

	local buffer = vim.api.nvim_get_current_buf()
	vim.api.nvim_exec("Gedit " .. nextCommitHash .. ":" .. gitNavigatorState.currentFileName, true)
	vim.api.nvim_buf_delete(buffer, { force = true })
end, { noremap = true, silent = true })

-- Open a popup listing all commits for the current buffer. Selecting one
-- opens the file at that commit's state via Gedit.
local gitNavigator = function()
	if not isCurrentFileInWorkTree() then
		print("Not in a git work tree.")
		return
	end

	local filePath = vim.api.nvim_exec("echo expand('%:p')", true)
	local commits = getAllFileCommits()

	if #commits == 0 then
		print("No commits found for this file.")
		return
	end

	local entries = {}
	for _, commit in ipairs(commits) do
		table.insert(
			entries,
			commit.message .. " (" .. commit.short_hash .. "), by " .. commit.author .. " at " .. commit.date
		)
	end

	-- Register a new window type for the git navigator
	if not core.WindowTypes.GitNavigator then
		core.WindowTypes.GitNavigator = "git-navigator"
	end

	core:spawnListPopup(
		core.WindowTypes.GitNavigator,
		"Git History",
		entries,
		function(lineNumber, _)
			local chosen = commits[lineNumber]
			if not chosen then
				return
			end
			local buffer = vim.api.nvim_get_current_buf()
			vim.api.nvim_exec("Gedit " .. chosen.hash .. ":" .. filePath, true)
			vim.api.nvim_buf_delete(buffer, { force = true })
		end,
		vim.g.popui_border_style
	)
end

return gitNavigator
