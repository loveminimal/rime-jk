import time
from functools import wraps

def timer(func):
    """
    统计函数执行时间的装饰器
    """
    @wraps(func)  # 保留原函数的元信息
    def wrapper(*args, **kwargs):
        start_time = time.time()  # 记录开始时间
        result = func(*args, **kwargs)  # 执行函数
        end_time = time.time()  # 记录结束时间
        print(f"⏰ 函数 {func.__name__} 执行时间: {end_time - start_time:.4f} 秒")
        return result
    return wrapper