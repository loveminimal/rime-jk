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
from header import get_header_sync
from timer import timer
from progress import progress
from is_chinese_char import is_chinese_char


@timer
def convert(src_dir, out_dir):
    """
    将用户同步的词典文件合并、排序并生成适用于 Rime 输入法的用户词典文件。

    :param src_dir: 源文件目录
    :param out_dir: 输出文件目录
    """
    # 遍历源文件夹文件，处理
    res_dict = defaultdict(set)  # 使用 defaultdict 提高效率
    lines_total = []

    src_file_path = src_dir / src_file

    print('☑️  已加载用户词库文件 » %s' % src_file_path)
    with open(src_file_path, 'r', encoding='utf-8') as f:
        lines_total = f.readlines()

    with open(out_dir / f'{out_file_temp}', 'w', encoding='utf-8') as o:
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
                code = line_list[0].strip()
                word = line_list[1]
                weight = line_list[2].split(' ')[0].split('=')[1]

                # 删除权重为负数的字词（废词）
                if int(weight) < 0:
                    continue

                # 处理特殊编码
                if '' in code:
                    code = code.split('')[1]

                # 此外不再过滤非 8105 字词（源码表已做过滤 & 加载超范字词）
                # 仅处理已合成词典中 不存在 或 已存在但编码不同的字词
                if word not in res_dict or code not in res_dict[word]:
                    res += f'{word}\t{code}\t{weight}\n'
                    res_dict[word].add(code)

        if len(res.strip()) > 0:
            progress('正在转换')
            print('\n✅  » 已生成用户词库临时文件 %s' % (out_dir / out_file_temp))
            o.write(res)

@timer
def combine(out_dir):
    res_dict = {}
    res_dict_weight = defaultdict(set)
    lines_total = []

    # 加载所有词典文件
    for file_path in out_dir.iterdir():
        if file_path.is_file() and file_path.name.startswith(f'{out_file.split('.')[0] + '.'}'):
            with open(file_path, 'r', encoding='utf-8') as f:
                lines_total.extend(f.readlines())

    # 去重并处理词条
    for line in set(lines_total):
        if is_chinese_char(line[0]):
            word, code, weight = line.strip().split('\t')

            # 增加用户词语的权重，放大亿点点 100,000,000
            if is_keep_user_dict_first:
                weight = int(weight)  * 100000000 if not weight.endswith('00000000') else int(weight)
            else:
                weight = int(weight) if not weight.endswith('00000000') else int(weight[:-8])

            if word not in res_dict or weight > max(res_dict_weight[word]):
                res_dict[word] = f'{code}\t{weight}'
                res_dict_weight[word].add(weight)

    # 多级分组排序（词长→编码长度→编码→汉字）
    with open(out_dir / out_file, 'w', encoding='utf-8') as o:
        o.write(get_header_sync(out_file))
        
        # 第一级：按词长分组
        word_len_dict = defaultdict(list)
        for word, value in res_dict.items():
            word_len_dict[len(word)].append((word, value))

        # 处理每组词长
        for word_len in sorted(word_len_dict.keys()):
            # 第二级：按编码长度分组
            code_len_dict = defaultdict(list)
            for word, value in word_len_dict[word_len]:
                code = value.split('\t')[0]
                code_len_dict[len(code)].append((word, code, value))

            # 按编码长度处理
            for code_len in sorted(code_len_dict.keys()):
                # 关键修改：当编码相同时，按汉字unicode排序
                group = sorted(code_len_dict[code_len], 
                             key=lambda x: (x[1], x[0]))  # 先按编码排序，再按汉字排序
                for word, _, value in group:
                    o.write(f'{word}\t{value}\n')
            print(f'☑️  已合并处理生成 {word_len} 字词语')
        print('✅  » 已合并生成用户词典 %s' % (out_dir / out_file))




if __name__ == '__main__':
    current_dir = Path.cwd()

    # --- 配置：是否让用户词库排在最前 ---
    # 权重放大亿点点
    is_keep_user_dict_first = True

    src_dir = Path('C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\RimeSync\\jk-jack')
    out_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts')

    src_file = 'jk_wubi.userdb.txt'
    out_file = 'wubi86_user.dict.yaml'
    out_file_temp = out_file + '.temp'

    # 如果存在输出文件，先删除
    current_out_file_temp = out_dir / out_file_temp
    if current_out_file_temp.exists():
        current_out_file_temp.unlink()
        
    print('🔜  === 开始同步转换用户自定义词库文件 ===')
    convert(src_dir, out_dir)
    # 合并至用户文件
    combine(out_dir)
    # 清理掉临时文件 *.temp
    current_out_file_temp.unlink()
