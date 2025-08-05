import re


# 正则表达式方法比直接 ord() 判断稍慢，但更简洁且覆盖全面
# def is_chinese_char(char):
#     """判断单个字符是否为汉字（覆盖所有 Unicode 汉字范围）"""
#     if len(char) != 1:
#         raise ValueError("只能判断单个字符")
    
#     # 正则表达式匹配所有汉字范围
#     pattern = re.compile(
#         r'[\u4E00-\u9FFF\u3400-\u4DBF\u20000-\u2A6DF\u2A700-\u2B739\u2B740-\u2B81D'
#         r'\u2B820-\u2CEAF\u2CEB0-\u2EBEF\u30000-\u3134A\uF900-\uFAFF\u2E80-\u2EFF'
#         r'\u2F00-\u2FDF\u2FF0-\u2FFF\u3000-\u303F\u3105-\u312F]'
#     )
#     return bool(pattern.fullmatch(char))


# 高性能
def is_chinese_char(char):
    """判断单个字符是否为汉字（直接 Unicode 范围比较）"""
    if len(char) != 1:
        raise ValueError("只能判断单个字符")
    
    code = ord(char)
    return (
        (0x4E00 <= code <= 0x9FFF) or    # 基本汉字
        (0x3400 <= code <= 0x4DBF) or    # 扩展 A
        (0x20000 <= code <= 0x2A6DF) or  # 扩展 B
        (0x2A700 <= code <= 0x2B739) or  # 扩展 C
        (0x2B740 <= code <= 0x2B81D) or  # 扩展 D
        (0x2B820 <= code <= 0x2CEAF) or  # 扩展 E
        (0x2CEB0 <= code <= 0x2EBEF) or  # 扩展 F
        (0x30000 <= code <= 0x3134A) or  # 扩展 G
        (0xF900 <= code <= 0xFAFF) or    # 兼容汉字
        (0x2E80 <= code <= 0x2EFF) or    # 部首补充
        (0x2F00 <= code <= 0x2FDF) or    # 康熙部首
        (0x2FF0 <= code <= 0x2FFF) or    # 汉字结构符
        (0x3000 <= code <= 0x303F) or    # 中文标点
        (0x3105 <= code <= 0x312F)       # 注音符号
    )