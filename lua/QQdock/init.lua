-- QQdock.nvim — Persistent adaptive terminal dock
--
-- 特性：持久化终端实例、自适应窗口方向（横屏右分屏/竖屏下分屏）、基于 Neovim 原生终端
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
    horizontal = nil, -- nil = 基于当前窗口高度动态计算
    vertical = nil, -- nil = 基于当前窗口宽度动态计算
  },
  keymaps = {},
  commands = {
    reasonix = 'reasonix',
    lazygit = 'lazygit',
  },
  debug = false,
}

---@class QdockTerm
---@field bufnr          integer
---@field winid          integer?
---@field job_id         integer
---@field cmd            string?
---@field borrowed       boolean?
---@field original_bufnr integer?

---@type table<string, QdockTerm>
local terms = {} -- 缓存终端实例，key 是命令名（nil = 普通 shell  → '__shell__'）

--- 基于当前窗口宽高返回 { direction, size }
---@return string direction  -- 'horizontal' | 'vertical'
---@return integer size
local function get_layout()
  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)

  -- 足够宽且宽度明显大于高度 → 右侧分屏
  if width >= 110 and width > height * 2 then
    local size = config.size.vertical or math.floor(width * 0.4)
    return 'vertical', size
  end

  -- 否则下方分屏
  local size = config.size.horizontal or math.max(10, math.floor(height * 0.35))
  return 'horizontal', size
end

---@param opts { size?: { horizontal?: integer, vertical?: integer }, keymaps?: table, commands?: table, debug?: boolean }
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})

  -- 防止 toggleterm 侧残留配置干扰（persist_size 默认 true，显式关掉）
  pcall(function()
    require('toggleterm').setup({ persist_size = false })
  end)

  -- 注册键位
  local km = config.keymaps
  local function safe_map(mode, lhs, fn)
    if mode and lhs and fn then
      vim.keymap.set(mode, lhs, fn, { noremap = true })
    end
  end
  if km.shell then
    safe_map(km.shell[1], km.shell[2], M.shell)
  end
  if km.shell_i then
    safe_map(km.shell_i[1], km.shell_i[2], M.shell)
  end
  if km.reasonix then
    safe_map(km.reasonix[1], km.reasonix[2], function()
      local cmd = config.commands.reasonix
      M.open(type(cmd) == 'function' and cmd() or cmd)
    end)
  end
  if km.lazygit then
    safe_map(km.lazygit[1], km.lazygit[2], function()
      local cmd = config.commands.lazygit
      M.open(type(cmd) == 'function' and cmd() or cmd)
    end)
  end
end

--- 打开/关闭持久终端
---@param cmd string? 要执行的命令，nil 表示普通 shell
function M.open(cmd)
  local name = cmd or '__shell__'
  local term = terms[name]

  -- 已打开 → 关闭/隐藏，终端进程继续
  if term and term.winid and vim.api.nvim_win_is_valid(term.winid) then
    if config.debug then
      vim.notify('QQdock: hide [' .. name .. ']', vim.log.levels.INFO)
    end
    if term.borrowed then
      -- 占了主窗口 → 换回原始空 buffer
      vim.api.nvim_win_set_buf(term.winid, term.original_bufnr)
    else
      vim.api.nvim_win_close(term.winid, true)
    end
    term.winid = nil
    term.borrowed = nil
    return
  end

  -- 需要打开 → 基于当前窗口计算布局
  local direction, size = get_layout()

  -- 检测当前窗口是否是空 buffer（没打开文件时直接占主窗口）
  local current_buf = vim.api.nvim_get_current_buf()
  local use_main = vim.api.nvim_buf_get_name(current_buf) == ''
    and vim.bo[current_buf].buftype == ''
    and not vim.bo[current_buf].modified

  if config.debug then
    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)
    local mode = use_main and 'main' or direction
    vim.notify(
      string.format('QQdock: %dx%d → %s %d [%s]', width, height, mode, size, name),
      vim.log.levels.INFO
    )
  end

  local winid
  if use_main then
    -- 没打开文件 → 直接占用当前主窗口
    winid = vim.api.nvim_get_current_win()
  else
    -- 基于当前窗口局部分屏（rightbelow，非 botright）
    if direction == 'vertical' then
      vim.cmd('rightbelow ' .. size .. 'vsplit')
    else
      vim.cmd('rightbelow ' .. size .. 'split')
    end
    winid = vim.api.nvim_get_current_win()

    -- 设置窗口固定尺寸，防止其他 split 操作挤压终端窗口
    if direction == 'vertical' then
      vim.wo[winid].winfixwidth = true
    else
      vim.wo[winid].winfixheight = true
    end
  end

  -- 已有 buffer → 放入窗口
  if term and term.bufnr and vim.api.nvim_buf_is_valid(term.bufnr) then
    vim.api.nvim_win_set_buf(winid, term.bufnr)
    term.winid = winid
    if use_main then
      term.borrowed = true
      term.original_bufnr = current_buf
    end
    vim.cmd('startinsert')
    return
  end

  -- 全新创建 terminal buffer
  local bufnr = vim.api.nvim_create_buf(false, true) -- not listed, scratch
  vim.api.nvim_win_set_buf(winid, bufnr)
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].bufhidden = 'hide' -- 关闭窗口时保留 buffer，进程继续

  -- 启动终端进程
  local job_id = vim.fn.termopen(cmd or vim.o.shell, { detach = 1 })

  -- 缓存实例
  local term_data = { bufnr = bufnr, winid = winid, job_id = job_id, cmd = cmd }
  if use_main then
    term_data.borrowed = true
    term_data.original_bufnr = current_buf
  end
  terms[name] = term_data

  -- <C-\><C-\> 隐藏当前终端窗口
  vim.keymap.set('t', '<C-\\><C-\\>', function()
    M.open(cmd)
  end, { buffer = bufnr, noremap = true })

  -- 进程退出时清理缓存和 buffer
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = bufnr,
    once = true,
    callback = function()
      terms[name] = nil
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end,
  })

  vim.cmd('startinsert')
end

--- 打开/关闭普通 shell（无自定义命令）
function M.shell()
  M.open(nil)
end

return M
