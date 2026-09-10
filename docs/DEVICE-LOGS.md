# 脱敏设备日志与操作时间线

本页把 `logs/` 下的 JSON/TXT 记录完整转录为 Markdown，便于只阅读文档也能复核本次操作。原始文件继续保留，用于机器处理与哈希校验。

## 固定设备信息

| 字段 | 值 |
| --- | --- |
| 型号 | `SM-S937U1` |
| 产品 / 设备代号 | `psquew / psq` |
| Android / SDK | `16 / 36` |
| 安全补丁 | `2026-07-05` |
| 固件增量版本 | `S937U1UES8CZF5` |
| Build fingerprint | `samsung/psquew/psq:16/BP4A.251205.006/S937U1UES8CZF5_OYM8CZF5:user/release-keys` |
| Sales / Boot sales / Carrier ID | `XAA / XAA / XAA` |
| SIM 配置 | `dsds` |
| 运营商 | `中国移动,中国移动` |

## 全部快照

| 时间（Asia/Hong_Kong） | 原始文件 | 阶段 | 网络类型 |
| --- | --- | --- | --- |
| 2026-08-27 01:09:43 +08:00 | `20260827-010943-device-check.json` | 初次检查 | `LTE,LTE` |
| 2026-08-27 01:10:06 +08:00 | `20260827-011006-before-recovery.json` | 恢复前尝试 | `LTE,LTE` |
| 2026-08-27 01:11:27 +08:00 | `20260827-011127-before-recovery.json` | 恢复前尝试 | `LTE,LTE` |
| 2026-08-27 01:12:47 +08:00 | `20260827-011247-before-recovery.json` | 恢复前尝试 | `LTE,LTE` |
| 2026-08-27 01:14:01 +08:00 | `20260827-011401-before-recovery.json` | 成功流程执行前 | `LTE,LTE` |
| 2026-08-27 01:19:35 +08:00 | `20260827-011935-after-recovery.json` | 成功流程重启后 | `NR_SA,LTE` |
| 2026-08-27 01:19:45 +08:00 | `20260827-011945-verification.json` | 独立复核 | `NR_SA,LTE` |

## 实际操作时间线

- 01:14：保存恢复前快照；网络类型 `LTE,LTE`，运营商为中国移动。
- 01:14：通过 ADB 控制三星拨号器打开 Service Mode。
- 01:14：选择 `UE SETTING & INFO → SETTING → SYSTEM → NEXT PAGE × 4 → SET LTE BAND CONFIG → SET DEFAULT LTE BAND`。
- 01:15：重新进入 Service Mode 主菜单。
- 01:15：选择 `UE SETTING & INFO → SETTING → PROTOCOL → NR5G → PRUNE STATUS → REMOVE NR5G PRUNE`。
- 01:16：重新进入 Service Mode 主菜单。
- 01:16：选择 `UE SETTING & INFO → SETTING → PROTOCOL → GCF → REMOVE ONLY NR WHITELIST`。
- 01:17：重新进入 Service Mode 主菜单。
- 01:17：选择 `UE SETTING & INFO → SETTING → PROTOCOL → NR5G → SA/NSA MODE CONTROL → SA/NSA ENABLE`。
- 01:18：重新进入 Service Mode 主菜单。
- 01:18：选择 `UE SETTING & INFO → SETTING → PROTOCOL → NR5G → SA/NSA MODE CONTROL → REMOVE SA PERMIT LIST`。
- 01:18：通过 ADB 请求正常重启。
- 01:19：手机开机后重新连接。
- 01:19：保存恢复后快照；网络类型 `NR_SA,LTE`，运营商为中国移动。
- 01:19：独立验证检测到 NR/5G 状态。

## 明确未执行

Root、Bootloader 解锁、固件刷写、CSC 修改、恢复出厂设置、FRP 操作、mmWave `ALL ENABLE`、CA Combo 修改、CDRX、DSS、NRDC、Protocol Simulation 和 `preferred_network_mode` 数据库修改均未执行。

## 脱敏说明

上述日志没有采集或保存 IMEI、IMSI、ICCID、电话号码、ADB/USB 序列号和小区位置。
