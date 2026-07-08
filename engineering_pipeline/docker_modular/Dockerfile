# =====================================================================
# 阶段一：STAGE 1 - 铸剑苦力 (Builder Stage)
# 价值：在这个时空拉满编译器，把所有硬核的 C 语言底层依赖全部焊好
# =====================================================================
FROM python:3.10-slim AS builder

WORKDIR /build

# 安装 Linux 底层编译军火库（gcc 等 C 语言环境）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖清单，在当前阶段编译出 Wheels 二进制包
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# =====================================================================
# 阶段二：STAGE 2 - 极简杀手 (Final Runtime Stage)
# 价值：彻底剥离 gcc 编译器，不带走一片云彩，只保留纯净的运行肉身
# =====================================================================
FROM python:3.10-slim AS runner

WORKDIR /app

# 注入高阶环境变量：强制打碎日志缓冲区，保证流式日志一秒一闪、零延迟！
ENV PYTHONUNBUFFERED=1

# 💥 跨时空物理劫掠：从 Stage 1 (builder) 的时空里，把编译好的纯净依赖库生生拷贝过来！
COPY --from=builder /root/.local /root/.local
COPY app.py /app/

# 让系统能够认到从上一个阶段拷贝过来的 Python 依赖库路径
ENV PATH=/root/.local/bin:$PATH

# 物理通电启动命令
CMD ["python", "app.py"]