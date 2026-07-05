import sys
import time

print("🛰️ [Yuto Pipeline] 容器化基础测试镜像通电成功！")
print(f"🐍 当前容器内部运行的 Python 物理版本为: {sys.version}")

# 模拟高频电商流式对账的无尽循环
try:
    for i in range(1, 500):
        print(f" [Yuto Pipeline] 正在进行第 {i} 次流式对账操作...")
        time.sleep(1)  # 模拟处理时间
    print("[Yuto Pipeline] 流式对账操作完成！")
except KeyboardInterrupt:
    print("[Yuto Pipeline] 流式对账操作被用户中断。")

