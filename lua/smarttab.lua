local M = {}

---@class SmartTabConfig
---@field skips (string|fun(node_type: string):boolean)[]
---@field mapping string|boolean
local configs = {
    skips = { "string_content" },
    mapping = "<tab>",
}

local function is_blank_line()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col == 0 or vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:match("%S") == nil
end

---@param node_type string
local function should_skip(node_type)
    for _, skip in ipairs(configs.skips) do
        if type(skip) == "string" and skip == node_type then
            return true
        elseif type(skip) == "function" and skip(node_type) then
            return true
        end
    end
    return false
end

local function smart_tab()
    local node = vim.treesitter.get_node()
    if not node then
        return
    end
    while should_skip(node:type()) do
        node = node:parent()
    end
    local row, col = node:end_()
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

-- NOTE: this allows cursor movement on expr mapping
vim.keymap.set("i", "<plug>(smarttab)", smart_tab)

---setup smarttab plugin
---@param opts? SmartTabConfig
function M.setup(opts)
    opts = opts or {}
    configs = vim.tbl_extend("force", configs, opts)
    if configs.mapping then
        vim.keymap.set("i", "<tab>", function()
            local non_treesitter = not pcall(vim.treesitter.get_node)
            if non_treesitter or is_blank_line() then
                return "<tab>"
            else
                return "<plug>(smarttab)"
            end
        end, { desc = "smarttab", expr = true })
    end
end

return M