# 基于官方自动同步的用户词典合并排序生成用户词典
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-jk/blob/master/scripts/sync_wubi_user_dict.py
# - py scripts/sync_wubi_user_dict.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
# 
# 默认目录：
# src - C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\RimeSync\\jk-wubi\\jk_wubi.userdb.txt
# out - C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts\\wubi_user.dict.yaml
# 
import sys
import re
from pathlib import Path
from collections import defaultdict
from header import get_header_sync
from data.char_8105 import char_8105
from timer import timer

@timer
def convert(SRC_DIR, OUT_DIR, FILE_ENDSWITH_FILETER, MULTIFILE_OUT_MODE):
	"""
    将用户同步的词典文件合并、排序并生成适用于 Rime 输入法的用户词典文件。

    :param SRC_DIR: 源文件目录
    :param OUT_DIR: 输出文件目录
    :param FILE_ENDSWITH_FILETER: 文件后缀过滤条件
    :param MULTIFILE_OUT_MODE: 输出模式（0：单个文件，1：多个文件）
    """
	# 遍历源文件夹文件，处理
	dict_num = 0
	res_dict = defaultdict(set)  # 使用 defaultdict 提高效率
	lines_total = []

	for file_path in SRC_DIR.iterdir():
		if file_path.is_file() and file_path.name.endswith(FILE_ENDSWITH_FILETER):
			dict_num = dict_num + 1
			print('☑️  已加载第 %d 份码表 » %s' % (dict_num, file_path))

			with open(file_path, 'r', encoding='utf-8') as f:
				lines = f.readlines()
				lines_total.extend(lines)

	# 设定最大统计字长列表 - 15个字
	word_len_list = list(range(50))
	has_header = False
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
			if not line[0] in '# ': 	# 忽略注释和特殊行
				line_list = re.split(r'\t+',line.strip())
				code = line_list[0]
				word = line_list[1]
				weight = line_list[2].split(' ')[0].split('=')[1]
				
				# 处理特殊编码
				if '' in code:
					code = code.split('')[1]


				# 按字长顺序过滤依次处理 1, 2, 3, 4 ...
				if len(word) == word_len and all(w in char_8105 for w in word):
					# 按字长过滤并确保词条唯一性
					# 仅处理已合成词典中 不存在 或 已存在但编码不同的字词
					if len(word) == word_len and all(w in char_8105 for w in word):
						if word not in res_dict or code not in res_dict[word]:
							res += f'{word}\t{code}\t{weight}\n'
							res_dict[word].add(code)

		if len(res.strip()) > 0:
			MULTIFILE_OUT_MODE = int(MULTIFILE_OUT_MODE)
			# 按字长生成多个文件
			if MULTIFILE_OUT_MODE == 1:
				with open(OUT_DIR / f'wubi86_{word_len}.dict.yaml', 'a', encoding='utf-8') as o:
					print('✅  » 已合并处理生成 %s 字文件' % word_len)
					o.write(get_header_sync(f'wubi86_{word_len}.dict.yaml'))
					o.write(res)
			# 统一生成在单个文件
			elif MULTIFILE_OUT_MODE == 0:
				with open(OUT_DIR / f'{out_file}', 'a', encoding='utf-8') as o:
					print('✅  » 已合并处理生成 %s 字词语' % word_len)
					if (not has_header and res[0] in char_8105):
						o.write(get_header_sync(f'{out_file}'))	# 仅字长为 1 时添加表头
						has_header = True
					o.write(res)

if __name__ == '__main__':
	current_dir = Path.cwd()

	src = 'C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\RimeSync\\jk-wubi' # 用户同步词典目录
	out = 'C:\\Users\\jack\\AppData\\Roaming\\Rime\\dicts'              # 输入用户词典目录
	file_endswith_filter = 'wubi.userdb.txt'                         # 待转换的用户词典
	multifile_out_mode = 0

	out_file = 'wubi_user.dict.yaml'                                    # 转换后的用户词典

	# 命令行输入选项
	# ... py scripts/wubi86.py [-i src] [-o out] [-f file_endswith_filter] [-m multifile_out_mode]
	for i, arg in enumerate(sys.argv):
		if arg == "-i":
			src = sys.argv[i + 1]
		elif arg == '-o':
			out = sys.argv[i + 1]
		elif arg == '-f':
			file_endswith_filter = sys.argv[i + 1]
		elif arg == '-m':
			multifile_out_mode = sys.argv[i + 1]

	src_dir = current_dir / src										    # 设置待处理的拼音词库文件夹
	out_dir =  current_dir / out									    # 转换后输出的五笔词库文件夹

	# 如果存在输出文件，先删除
	current_out_file = out_dir / out_file
	if current_out_file.exists():
		current_out_file.unlink()


	convert(src_dir, out_dir, file_endswith_filter, multifile_out_mode)
