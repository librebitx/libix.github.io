# Libix's Blog

[![Deploy Hugo site to Pages](https://github.com/librebitx/librebitx.github.io/actions/workflows/hugo.yaml/badge.svg)](https://github.com/librebitx/librebitx.github.io/actions/workflows/hugo.yaml)
[![Hugo](https://img.shields.io/badge/Generator-Hugo-pink?style=flat-square)](https://gohugo.io)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

欢迎来到我的个人博客。这里是本人博客的源代码仓库。

原本基于 **Jekyll** 构建，现已全面迁移至 **Hugo**，并使用 **GitHub Actions** 实现自动化部署。

这里主要用于记录技术学习过程、项目经验总结以及一些生活随笔。

如果您发现文中存在技术错误或表述不当，恳请不吝赐教。

您的每一次[指正](https://github.com/librebitx/librebitx.github.io/issues)都是我 Day Day UP 的动力！

希望我的文章能对你有所帮助！

## 本地部署

如果你喜欢我的博客风格并且想在本地预览博客：

1. **克隆仓库**

   ```bash
   git clone --depth 1 --recursive https://github.com/librebitx/librebitx.github.io.git
   # --depth 1 表示只下载最后一次提交，不下载过去的历史记录
   
   cd librebitx.github.io
   ```

2. [**安装 Hugo**](https://github.com/gohugoio/hugo?tab=readme-ov-file#installation)

3. **部署到 GitHub**

   可以参考我的 [Git](https://librebitx.github.io/posts/git/) 笔记

4. **便捷管理**

   ```bash
   ～$ ./blog.sh
   1) New Post  (新建文章)
   2) Preview   (本地预览)
   3) Deploy    (提交发布)
   q) Quit      (退出)
   Select option:
   ```



## 目录结构

```
.
├── .github/                # GitHub Actions 自动化部署配置
│   └── workflows/
│       └── hugo.yaml       # 自动编译、部署到 GitHub Pages 的脚本
├── archetypes/             # 预设的文章元数据模板
│   └── default.md          # 新建文章时自动套用的默认 Front Matter
├── content/                # 站点所有页面和文章的核心内容存放区
│   ├── archives/           # 归档页面入口配置
│   ├── code/               # 代码分享中心（各类配置文件与脚本存储在这里）
│   ├── posts/              # 所有日常博客笔记和文章存放的地方
│   ├── _index.md           # 博客首页内容（个人 About 介绍页内容）
│   └── code-viewer.md      # 用于在原生浏览器环境下无感查看 raw 代码的虚拟入口
├── static/                 # 静态资源存放区（不会被 Hugo 处理，直接复制到公网）
│   └── code -> ../content/code  # 利用软链接使 content/code 中的脚本可以被直接被访问下载
├── themes/                 # Hugo 博客主题存储目录
│   └── bitx/               # 本博客定制的 Accessible Minimalism 极简风格主题
│       ├── layouts/        # 决定页面呈现效果的全部 HTML 模板布局文件
│       └── static/         # 极简主题专用的纯净版 CSS 和 JS 等静态资源
├── hugo.toml               # Hugo 项目的全局配置文件（网站名、菜单、构建开关等）
├── blog.sh                 # 快捷高效的本地管理脚本（包含新建文章、本地预览与自动推送）
├── .gitignore              # 自动过滤敏感文件（如 .env, .key）和编译产物的安全护盾
└── README.md               # 项目自述文件（即本文档）
```

## License

本博客所有文章均采用 [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) 许可协议。转载请注明出处。