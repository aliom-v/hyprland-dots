# hyprland dots

项目简介：

这是一个基于上游项目 [`caelestia-dots/caelestia`](https://github.com/caelestia-dots/caelestia) 二次修改的个人 Hyprland dotfiles 仓库，支持配置级一键安装与一键回滚。
仓库围绕 Hyprland、Caelestia 和 Quickshell 组织，同时整合了终端、启动器、输入法、主题状态和常用运行时配置，用于在换机、重装系统或新设备初始化时，尽快恢复到接近当前机器的桌面环境。

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
- `config/` 对应 `~/.config/`
- `pictures/` 对应 `~/Pictures/`

一键安装（Arch 系）：

仓库内置一键安装脚本 [install.sh](./install.sh)，可以直接完成依赖安装、软链接建立和初始状态写入。

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

一键卸载：

如果不想继续使用这套配置，可以先预览，再执行卸载：

```bash
bash ./install.sh --dry-run --uninstall
bash ./install.sh --uninstall
```

卸载会做这些事：
- 按“上一次安装”记录恢复已备份的文件和目录
- 删除仍然指向这个仓库的软链接
- 清理安装脚本首次写入的初始状态文件
- 移除安装状态记录 `~/.local/state/hyprland-dots/last-install.sh`

说明：
- 当前卸载不会自动删除通过脚本安装的软件包
- 如果是旧版脚本安装的，没有安装状态记录，`--uninstall` 会按最近一次 `~/.dots-backups/<timestamp>/` 和默认初始化内容尽量回滚

说明：
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

说明：
- `install.sh` 在建立软链接之前，会先把已有目标移动到 `~/.dots-backups/<timestamp>/`
- `install.sh` 会把最近一次安装记录写到 `~/.local/state/hyprland-dots/last-install.sh`，供 `--uninstall` 回滚
- 这个仓库本质上是当前机器配置的一份快照；如果你后续修改了本地配置，需要再同步回仓库
- 机器专属覆盖配置应该放到 git 忽略的文件里：
  `~/.config/caelestia/hypr-user.local.conf`
  `~/.config/caelestia/hypr-execs.local.conf`

项目致谢：

这个仓库建立在多个优秀开源项目之上，当前桌面环境和使用体验直接受益于这些项目：
- [`caelestia-dots/caelestia`](https://github.com/caelestia-dots/caelestia)
- Hyprland
- Quickshell
- Caelestia
- UWSM
- Fcitx5
- Kitty
- Foot
- Fish
- Starship
- Fastfetch
- btop
- Fuzzel

感谢这些项目的开发者和贡献者。
其中，本仓库整体思路和一部分配置结构直接参考并继承自 `caelestia-dots/caelestia`，其余部分则是在此基础上的个人整理、替换和调整。
