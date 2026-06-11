# QQdock.nvim

持久化自适应浮动终端管理器。

每次按 `<c-t>` 打开 shell，聊完 Reasonix 按 `<C-i>` 隐藏，再按回来——对话还在。横屏自动右侧分屏，竖屏自动下方分屏。

## 安装

```lua
-- lazy.nvim
{
  'newbie/QQdock.nvim',
  url = 'https://git.qyhhh.top/newbie/QQdock.nvim',
  dependencies = { 'akinsho/toggleterm.nvim' },
  config = function()
    require('QQdock').setup({
      -- 可选：自定义尺寸
      size = {
        horizontal = 10,
        vertical = 40,
      },
      -- 可选：自定义快捷键（不传则无默认，需自己手动注册）
      keymaps = {
        shell    = { 'n', '<c-t>'      },
        shell_i  = { 'i', '<c-t>'      },
        reasonix = { 'n', '<C-i>'      },
        lazygit  = { 'n', '<leader>gg' },
      },
    })
  end,
}
```

## 自定义快捷键

`keymaps` 表里的每个字段格式是 `{ mode, lhs }`。想换键就改，不想用某个功能就不传那个字段。例如只用 shell 和 lazygit，不要 Reasonix：

```lua
require('QQdock').setup({
  keymaps = {
    shell   = { 'n', '<c-t>'      },
    shell_i = { 'i', '<c-t>'      },
    lazygit = { 'n', '<leader>gg' },
    -- reasonix 不写 → 不注册快捷键
  },
})
```

想用 `<leader>ft` 开终端：

```lua
require('QQdock').setup({
  keymaps = {
    shell = { 'n', '<leader>ft' },
    -- …
  },
})
```

**不传 `keymaps` 则不注册任何快捷键**，你可以完全手动绑定：

```lua
local Q = require('QQdock')
vim.keymap.set('n', '<leader>s', Q.shell, { noremap = true })
vim.keymap.set('n', '<leader>r', function() Q.open('reasonix') end)
```

## 终端内隐藏键

所有终端内按 **`<C-\><C-\>`**（双击 Ctrl+\）隐藏回代码，不影响 TUI 程序。

## 用法

```lua
local Q = require('QQdock')

Q.shell()                -- 普通 shell
Q.open('reasonix')       -- Reasonix AI agent
Q.open('lazygit')        -- lazygit
Q.open('btm')            -- 系统监控
Q.open('yazi')           -- 文件管理器
```

## API

| 函数 | 参数 | 作用 |
|------|------|------|
| `Q.setup(opts)` | opts | 配置尺寸、快捷键、命令映射 |
| `Q.shell()` | — | 打开/关闭持久 shell |
| `Q.open(cmd)` | cmd | 打开/关闭指定命令的持久终端 |

### setup 参数

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `size.horizontal` | number | nil | 竖屏下方终端高度 |
| `size.vertical` | number | nil | 横屏右侧终端宽度 |
| `keymaps.shell` | { mode, key } | — | 普通终端快捷键 |
| `keymaps.shell_i` | { mode, key } | — | 插入模式开终端 |
| `keymaps.reasonix` | { mode, key } | — | Reasonix 快捷键 |
| `keymaps.lazygit` | { mode, key } | — | lazygit 快捷键 |
| `commands.reasonix` | string | `"reasonix"` | Reasonix 启动命令 |
| `commands.lazygit` | string | `"lazygit"` | lazygit 启动命令 |

## 特性

- **持久化** — toggle 显隐，终端状态保留
- **自适应** — 横屏右侧分屏，竖屏下方分屏
- **轻量** — 仅依赖 toggleterm.nvim

## TODO

- [ ] 翻译（trans）
- [ ] 系统监控（btop）
- [ ] 文件管理器（yazi）

## 协议

MIT
