# 使用 支持最新依赖与 Edition 2024 (rustc 1.96+) 的 Rust Nightly 版本作为多阶段构建的编译阶段
FROM --platform=$BUILDPLATFORM rust:alpine AS builder

# 安装 musl 编译所需的工具链及 C 依赖
RUN apk add --no-cache musl-dev gcc build-base

WORKDIR /usr/src/go_short

# 拷贝后端 Cargo 配置文件
COPY backend/Cargo.toml backend/Cargo.lock ./backend/

# 创建一个哑源文件以便预先拉取并编译依赖项，缓存 Docker 编译层
RUN mkdir -p backend/src && echo "fn main() {}" > backend/src/main.rs
RUN cargo build --release --locked --manifest-path=backend/Cargo.toml

# 拷贝真正的 Rust 业务源代码
COPY backend/src ./backend/src

# 编译真正的可执行文件（更新之前的哑文件编译产物）
RUN touch backend/src/main.rs && cargo build --release --locked --manifest-path=backend/Cargo.toml

# ========================================================
# 第二阶段：构建最终极轻量级的运行镜像
# ========================================================
FROM alpine:latest

# 安装必要的基础运行时组件，如时区数据
RUN apk add --no-cache tzdata

WORKDIR /

# 从 builder 编译阶段拷贝出已编译好的 Rust 二进制文件
COPY --from=builder /usr/src/go_short/backend/target/release/go-short /go-short

# 将项目自定义前端完全装入镜像中，彻底免去宿主机卷目录映射
COPY frontend /frontend
COPY custom_landing /custom_landing

# 配置默认落地页环境变量指向容器内落地页目录
ENV CHHOTO_CUSTOM_LANDING_DIRECTORY=/custom_landing

ENTRYPOINT ["/go-short"]
