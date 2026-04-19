local Git = require("lazy.manage.git")
local Util = require("lazy.util")

local M = {}

---@param plugin LazyPlugin
---@param diff LazyDiff
---@return boolean
local function is_upstream_compare(plugin, diff)
  return not not (plugin.upstream and diff.url and diff.url == Git.get_url(plugin, "upstream"))
end

---@alias LazyDiff {commit:string, url?:string} | {from:string, to:string, url?:string}
---@alias LazyDiffFun fun(plugin:LazyPlugin, diff:LazyDiff)

M.handlers = {

  ---@type LazyDiffFun
  browser = function(plugin, diff)
    local remote = diff.url or plugin.url
    if remote then
      local url = remote:gsub("%.git$", "")
      if diff.commit then
        Util.open(url .. "/commit/" .. diff.commit)
      else
        local dots = is_upstream_compare(plugin, diff) and "..." or ".."
        Util.open(url .. "/compare/" .. diff.from .. dots .. diff.to)
      end
    else
      Util.error("No url for " .. plugin.name)
    end
  end,

  ---@type LazyDiffFun
  ["diffview.nvim"] = function(plugin, diff)
    local args
    if diff.commit then
      args = ("-C=%s"):format(plugin.dir) .. " " .. diff.commit .. "^!"
    else
      args = ("-C=%s"):format(plugin.dir) .. " " .. diff.from .. ".." .. diff.to
    end
    vim.cmd("DiffviewOpen " .. args)
  end,

  ---@type LazyDiffFun
  git = function(plugin, diff)
    local cmd = { "git" }
    if diff.commit then
      cmd[#cmd + 1] = "show"
      cmd[#cmd + 1] = diff.commit
    else
      cmd[#cmd + 1] = "diff"
      cmd[#cmd + 1] = diff.from
      cmd[#cmd + 1] = diff.to
    end
    Util.float_cmd(cmd, { cwd = plugin.dir, filetype = "git" })
  end,

  ---@type LazyDiffFun
  terminal_git = function(plugin, diff)
    local cmd = { "git" }
    if diff.commit then
      cmd[#cmd + 1] = "show"
      cmd[#cmd + 1] = diff.commit
    else
      cmd[#cmd + 1] = "diff"
      cmd[#cmd + 1] = diff.from
      cmd[#cmd + 1] = diff.to
    end
    Util.float_term(cmd, { cwd = plugin.dir, interactive = false, env = { PAGER = "cat" } })
  end,
}

return M
