# 获取 Rime 版本
# by Jack Liu <https://aituyaa.com>
# 


# 执行部署命令
from pathlib import Path


def get_rime_version():
    proj_dir = Path(__file__).resolve().parent.parent
    installation_path = proj_dir / 'installation.yaml'

    with open(installation_path, 'r', encoding='utf-8') as f:
        for line in f:
            stripped_line = line.strip()
            if stripped_line.startswith("distribution_version:"):
                _, value = stripped_line.split(":", 1)
                distribution_version = value.strip()
                return distribution_version

# 主程序
if __name__ == "__main__":

    version = get_rime_version()
    print(version)
