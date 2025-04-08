# 排序现有标准词库
# created by Jack Liu <https://aituyaa.com>
# 
from pathlib import Path
from collections import defaultdict
from header import get_header_sort
from timer import timer


def is_chinese_char(char: str) -> bool:
    code = ord(char)
    return (0x4E00 <= code <= 0x9FFF)

@timer
def combine(src_dir, out_dir):
    res_dict = {}
    res_dict_weight = defaultdict(set)
    lines_total = []

    # 加载所有词典文件
    for file_path in src_dir.iterdir():
        if file_path.is_file() and file_path.name.startswith(dict_start):
            with open(file_path, 'r', encoding='utf-8') as f:
                lines_total.extend(f.readlines())

    # 保留原有词典表头
    header_str = ''
    is_header_end = False
    for line in lines_total:
        if line.startswith('.'):
            is_header_end = True
        if (not is_chinese_char(line[0])) and not is_header_end:
            header_str += line 


    # 去重并处理词条
    for line in set(lines_total):
        if is_chinese_char(line[0]):
            word, code, weight = line.strip().split('\t')
            weight = int(weight)
            if word not in res_dict or weight > max(res_dict_weight[word]):
                res_dict[word] = f'{code}\t{weight}'
                res_dict_weight[word].add(weight)


    # 多级分组排序（词长→编码长度→编码→汉字）
    with open(out_dir / out_file, 'w', encoding='utf-8') as o:
        o.write(header_str)
        o.write(get_header_sort(out_file))
        o.write('...\n')
        
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
            print(f'✅ 已合并处理生成 {word_len} 字词语')
        print('✅  » 已合并生成用户词典 %s' % (out_dir / out_file))


if __name__ == '__main__':
    current_dir = Path.cwd()

    src_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts')
    out_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts')
    dict_start = 'wubi86_district'

    # out_file = f'{dict_start}.sorted.dict.yaml'
    out_file = f'{dict_start}.dict.yaml'

    print('🔜  === 开始同步转换词库文件 ===')
    # 合并至用户文件
    combine(src_dir, out_dir)

