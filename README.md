# Go Shortener — 高端轻量自建短链服务

本项目是一个基于 Rust + SQLite 的极致轻量级自建短链服务。为了提供更佳的用户体验，本项目重新设计并构建了极具现代科技感的前端界面（包含科技暗黑主题、毛玻璃质感卡片、一键复制动画以及动态生成二维码下载功能）。

我们将前端资源整合在 `frontend/` 文件夹下，并通过挂载卷的形式直接被 Docker 容器读取，让后端容器原生提供我们的自定义前端，最后通过 Nginx 进行纯粹的反向代理。

---

## 🏗️ 架构设计

项目采用前端资源直接载入容器、Nginx 反向代理的架构：
1. **Docker 容器**：后端基于 Docker 运行 Rust 编写的 [Chhoto URL](https://github.com/SinTan1729/chhoto-url) 容器。通过挂载 `frontend/` 文件夹并配置 `CHHOTO_CUSTOM_LANDING_DIRECTORY` 环境变量，使容器原生托管我们的自定义精美前端。
2. **Nginx 代理**：仅作为域名的 SSL/HTTPS 终结和反向代理，将所有流量直接打入 Docker 容器。

---

## 🚀 部署步骤

### 第一步：准备代码目录

1. 将本项目的所有代码克隆或下载到您的服务器上的目标部署文件夹中（例如 `/www/wwwroot/shorturl`）：
   ```bash
   git clone https://github.com/Fate-lite/go_short.git /www/wwwroot/shorturl
   ```

### 第二步：启动 Docker 容器

1. 进入部署文件夹：
   ```bash
   cd /www/wwwroot/shorturl
   ```
2. 运行 Docker Compose 启动容器：
   ```bash
   docker-compose up -d
   ```
   *容器将会挂载同目录下的 `frontend/` 提供网页展示，挂载 `data/` 持久化 SQLite 数据库。*

### 第三步：配置 Nginx 反向代理

1. 打开域名的 Nginx 配置文件（在宝塔面板中可以直接在网站设置中的“配置文件”处修改）。
2. 将其修改为类似 `nginx.conf.example` 的反向代理配置，配置段结构如下：

```nginx
# 1. 代理 /dashboard 路由至容器的 /dashboard.html 资源
location = /dashboard {
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header Host $http_host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_redirect off;
  proxy_pass http://127.0.0.1:25504/dashboard.html;
  proxy_buffering off;
}

# 2. 其余所有请求直接透明代理到 Docker 容器
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
