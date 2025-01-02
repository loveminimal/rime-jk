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
version: {datetime.now().date()}
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'


# === 用户词典同步表头 ===
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
# - https://github.com/loveminimal/rime-jk/blob/master/scripts/sync_wubi_user_dict.py
# - py scripts/rime_sync_dict_to_wubi86_user_dict.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
# 
---
name: {'.'.join(file_name.split('.')[:-2])}
version: {datetime.now().date()}
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
# 该字典是基于雾淞版本和黄狗超大字符集英文码表合并排序生成
# - 按字母长度数进行排序处理
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-utils/blob/master/scripts/melt_eng.py
# - py scripts/wubi86.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
# 
# 参考码表：
# - https://github.com/iDvel/rime-ice
#
---
name: {'.'.join(file_name.split('.')[:-2])}
version: {datetime.now().date()}
sort: by_weight
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'