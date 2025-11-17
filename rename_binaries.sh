#!/bin/bash
# 重命名二进制文件以便上传到 GitHub Releases

cd "$(dirname "$0")/amy2024" || exit 1

echo "重命名 cns 二进制文件..."
for file in linux_*; do
    if [ -f "$file" ]; then
        new_name="cns-linux-${file#linux_}"
        mv "$file" "$new_name"
        echo "  $file -> $new_name"
    fi
done

if [ -d "upx" ]; then
    echo "重命名 cns UPX 二进制文件..."
    cd upx || exit 1
    for file in linux_*; do
        if [ -f "$file" ]; then
            new_name="cns-upx-linux-${file#linux_}"
            mv "$file" "$new_name"
            echo "  $file -> $new_name"
        fi
    done
    cd ..
fi

echo ""
echo "重命名 amy4Server 二进制文件..."
# 注意：如果 amy4Server 的二进制文件在其他目录，需要相应调整路径
# 这里假设结构和 cns 类似

echo ""
echo "重命名 xray 二进制文件..."
# 注意：如果 xray 的二进制文件在其他目录，需要相应调整路径
# 这里假设结构和 cns 类似

echo ""
echo "完成！现在可以将重命名后的文件上传到 GitHub Releases。"

