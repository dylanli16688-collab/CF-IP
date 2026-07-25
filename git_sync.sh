#!/bin/bash

# ============================================================
# CF-IP 自动同步 GitHub
#
# 功能：
# 1. 专用 SSH Key
# 2. 只同步 ip.txt
# 3. 自动忽略临时文件
# 4. 防止重复运行
# 5. GitHub失败自动重试
# ============================================================


PROJECT_DIR="/opt/1panel/apps/cfnb"

LOCK_FILE="/tmp/cfip_git_sync.lock"

SSH_KEY="$HOME/.ssh/id_ed25519_cfip"

REMOTE="git@github-cfip:dylanli16688-collab/CF-IP.git"

MAX_RETRY=3


echo "================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') CF-IP GitHub同步开始"
echo "================================================"



# =============================
# 防重复执行
# =============================

if [ -f "$LOCK_FILE" ]; then

    echo "检测到同步任务正在运行"

    exit 0

fi


touch "$LOCK_FILE"


trap "rm -f $LOCK_FILE" EXIT



cd "$PROJECT_DIR" || exit 1



# =============================
# SSH检查
# =============================


echo "测试GitHub SSH连接"


ssh \
-o IdentitiesOnly=yes \
-i "$SSH_KEY" \
-T git@github-cfip 2>&1 | head -1



# =============================
# 设置远程仓库
# =============================


git remote set-url origin "$REMOTE"



echo

echo "当前远程仓库:"
git remote -v



# =============================
# 检查ip.txt
# =============================


if [ ! -f ip.txt ]; then

    echo "错误：ip.txt不存在"

    exit 1

fi



# =============================
# 只添加ip.txt
# =============================


git add ip.txt



if git diff --cached --quiet; then


    echo "ip.txt 无变化，无需同步"

    exit 0


fi



# =============================
# 提交
# =============================


MSG="Update ip.txt $(date '+%Y-%m-%d %H:%M:%S')"



git commit -m "$MSG"



if [ $? -ne 0 ]; then

    echo "提交失败"

    exit 1

fi



# =============================
# 推送
# =============================


for ((i=1;i<=MAX_RETRY;i++))

do


echo

echo "正在推送 GitHub 尝试 $i/$MAX_RETRY"


GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" \
git push origin main



if [ $? -eq 0 ]; then


    echo

    echo "GitHub同步成功"


    exit 0


fi



echo "推送失败"

sleep 5


done



echo

echo "GitHub同步失败"


exit 1