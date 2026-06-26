# 🌌 Go Short — 极具未来感的轻量级自建短链服务

[![Rust](https://img.shields.io/badge/Language-Rust-orange.svg?style=flat-square)](https://www.rust-lang.org/)
[![Docker](https://img.shields.io/badge/Container-Docker-blue.svg?style=flat-square)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

**Go Short** 是一个基于 **Rust + SQLite** 极致轻量级自建短链解决方案。为提升产品视觉质感与人机交互体验，本项目全套重构了前台短链缩短器以及后台链接管理面板，融入了**赛博暗黑主题、毛玻璃拟态卡片 (Glassmorphism)、智能渐变微光、动态二维码生成下载**等现代高端设计元素。

本项目通过自主编写 Dockerfile，将精美的响应式前端代码无缝整合到 Docker 镜像内，实现了无挂载、原生的容器部署形态，前置 Nginx 只作为纯净的 SSL 终结与反向代理。

---

## 🎨 界面预览

### 🛸 落地页短链缩短器 (Landing Page)
拥有极致丝滑的微光特效与毛玻璃拟态输入组件，支持自定义后缀、失效时间设置，并提供一键下载短链专属二维码的能力。
![Landing Page Preview](go_short_landing_preview.png)

### 📊 智能后台管理面板 (Admin Dashboard)
集成多维度 Telemetry 视觉图表感官，提供清晰的链接状态、历史点击量 (Hits) 追踪、到期管理等深度运维功能。
![Admin Dashboard Preview](go_short_dashboard_preview.png)

---

## 🏗️ 架构设计与集成机制

本项目抛弃了传统的“外挂挂载卷”的部署方式，采用了更加高内聚、易维护的**镜像一体化**设计：

1. **零挂载原生前端**：我们在 `Dockerfile` 中通过 `COPY` 指令将 `custom_landing/` 与 `frontend/` 直接打包进入了 Docker 镜像内，使其成为了容器的一部分。
2. **纯粹的 Nginx 代理**：域名的 Nginx 配置退化为极其纯净的四层/七层透明代理，不承载任何静态资源文件路由，所有流量直接透明打入容器，防止 Nginx 与后端容器产生文件同步不一致的痛点。

---

## 🚀 极速部署指南

### 第一步：克隆项目代码
将本项目的所有代码克隆到您的服务器目标部署文件夹中：
```bash
git clone https://github.com/Fate-lite/go_short.git /www/wwwroot/shorturl
```

### 第二步：启动容器服务
进入部署目录，一键构建镜像并启动容器：
```bash
cd /www/wwwroot/shorturl
docker-compose up -d --build
```
> 容器会在本地构建专属 Docker 镜像，挂载 `/data` 用以持久化 SQLite 数据库文件（`urls.sqlite`）。

### 第三步：配置 Nginx 反向代理
在 Nginx 站点配置中（或宝塔面板站点配置文件中）加入以下规则，实现域名的透明转发：

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name go.fatep.eu.org;
    
    # SSL 配置与证书文件设置（略）
    
    # 纯净透明反向代理
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:25504;
        proxy_buffering off;
    }
}
```
保存后重载 Nginx：
```bash
nginx -t && nginx -s reload
```

---

## 🔒 安全与凭据自定义

您可以在 `docker-compose.yml` 的 `environment` 中自定义以下安全凭证：
* **`password`**: 管理面板的解锁密码（已默认为 `110`）。
* **`CHHOTO_API_KEY`**: 通用 REST API 接口鉴权密钥（已默认为 `fate110_api_key`）。

---

## 🔌 高性能 REST API 接口规范

除了精美的可视化 UI，您可以通过任意程序调用底层通用接口进行短链管理。

### 1. 瞬时生成短链接 (POST)
* **API 端点**: `POST https://yourdomain.com/api/new`
* **请求头**:
  * `X-Api-Key: fate110_api_key`
  * `Content-Type: application/json`
* **JSON 请求体**:
  ```json
  {
    "longlink": "https://www.baidu.com",
    "shortlink": "baidu"  // (选填) 自定义后缀，若缺省则由系统智能生成
  }
  ```
* **响应结果**:
  ```json
  {
    "success": true,
    "error": false,
    "shorturl": "https://go.fatep.eu.org/baidu",
    "expiry_time": 0
  }
  ```

### 2. 导出所有链接资产 (GET)
* **API 端点**: `GET https://yourdomain.com/api/all`
* **请求头**:
  * `X-Api-Key: fate110_api_key`
* **响应结果**:
  ```json
  [
    {
      "shortlink": "baidu",
      "longlink": "https://www.baidu.com",
      "hits": 105,
      "expiry_time": 0,
      "notes": ""
    }
  ]
  ```
