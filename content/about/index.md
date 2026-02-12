---
title: "关于"
description: "Libix 的个人简介"
date: 2025-01-01
menu: "main"
weight: 2
header_visible: true
---

## Hello

欢迎来到我的个人博客。这里主要用于记录技术学习过程、项目经验总结以及一些生活随笔。

我是一名全栈开发工程师，热衷于探索前沿技术，追求简洁优雅的代码实现。

### 主要关注领域

- Web 前端开发 (React, Vue, Modern CSS)
- 服务端开发 (Go, Node.js)
- 云原生技术 (Docker, K8s)

### 联系我

如果你对我的内容感兴趣，或者有合作意向，欢迎通过以下方式联系：

- **Email**: email@example.com
- **Github**: github.com/libix

希望我的文章能对你有所帮助！



# 项目结构说明 (Project Structure)

以下是您 Hugo 博客项目的目录和文件说明：

## 根目录

- **`hugo.toml`**:
  **核心配置文件**。包含了网站的全局设置，如网站标题 (`title`)、基础 URL (`baseURL`)、当前使用的主题 (`theme = "bitx"`)、菜单 (`[menu]`)、以及构建参数等。这是控制整个博客行为的最重要文件。
- **`content/`**:
  **内容目录**。您写的博客文章（Markdown 文件）都存放在这里。比如 `content/posts/` 下通常存放您的博客文章。Hugo 会根据这里的结构生成最终的网页。
- **`themes/`**:
  **主题目录**。存放博客的主题文件。
  - `themes/bitx/`: 您当前正在使用的主题。包含了该主题的布局模板 (`layouts`)、样式表 (`static/css`)、配置文件等。
- **`static/`**:
  **静态资源目录**。存放在这里的图片、CSS、JS 文件会被直接复制到生成的网站根目录下。
  - 例如，如果您放一个 `image.png` 在这里，可以通过 `您的域名/image.png` 访问。
  - 注意：主题也有自己的 `static` 目录 (`themes/bitx/static`)，两者的内容最终会合并，根目录下的 `static` 优先级更高（可以覆盖主题的资源）。
- **`layouts/`** (如果存在):
  **布局模板目录**。如果您想自定义修改主题的某个 HTML 结构，但不想直接修改 `themes/` 目录下的文件（因为升级主题会覆盖），可以将对应文件复制到这个目录下进行修改。Hugo 会优先使用这里的模板。
- **`archetypes/`**:
  **文章原型目录**。定义了新建文章时（使用 `hugo new` 命令）Front Matter（文章头部的元数据，如标题、日期）的默认模板。
- **`public/`**:
  **发布目录**。当您运行 `hugo` 命令生成静态网站时，最终生成的 HTML、CSS、JS 文件都会存放在这里。**这是您需要发布到服务器或 GitHub Pages 的内容。**
- **`data/`** (如果存在):
  **数据目录**。存放 YAML, JSON 或 TOML 格式的数据文件，可以在模板中动态调用。
- **`.gitignore`**:
  **Git 忽略文件**。告诉 Git 哪些文件不需要版本控制（例如 `public/` 目录通常不需要提交，因为它是生成的）。
- **`.hugo_build.lock`**:
  **锁定文件**。防止多个 Hugo 进程同时构建网站，通常不需要手动处理。
- **`.github/`**:
  **GitHub 配置目录**。通常包含 GitHub Actions 的工作流文件（用于自动部署）或 Issue 模板等。
