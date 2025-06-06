# 将没有辅助码的词典转换成带辅助码的万象
# --- AMZ

import os
from pathlib import Path
import re
import shutil

# 加载元数据函数，用于加载单字及其对应的拼音辅助码
def load_metadata(metadata_dir):
    metadata = {}
    # 遍历元数据目录中的所有文件
    for filename in os.listdir(metadata_dir):
        file_path = os.path.join(metadata_dir, filename)
        # 只处理以 .txt、.yaml 或 .yml 结尾的文件
        if os.path.isfile(file_path) and (filename.endswith('.yaml') or filename.endswith('.yml')):
            print(f'正在加载元数据文件: {filename}')
            with open(file_path, 'r', encoding='utf-8') as file:
                for line in file:
                    parts = line.strip().split('\t')
                    # 确保行内容至少有两个部分：字符和拼音辅助码
                    if len(parts) >= 2:
                        character = parts[0]  # 第一列汉字
                        pinyin_aux = parts[1]  # 第二列拼音或辅助码
                        metadata[character] = pinyin_aux
    return metadata

# 处理单个文件的函数
def process_file(file_path, metadata, output_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    # 找到包含 "..." 的行的索引
    start_index = next((i for i, line in enumerate(lines) if '...' in line), None)
    if start_index is None:
        print(f'在 {file_path} 中未找到起始行。跳过该文件。')
        return

    # 从 "..." 后一行开始处理文件内容
    output_lines = []
    output_lines.extend(lines[:start_index + 1])  # 保留 "..." 行及之前的所有内容

    for line_num, line in enumerate(lines[start_index + 1:], start=start_index + 2):  # 从第二行开始（+2，因为从第1行开始是从0开始）
        # 如果行以 '#' 开头，则原样保留
        if line.strip().startswith('#'):
            # output_lines.append(line)
            continue

        parts = line.strip().split('\t')
        if len(parts) >= 1:
            characters = parts[0]  # 获取字符部分
            pinyin_data = []

            # 获取第二列（拼音）和第三列（频率）
            second_column = parts[1] if len(parts) > 1 else ''
            frequency = parts[2] if len(parts) > 2 else ''
            fourth_column = parts[3] if len(parts) > 3 else ''

            # 如果第二列是数字，则认为它是频率
            if re.match(r'^\d+$', second_column):
                frequency = second_column
                second_column = ''

            # 将第二列的拼音分开，逐字查找拼音辅助码
            pinyin_parts = second_column.split(' ')  # 以空格分隔的拼音部分
            pinyin_string = ''

            if len(pinyin_parts) != len(characters):
                # 如果拼音数量不匹配，输出警告并记录错误行号
                warning_message = f"警告: 拼音数量与汉字数量不匹配，跳过该行（文件: {file_path}，第 {line_num} 行）：{line.strip()}结束"
                # print(warning_message)  # 在控制台打印警告
                # output_lines.append(warning_message + "\n")  # 将警告信息加到 output_lines
                continue  # 跳过该行的处理

            for idx, char in enumerate(characters):
                if char in metadata:
                    aux_code = metadata[char]
                    # 拼接拼音和辅助码
                    pinyin_string += pinyin_parts[idx] + aux_code if idx == 0 else ' ' + pinyin_parts[idx] + aux_code
                else:
                    # 如果元数据中没有拼音，直接添加拼音部分并补充辅助码
                    pinyin_string += pinyin_parts[idx] + ';;;;;;;;;' if idx == 0 else ' ' + pinyin_parts[idx] + ';;;;;;;;;'

            output_line = f"{characters}\t{pinyin_string}\t{frequency}"
            if fourth_column:
                output_line += f"\t{fourth_column}"
            output_line += "\n"

            output_lines.append(output_line)

    # 确保输出路径的目录存在
    output_dir = os.path.dirname(output_path)
    os.makedirs(output_dir, exist_ok=True)  # 创建目录（如果不存在）

    # 将处理后的内容写入新的文件
    with open(output_path, 'w', encoding='utf-8') as output_file:
        output_file.writelines(output_lines)
    print(f'已处理并保存: {output_path}')

# 处理输入目录或文件，输出到目录或文件
def process_input(input_path, metadata, output_path):
    if os.path.isdir(input_path):
        # 输入是目录，处理目录中的所有文件
        for filename in os.listdir(input_path):
            file_path = os.path.join(input_path, filename)
            if os.path.isfile(file_path) and (filename.endswith('.yaml') or filename.endswith('.yml')):
                output_file_path = os.path.join(output_path, filename)
                process_file(file_path, metadata, output_file_path)
    elif os.path.isfile(input_path):
        # 输入是单个文件，直接处理该文件
        process_file(input_path, metadata, output_path)
    else:
        print(f"输入路径 {input_path} 无效！")

if __name__ == "__main__":
    proj_dir = Path(__file__).resolve().parent.parent
    work_dir = Path("../.temp_rime").resolve()
    # metadata_directory = '单字表万象辅助码'  # 替换为你的元数据目录路径
    # input_path = '/home/amz/.local/share/fcitx5/rime/cn_dicts'  # 输入路径（可以是文件或目录）
    # output_path = '/home/amz/.local/share/fcitx5/rime/万象cn_dicts'  # 输出路径（可以是文件或目录）
    metadata_directory = proj_dir / 'scripts'  # 替换为你的元数据目录路径
    input_path = work_dir / 'cn_dicts'  # 输入路径（可以是文件或目录）
    output_path = work_dir / 'out'  # 输出路径（可以是文件或目录）

    # 如果存在输出文件，先删除
    if os.path.exists(output_path):
        shutil.rmtree(output_path)
    os.mkdir(output_path)

    # 加载元数据
    metadata = load_metadata(metadata_directory)
    print(f'已加载 {len(metadata)} 个字符的元数据。')

    # 处理输入路径
    process_input(input_path, metadata, output_path)
