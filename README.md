# hyprland dots

当前桌面环境配置的 dotfiles 仓库。

包含内容：
- Hyprland
- Caelestia + Quickshell
- Kitty 和 Foot
- Fuzzel + XDG menus
- Fish + Starship
- Fastfetch
- Fcitx5
- UWSM
- btop
- 当前壁纸

目录映射：
- `config/` maps to `~/.config/`
- `pictures/` maps to `~/Pictures/`

快速开始（Arch 系）：

```bash
git clone git@github.com:aliom-v/hyprland-dots.git
cd hyprland-dots
bash ./install.sh --dry-run
bash ./install.sh
```

如果仓库已经在本地，只需要执行后两条命令。

安装脚本会做这些事：
- 从 `packages/pacman.txt` 安装官方仓库依赖
- 如果缺少 `yay`，自动引导安装
- 从 `packages/aur.txt` 安装 AUR 依赖
- 把 dotfiles 链接到 `~/.config` 和 `~/Pictures`
- 初始化 `~/.local/state/caelestia` 里的壁纸和主题状态

常用参数：
- `--skip-deps`：只链接配置，不安装依赖
- `--deps-only`：只安装依赖，不链接配置
- `--dry-run`：只打印将要执行的操作，不改动系统

Notes:
- 依赖安装部分目前面向 Arch 系
- 如果不是 Arch 系，使用 `bash ./install.sh --skip-deps`，然后手动安装需要的软件
- 脚本会覆盖这个仓库里实际用到的 shell、运行时和桌面依赖
- 像 `brave`、`code` 这种个人应用选择仍然需要你自己决定

这个仓库会管理：
- `~/.config/hypr`
- `~/.config/caelestia`
- `~/.config/quickshell`
- `~/.config/kitty`
- `~/.config/foot`
- `~/.config/fuzzel`
- `~/.config/fish`
- `~/.config/fastfetch`
- `~/.config/menus`
- `~/.config/fcitx5`
- `~/.config/uwsm`
- `~/.config/btop`
- `~/.config/starship.toml`
- `~/Pictures/Wallpapers/1358147.png`

有意不纳管的内容：
- `fish_variables`
- `fcitx5/conf/cached_layouts`
- 应用数据、缓存、通知历史、launcher 数据库，以及其他会频繁变化的运行时状态
- 当前未使用的配置，比如 Waybar

Notes:
- `install.sh` 在建立软链接之前，会先把已有目标移动到 `~/.dots-backups/<timestamp>/`
- 这个仓库本质上是当前机器配置的一份快照；如果你后续修改了本地配置，需要再同步回仓库
- 机器专属覆盖配置应该放到 git 忽略的文件里：
  `~/.config/caelestia/hypr-user.local.conf`
  `~/.config/caelestia/hypr-execs.local.conf`
