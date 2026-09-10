# 归档完整性

## 原始截图指纹

| 文件 | SHA-256 |
| --- | --- |
| `evidence/service-mode-steps.png` | `5a06a08a545821c42d3986d938693d85a66da46782af5183ac4e52746a7f3b2d` |
| `evidence/discussion.png` | `4c4eb8e8772b7f014626b8062a66b17f40b0c64ad8dadbcacc3ff205c615b8aa` |

用户后来再次附上的第一张截图与已归档的 `service-mode-steps.png` 哈希完全相同，因此没有保留重复副本。

## ADB 工具版本

- 主版本：Google Android SDK Platform-Tools `37.0.1`
- 兼容对照：Google Android SDK Platform-Tools `36.0.2`
- 已核对的 36.0.2 官方下载包 SHA-256：`b024d4f319d6ad3004de1ba7b96a5c7c5f3512e8b14126308d598b4ab93dcead`

## 全目录校验

根目录 [`../SHA256SUMS.txt`](../SHA256SUMS.txt) 保存除其自身以外全部归档文件的 SHA-256。PowerShell 校验示例：

```powershell
Get-Content .\SHA256SUMS.txt | ForEach-Object {
    $hash, $path = $_ -split '  ', 2
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
    if ($actual -ne $hash) { throw "Hash mismatch: $path" }
}
```

校验表需要在文档、脚本或证据发生变更后重新生成。
