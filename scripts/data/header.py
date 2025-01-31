from datetime import datetime

# --- 用户词典同步表头 ---
# ① 五笔
# ② 拼音+五笔前二辅助码
# 
def get_header_sync(file_name):
    header = f'''
# Rime dictionary - {file_name}
# encoding: utf-8
# 
# --- 说明 ---
# 该字典是基于官方自动同步的用户词典合并排序生成
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 运行脚本：
# - --- 五笔 ---
# - https://github.com/loveminimal/rime-jk/blob/master/scripts/sync_wubi_user_dict.py
# - py scripts/sync_wubi_user_dict.py
# - --- 拼音 ---
# - https://github.com/loveminimal/rime-jk/blob/master/scripts/sync_pinyin_user_dict.py
# - py scripts/sync_pinyin_user_dict.py
# 
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'

# --- 自定义脚本指令 ---
# 
def get_en_aliases_header(file_name):
    header = f'''
# Rime dictionary - {file_name}
# encoding: utf-8
# 
# --- 说明 ---
# 该字典是对既有英文词典的个人扩充
# 用于自定义字符串、命令的快捷输入
# 转化自个人使用的 .bash_aliases 脚本别名文件
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-jk/blob/master/scripts/sync_en_aliases_dict.py
# - py scripts/sync_en_aliases_dict.py
#
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...

'''
    return header.strip() + '\n'
