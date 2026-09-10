# 手动菜单路径

当自动点击找不到菜单文字时，用本页继续。三星工程菜单里的返回不要用系统返回手势；若需要返回上一级，点右上角三点菜单里的 `Back`。更稳的办法是退出后重新运行 `scripts/02-open-service-mode.ps1`，每一项都从主菜单重新进入。

## 进入 Service Mode

优先运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\02-open-service-mode.ps1
```

手工备用方法：三星拨号器输入 `*#27663368378#` 直达主菜单；或输入 `*#73#` 进入 RF Test，点 `Band Selection`，再用右上角三点菜单的 `Back` 连续返回到主菜单。

## 更新后核心必做

### 1. 恢复默认 LTE band 配置

`UE SETTING & INFO → SETTING → SYSTEM → NEXT PAGE × 4 → SET LTE BAND CONFIG → SET DEFAULT LTE BAND`

### 2. 移除 NR5G prune

`UE SETTING & INFO → SETTING → PROTOCOL → NR5G → PRUNE STATUS → REMOVE NR5G PRUNE`

如果页面显示 `RESTORE NR5G PRUNE`，说明 prune 已经移除，不要再点，因为那会恢复限制。

### 3. 移除 NR 白名单

`UE SETTING & INFO → SETTING → PROTOCOL → GCF → REMOVE ONLY NR WHITELIST`

### 4. 打开 SA/NSA

`UE SETTING & INFO → SETTING → PROTOCOL → NR5G → SA/NSA Mode Control → SA/NSA ENABLE`

### 5. 移除 SA permit list

`UE SETTING & INFO → SETTING → PROTOCOL → NR5G → SA/NSA Mode Control → Remove SA permit list`

### 6. SIM 2 / eSIM 注意

若中国移动卡实际使用第二个基带栈，应在改任何 NR5G 选项前先做：

`UE SETTING & INFO → SETTING → PROTOCOL → NR5G → Stack Selection → Select STACK 2`

实体 SIM 1 默认不需要这一项。

## 截图中的可选项（默认不自动执行）

### mmWave 全开

`UE SETTING & INFO → SETTING → PROTOCOL → NR5G → Sub6/mmWave → ALL ENABLE`

中国移动大陆 5G 主要需求是 Sub‑6；美版 mmWave 开关对中国移动基础接入没有帮助，因此本项目不自动改。

### LTE+ / CA 故障排查

仅当 LTE 到 LTE+ 的载波聚合确实异常时：

`UE SETTING & INFO → SETTING → PROTOCOL → AS → NEXT PAGE → DISABLE CA COMBO CHECK → DISABLE ON`

它可能放宽组合校验，不是基础 5G 解锁必需项。

### NR CDRX

`UE SETTING & INFO → SETTING → PROTOCOL → AS → NEXT PAGE → NR CDRX CONTROL → NR CDRX ENABLE`

这是 5G 省电相关能力，通常固件默认已开。

### NR DSS

`UE SETTING & INFO → SETTING → PROTOCOL → AS → NEXT PAGE × 2 → NR DSS CONTROL → NR DSS ENABLE`

DSS 是动态频谱共享；不是中国移动 n41/n79 基础接入的通用前提。

### NRDC

`UE SETTING & INFO → SETTING → PROTOCOL → NR5G → NRDC → NRDC ENABLE`

NRDC 是 NR 双连接能力，只在运营商网络实际部署并使用时有意义。

## 重启与检查

完成后重启手机。进入 `*#73# → Band Selection → SIM 1/2` 可以查看 NR5G band 列表；然后在已知中国移动 5G 覆盖区关闭 Wi‑Fi，观察 5G 图标，并运行根目录的 `verify-5g.cmd`。

看见所有 band “enabled”不等于一定能驻留：还取决于 SM-S937U/U1 的射频硬件、当地频段、SIM/套餐开通、运营商鉴权和现场信号。
