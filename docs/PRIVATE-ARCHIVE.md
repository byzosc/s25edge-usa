# S25 Edge 美版 + 中国移动 5G 私人归档

## 归档目的

本目录把 2026-08-27 在美版 Samsung Galaxy S25 Edge 上恢复中国移动 5G 的资料、来源、真机操作、故障排查和可重复脚本统一落盘。系统或 CSC 更新再次清除基带工程设置时，可直接按这里的流程重跑。

这不是“修改一次永久不丢”的补丁：三星更新若覆盖 CSC/CP 配置，仍可能重置 Service Mode。落盘解决的是步骤可复现、证据可核对、更新后可快速恢复。

## 已验证结论

- 设备：`SM-S937U1`，产品 `psquew / psq`
- CSC：`XAA / XAA`
- 系统：Android 16（SDK 36）
- 安全补丁：2026-07-05
- 固件：`S937U1UES8CZF5`
- 双卡：DSDS，两个逻辑卡槽均识别为中国移动
- 执行前：`LTE,LTE`
- 执行后：`NR_SA,LTE`
- 结果：SIM 1 驻留中国移动 5G SA，SIM 2 保持 LTE

## 真机实际执行

ADB 负责连接、打开三星拨号器、输入工程码并按可见文字操作 Service Mode；真正写入基带设置的是三星自己的 Service Mode。

1. `SET DEFAULT LTE BAND`
2. `REMOVE NR5G PRUNE`
3. `REMOVE ONLY NR WHITELIST`
4. `SA/NSA ENABLE`
5. `REMOVE SA PERMIT LIST`
6. 通过 ADB 请求正常重启
7. 开机后读取网络状态并保存验证快照

中国移动卡当时使用 SIM 1，所以没有切换 `STACK 2`。若卡在 SIM 2/eSIM 对应的第二基带栈，应在修改 NR5G 项目前执行 `SELECT STACK 2`。

## 没有执行的高风险或非必要操作

- 没有 Root、解锁 Bootloader、Odin 刷机、改变 CSC 或恢复出厂设置。
- 没有操作 FRP 或 Samsung Account。
- 没有自动打开 mmWave、CA Combo、NR CDRX、NR DSS、NRDC 或 Protocol Simulation。
- 没有写入未经证实的 `preferred_network_mode` 等 Android Settings 键。

## Android 16 / ADB 实测经验

- Platform-Tools 37 的 `adb devices -l` 在本机使用空白字符分隔，不能只按制表符解析。
- Android 16 拒绝 shell 直接启动未导出的 `ServiceModeApp`，也拒绝 shell 发送 `SECRET_CODE` 广播。
- 可用入口是 ADB 打开三星拨号器并注入 `*#27663368378#` 的按键序列。
- Service Mode 打开后，UI Automator 能读取菜单文字；脚本按文字节点中心点击，不依赖固定坐标。
- 每完成一项都关闭旧的 Service Mode 页面，再从拨号器重新进入主菜单，避免深层页面状态干扰下一项。

## USB 半连接经验

真机曾出现“USB 用途入口可见但点不进去、随后不充电”的状态。Windows 同时枚举 MTP、ADB、Modem 和 USB Composite，但 MTP 可用而 ADB/Modem 返回错误 31，属于三星 USB 复合设备的部分端点卡死。

安全顺序是先断线、强制重启、用墙充确认充电恢复，再保持手机解锁连接电脑；必要时撤销 USB 调试授权，关闭再打开 USB 调试，并重新确认“始终允许这台电脑”。完整步骤见 [`usb-connection-recovery.md`](usb-connection-recovery.md)。

## 来源结论

用户截图的英文正文与 XDA 用户 `peacey8` 在 2023-02-17 创建的 S23 系列教程 `C. METHOD 1` 高度一致：标题、两个工程码、核心菜单路径、DSS/CDRX、SA/NSA、NRDC、CSC 更新后需重做和 SIM 2 的 Stack 2 提示均可对应。

- 直接来源：[XDA S23 Service Menu 指南](https://xdaforums.com/t/how-to-enable-all-bands-through-service-menu-on-us-ca-s23-series-including-sub-6-and-mmwave.4554611/)
- 同作者上游：[XDA S22 指南](https://xdaforums.com/t/how-to-enable-all-bands-through-service-menu-on-us-ca-s22-series-including-sub-6-and-mmwave.4488435/)
- 更早基础研究：[mellojosh 的 S20U Service Mode 指南](https://xdaforums.com/t/guide-service-mode-and-csc-guide-enable-lte-5g-bands-and-services-5g-low-band-on-u1.4182293/)
- 中文二级存档：[树新博客转载](https://www.mailshuxin.com/1606/)
- 独立旁证：[Enable 5G on Samsung Qualcomm Devices](https://gist.github.com/olkitu/171e3a27d470cd5b9ba67fedcb769d45)

中文社交平台截图属于二次传播；仅凭画面无法证明平台账号是英文正文首发者，也无法确认最初制图者。详细比对见 [`SOURCES.md`](SOURCES.md) 与 [`screenshot-transcription.md`](screenshot-transcription.md)。

## 文件索引

- [`../README.md`](../README.md)：用法、安全边界和文件说明。
- [`DEVICE-LOGS.md`](DEVICE-LOGS.md)：全部脱敏快照与实际操作时间线的 Markdown 转录。
- [`INTEGRITY.md`](INTEGRITY.md)：截图指纹、ADB 版本和全目录校验说明。
- [`METHODS-AND-AUTOMATION.md`](METHODS-AND-AUTOMATION.md)：不同解锁路径、实测耗时和自动化边界。
- [`2026-08-27-live-run.md`](2026-08-27-live-run.md)：真机执行纪要和适配问题。
- [`manual-menu-paths.md`](manual-menu-paths.md)：自动流程失败时的手工菜单路径。
- [`usb-connection-recovery.md`](usb-connection-recovery.md)：USB 半连接和不充电排查。
- [`screenshot-transcription.md`](screenshot-transcription.md)：两张截图的结构化转录与取舍。
- [`SOURCES.md`](SOURCES.md)：来源链、作者与可信度。
- [`evidence/`](evidence/)：用户提供的两张参考截图。
- [`../scripts/`](../scripts/)：ADB 检查、Service Mode 打开、恢复和验证脚本。
- [`../logs/`](../logs/)：原始脱敏 JSON 快照和 TXT 操作记录。
- [`../SHA256SUMS.txt`](../SHA256SUMS.txt)：归档文件完整性校验。

## 隐私检查范围

归档不包含 IMEI、IMSI、ICCID、电话号码、ADB/USB 序列号、精确位置或 GitHub 凭据。型号、CSC、系统与固件版本属于复现实机结果所需的非唯一技术信息。
