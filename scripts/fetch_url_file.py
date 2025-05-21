import os
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

def format_progress_bar(downloaded, total_size, bar_length=50):
    # print(total_size)
    # 可能获取不到 total_size 或 total_size 为 0
    percent = downloaded / (total_size or downloaded)
    filled = int(bar_length * percent)
    bar = '#' * filled + ' ' * (bar_length - filled)
    size = f'{downloaded / 1024 / 1024:.1f}/{total_size / 1024 / 1024:.1f} M' if total_size != 0 else f'{downloaded / 1024 / 1024:.1f} M'
    progress = f"\r🔜 正在下载「 {bar} 」 {size} ¦ {percent * 100:.1f}%"
    print(progress, end='')

def get_remote_mtime(url):
    with urllib.request.urlopen(url) as response:
        last_modified = response.getheader('Last-Modified')
        if last_modified:
            # 转换GMT时间字符串为时间戳（需处理时区请自行调整）
            gmt_time = datetime.strptime(last_modified, '%a, %d %b %Y %H:%M:%S GMT')
            # 添加UTC时区标记
            utc_time = gmt_time.replace(tzinfo=timezone.utc)
            # 转换为北京时间（东八区）
            beijing_time = utc_time.astimezone(timezone(timedelta(hours=8)))
            
            return beijing_time.strftime('%Y-%m-%d %H:%M:%S')
    return None


def fetch_url_file(url, out_dir):
    default_url = 'https://github.com/amzxyz/rime_wanxiang_pro/releases/download/dict-nightly/9-cn_dicts.zip'
    url = url or default_url

    filename = os.path.basename(url)
    # if not filename:
        # filename = 'file.zip'
    filename = 'cn_dicts.zip'
    # print(get_remote_mtime(url))
    out_dir.mkdir(parents=True, exist_ok=True)

    try:
        with urllib.request.urlopen(url) as response:
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            chunk_size = 8192  # 8KB

            with open(out_dir / filename, 'wb') as f:
                while True:
                    chunk = response.read(chunk_size)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)
                    format_progress_bar(downloaded, total_size)

        print(f"\n✅ » 下载完成 {out_dir}")

    except Exception as e:
        print(f"\n下载失败：{e}")


if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent
    work_dir = Path('../.temp_rime').resolve()
    # url = 'https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram'
    url = 'https://github.com/amzxyz/rime_wanxiang/releases/download/dict-nightly/cn_dicts.zip'
    # url = 'https://cdn.bootcdn.net/ajax/libs/vue/3.5.13/vue.global.js'
    # url = 'https://cdn.bootcdn.net/ajax/libs/vue/3.5.13/vue.cjs.js'
    # url = 'https://github.com/amzxyz/rime_wanxiang_pro/releases/download/dict-nightly/9-cn_dicts.zip'
    out_dir = work_dir / 'url_download'
    if not out_dir.exists():
        out_dir.mkdir(parents=True, exist_ok=True)

    fetch_url_file(url, out_dir)
