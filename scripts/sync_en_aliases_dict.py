# 基于本地用户 .bash_aliases 文件生成可用的 en_aliases 英文反查词库
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-jk/blob/master/scripts/sync_en_aliases_dict.py
# - py scripts/sync_en_aliases_dict.py [-i src] [-o out] [-f file_endswith_filter]
# 
# 默认目录：
# src - C:\\Users\\jack\\.bash_aliases
# out - C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts\\en_aliases.dict.yaml
# 
import re
from pathlib import Path
from header import get_en_aliases_header
from timer import timer

from progress import progress


@timer
def convert(src_dir, out_dir, file_endswith_filter):
    # 遍历源文件夹文件，处理
    dict_num = 0
    lines = []

    # for file_path in src_dir.iterdir():
    #     if file_path.is_file() and file_path.name.endswith(file_endswith_filter):
    #         dict_num = dict_num + 1
    #         print('☑️  已加载第 %d 份码表 » %s' % (dict_num, file_path))

    #         with open(file_path, 'r', encoding='utf-8') as f:
    #             lines = f.readlines()

    file_path = src_dir / file_endswith_filter
    print('☑️  已加载快捷别名命令列表 » %s' % (file_path))
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    lines_list = []
    res = ''
    is_start = False
    for line in lines:
        if not is_start and not line.startswith('alias'):
            continue
        # elif line.strip() == '':
        # 	res = res + line
        else:
            is_start = True
            if not line.startswith('#') and line.strip() != '':
                line_list = re.split(r'(alias |=["\'])', line.strip()[:-1])
                # ['', 'alias ', 'cphs', '="', 'cp ~/.bash_aliases ~/.shell/']
                alias = line_list[2]
                cmd = line_list[4]

                res = res + f'{cmd}\t{alias}\t0\n'
            else:
                res = res + line

    with open(out_dir / f'{out_file}', 'a', encoding='utf-8') as o:
        progress()
        print(f'\n✅  » 已合并排序去重英文码表 - 共 {len(lines_list)} 条')
        o.write(get_en_aliases_header(f'{out_file}'))
        o.write(res)


if __name__ == '__main__':
    current_dir = Path.cwd()

    src_dir = Path('C:\\Users\\jack')
    out_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts')
    file_endswith_filter = '.bash_aliases'

    out_file = 'en_aliases.dict.yaml'

    # 如果存在输出文件，先删除
    current_out_file = out_dir / out_file
    if current_out_file.exists():
        current_out_file.unlink()
    print('☑️  === 开始同步转换本地脚本别名文件 ===')
    convert(src_dir, out_dir, file_endswith_filter)
