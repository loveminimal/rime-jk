# 当前脚本用于拉取万象词库的最近更新，并进行「转换 ➭ 合并 ➭ 排序」处理，以
# 生成所需的虎码整句词库 dicts/tiger_zj.dict.yaml
import re
import subprocess
import hashlib
from pathlib import Path
from timer import timer
from tiger_map import tiger_map
from wubi86_8105_map import wubi86_8105_map
from header import get_header_zj
from collections import defaultdict


def run_git_command(command, cwd=None):
    """执行git命令并返回是否成功"""
    try:
        subprocess.run(
            ["git"] + command,
            cwd=cwd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return True
    except subprocess.CalledProcessError:
        return False


def sync_repository(repo_url, local_path):
    """同步Git仓库（克隆时只获取最新版本）"""
    git_dir = local_path / ".git"
    
    if git_dir.exists():
        print(f"仓库已存在于 {local_path}")
        print(f"🔜  正在拉取最新更新...")
        if run_git_command(["pull"], cwd=local_path):
            print("✅  » 拉取更新成功")
        else:
            print("🚫  » 拉取更新失败")
    else:
        print(f"本地仓库不存在")
        print(f"🔜  正在浅克隆 {repo_url}...")
        local_path.parent.mkdir(parents=True, exist_ok=True)
        
        if run_git_command(["clone", "--depth=1", repo_url, str(local_path)]):
            print(f"✅  » 仓库已浅克隆到 {local_path}")
        else:
            print("🚫  » 克隆仓库失败")


def get_tiger_code(word: str) -> str:
    """将汉字转换为虎码编码"""
    code_parts = []
    for char in word:
        wubi_code = tiger_map[char]
        if len(wubi_code) == 3:
            code_parts.append(f"{wubi_code[:2]};{wubi_code[2:]}z")
        else:
            code_parts.append(f"{wubi_code[:2]};{wubi_code[2:]}")
    return ' '.join(code_parts)


@timer
def convert(src_dir: Path, out_dir: Path, file_endswith_filter: str) -> None:
    """将拼音词库转换为虎码词库"""
    out_dir.mkdir(parents=True, exist_ok=True)
    tab_split_re = re.compile(r'\t+')

    for file_num, file_path in enumerate(src_dir.glob(f'*{file_endswith_filter}'), 1):
        print(f'☑️  已加载第 {file_num} 份码表 » {file_path.name}')

        valid_entries = set()
        invalid_line_count = 0

        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line[0] not in tiger_map:
                    continue

                parts = tab_split_re.split(line)
                if len(parts) < 3:
                    continue

                word, _, weight = parts[0], parts[1], parts[2]
                
                # 8105 过滤器开关 - is_filter_8105
                if is_filter_8105 and any(char not in wubi86_8105_map for char in word):
                    continue

                try:
                    wubi_code = get_tiger_code(word)
                    valid_entries.add(f"{word}\t{wubi_code}\t{weight}\n")
                except KeyError:
                    invalid_line_count += 1

        if valid_entries:
            output_path = out_dir / f"{file_path.stem}.yaml"
            with open(output_path, 'w', encoding='utf-8') as o:
                o.writelines(sorted(valid_entries))

            # print(f"  成功转换 {len(valid_entries)} 条记录，跳过 {invalid_line_count} 条无效记录")


@timer
def filter_8105(src_dir: Path, out_file: Path):
    """过滤并合并虎码码表，保持按词长排序"""
    dict_num = 0
    res_dict = {}
    res_dict_code = defaultdict(set)
    tab_split_re = re.compile(r'\t+')
    word_len_groups = {}
    
    # 按词长分组处理
    for filepath in src_dir.iterdir():
        if filepath.is_file():
            dict_num += 1
            print(f'☑️  已加载第 {dict_num} 份码表 » {filepath.name}')
            
            with open(filepath, 'r', encoding='utf-8') as f:
                for line in f:
                    if not line or line[0] not in tiger_map:
                        continue
                        
                    parts = tab_split_re.split(line.strip())
                    if len(parts) < 2:
                        continue
                        
                    word, code = parts[0], parts[1]
                    weight = parts[2] if len(parts) >= 3 else '0'
                    word_len = len(word)
                    
                    try:
                        if word not in res_dict or code not in res_dict_code[word]:
                            res_dict[word] = {code}
                            res_dict_code[word].add(code)
                            
                            if word_len not in word_len_groups:
                                word_len_groups[word_len] = []
                            word_len_groups[word_len].append(f"{word}\t{code}\t{weight}\n")
                    except KeyError:
                        continue
    
    print('\n🔜  --- 正在合并处理词库文件 ---')
    
    # 按词长排序并收集结果
    output_lines = []
    line_count_sum = 0
    for word_len in sorted(word_len_groups.keys()):
        group_lines = word_len_groups[word_len]
        output_lines.extend(group_lines)
        line_count_sum += len(group_lines)
        print(f'☑️  已合并处理生成 {word_len} 字词语，共计 {len(group_lines)} 行')
    
    print(f'✅ » 共生成 {line_count_sum} 行数据')
    
    # 写入输出文件
    out_file.parent.mkdir(parents=True, exist_ok=True)
    if out_file.exists():
        out_file.unlink()
        
    with open(out_file, 'w', encoding='utf-8') as o:
        o.write(get_header_zj(out_file.name))
        o.writelines(output_lines)


def get_md5(text: str) -> str:
    """计算字符串的 MD5 哈希值"""
    md5 = hashlib.md5()  # 创建 MD5 对象
    md5.update(text.encode('utf-8'))  # 传入字节数据（必须 encode）
    return md5.hexdigest()  # 返回 32 位 16 进制字符串

@timer
def sort_dict(src_dir, out_dir, dict_start):
    res_dict = {}
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
        if line[0] not in tiger_map and not is_header_end:
            header_str += line 


    # 去重并处理词条
    for line in set(lines_total):
        if line[0] in tiger_map:
            word, code, weight = line.strip().split('\t')
            weight = int(weight)
            
            # 唯一化
            if word not in res_dict:
                res_dict[word + get_md5(line)] = f'{code}\t{weight}'


    # 多级分组排序（词长→编码长度→编码→汉字）
    with open(out_dir / f'{dict_start}.dict.yaml', 'w', encoding='utf-8') as o:
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
                for word, _, value in group:
                    o.write(f'{word[:-32]}\t{value}\n')
            print(f'☑️  已排序处理生成 {word_len - 32} 字词语')
        print('✅ » 已排序生成用户词典 %s' % (out_dir / f'{dict_start}.dict.yaml'))




if __name__ == "__main__":
    proj_dir = Path(__file__).resolve().parent.parent
    work_dir = "../.temp_rime"

    # 是否开启 8105 通规字字符范围过滤
    is_filter_8105 = False
    
    # 同步仓库
    repository_url = "https://github.com/amzxyz/rime_wanxiang.git"
    local_directory = proj_dir / work_dir / "rime_wanxiang"
    print('🔜  === 开始获取最新词库文件 ===')
    sync_repository(repository_url, local_directory)

    # 转换拼音词库为虎码词库
    src_dir = proj_dir / work_dir / 'rime_wanxiang/cn_dicts'
    out_dir = proj_dir / work_dir / 'cn_dicts_t'
    print('\n🔜  === 开始同步转换词库文件 ===')
    convert(src_dir, out_dir, '.dict.yaml')

    # 过滤合并虎码码表
    src_dir = proj_dir / work_dir / 'cn_dicts_t'
    out_file = proj_dir / work_dir / 'tiger_zj.dict.yaml'
    print('\n🔜  === 开始合并处理词库文件 ===')
    filter_8105(src_dir, out_file)

    
    src_dir = proj_dir /  work_dir
    out_dir = proj_dir / 'dicts'
    dict_start = 'tiger_zj'
    print('\n🔜  === 开始排序处理词库文件 ===')
    # 排序处理至用户词典
    sort_dict(src_dir, out_dir, dict_start)