# 基于官方自动同步的用户词典合并排序生成用户词典
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-jk/blob/master/scripts/sync_wubi_user_dict.py
# - py scripts/sync_wubi_user_dict.py
# 
# 默认目录：
# src - C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\RimeSync\\jk-jack\\jk_wubi.userdb.txt
# out - C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts\\wubi86_user.dict.yaml
# 
import re
from pathlib import Path
from collections import defaultdict
from data.header import get_header_sync
from timer import timer


def convert(src_dir, out_dir, file_endswith_filter):
    """
    将用户同步的词典文件合并、排序并生成适用于 Rime 输入法的用户词典文件。

    :param src_dir: 源文件目录
    :param out_dir: 输出文件目录
    :param file_endswith_filter: 文件后缀过滤条件
    """
    # 遍历源文件夹文件，处理
    dict_num = 0
    res_dict = defaultdict(set)  # 使用 defaultdict 提高效率
    lines_total = []

    for file_path in src_dir.iterdir():
        if file_path.is_file() and file_path.name.endswith(file_endswith_filter):
            dict_num = dict_num + 1
            print('☑️  已加载第 %d 份码表 » %s' % (dict_num, file_path))

            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                lines_total.extend(lines)

    # 设定最大统计字长列表 - 15个字
    word_len_list = list(range(26))
    with open(out_dir / f'{out_file_temp}', 'a', encoding='utf-8') as o:
        for word_len in word_len_list:
            res = ''
            # 以下几行为原始同步词典格式
            # ---------------------------------------------------
            # yywg 	方便	c=3 d=0.187308 t=1959
            # yywr 	文件	c=1 d=0.826959 t=1959
            # encabb 	萍聊了	c=0 d=0.0201897 t=1959
            # encabbk 	萍聊了吗	c=0 d=0.0202909 t=1959
            # encabbn 	萍聊了	c=0 d=0.0201897 t=1959
            # ---------------------------------------------------
            for line in lines_total:
                if not line[0] in '# ':  # 忽略注释和特殊行
                    line_list = re.split(r'\t+', line.strip())
                    code = line_list[0]
                    word = line_list[1]
                    weight = line_list[2].split(' ')[0].split('=')[1]

                    # 删除权重为负数的字词（废词）
                    if int(weight) < 0:
                        continue

                    # 处理特殊编码
                    if '' in code:
                        code = code.split('')[1]

                    # 按字长顺序过滤依次处理 1, 2, 3, 4 ...
                    # if len(word) == word_len and all(w in char_8105 for w in word):
                    # 此外不再过滤非 8105 字词（源码表已做过滤 & 加载超范字词）
                    if len(word) == word_len:
                        # 按字长过滤并确保词条唯一性
                        # 仅处理已合成词典中 不存在 或 已存在但编码不同的字词
                            if word not in res_dict or code not in res_dict[word]:
                                res += f'{word}\t{code}\t{weight}\n'
                                res_dict[word].add(code)

            if len(res.strip()) > 0:
                print('✅  » 已合并处理生成 %s 字词语' % word_len)
                o.write(res)

def is_chinese_char(char: str) -> bool:
    code = ord(char)
    return (0x4E00 <= code <= 0x9FFF)

@timer
def combine(out_dir):
    dict_num = 0
    res_dict = {}
    res_dict_weight = defaultdict(set)
    lines_total = []
    print('☑️  === 合并到用户词典 ===')
    for file_path in out_dir.iterdir():
        if file_path.is_file() and file_path.name.startswith('wubi86_user'):
            dict_num = dict_num + 1
            print('☑️  已加载第 %d 份码表 » %s' % (dict_num, file_path))

            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                lines_total.extend(lines)

    # 去重未变动行
    lines_total = list(dict.fromkeys(lines_total))

    # 设定最大统计字长列表 - 15个字
    word_len_list = list(range(26))
    with open(out_dir / f'{out_file}', 'w', encoding='utf-8') as o:
        for word_len in word_len_list:
            res = ''
            for line in lines_total:
                if not is_chinese_char(line[0]):  # 忽略注释和特殊行
                    continue

                word, code, weight = line.strip().split('\t')

                # 按字长顺序过滤依次处理 1, 2, 3, 4 ...
                # 此外不再过滤非 8105 字词（源码表已做过滤 & 加载超范字词）
                if len(word) == word_len:
                    if word not in res_dict or weight > max(res_dict_weight[word]):
                        res_dict[word] = f'{code}\t{weight}'
                        res_dict_weight[word].add(weight)

        res = ''
        for key, value in res_dict.items():
            res += f'{key}\t{value}\n'

        if len(res.strip()) > 0:
            print('✅  » 已合并生成用户词典')
            o.write(get_header_sync(f'{out_file}'))
            o.write(res)


if __name__ == '__main__':
    current_dir = Path.cwd()

    src_dir = Path('C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\RimeSync\\jk-jack')
    out_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts')
    file_endswith_filter = 'jk_wubi.userdb.txt'

    out_file = 'wubi86_user.dict.yaml'
    out_file_temp = out_file + '.temp'

    # 如果存在输出文件，先删除
    current_out_file_temp = out_dir / out_file_temp
    if current_out_file_temp.exists():
        current_out_file_temp.unlink()
        
    print('☑️  === 开始同步转换用户自定义词库文件 ===')
    convert(src_dir, out_dir, file_endswith_filter)
    # 合并至用户文件
    combine(out_dir)
    # 清理掉临时文件 *.temp
    current_out_file_temp.unlink()