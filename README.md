# Libix's Blog

[![Deploy Hugo site to Pages](https://github.com/librebitx/librebitx.github.io/actions/workflows/hugo.yaml/badge.svg)](https://github.com/librebitx/librebitx.github.io/actions/workflows/hugo.yaml)
[![Hugo](https://img.shields.io/badge/Generator-Hugo-pink?style=flat-square)](https://gohugo.io)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

## 关于

这里是本人博客的源代码仓库。
原本基于 **Jekyll** 构建，现已全面迁移至 **Hugo**，并使用 **GitHub Actions** 实现自动化部署。

## 本地部署

如果你喜欢我的博客风格并且想在本地预览博客：

1. **克隆仓库**

   ```bash
   git clone --recursive https://github.com/librebitx/librebitx.github.io.git
   cd librebitx.github.io
   ```

2. **启动 Hugo 服务器**

   ```bash
   # 包含了草稿预览
   hugo server -D
   ```

3. **访问**
   打开浏览器访问 `http://localhost:1313`

4. **添加文章**

   ```bash
   hugo new posts/my-post/index.md
   ```

   这样可以直接把图片放在 `content/posts/my-post/` 文件夹内，在 Markdown 中直接引用即可。

5. **快捷提交**

   ```bash
   # 提交前记得删除 public 文件夹
   sudo rm -rf public
   
   ./publish.sh "Update"
   ```

## 目录结构

```bash
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