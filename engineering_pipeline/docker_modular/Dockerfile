# ==========================================
# STAGE 1: 编译器苦力阶段 (Builder Stage)
# ==========================================
FROM python:3.10-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ==========================================
# STAGE 2: 纯净运行杀手阶段 (Runner Stage)
# ==========================================
FROM python:3.10-slim AS runner
WORKDIR /app

# 注入常驻听诊环境变量，防止日志卡在缓冲区
ENV PYTHONUNBUFFERED=1

# 从第一阶段拷来干净的二进制 Python 依赖包
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# 💥 全量压入初学者实验文件夹下的核心代码与资产配置
# COPY raw_data/ /app/raw_data/    把这行删去，采用解耦的数据目录方式挂载
COPY config.yaml /app/
COPY pipeline.py /app/
COPY app.py /app/

CMD ["python", "app.py"]