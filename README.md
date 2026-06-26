# Go Shortener — 高端轻量自建短链服务

本项目是一个基于 Rust + SQLite 的极致轻量级自建短链服务。为了提供更佳的用户体验，本项目重新设计并构建了极具现代科技感的前端界面（包含科技暗黑主题、毛玻璃质感卡片、一键复制动画以及动态生成二维码下载功能），并基于 Nginx 实现了前后端解耦的混合路由部署方案。

---

## 🏗️ 架构设计

项目采用前后端分离的混合部署架构：
1. **前端静态网页 (`/`, `/dashboard`, `/style.css`)**：由宿主机的 Nginx 服务直接极速分发，静态资源修改免重启，即时生效。
2. **后端服务容器 (`/api/*`, `/*`)**：基于 Docker 运行 Rust 编写的 [Chhoto URL](https://github.com/SinTan1729/chhoto-url) 容器，负责数据库管理、短链生成及 `308` 高并发跳转转发。

---

## 🚀 部署步骤

### 第一步：启动后端 Docker 容器

1. 将 `docker-compose.yml` 复制到服务器的目标文件夹下（例如 `/www/wwwroot/shorturl`）。
2. 在该文件夹下运行以下命令启动服务：
   ```bash
   docker-compose up -d
   ```
   *服务将运行在宿主机的 `25504` 端口，并将 SQLite 数据库文件持久化在同目录下的 `./data` 文件夹中。*

### 第二步：配置前端静态文件

1. 将 `index.html`、`dashboard.html` 和 `style.css` 上传至您网站的根目录下（例如 `/www/wwwroot/go.fatep.eu.org/`）。

### 第三步：配置 Nginx 反向代理

1. 打开域名的 Nginx 配置文件（在宝塔面板中可以直接在网站设置中的“配置文件”处修改）。
2. 将其修改为类似 `nginx.conf.example` 的配置，重点是以下路由规则：

```nginx
# 1. 首页静态资源由 Nginx 直接提供
location = / {
  root /www/wwwroot/go.fatep.eu.org;
  try_files /index.html =404;
}

# 2. 管理面板静态资源由 Nginx 直接提供
location = /dashboard {
  root /www/wwwroot/go.fatep.eu.org;
  try_files /dashboard.html =404;
}

# 3. 样式表资源直接提供
location = /style.css {
  root /www/wwwroot/go.fatep.eu.org;
  try_files /style.css =404;
}

# 4. REST API 接口转发至 Docker 容器
location /api/ {
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header Host $http_host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_redirect off;
  proxy_pass http://127.0.0.1:25504;
  proxy_buffering off;
}

# 5. 其余跳转后缀请求 Fallback 路由至 Docker 容器
location / {
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header Host $http_host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_redirect off;
  proxy_pass http://127.0.0.1:25504;
  proxy_buffering off;
}
```
3. 保存后测试并重载 Nginx 服务：
   ```bash
   nginx -t && nginx -s reload
   ```

---

## 🔒 权限与凭据配置

您可以在 `docker-compose.yml` 的 `environment` 中自定义以下安全凭证：
* **`password`**: 管理面板解锁密码（已配置为 `110`）。
* **`CHHOTO_API_KEY`**: REST API 鉴权密钥（已配置为 `fate110_api_key`）。

---

## 🔌 通用 REST API 接口说明

服务提供通用的 OpenAPI 接口，方便集成至快捷指令（iOS Shortcuts）、Alfred 插件或第三方脚本中。

### 1. 生成短链接 (POST)
* **地址**: `POST https://yourdomain.com/api/new`
* **Headers**:
  * `X-Api-Key: fate110_api_key`
  * `Content-Type: application/json`
* **JSON 请求体**:
  ```json
  {
    "longlink": "https://www.baidu.com",
    "shortlink": "baidu"  // (选填) 自定义后缀，不传则随机生成
  }
  ```
* **响应结果**:
  ```json
  {"success":true,"error":false,"shorturl":"https://go.fatep.eu.org/baidu","expiry_time":0}
  ```

### 2. 获取链接列表 (GET)
* **地址**: `GET https://yourdomain.com/api/all`
* **Headers**:
  * `X-Api-Key: fate110_api_key`
* **响应结果**:
  ```json
  [
    {
      "shortlink": "baidu",
      "longlink": "https://www.baidu.com",
      "hits": 12,
      "expiry_time": 0,
      "notes": ""
    }
  ]
  ```
