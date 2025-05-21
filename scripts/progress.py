import time

def progress(msg = '正在处理', sleep = 0.01):
    for i in range(50):
        i += 1
        print(f"\r🔜 {msg}「 {'#' * i}{' ' * (50 - i)} 」{i * 2}%", end="")
        time.sleep(sleep) # 每次循环暂停 0.1 秒

def format_progress_bar(downloaded, total_size, bar_length=50):
    # print(total_size)
    # 可能获取不到 total_size 或 total_size 为 0
    percent = downloaded / (total_size or downloaded)
    filled = int(bar_length * percent)
    bar = '#' * filled + ' ' * (bar_length - filled)
    size = f'{downloaded / 1024 / 1024:.1f}/{total_size / 1024 / 1024:.1f} M' if total_size != 0 else f'{downloaded / 1024 / 1024:.1f} M'
    progress = f"\r🔜 正在下载「 {bar} 」 {size} ¦ {percent * 100:.1f}%"
    print(progress, end='')

if __name__ == '__main__':
    progress()