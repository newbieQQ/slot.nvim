-- QQdock.nvim — Persistent adaptive terminal dock
--
-- 特性：持久化终端实例、自适应窗口方向（横屏右分屏/竖屏下分屏）、依赖 toggleterm.nvim
--
-- 配置（可选）：
--   require('QQdock').setup({
--     size = {
--       horizontal = 10,  -- 竖屏下方终端高度（行数）
--       vertical = 40,    -- 横屏右侧终端宽度（列数）
--     },
--   })
--
-- 用法：
--   local Q = require('QQdock')
--   Q.shell()                -- 打开/关闭普通 shell
--   Q.open('reasonix')       -- 打开/关闭 Reasonix
--   Q.open('lazygit')        -- 打开/关闭 lazygit

local M = {}

local config = {
  size = {
    horizontal = nil,  -- nil = toggleterm 默认值
    vertical = nil,
  },
}

local terms = {}  -- 缓存终端实例，key 是命令名（nil = 普通 shell）

---@param opts { size?: { horizontal?: integer, vertical?: integer } }
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
end

function M.open(cmd)
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return
  end
  local tall = ui.height > ui.width
  local name = cmd or '__shell__'
  local opts = {
    direction = tall and 'horizontal' or 'vertical',
    cmd = cmd,
    hidden = true,  -- 隐藏时进程继续跑，toggle() 只切显隐
  }
  local sz = tall and config.size.horizontal or config.size.vertical
  if sz then
    opts.size = sz
  end

  if not terms[name] then
    terms[name] = require('toggleterm.terminal').Terminal:new(vim.tbl_extend('force', opts, {
      on_open = function(term)
        vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { buffer = term.bufnr, noremap = true })
      end,
    }))
  end

  terms[name]:toggle()
end

function M.shell()
  M.open(nil)
end

return M
