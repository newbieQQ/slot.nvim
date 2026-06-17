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
--     keymaps = {
--       shell    = { 'n', '<c-t>'        },  -- 普通终端
--       shell_i  = { 'i', '<c-t>'        },  -- 插入模式也开终端
--       reasonix = { 'n', '<C-i>'        },  -- Reasonix
--       lazygit  = { 'n', '<leader>gg'   },  -- lazygit
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
  keymaps = {},
  commands = {
    reasonix = 'reasonix',
    lazygit  = 'lazygit',
  },
}

local terms = {}  -- 缓存终端实例，key 是命令名（nil = 普通 shell）

--- 基于当前窗口宽高返回 { direction, size }
---@return string direction  -- 'horizontal' | 'vertical'
---@return integer size
local function get_layout()
  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)

  -- 足够宽且宽度大于高度 2 倍 -> 右侧分屏
  if width >= 110 and width > height * 2 then
    local size = config.size.vertical or math.floor(width * 0.4)
    return 'vertical', size
  end

  -- 否则下方分屏
  local size = config.size.horizontal or math.max(10, math.floor(height * 0.35))
  return 'horizontal', size
end

---@param opts { size?: { horizontal?: integer, vertical?: integer }, keymaps?: table, commands?: table }
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})

  -- 注册键位
  local km = config.keymaps
  local function safe_map(mode, lhs, fn)
    if mode and lhs and fn then
      vim.keymap.set(mode, lhs, fn, { noremap = true })
    end
  end
  if km.shell    then safe_map(km.shell[1],    km.shell[2],    M.shell) end
  if km.shell_i  then safe_map(km.shell_i[1],  km.shell_i[2],  M.shell) end
  if km.reasonix then safe_map(km.reasonix[1], km.reasonix[2], function()
    local cmd = config.commands.reasonix
    M.open(type(cmd) == 'function' and cmd() or cmd)
  end) end
  if km.lazygit  then safe_map(km.lazygit[1],  km.lazygit[2],  function()
    local cmd = config.commands.lazygit
    M.open(type(cmd) == 'function' and cmd() or cmd)
  end) end
end

function M.open(cmd)
  local direction, size = get_layout()
  local name = cmd or '__shell__'
  local opts = {
    direction = direction,
    size = size,
    cmd = cmd,
    persist_size = false,  -- 不记忆旧尺寸，每次 toggle 使用最新值
    hidden = true,         -- 隐藏时进程继续跑，toggle() 只切显隐
  }

  if not terms[name] then
    local cmd_saved = cmd
    terms[name] = require('toggleterm.terminal').Terminal:new(vim.tbl_extend('force', opts, {
      on_open = function(term)
        vim.keymap.set('t', '<C-\\><C-\\>', function()
          M.open(cmd_saved)
        end, { buffer = term.bufnr, noremap = true })
      end,
    }))
  end

  -- 每次 toggle 传入最新方向/尺寸，确保分屏后重新计算
  terms[name]:toggle(size, direction)
end

function M.shell()
  M.open(nil)
end

return M
