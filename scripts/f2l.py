def convert_rime_to_lua(input_file, output_file):
    # 读取输入文件
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 处理每一行
    lua_table = {}
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#') or line.startswith('---') or line.startswith('...'):
            continue
            
        # 分割字符和编码
        parts = line.split('\t')
        if len(parts) != 2:
            continue
            
        char, code = parts
        char = char.strip()
        code = code.strip()
        
        # 处理多编码情况
        if char in lua_table:
            lua_table[char] += ";" + code
        else:
            lua_table[char] = code

    # 写入输出文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('local flyyx_code_table = {\n')
        for char, codes in sorted(lua_table.items()):
            f.write(f'    ["{char}"] = "{codes}",\n')
        f.write('}\n\nreturn flyyx_code_table\n')

# 使用示例
input_file = 'dicts/flyyx_chars.dict.yaml'  # 输入文件名
output_file = 'lua/flyyx_code_table.lua'    # 输出文件名
convert_rime_to_lua(input_file, output_file)