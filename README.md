# 美版 Galaxy S25 Edge + 中国移动 5G 恢复包

[![Verify release files](https://github.com/zerbLion/s25edge-usa/actions/workflows/verify.yml/badge.svg)](https://github.com/zerbLion/s25edge-usa/actions/workflows/verify.yml)

这套文件用于 **SM-S937U / SM-S937U1** 在系统或 CSC 更新后，重复恢复三星 Service Mode 里的 5G 设置。它不 Root、不解锁 Bootloader、不刷机、不改 CSC，也不会执行恢复出厂设置。

> 已再次实机验证（2026-09-10）：SM-S937U1、XAA、Android 16、2026-08-05 安全补丁、固件 `S937U1UES9CZF9`。执行核心设置并重启后，无线属性由 `LTE,LTE` 变为 `NR_SA,LTE`，SIM 1 已驻留中国移动 5G SA。最初验证的 `S937U1UES8CZF5` 也保留在归档中。

## 最快用法

1. 手机保持解锁，打开“设置 → 开发者选项 → USB 调试”。
2. 用数据线连接电脑；首次连接时在手机上勾选“始终允许”，再点“允许”。
3. 双击 `check-device.cmd`。确认显示的型号是 `SM-S937U` 或 `SM-S937U1`。
4. 双击 `run-recovery.cmd`。一键入口会在型号校验通过后直接开始，不再要求输入 `YES`。
5. 脚本会通过 ADB 打开三星 Service Mode，按屏幕文字执行核心设置，然后重启并检查当前网络类型。
6. 到中国移动 5G 覆盖良好的室外位置，关掉 Wi‑Fi，再双击 `verify-5g.cmd`。

如果手机连稳定充电都做不到，先不要运行恢复入口，按 [USB 半连接 / 不充电恢复](docs/usb-connection-recovery.md) 排查。

如果中国移动卡放在 SIM 2，不要双击默认入口；在本目录打开 PowerShell 后运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\03-recover-5g-after-update.ps1 -SimSlot 2
```

## 自动恢复的核心项

1. `SET DEFAULT LTE BAND`
2. `REMOVE NR5G PRUNE`
3. `REMOVE ONLY NR WHITELIST`
4. `SA/NSA ENABLE`
5. `REMOVE SA PERMIT LIST`
6. 仅 SIM 2 时先 `SELECT STACK 2`

这些项目对应截图中真正影响美版机在非美国运营商网络使用 NR 的核心路径。脚本每次都重新从 Service Mode 主菜单进入，避免依赖返回键和固定屏幕坐标。

## 为什么不是一条 `adb settings put` 命令

三星的 `NR5G PRUNE`、`NR whitelist` 和 `SA permit list` 是基带/CP 的工程配置，不是 Android 公共 Settings 数据库中的普通开关。未 Root 的普通 ADB 没有一个可靠、公开的键能直接写它们。网上常见的 `preferred_network_mode` 命令最多改变 Android 侧“偏好网络类型”，不能代替截图中的解锁。

本项目采用的 ADB 方式是：检查设备和固件 → 尝试用 Activity/Secret Code 广播打开 Service Mode → 必要时用 ADB 在三星拨号器输入工程码 → 用 UI 层按可见菜单文字点击 → 重启 → 读取脱敏后的无线状态。真正落到基带里的改动仍由三星自己的 Service Mode 完成。

本机 Android 16 已验证会禁止 shell 直接启动未导出的 Service Mode，也会拒绝 shell 发送 `SECRET_CODE` 广播；脚本会自动跳过这两个被拒入口，改用 ADB 控制三星拨号器输入工程码。UI Automator 能读取本机 Service Mode 菜单文字，因此点击按文字匹配，不依赖固定坐标。

`S937U1UES9CZF9` 会在 `dumpsys window` 中同时返回空焦点和真实焦点；脚本会合并检查所有焦点行，并等待菜单文字出现。2026-09-10 的实测确认菜单层级本身没有变化。操作日志写入失败时会短暂重试，仍失败则只报警告，不再中断基带设置。

## 更新后为什么还要重跑

截图本身已注明：重启通常不会清除 band selection，但包含 CSC 的系统更新或重新刷 CSC 可能重置工程菜单设置。公开的高通三星 5G 操作记录也说明，更新到新的软件版本后需要再次操作。因此这里的“落盘”是把可靠流程、工具和验证保存到电脑，更新后双击重跑；它无法保证三星更新覆盖基带配置后仍永久保留。

## 自动点击失败时

脚本只要无法确认当前页面上的菜单文字，就会立即停止，不会猜坐标。此时手机会停在最后一个已确认页面；按 [手动菜单路径](docs/manual-menu-paths.md) 完成即可。

常见原因：

- 手机锁屏，ADB 无法向当前界面输入。
- 新版 Service Mode 改了菜单文字或层级。
- Service Mode 没有把文字暴露给 UI Automator。
- 美版 CSC 禁用了 Secret Code。此时先按截图评论所述，用 SamFW 的 MTP “Enable secret code for Verizon” 做一次启用，再重跑。SamFW 不是本项目附带软件，也不会自动下载或执行。

## 安全边界

- 只允许型号 `SM-S937U/U1`；其他型号默认拒绝改动。
- 不保存 IMEI、电话号码、IMSI、ICCID 或小区位置。
- 不调用 `fastboot`、Odin、Root、CSC 切换、FRP 或恢复出厂设置。
- 不自动打开 mmWave、CA Combo、DSS、NRDC 等可选项；它们不是中国移动基础 5G 解锁的必要条件，乱改可能增加耗电或造成驻网异常。
- 硬件本身不支持的频段不能通过软件“变出来”。解锁只解除软件侧限制。
- AT&T 公布的 SM-S937U 规格列有中国移动常用的 `n41`，但没有列出 `n79`；所以即使解锁成功，也应主要在有 n41 覆盖的位置验证，不能把 n79 当成已支持频段。

## 文件说明

- `docs/PRIVATE-ARCHIVE.md`：本次来源、真机结论、Android 16 适配、USB 故障与文件索引的总归档。
- `docs/DEVICE-LOGS.md`：全部脱敏 JSON/TXT 记录的 Markdown 转录与操作时间线。
- `docs/INTEGRITY.md`：原始截图、ADB 版本和全目录校验方法。
- `docs/METHODS-AND-AUTOMATION.md`：最短路径对比、实测耗时、自动化边界及何时需要人工介入。
- `run-recovery.cmd`：更新后一键恢复入口。
- `check-device.cmd`：只检查连接、型号、CSC 和固件，不改设置。
- `verify-5g.cmd`：读取当前 NR/5G 状态，不改设置。
- `scripts/02-open-service-mode.ps1`：只通过 ADB 打开 Service Mode。
- `docs/manual-menu-paths.md`：核心路径和可选项的中文说明。
- `docs/usb-connection-recovery.md`：当前 USB 错误 31、部分端点失效与不充电的处理顺序。
- `docs/screenshot-transcription.md`：两张原始截图的结构化转录与取舍。
- `docs/SOURCES.md`：截图正文的 XDA 来源链、作者、上游指南与可信度说明。
- `docs/2026-08-27-live-run.md`：本次 S25 Edge 真机执行全过程和 Android 16 适配记录。
- `docs/2026-09-10-live-run.md`：`S937U1UES9CZF9` 更新后的恢复、兼容性修正与复核记录。
- `docs/evidence/`：用户提供的两张原始截图副本。
- `logs/`：每次运行产生的脱敏设备快照；新的运行日志默认由 Git 忽略，避免误提交本机路径和重复记录。
- `SHA256SUMS.txt`：核心脚本、证据图和成功前后日志的完整性校验值。
- `THIRD_PARTY_NOTICES.md`：便携 ADB、参考截图和外部资料的授权边界。
- `tools/platform-tools/`：Google 官方便携 ADB 37.0.1。
- `tools/compat-r36.0.2/`：Google 官方 ADB 36.0.2 兼容性对照副本；下载包 SHA-256 已核对为 `b024d4f319d6ad3004de1ba7b96a5c7c5f3512e8b14126308d598b4ab93dcead`。

## 资料来源

- [Google：Android Debug Bridge](https://developer.android.com/tools/adb)
- [Google：SDK Platform-Tools 下载与版本说明](https://developer.android.com/tools/releases/platform-tools)
- [AT&T：SM-S937U 频段规格（含 n41，不含 n79）](https://www.att.com/es-us/device-support/article/wireless/000108462/Samsung/SamsungSMS937U)
- [社区原始记录：Enable 5G on Samsung Qualcomm Devices](https://gist.github.com/olkitu/171e3a27d470cd5b9ba67fedcb769d45)
- [Service Mode Activity/keyString 的早期原始研究记录](https://gist.github.com/oboenikui/5653234)

社区资料只用于解释三星私有菜单；最终以本机屏幕和实测驻网结果为准。
