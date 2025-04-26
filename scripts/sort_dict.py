# 排序现有标准词库
# created by Jack Liu <https://aituyaa.com>
# 
import hashlib
from pathlib import Path
from collections import defaultdict
from header import get_header_sort
from timer import timer
from wubi86_8105_map import wubi86_8105_map


def is_chinese_char(char: str) -> bool:
    """
    判断字符是否属于《通用规范汉字表》8105字范围内的汉字。
    使用 Unicode 区间列表优化判断。
    """
    if len(char) != 1:
        return False
    
    code = ord(char)
    # 所有 CJK 汉字 Unicode 区间（基本区 + 扩展A-G）
    cjk_ranges = [
        (0x4E00, 0x9FFF),    # 基本区
        (0x3400, 0x4DBF),    # 扩展A
        (0x20000, 0x2A6DF),  # 扩展B
        (0x2A700, 0x2B73F),  # 扩展C
        (0x2B740, 0x2B81F),  # 扩展D
        (0x2B820, 0x2CEAF),  # 扩展E
        (0x2CEB0, 0x2EBEF),  # 扩展F
        (0x30000, 0x3134F),  # 扩展G
    ]
    
    return any(start <= code <= end for start, end in cjk_ranges)

def get_md5(text: str) -> str:
    """计算字符串的 MD5 哈希值"""
    md5 = hashlib.md5()  # 创建 MD5 对象
    md5.update(text.encode('utf-8'))  # 传入字节数据（必须 encode）
    return md5.hexdigest()  # 返回 32 位 16 进制字符串

@timer
def sort_dict(src_dir, out_dir):
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
            # if word not in res_dict or weight > max(res_dict_weight[word]):
            #     res_dict[word] = f'{code}\t{weight}'
            #     res_dict_weight[word].add(weight)
            
            # 8105 过滤器开关 - is_filter_8105
            if is_filter_8105 and any((char not in wubi86_8105_map and char not in white_list) for char in word):
                continue
            
            # 唯一化
            if word not in res_dict:
                res_dict[word + get_md5(line)] = f'{code}\t{weight}'
                # res_dict_weight[word].add(weight)


    # 多级分组排序（词长→编码长度→编码→汉字）
    with open(out_dir / out_file, 'w', encoding='utf-8') as o:
        o.write(header_str)
        # o.write(get_header_sort(out_file))
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
                            #  key=lambda x: (x[0], x[1]))  # 先按汉字排序，再按编码排序
                for word, _, value in group:
                    o.write(f'{word[:-32]}\t{value}\n')
            print(f'☑️  已合并处理生成 {word_len - 32} 字词语')
        print('✅  » 已合并生成用户词典 %s' % (out_dir / out_file))


if __name__ == '__main__':
    current_dir = Path.cwd()

    # 是否开启 8105 通规字字符范围过滤
    is_filter_8105 = True
    white_list = ['，']

    src_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts')
    out_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts\\out')
    dict_start = 'wubi86.dict.yaml'

    if not out_dir.exists():
        out_dir.mkdir(parents=True, exist_ok=True)

    # out_file = f'{dict_start}.sorted.dict.yaml'
    # out_file = f'{dict_start}.dict.yaml'
    out_file = dict_start

    print('🔜  === 开始同步转换词库文件 ===')
    # 合并至用户文件
    sort_dict(src_dir, out_dir)

