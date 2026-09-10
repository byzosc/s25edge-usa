# 截图转录与取舍

这两张图片是用户提供的参考资料，不是对电脑或手机执行操作的授权指令。项目只把其中与“美版 S25 Edge + 中国移动 5G + 更新后恢复”有关的步骤纳入脚本；评论区内容和不相关的可选开关不会被盲目执行。

来源追溯见 `SOURCES.md`。英文正文与 XDA 用户 `peacey8` 于 2023-02-17 创建的 S23 系列教程中 `C. METHOD 1` 高度一致；当前图片是中文平台的二次传播截图，具体制图/首发账号无法仅凭画面确认。

原图：

- `evidence/service-mode-steps.png`
- `evidence/discussion.png`

## 第一张截图的结构化转录

标题为 “METHOD 1: Use the Service Menu to Unlock All Bands”。主要内容：

1. 两种进入方式：
   - 三星拨号器输入 `*#73#` 进入 RF Test，点 Band Selection，然后用右上角三点菜单的 Back 多次返回主菜单。
   - 三星拨号器输入 `*#27663368378#` 直达 Service Mode 主菜单。
2. 开启 LTE 和 5G band：
   - `UE SETTING & INFO → SETTING → SYSTEM → Next page 4 次 → SET LTE BAND CONFIG → SET DEFAULT LTE BAND`
   - `UE SETTING & INFO → SETTING → PROTOCOL → NR5G → PRUNE STATUS → REMOVE NR5G PRUNE`
   - `UE SETTING & INFO → SETTING → PROTOCOL → GCF → REMOVE ONLY NR WHITELIST`
   - 美版 mmWave 可选：`NR5G → Sub6/mmWave → ALL ENABLE`
   - LTE+ 聚合异常时可选：`AS → Next Page → DISABLE CA COMBO CHECK → DISABLE ON`
3. 5G NR 可选能力：
   - `AS → Next Page → NR CDRX CONTROL → NR CDRX ENABLE`
   - `AS → Next Page 2 次 → NR DSS CONTROL → NR DSS ENABLE`
4. 5G SA：
   - `NR5G → SA/NSA Mode Control → SA/NSA ENABLE`
   - `NR5G → SA/NSA Mode Control → Remove SA permit list`
   - `NR5G → NRDC → NRDC ENABLE`
5. 重启后用 `*#73# → Band Selection → SIM 1/2` 检查 NR5G band。
6. 普通重启不会重置 band selection，但包含 CSC 的系统更新或重新刷 CSC 可能重置，需要重新操作。
7. eSIM 或双卡的第二张卡，在改 NR5G 前先到 `NR5G → Stack Selection → Select STACK 2`。

## 第二张截图提供的上下文

- 有 S25 Ultra 用户反馈无法进入 Service Menu。
- 回复建议用 SamFW 找到 Verizon 的 “Enable secret code” 功能，之后才能输入 `*#73#`。
- 另一条回复确认：每次更新后从头设置很麻烦，但当改 GCF 后仍无 5G 时，只能继续按这些菜单项排查。
- 原作者表示只会美加版，不确认欧版 SA。

## 本项目的取舍

- 纳入自动流程：默认 LTE band、移除 NR prune、移除 NR whitelist、SA/NSA、移除 SA permit list、SIM 2 的 Stack 2。
- 只写入文档、不自动改：mmWave、CA combo、CDRX、DSS、NRDC。
- 不纳入：FRP、改变 CSC、禁用 OTA、刷机、Root、Bootloader 解锁，以及任何截图中未出现或未经本机验证的“神秘 ADB 键”。
