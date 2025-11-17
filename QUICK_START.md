# 快速上传指南

## 问题
GitHub 无法上传大文件（二进制文件）。

## 解决方案

### 方案 1：只上传脚本文件（推荐）

1. **使用 .gitignore 排除二进制文件**
   - 已创建 `.gitignore` 文件，会自动排除所有二进制文件
   - 只会上传脚本文件（.sh, .init, .service, .json）

2. **上传到 GitHub**
   ```bash
   git add .
   git commit -m "Update scripts with GitHub URLs"
   git push
   ```

3. **将二进制文件上传到 GitHub Releases**
   - 访问：https://github.com/boaom/amy4/releases
   - 创建新 Release（如 v1.0.0）
   - 上传二进制文件（需要重命名，见下方）

### 方案 2：暂时保留二进制文件在仓库（不推荐）

如果暂时无法使用 Releases，可以：
1. 修改 `.gitignore`，暂时允许二进制文件
2. 但注意：GitHub 可能仍然拒绝大文件上传

## 二进制文件命名规则

上传到 Releases 时，文件需要重命名为：

### cns
- 普通版本：`cns-linux-amd64`, `cns-linux-386`, `cns-linux-arm`, 等
- UPX 版本：`cns-upx-linux-amd64`, `cns-upx-linux-386`, 等

### amy4Server
- 普通版本：`amy4Server-linux-amd64`, `amy4Server-linux-386`, 等
- UPX 版本：`amy4Server-upx-linux-amd64`, 等

### xray
- 普通版本：`xray-linux-amd64`, `xray-linux-386`, 等
- UPX 版本：`xray-upx-linux-amd64`, 等

## 脚本自动回退机制

脚本已配置为：
1. 首先尝试从 GitHub Releases 下载
2. 如果失败，回退到 raw.githubusercontent.com（但那里没有二进制文件，因为被 .gitignore 排除了）

**因此，必须将二进制文件上传到 Releases 才能正常工作。**

## 当前状态

✅ 所有脚本已更新为使用 GitHub 地址
✅ .gitignore 已创建，排除二进制文件
✅ 脚本已配置为从 Releases 下载

❌ 需要：将二进制文件上传到 GitHub Releases

