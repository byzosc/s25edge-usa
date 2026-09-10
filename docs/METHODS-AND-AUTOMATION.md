# 路径选择、执行耗时与自动化边界

## 结论

对本机 `SM-S937U1 / XAA / Android 16` 而言，当前“五项核心设置”不是理论上点击次数最少的方案，但它是已经在这台手机上完成前后状态验证的最短低风险方案：执行前为 `LTE,LTE`，执行后为 `NR_SA,LTE`。

不建议为了少点几下，改用影响范围更广的 GCF Protocol Simulation；也不建议为了追求跨更新永久保存而 Root、修改 EFS、刷 CSC 或改基带文件。

## 公开方法对比

| 方法 | 大致耗时 | 适用性 | 本项目判断 |
| --- | ---: | --- | --- |
| 当前五项核心设置 | 约 4–6 分钟（含重启验证） | 已在本机验证中国移动 5G SA | 推荐，作为默认恢复方式 |
| 仅移除 `NR5G PRUNE` 和 NR whitelist | 约 1–2 分钟 | 较老 S20/S21/Note20 高通机型有记录 | 没有明确处理 SA permit list，不替代当前流程 |
| Protocol Simulation 模拟 GCF | 约 1–2 分钟 | XDA Method 1 无效或频段仍未完全开放时 | 点击更少但影响范围更广，只作备用方案 |
| Root / EFS / 刷 CSC / 修改基带 | 不定 | 追求更底层或更持久的改动 | 风险高，不采用 |

XDA S23 教程把 Service Mode 路径列为 `METHOD 1`。其 `METHOD 2` 会在 Protocol Simulation 中把 AP、NET1、NET2 模拟为 GCF 后写入并重启；原教程明确把它定位为 Method 1 无效时的备用方案，而且若频段仍未开放，仍需返回 Method 1。因此 Method 2 只是点击更少，不代表对本机更安全或更可靠。

较早的高通三星记录只执行 `REMOVE NR5G PRUNE` 和移除 NR whitelist 后重启。这能说明两项设置是基础条件，但不能证明在 S25 Edge、中国移动 SA 和当前固件上可以省略 `SA/NSA ENABLE`、`REMOVE SA PERMIT LIST` 或 LTE band 初始化。

## 当前五项为何保留

1. `SET DEFAULT LTE BAND`
2. `REMOVE NR5G PRUNE`
3. `REMOVE ONLY NR WHITELIST`
4. `SA/NSA ENABLE`
5. `REMOVE SA PERMIT LIST`

本次真机测试一次性执行了以上五项，所以现有证据只能证明“五项组合”有效，不能把成功结果可靠归因到其中某两项。若删除某项，需要重新进行有控制变量的更新后测试；在没有这种证据前，保留五项更稳妥。

## 一次执行需要多久

2026-08-27 的实测时间线：

- 01:14：保存恢复前快照，开始操作；
- 01:14–01:18：完成五项 Service Mode 设置；
- 01:18：请求正常重启；
- 01:19：手机重新连接，保存恢复后快照并确认 `NR_SA,LTE`。

本次约 5 分钟。USB 已授权、手机保持解锁且连接稳定时，正常预期为 4–6 分钟：菜单操作约 3–4 分钟，重启和重新连接约 1–2 分钟。

脚本每一项都关闭旧的 Service Mode 页面并从主菜单重新进入。熟练人工通过三点菜单连续返回可能更快，但自动流程采用重新进入是为了避免深层页面残留导致误点。

脚本参数中的 120 秒和重启后的 180 秒是异常情况下等待设备的最长时间，不是正常执行耗时。

## 当前已经自动化到什么程度

当前流程不依赖 Agent。用户只需要：

1. 保持手机解锁；
2. 连接已经授权 USB 调试的电脑；
3. 双击根目录 `run-recovery.cmd`；
4. 输入大写 `YES`；
5. 等待脚本完成菜单操作、重启、验证和日志保存。

脚本已经自动完成：

- 校验 ADB 连接、型号、CSC 和固件；
- 保存脱敏的恢复前状态；
- 通过三星拨号器打开 Service Mode；
- 按可见菜单文字定位和点击，不使用固定坐标；
- 应用五项核心设置；
- 正常重启并等待手机重新连接；
- 保存恢复后状态、网络摘要和操作日志；
- 找不到预期文字时立即停止，不猜测点击位置。

因此，每次正常系统更新后不需要再次找 Agent，直接运行已落盘脚本即可。

## 为什么不能在任何状态下完全无人值守

普通非 Root ADB 有系统安全边界：首次连接或授权失效时，需要在已解锁手机上确认电脑的 RSA 指纹；USB 调试关闭、手机未授权、USB 端点失效时，电脑不能直接控制手机界面。

本机 Android 16 还会拒绝 shell 直接启动未导出的 Service Mode Activity 和发送 Secret Code 广播，因此脚本必须通过 ADB 控制已解锁的三星拨号器输入工程码。锁屏、工程码重新被禁用或三星改变菜单结构时，纯 ADB 脚本不能安全地绕过这些条件。

## 什么时候才需要 Agent 或人工排障

- 更新改变了 Service Mode 菜单文字或层级，脚本在首个未识别页面停止；
- Secret Code 被重新锁定，需要再次通过 SamFW 启用；
- USB 调试授权丢失、ADB 不可见或 USB 复合设备再次发生错误 31；
- 手机型号、SIM 栈或运营商条件与当前验证环境不同；
- 执行完成后仍没有 NR，需要区分频段硬件、覆盖、套餐、SIM 鉴权和基带设置。

## 可以继续优化但尚未启用的功能

- 增加明确的无人确认参数，省略输入 `YES`；
- 为全部五项增加“已应用”状态识别，自动跳过没有被更新重置的项目；
- 比较更新前后固件版本，只在检测到新版本且 5G 状态异常时提醒运行；
- 提供快速模式，在同一次 Service Mode 会话中复用菜单路径。

这些改进可以减少几十秒到约两分钟，但不能消除手机解锁和 ADB 授权要求。快速模式复用深层页面会降低对菜单状态变化的容错，因此当前默认仍采用较稳妥的逐项重新进入方式。

## 资料来源

- [XDA：S23 美加版全频段教程，peacey8，2023-02-17](https://xdaforums.com/t/how-to-enable-all-bands-through-service-menu-on-us-ca-s23-series-including-sub-6-and-mmwave.4554611/)
- [XDA：同作者 S22 教程](https://xdaforums.com/t/how-to-enable-all-bands-through-service-menu-on-us-ca-s22-series-including-sub-6-and-mmwave.4488435/)
- [GitHub Gist：较老高通三星机型的两项基础设置记录](https://gist.github.com/olkitu/171e3a27d470cd5b9ba67fedcb769d45)
- [Google：Android Debug Bridge](https://developer.android.com/tools/adb)
- [Google：UiAutomation API](https://developer.android.com/reference/android/app/UiAutomation)

以上 Service Mode 和 GCF 方法属于社区研究，不是三星官方支持流程；本项目对 S25 Edge 的结论以本机真机日志为准。
