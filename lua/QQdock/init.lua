-- QQdock.nvim — Persistent adaptive terminal dock
--
-- 特性：持久化终端实例、自适应窗口方向（横屏右分屏/竖屏下分屏）、依赖 toggleterm.nvim
--
-- 用法：
--   local Q = require('QQdock')
--   Q.shell()                -- 打开/关闭普通 shell
--   Q.open('reasonix')       -- 打开/关闭 Reasonix
--   Q.open('lazygit')        -- 打开/关闭 lazygit

local M = {}

local terms = {}  -- 缓存终端实例，key 是命令名（nil = 普通 shell）

function M.open(cmd)
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return
  end
  local tall = ui.height > ui.width
  local name = cmd or '__shell__'

  if not terms[name] or not terms[name]:is_open() then
    terms[name] = require('toggleterm.terminal').Terminal:new({
      direction = tall and 'horizontal' or 'vertical',
      cmd = cmd,
      size = tall and math.floor(ui.height * 0.4) or math.floor(ui.width * 0.45),
    })
  end

  terms[name]:toggle()
end

function M.shell()
  M.open(nil)
end

return M
