import time

def progress(msg = '正在处理', sleep = 0.01):
    for i in range(50):
        i += 1
        print(f"\r🔜 {msg}「 {'#' * i}{' ' * (50 - i)} 」{i * 2}%", end="")
        time.sleep(sleep) # 每次循环暂停 0.1 秒
if __name__ == '__main__':
    progress()