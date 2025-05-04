# fetch_wubi_dict.py
# encoding: utf-8
# -------------------------------------------------------------------------
# 作用：
# 当前脚本用于拉取万象词库的最近更新，并进行「转换 ➭ 合并 ➭ 排序」处理，以
# 生成所需的五笔整句词库 dicts/wubi86_ext.dict.yaml 或者 cn_dicts/*
# 
# 配置：「 五笔该项设置不生效，只生成 8105 通规字组成的字词 」
# 是否开启 8105 通规字字符范围过滤，默认「 开启 」
# is_filter_8105 = True
# 是否限制词库最大词长，若为 0 ，则不限制
# word_length_limit = 0
# -------------------------------------------------------------------------
# 
import os
import platform
import re
import shutil
import subprocess
import hashlib
from pathlib import Path
import threading
from timer import timer
from wubi86_8105_map import wubi86_8105_map
from header import get_header_ext
from header import get_header_common
from collections import defaultdict


def run_git_command(command, cwd=None):
    """执行git命令并返回是否成功"""
    try:
        result = subprocess.run(["git"] + command, cwd=cwd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return {
            "success": True,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip()
        }
    except subprocess.CalledProcessError:
        return False
    

def ask_yes_no(question, timeout=5):
    answer = [None]  # 使用列表以便在嵌套函数中修改
    
    def input_thread():
        answer[0] = input(f"{question} ? (y/n) y: ").strip().lower() or "y"

    print(f"\n--- 默认 {timeout} 秒后取消转换 ---")
    thread = threading.Thread(target=input_thread)
    thread.daemon = True
    thread.start()
    thread.join(timeout)
    if answer[0] in ("y", "yes"):
        return True
    else:
        return False


def force_delete(path):
    """暴力删除文件/文件夹（无视权限和占用）"""
    try:
        if not os.path.exists(path):
            return True
        if platform.system() == "Windows":
            # ^ Windows系统处理
            path = os.path.abspath(path)
            # 使用robocopy空文件夹替换（微软官方推荐）
            temp_dir = os.path.join(os.path.dirname(path), "temp_empty")
            os.makedirs(temp_dir, exist_ok=True)
            subprocess.run(["robocopy", temp_dir, path, "/mir", "/njh", "/njs", "/ndl", "/np"], check=True, stderr=subprocess.DEVNULL)
            os.rmdir(temp_dir)
            # 二次清理残留
            subprocess.run(["rd", "/s", "/q", path], shell=True, stderr=subprocess.DEVNULL)
        else:
            # ^ Linux/Mac系统
            subprocess.run(["rm", "-rf", path], check=True)
        return True
    except Exception:
        return False


def sync_repository(repo_url, local_path):
    """同步Git仓库（克隆时只获取最新版本）"""
    git_dir = local_path / ".git"
    backup_path = local_path.with_suffix('.bak')
    sync_success = True

    if git_dir.exists():
        print(f"仓库已存在于 {local_path}")
        print(f"--- 拉取最新更新 ---")
        print(f"🔜  正在拉取最新更新...")
        pull_result = run_git_command(["pull", "--depth=1"], cwd=local_path)
        if pull_result and pull_result['success']:
            # print("输出信息:", pull_result["stdout"])
            if 'Already up to date' in pull_result["stdout"]:
                print("✅  » 无需转换 ¦ 仓库没有新的提交")
                # sync_success = False
                sync_success = ask_yes_no(f"🔔  是否继续执行转换操作")
                if sync_success:
                    print("🔜  » 继续转换 ¦ 即将开始转换...")
                else:
                    print("\n🎉  » 不再转换 ¦ 祝你使用愉快")
            else:
                print("✅  » 拉取更新成功")
        else:
            print("🚫  » 拉取更新失败")
            sync_success = False
            if local_path.exists():
                if backup_path.exists():
                    shutil.rmtree(backup_path)
                local_path.rename(backup_path)
                print(f"✅  » 当前仓库已备份为 { backup_path }")
            print(f"--- 重新浅克隆 ---")
            sync_success = sync_repository(repo_url, local_path)
    else:
        print(f"🔜  正在浅克隆 {repo_url}...")
        local_path.parent.mkdir(parents=True, exist_ok=True)
        
        if run_git_command(["clone", "--depth=1", repo_url, str(local_path)]):
            print(f"✅  » 仓库已浅克隆到 {local_path}")
            sync_success = True
        else:
            print("🚫  » 克隆仓库失败")
            if backup_path.exists():
                print(f"--- 开始恢复仓库 ---")
                if local_path.exists():
                    shutil.rmtree(local_path)
                backup_path.rename(local_path)
                print(f"✅  » 仓库恢复成功 {local_path}")
                sync_success = False
    return sync_success


def get_wubi_code(word: str) -> str:
    """将汉字转换为五笔编码"""
    if is_wubi_normal:
        # ^ 常规编码
        if len(word) == 1:
            return f'{wubi86_8105_map[word]}'
        elif len(word) == 2:
            return f'{wubi86_8105_map[word[0]][:2]}{wubi86_8105_map[word[1]][:2]}'
        elif len(word) == 3:
            return f'{wubi86_8105_map[word[0]][0]}{wubi86_8105_map[word[1]][0]}{wubi86_8105_map[word[2]][:2]}'
        elif len(word) >= 4:
            return f'{wubi86_8105_map[word[0]][0]}{wubi86_8105_map[word[1]][0]}{wubi86_8105_map[word[2]][0]}{wubi86_8105_map[word[len(word) - 1]][0]}'
    else:
        # ^ 整句编码
        code_parts = []
        for char in word:
            wubi_code = wubi86_8105_map[char]
            if len(wubi_code) == 3:
                code_parts.append(f"{wubi_code[:2]};{wubi_code[2:]}z")
            else:
                code_parts.append(f"{wubi_code[:2]};{wubi_code[2:]}")
        return ' '.join(code_parts)


@timer
def convert(src_dir: Path, out_dir: Path, file_endswith_filter: str) -> None:
    """将拼音词库转换为五笔词库"""
    out_dir.mkdir(parents=True, exist_ok=True)
    tab_split_re = re.compile(r'\t+')

    for file_num, file_path in enumerate(src_dir.glob(f'*{file_endswith_filter}'), 1):
        print(f'☑️  已加载第 {file_num} 份码表 » {file_path.name}')

        valid_entries = set()
        invalid_line_count = 0

        res_dict_word_weight = {}

        # 预处理，获取权重字的最大权重映射
        with open(file_path, 'r', encoding='utf-8') as fp:
            for line in fp:
                line = line.strip()
                if not line or line[0] not in wubi86_8105_map:
                    continue

                parts = tab_split_re.split(line)
                if len(parts) < 3:
                    continue
                word, _, weight = parts[0], parts[1], parts[2]

                # 将权重转换为整数以便比较
                current_weight = int(weight)
                # 如果字不存在于字典中，或者当前权重更大，则更新字典
                if word not in res_dict_word_weight or current_weight > res_dict_word_weight[word]:
                    res_dict_word_weight[word] = current_weight


        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line[0] not in wubi86_8105_map:
                    continue

                parts = tab_split_re.split(line)
                if len(parts) < 3:
                    continue

                word, _, weight = parts[0], parts[1], parts[2]
                
                if word_length_limit > 0 and len(word) > word_length_limit:
                    # print(f"过滤掉长词语: {word} (长度: {len(word)})")
                    continue
                
                # 8105 过滤器开关 - is_filter_8105
                if is_filter_8105 and any(char not in wubi86_8105_map for char in word):
                    continue

                try:
                    wubi_code = get_wubi_code(word)
                    valid_entries.add(f"{word}\t{wubi_code}\t{res_dict_word_weight[word]}\n")
                except KeyError:
                    invalid_line_count += 1

        if valid_entries:
            output_path = out_dir / f"{file_path.stem}.yaml"
            with open(output_path, 'w', encoding='utf-8') as o:
                o.writelines(get_header_common(f"{file_path.stem}.yaml"))
                o.writelines(sorted(valid_entries))

            # print(f"  成功转换 {len(valid_entries)} 条记录，跳过 {invalid_line_count} 条无效记录")


@timer
def filter_8105(src_dir: Path, out_file: Path):
    """过滤并合并五笔码表，保持按词长排序"""
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
                    if not line or line[0] not in wubi86_8105_map:
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
        o.write(get_header_ext(out_file.name))
        o.writelines(output_lines)


def get_md5(text: str) -> str:
    """计算字符串的 MD5 哈希值"""
    md5 = hashlib.md5()  # 创建 MD5 对象
    md5.update(text.encode('utf-8'))  # 传入字节数据（必须 encode）
    return md5.hexdigest()  # 返回 32 位 16 进制字符串

@timer
def sort_dict(src_dir, out_dir, dict_start):
    """分组排序处理用户词典"""
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
        if line[0] not in wubi86_8105_map and not is_header_end:
            header_str += line 


    # 去重并处理词条
    for line in set(lines_total):
        if line[0] in wubi86_8105_map:
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


def exec(proj_dir, work_dir, repository_url):
    exec_success = True

    # ① 同步仓库
    repository_url = repository_url or "https://github.com/amzxyz/rime_wanxiang.git"
    repository_name = repository_url.split('/')[-1][:-4] # 如 rime_wanxiang
    local_directory = (proj_dir / work_dir / repository_name).resolve()
    print('🔜  === 开始获取最新词库文件 ===')
    exec_success = sync_repository(repository_url, local_directory)
    if not exec_success:
        return False;

    # ② 转换拼音词库为五笔词库
    src_dir = proj_dir / work_dir / repository_name / 'cn_dicts'
    out_dir = proj_dir / work_dir / 'cn_dicts_x'
    # 已存在，先删除，再转换
    if out_dir.exists():
        shutil.rmtree(out_dir)
    print('\n🔜  === 开始同步转换词库文件 ===')
    convert(src_dir, out_dir, '.dict.yaml')

    # 分包操作，以减小推送之后仓库快照体积
    if not is_merge:
        dist_dir = proj_dir / 'cn_dicts'
        if dist_dir.exists():
            shutil.rmtree(dist_dir)
        shutil.copytree(out_dir, dist_dir)
        return

    # ③ 过滤合并五笔码表
    out_file_name = 'wubi86_ext.dict.yaml' if is_wubi_normal else 'wubi86_zj.dict.yaml'
    src_dir = proj_dir / work_dir / 'cn_dicts_x'
    out_file = proj_dir / work_dir / out_file_name
    print('\n🔜  === 开始合并处理词库文件 ===')
    filter_8105(src_dir, out_file)
    
    # ④ 重新排序
    src_dir = proj_dir /  work_dir
    out_dir = proj_dir / 'dicts'
    dict_start = 'wubi86_ext' if is_wubi_normal else 'wubi86_zj'
    # 若不存在，创建
    if not out_dir.exists():
        out_dir.mkdir(parents=True, exist_ok=True)
    print('\n🔜  === 开始排序处理词库文件 ===')
    # 排序处理至用户词典
    sort_dict(src_dir, out_dir, dict_start)


if __name__ == "__main__":
    proj_dir = Path(__file__).resolve().parent.parent
    work_dir = "../.temp_rime"

    # --- 可配置项 ---
    # 是否开启 8105 通规字字符范围过滤
    # 该设置项仅供有扩展字符集需求（需修改当前脚本）
    is_filter_8105 = True
    # 常规五笔编码还是整句编码, True 常规 False 整句
    is_wubi_normal = False
    # 分包还是归并
    # - 归并 True （dicts/wubi86_ext.dict.yaml）
    # - 分包 Flase（cn_dicts/*）
    is_merge = True
    # 是否限制词库最大词长，若为 0 ，则不限制
    word_length_limit = 0
    # 待转换的词典仓库
    # repository_url = "https://github.com/amzxyz/rime_wanxiang_pro.git"
    repository_url = "https://github.com/amzxyz/rime_wanxiang.git"
    # repository_url = "https://github.com/gaboolic/rime-frost.git"
    # repository_url = "https://github.com/iDvel/rime-ice.git"


    # 开始执行
    exec(proj_dir, work_dir, repository_url)