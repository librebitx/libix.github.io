#!/bin/bash

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ 错误: 当前目录不是 Git 仓库。"
  exit 1
fi

TARGET_DIR="./_posts"
file="$1"

# ==========================================
# 分支 1: 指定了文件 -> 处理文件 + Git
# ==========================================
if [[ -n "$file" ]]; then

    if [[ ! -f "$file" ]]; then
        echo "❌ 错误: 文件 '$file' 不存在。"
        exit 1
    fi

    if [[ ! -d "$TARGET_DIR" ]]; then
        mkdir -p "$TARGET_DIR"
    fi

    filename=$(basename -- "$file")
    timestamp_regex="^[0-9]{2}-[0-9]{2}-[0-9]{2}-"

    if [[ "$filename" =~ $timestamp_regex ]]; then
        final_name="$filename"
    else
        date_prefix=$(date '+%y-%m-%d')
        final_name="${date_prefix}-${filename}"
        echo "🔄 重命名: $filename -> $final_name"
    fi

    # 4. 移动文件到 _posts
    target_path="${TARGET_DIR}/${final_name}"
    
    if [[ "$(readlink -f "$file")" != "$(readlink -f "$target_path")" ]]; then
        mv "$file" "$target_path"
    fi

    echo "🔍 检查笔记头部信息 (Front Matter)..."
    
    current_date=$(date -d "yesterday" '+%Y-%m-%d')

    # 检测文件第一行是否为 ---
    first_line=$(head -n 1 "$target_path")

    if [[ "$first_line" != "---" ]]; then
        echo "⚠️  未检测到 YAML 头部，正在创建..."
        
        # 询问用户输入
        read -p "📝 请输入标题 (title): " input_title
        read -p "🏷️  请输入标签 (blog-label): " input_label
        
        # 创建临时头部文件
        cat > header_tmp.txt <<EOF
---
layout: default
title:   "$input_title"
date:   $current_date
blog-label: $input_label
---

EOF
        # 将头部拼接在原内容前面
        cat "$target_path" >> header_tmp.txt
        mv header_tmp.txt "$target_path"
        echo "✅ 已添加完整头部。"
        
    else
        # --- 文件已有头部，检查缺失项 ---
        
        # 1. 检查 layout (自动添加 default)
        if ! grep -q "^layout:" "$target_path"; then
            sed -i "1a layout: default" "$target_path"
            echo "➕ 自动添加: layout: default"
        fi

        # 2. 检查 date (自动添加今天)
        if ! grep -q "^date:" "$target_path"; then
            sed -i "1a date:   $current_date" "$target_path"
            echo "➕ 自动添加: date: $current_date"
        fi

        # 3. 检查 title (询问)
        if ! grep -q "^title:" "$target_path"; then
            read -p "📝 检测缺少 title，请输入: " input_title
            sed -i "1a title:  \"$input_title\"" "$target_path"
        fi

        # 4. 检查 blog-label (询问)
        if ! grep -q "^blog-label:" "$target_path"; then
            read -p "🏷️  检测缺少 blog-label，请输入: " input_label
            sed -i "1a blog-label: $input_label" "$target_path"
        fi
    fi

    # 5. Git 添加特定文件
    #git add "$target_path"
    #default_msg="Add post: $final_name"
    git add .
    default_msg="Added a new note $target_path"

# ==========================================
# 分支 2: 未指定文件 -> 全局同步
# ==========================================
else
    echo "📂 未指定具体文件，执行全局 Git 同步..."
    git add .
    default_msg="Updated some features $(date -d "yesterday" '+%Y/%m/%d-%H:%M:%S')"
fi

# ==========================================
# ☁️ Git 提交流程
# ==========================================
echo "----------------------------------------"

if git diff-index --quiet HEAD --; then
    echo "ℹ️  没有检测到文件变更 (Nothing to commit)。"
    exit 0
fi

echo "📝 请输入提交信息 (回车使用默认值):"
read -p "Commit msg [$default_msg] > " user_msg

if [[ -z "$user_msg" ]]; then
    commit_msg="$default_msg"
else
    commit_msg="$user_msg"
fi

if git commit -m "$commit_msg"; then
    echo "✅ 提交成功"
else
    echo "❌ 提交失败"
    exit 1
fi

echo "🚀 正在推送..."
if git push; then
    echo "🎉 完成!" 
else
    echo "❌ 推送失败"
    exit 1
fi
