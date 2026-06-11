# QQdock.nvim

持久化自适应浮动终端管理器。

每次按 `<c-t>` 打开 shell，聊完 Reasonix 按 `<C-i>` 隐藏，再按回来——对话还在。横屏自动右侧分屏，竖屏自动下方分屏。

## 安装

```lua
-- lazy.nvim
{
  'newbie/QQdock.nvim',
  dependencies = { 'akinsho/toggleterm.nvim' },
  config = function()
    -- QQdock 无全局配置，直接用
  end,
}
```

## 用法

```lua
local Q = require('QQdock')

Q.shell()                -- 普通 shell
Q.open('reasonix')       -- Reasonix AI agent
Q.open('lazygit')        -- lazygit
Q.open('btm')            -- 系统监控
Q.open('yazi')           -- 文件管理器
```

## 推荐键位

```lua
vim.keymap.set({ 'n', 'i' }, '<c-t>',      Q.shell, { noremap = true })
vim.keymap.set('n',          '<C-i>',       function() Q.open('reasonix') end)
vim.keymap.set('n',          '<leader>gg',  function() Q.open('lazygit') end)
```

## API

| 函数 | 参数 | 作用 |
|------|------|------|
| `Q.shell()` | — | 打开/关闭持久 shell |
| `Q.open(cmd)` | cmd | 打开/关闭指定命令的持久终端 |

## 特性

- **持久化** — toggle 显隐，终端状态保留
- **自适应** — 横屏右侧分屏，竖屏下方分屏（toggleterm 默认尺寸）
- **轻量** — 仅依赖 toggleterm.nvim，无其他依赖

## TODO

- [ ] 翻译（trans）
- [ ] 系统监控（btop）
- [ ] 文件管理器（yazi）

## 协议

MIT
