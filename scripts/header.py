from datetime import datetime

# === 中文表头 ===
def get_header(file_name):
    header = f'''
# Rime dictionary - {file_name}
# encoding: utf-8
# 
# --- 说明 ---
# 该字典是基于官方及极点五笔码表合并排序生成
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 修改内容：
# - 删除非国标 8105-2023 单字及其所组词语 
# - 按字数进行分表处理
# - 合并全国省区县扩展词表
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/wubi86.py
# - py scripts/wubi86.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
# 
# 参考码表：
# - https://github.com/rime/rime-wubi
# - https://github.com/KyleBing/rime-wubi86-jidian
# 
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'


# === 中文表头 ===
def get_header_wx(file_name):
    header = f'''
# Rime dictionary - {file_name}
# encoding: utf-8
# 
# --- 说明 ---
# 该字典是基于白霜拼音结合万象词库转换而成
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 修改内容：
# - 删除非国标 8105-2023 单字及其所组词语
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/py2wx_8105.py
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/wx2custom_8105.py
# 
# 参考码表：
# - https://github.com/iDvel/rime-ice
# - https://github.com/gaboolic/rime-frost 
# - https://github.com/amzxyz/rime_wanxiang_pro
# 
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'


# === 用户词典同步表头 ===
# --- 用户词典同步表头·五笔86 ---
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
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/sync_wubi_user_dict.py
# - py scripts/sync_wubi_user_dict.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
# 
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'

# --- 用户词典同步表头·拼音+五笔前二 ---
def get_header_sync_flypy(file_name):
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
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/sync_flypy_user_dict.py
# - py scripts/sync_flypy_user_dict.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
# 
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'


# === 英文表头 ===
def get_en_header(file_name):
    header = f'''
# Rime dictionary - {file_name}
# encoding: utf-8
# 
# --- 说明 ---
# 该字典是基于雾淞版本、Easy English Nano 和黄狗超大字符集英文码表合并排序生成
# - ¹按字母长度数进行排序处理
# - ²按字母 A-Za-z 顺序排序，不区分大小写
# - ³将字母编码部分全部转为小写并擦去特殊符号，如 -': 等
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/melt_eng.py
# - py scripts/wubi86.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
# 
# 参考码表：
# - https://github.com/iDvel/rime-ice
# - https://github.com/tumuyan/rime-melt
#
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'


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
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/bash_alias2en_aliases_dict.py
# - py scripts/wubi86.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
#
---
name: {'.'.join(file_name.split('.')[:-2])}
version: '{datetime.now().date().strftime("%Y.%m")}'
sort: by_weight
use_preset_vocabulary: false
...

'''
    return header.strip() + '\n'