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
    local cmd_saved = cmd
    terms[name] = require('toggleterm.terminal').Terminal:new(vim.tbl_extend('force', opts, {
      on_open = function(term)
        vim.keymap.set('t', '<C-\\><C-\\>', function()
          M.open(cmd_saved)
        end, { buffer = term.bufnr, noremap = true })
      end,
    }))
  end

  terms[name]:toggle()
end

function M.shell()
  M.open(nil)
end

return M
