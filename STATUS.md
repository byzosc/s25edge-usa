# 当前真机状态（2026-09-10 已再次成功）

- 真机：`SM-S937U1`，产品 `psquew`，XAA/XAA，Android 16，2026-08-05 安全补丁，固件 `S937U1UES9CZF9`，DSDS。
- 运营商：两个逻辑卡槽均为中国移动。
- 恢复前：`gsm.network.type=LTE,LTE`。
- 已自动执行：`SET DEFAULT LTE BAND`、`REMOVE NR5G PRUNE`、`REMOVE ONLY NR WHITELIST`、`SA/NSA ENABLE`、`REMOVE SA PERMIT LIST`。
- 恢复后重启并复核：`gsm.network.type=NR_SA,LTE`；SIM 1 已恢复中国移动 5G SA，SIM 2 保持 LTE。
- 脱敏记录：`logs/20260910-183406-before-recovery.json`、`logs/20260910-184421-verification.json`。
- 新固件兼容修正：前台窗口检测会处理多用户/多显示器产生的空焦点行；Service Mode 入口会等待菜单加载；日志追加失败不再中断恢复；`run-recovery.cmd` 直接执行，不再要求输入 `YES`。

## 2026-08-27 首次成功记录

- 记录时间：2026-08-27（Asia/Hong_Kong），2026-08-28 复核
- ADB：Google Platform-Tools 37.0.1 已安装到项目内，连接正常。
- 真机：`SM-S937U1`，产品 `psquew`，XAA/XAA，Android 16，安全补丁 2026-07-05，固件 `S937U1UES8CZF5`，DSDS。
- 运营商：两个逻辑卡槽均显示中国移动。
- 改动前：`gsm.network.type=LTE,LTE`。
- 已由 ADB 驱动 Service Mode 实际执行：`SET DEFAULT LTE BAND`、`REMOVE NR5G PRUNE`、`REMOVE ONLY NR WHITELIST`、`SA/NSA ENABLE`、`REMOVE SA PERMIT LIST`。
- 改动后自动重启并复核：`gsm.network.type=NR_SA,LTE`；SIM 1 已驻留中国移动 5G SA，SIM 2 保持 LTE。
- 脱敏记录：`logs/20260827-011401-before-recovery.json`、`logs/20260827-011935-after-recovery.json`、`logs/20260827-011945-verification.json`。

> 2026-08-28 更正：当天那些 USB 枚举/充电异常是一次性的外设问题，**已经没了**，不构成本项目的状态。
> 原先把它当"当前状态"记在这里是错的——它误导了后续判断（另一个项目直接把它当成了前置障碍）。
> 排查步骤保留在 `docs/usb-connection-recovery.md` 供万一复发时查，但它**不是这台机器的现状**。

结论：两次目标均已完成。以后系统/CSC 更新导致失效时，保持手机解锁并双击根目录 `run-recovery.cmd` 即可重复恢复；完成后用 `verify-5g.cmd` 复核。

脚本兼容性修正：ADB 37 的 `devices -l` 在本机以空格而非制表符分隔，连接解析已修正；Android 16 禁止 shell 直接启动未导出 Activity/发送 Secret Code 广播，脚本已验证可自动回退到三星拨号器输入；每项设置前会关闭并重新打开 Service Mode，保证从主菜单开始。
