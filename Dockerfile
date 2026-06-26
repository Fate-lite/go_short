FROM sintan1729/chhoto-url:latest

# 将自定义前端复制入镜像内部，避免外部目录挂载
COPY frontend /frontend

# 配置环境变量默认指向镜像内的前端目录
ENV CHHOTO_CUSTOM_LANDING_DIRECTORY=/frontend
