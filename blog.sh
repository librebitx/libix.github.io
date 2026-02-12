#!/bin/bash

# ==========================================
# Hugo Blog Manager (Fix: Commit -> Pull -> Push)
# ==========================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 新建文章
function new_post() {
    echo -e "${YELLOW}>>> Creating New Post...${NC}"
    read -p "Enter Title: " TITLE
    SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    hugo new "posts/$SLUG/index.md"
    echo -e "${GREEN}Created: content/posts/$SLUG/index.md${NC}"
    
    vim "content/posts/$SLUG/index.md"

}

# 本地预览
function preview() {
    echo -e "${YELLOW}>>> Starting Local Server...${NC}"
    hugo server -D
}

# 自动发布
function deploy() {
    echo -e "${YELLOW}>>> Starting Deployment Workflow...${NC}"

    # --- 提交本地修改 ---
    echo "1. Staging and Committing changes..."
    git add .
    
    read -p "Enter commit message (default: update): " MSG
    if [ -z "$MSG" ]; then
        MSG="update: $(date +'%Y-%m-%d %H:%M')"
    fi
    
    git commit -m "$MSG"
    
    # --- 同步云端 ---
    echo "2. Syncing with GitHub (Pulling)..."
    git pull --rebase origin main
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Conflict detected! Please fix conflicts manually.${NC}"
        exit 1
    fi

    # --- 推送到云端 ---
    echo "3. Pushing to GitHub..."
    git push origin main

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}>>> Success! Blog updated. 🚀${NC}"
    else
        echo -e "${RED}>>> Push failed. Check network or git errors.${NC}"
    fi
}

echo -e "${GREEN}=== Hugo Blog Manager ===${NC}"
echo "1) New Post  (新建文章)"
echo "2) Preview   (本地预览)"
echo "3) Deploy    (提交发布)"
echo "q) Quit      (退出)"

read -p "Select option: " choice

case $choice in
    1) new_post ;;
    2) preview ;;
    3) deploy ;;
    q) exit 0 ;;
    *) echo "Invalid option" ;;
esac