---
description: 如何简化提交并发布博客
---

1. 在终端中运行发布脚本：
```bash
./publish.sh "这里填写提交信息"
```

该脚本会自动完成：
- `git add .` (添加所有修改)
- `git commit -m "..."` (提交代码)
- `git push origin main` (推送至 GitHub)

随后 GitHub Actions 会自动开始构建并发布您的站点。
