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
│       └── hugo.yaml       # 持续集成与发布脚本
├── archetypes/             # 文章内容模板
│   └── default.md          # 新建文章时的默认元数据
├── content/                # 站点核心内容
│   ├── about/              # “关于”页面
│   ├── archives/           # 归档页面定义
│   ├── posts/              # 博客文章博文目录
│   └── code/               # 代码中心
│       ├── code-viewer.md  # 代码查看器逻辑
│       └── ...             # 各类脚本与配置文件目录
├── data/                   # 外部数据文件
├── static/                 # 静态资源
├── themes/                 # 主题存储目录
│   └── bitx/               # 当前使用的 bitx 主题
│       ├── layouts/        # HTML 模板布局
│       └── static/         # 主题专用的 CSS/JS 资源
├── hugo.toml               # 项目全局配置文件
└── README.md               # 项目自述文件
```

## License

本博客所有文章均采用 [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) 许可协议。转载请注明出处。