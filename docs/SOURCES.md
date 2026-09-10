# 来源与可信度

## 结论

用户截图中的英文正文可以高置信度追溯到 XDA 用户 `peacey8` 的教程：

**How to Enable All Bands Through Service Menu on US/CA S23 series (including Sub-6 and mmWave)**

- 原始 XDA 主题：<https://xdaforums.com/t/how-to-enable-all-bands-through-service-menu-on-us-ca-s23-series-including-sub-6-and-mmwave.4554611/>
- 作者：`peacey8`
- 创建时间：2023-02-17（XDA 的主题索引记录）
- 对应部分：`C. METHOD 1: Use the Service Menu to Unlock All Bands`
- 匹配依据：标题、两个工程码、五条核心菜单路径、DSS/CDRX、SA/NSA、NRDC、CSC 更新后需重做、SIM 2 先切换 Stack 2 等结构和措辞均一致。

截图是中文社交平台中的二次截图。仅凭当前画面不能证明该平台账号是英文教程首发者，也无法确定是谁首次把 XDA 正文制成了这张图片。因此应把 `peacey8 / XDA` 标为“正文来源”，把社交平台图片标为“二次传播，具体制图者未知”。

## 来源链

### 1. 直接匹配来源：XDA S23 指南

`peacey8` 的 S23 指南与截图正文直接匹配。XDA 页面有时会对自动访问返回 403，但主题链接、标题、作者、日期及正文均可由搜索索引和多个引用页交叉验证。

### 2. 上游：同作者的 XDA S22 指南

- <https://xdaforums.com/t/how-to-enable-all-bands-through-service-menu-on-us-ca-s22-series-including-sub-6-and-mmwave.4488435/>

S23 指南明确说明它是同作者 S22U 指南的复制和适配版本。截图采用的是较新的 S23 版层级，例如 `PRUNE STATUS` 和 `SA/NSA Mode Control` 的写法。

### 3. 更早上游：mellojosh 的 S20U Service Mode 指南

- <https://xdaforums.com/t/guide-service-mode-and-csc-guide-enable-lte-5g-bands-and-services-5g-low-band-on-u1.4182293/>

S22/S23 指南都把 `mellojosh` 的 S20U1 Service Mode 研究列为主要基础来源；`wr3cckl3ss1` 被列为 Protocol Simulation 相关方法的贡献者。

### 4. 中文存档/转载

- [树新博客：美版三星手机如何在国内免ROOT通过工程模式开启5G频段](https://www.mailshuxin.com/1606/)，发布于 2024-05-19。

该页面完整保留了 S23 指南的来源说明、核心路径和 XDA 引用链接，是可访问的中文二级存档，不是英文正文的原始作者。

### 5. 独立交叉验证

- [GitHub Gist：Enable 5G on Samsung Qualcomm Devices](https://gist.github.com/olkitu/171e3a27d470cd5b9ba67fedcb769d45)

该记录独立描述了高通三星设备上的 `REMOVE NR5G PRUNE`、`REMOVE NR WHITELIST` 和更新后需重做等现象，可作为菜单行为的旁证，但它测试的是较早的 S20/S21/Note20 港台版本。

## 官方资料

- [Google：Android Debug Bridge](https://developer.android.com/tools/adb)
- [Google：SDK Platform-Tools 版本说明](https://developer.android.com/tools/releases/platform-tools)
- [AT&T：SM-S937U 频段规格](https://www.att.com/es-us/device-support/article/wireless/000108462/Samsung/SamsungSMS937U)
- [Samsung：USB 连接故障排查](https://www.samsung.com/us/support/troubleshooting/TSG01212959/)
- [Samsung：One UI 7 USB 连接限制](https://www.samsung.com/us/support/troubleshoot/TSG10005233/)

## 原教程与本项目的区别

原教程面向 S22/S23，且含有刷 XAA、SamFW、mmWave、CA Combo、DSS、NRDC、Protocol Simulation 等扩展步骤。本项目没有照单全做；本机本来就是 SM-S937U1/XAA，最终只执行了经真机确认且足以让中国移动 5G SA 生效的五项核心设置。

本项目对 S25 Edge、Android 16 和 2026-07 固件的可用性证据来自本机前后状态，而不是对旧帖兼容性的推测。实测由 `LTE,LTE` 变为 `NR_SA,LTE`。
