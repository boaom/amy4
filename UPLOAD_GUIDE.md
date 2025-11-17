# 上传指南

## 问题
GitHub 对单个文件大小有限制（100MB），大量二进制文件会导致上传失败。

## 解决方案

### 1. 只上传脚本文件
使用 `.gitignore` 文件排除所有二进制文件，只上传脚本文件到仓库。

### 2. 二进制文件上传到 GitHub Releases
脚本已修改为优先从 GitHub Releases 下载二进制文件。

#### 二进制文件命名规则：
- **cns**: `cns-linux-{arch}` 或 `cns-upx-linux-{arch}`
- **amy4Server**: `amy4Server-linux-{arch}` 或 `amy4Server-upx-linux-{arch}`
- **xray**: `xray-linux-{arch}` 或 `xray-upx-linux-{arch}`

其中 `{arch}` 可以是：
- `amd64`
- `386`
- `arm`
- `arm64`
- `mips`
- `mips64`
- `mips64le`
- `mipsle`
- `mips64_softfloat`
- `mipsle_softfloat`
- `s390x`

#### 上传步骤：
1. 在 GitHub 仓库页面，点击 "Releases"
2. 点击 "Create a new release"
3. 填写版本号（如 `v1.0.0`）
4. 上传所有二进制文件，使用上述命名规则
5. 发布 Release

#### 文件重命名脚本示例：
```bash
# 重命名 cns 二进制文件
cd amy2024
for file in linux_*; do
    mv "$file" "cns-linux-${file#linux_}"
done

cd upx
for file in linux_*; do
    mv "$file" "cns-upx-linux-${file#linux_}"
done
```

### 3. 脚本会自动回退
如果 GitHub Releases 中没有找到文件，脚本会自动尝试从 raw.githubusercontent.com 下载（作为备选方案）。

## 当前上传的文件
只需要上传以下文件到仓库：
- `builds.sh`
- `cns.sh`
- `cns.init`
- `cns.service`
- `amy4Server.sh`
- `amy4Server.init`
- `amy4Server.service`
- `xray.sh`
- `xray.init`
- `xray.service`
- `tinyproxy.sh`
- 其他 `.sh`、`.init`、`.service`、`.json` 脚本文件

所有二进制文件（`linux_*`）都会被 `.gitignore` 排除。

