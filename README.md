# slot.nvim

持久化自适应终端 Dock — 无外部依赖，基于 Neovim 原生终端。

像电脑扩展槽一样：每个命令（shell、reasonix、lazygit、codex…）占用一个 slot，toggle 切换显隐，进程不中断。

横屏自动右侧分屏，竖屏自动下方分屏。没打开文件时直接占用主窗口。`<C-\><C-\>` 隐藏，对话还在。

## 安装

```lua
-- lazy.nvim
{
  'newbieQQ/slot.nvim',
  url = 'https://github.com/newbieQQ/slot.nvim',
  config = function()
    require('slot').setup({
      size = {
        horizontal = 10,   -- 竖屏下方终端高度（行数，nil = 自动）
        vertical   = 40,   -- 横屏右侧终端宽度（列数，nil = 自动）
      },
      commands = {
        reasonix = 'reasonix',
        lazygit  = 'lazygit',
      },
      keymaps = {
        shell    = { 'n', '<c-t>'        },
        shell_i  = { 'i', '<c-t>'        },
        reasonix = { 'n', '<C-i>'        },
        lazygit  = { 'n', '<leader>gg'   },
      },
    })
  end,
}
```

## 自定义命令 & 快捷键

添加新工具只需在 `commands` 和 `keymaps` 各加一行，键名一致即可：

```lua
require('slot').setup({
  commands = {
    reasonix = 'reasonix',
    lazygit  = 'lazygit',
    codex    = 'codex',                     -- 新增工具
    btop     = 'btop',
  },
  keymaps = {
    shell    = { 'n', '<c-t>'        },
    shell_i  = { 'i', '<c-t>'        },
    reasonix = { 'n', '<C-i>'        },
    lazygit  = { 'n', '<leader>gg'   },
    codex    = { 'n', '<leader>cx'   },     -- 新增快捷键
    btop     = { 'n', '<leader>bt'   },
  },
})
```

`commands` 的值也支持函数（lazy eval）：

```lua
commands = {
  reasonix = function()
    return vim.fn.expand('$HOME') .. '/.local/bin/reasonix'
  end,
}
```

不想用某个功能就不写对应字段。完全不传 `keymaps` 则不注册任何快捷键，可手动绑定：

```lua
local S = require('slot')
vim.keymap.set('n', '<leader>s', S.shell, { noremap = true })
vim.keymap.set('n', '<leader>r', function() S.open('reasonix') end)
vim.keymap.set('n', '<leader>cx', function() S.open('codex') end)
```

## 终端内隐藏键

所有终端内按 **`<C-\><C-\>`**（双击 Ctrl+\\）隐藏回代码，不影响 TUI 程序。

## 分屏逻辑

| 场景 | 行为 |
|------|------|
| 刚打开 Neovim，没加载文件 | 终端直接占用主窗口（不 split） |
| 宽屏（≥110 列，宽度 > 高度×2） | 右侧 `vsplit`，宽度 40% |
| 竖屏 / 普通窗口 | 下方 `split`，高度 35%（最低 10 行） |
| 分屏基于**当前窗口**（rightbelow），不干扰其他窗口布局 | |

设置 `debug = true` 可在 `:messages` 里看到每次的布局决策。

## API

| 函数 | 参数 | 作用 |
|------|------|------|
| `S.setup(opts)` | opts | 配置尺寸、快捷键、命令映射 |
| `S.shell()` | — | 打开/关闭持久 shell |
| `S.open(cmd)` | cmd | 打开/关闭指定命令的持久终端 |

### setup 参数

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `size.horizontal` | number | nil | 竖屏下方终端高度（行数，nil = 自动） |
| `size.vertical` | number | nil | 横屏右侧终端宽度（列数，nil = 自动） |
| `commands` | table | `{reasonix, lazygit}` | 工具命令映射，key 匹配 keymaps |
| `keymaps.shell` | {mode, key} | — | 普通终端快捷键 |
| `keymaps.shell_i` | {mode, key} | — | 插入模式开终端 |
| `keymaps.<name>` | {mode, key} | — | 对应 commands 里同名工具快捷键 |
| `debug` | boolean | false | 开启布局调试日志 |

## 特性

- **零外部依赖** — 基于 `vim.fn.termopen` 原生终端
- **持久化** — toggle 显隐，终端进程不中断
- **自适应布局** — 横屏右分、竖屏下分、无文件占主窗
- **单文件** — `lua/slot/init.lua` ~220 行

## 协议

MIT
