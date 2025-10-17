# pr_versions.py
import requests
import subprocess
import os
import shutil


# def get_pr_versions(repo, pr_number, github_token=None):
#     headers = {}
#     if github_token:
#         headers['Authorization'] = f'token {github_token}'
#
#     # 获取PR信息
#     url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"
#     response = requests.get(url, headers=headers)
#     pr_data = response.json()
#
#     base_sha = pr_data['base']['sha']
#     merge_sha = pr_data['merge_commit_sha']
#
#     print(f"PR前版本: {base_sha}")
#     print(f"PR后版本: {merge_sha}")
#
#     # 创建目标目录结构
#     repo_name = repo.split('/')[-1]  # 获取 quant-mind
#     versions_dir = f"versions/{repo_name}_{pr_number}"
#     os.makedirs(versions_dir, exist_ok=True)
#
#     before_dir = os.path.join(versions_dir, "before")
#     after_dir = os.path.join(versions_dir, "after")
#
#     # 清理旧的版本目录
#     if os.path.exists(before_dir):
#         shutil.rmtree(before_dir)
#     if os.path.exists(after_dir):
#         shutil.rmtree(after_dir)
#
#     # 临时克隆目录
#     temp_clone = f"temp_{repo_name}"
#     if os.path.exists(temp_clone):
#         shutil.rmtree(temp_clone)
#
#     # 克隆仓库到临时目录
#     subprocess.run(['git', 'clone', f'https://github.com/{repo}.git', temp_clone])
#
#     # 检出PR前版本并保存
#     subprocess.run(['git', 'checkout', base_sha], cwd=temp_clone)
#     shutil.copytree(temp_clone, before_dir, ignore=shutil.ignore_patterns('.git'))
#
#     # 检出PR后版本并保存
#     subprocess.run(['git', 'checkout', merge_sha], cwd=temp_clone)
#     shutil.copytree(temp_clone, after_dir, ignore=shutil.ignore_patterns('.git'))
#
#     # 清理临时目录
#     shutil.rmtree(temp_clone)
#
#     print("版本提取完成!")
#     print(f"PR前版本保存在: {before_dir}")
#     print(f"PR后版本保存在: {after_dir}")
#
#     return before_dir, after_dir
#



import os, subprocess, shutil, tarfile, requests


def get_pr_versions(repo, pr_number, github_token=None):
    headers = {}
    if github_token:
        headers['Authorization'] = f'token {github_token}'

    # 获取PR信息
    url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"
    response = requests.get(url, headers=headers)
    pr_data = response.json()

    base_sha = pr_data['base']['sha']
    merge_sha = pr_data['merge_commit_sha']

    print(f"PR前版本: {base_sha}")
    print(f"PR后版本: {merge_sha}")

    # 创建目标目录结构
    repo_name = repo.split('/')[-1]
    versions_dir = f"versions/{repo_name}_{pr_number}"

    if os.path.exists(versions_dir):
        before_dir = os.path.join(versions_dir, "before")
        after_dir = os.path.join(versions_dir, "after")
        print(f"版本目录已存在,跳过处理: {versions_dir}")
        return before_dir, after_dir

    os.makedirs(versions_dir, exist_ok=True)

    before_dir = os.path.join(versions_dir, "before")
    after_dir = os.path.join(versions_dir, "after")

    # 清理旧的版本目录
    if os.path.exists(before_dir):
        shutil.rmtree(before_dir)
    if os.path.exists(after_dir):
        shutil.rmtree(after_dir)

    # 临时克隆目录
    temp_clone = f"temp_{repo_name}"
    if os.path.exists(temp_clone):
        shutil.rmtree(temp_clone)

    # 克隆仓库到临时目录
    subprocess.run(['git', 'clone', f'https://github.com/{repo}.git', temp_clone])

    # 检出PR前版本并保存
    subprocess.run(['git', 'checkout', base_sha], cwd=temp_clone)
    shutil.copytree(temp_clone, before_dir,
                    symlinks=True,  # 添加这个参数
                    ignore=shutil.ignore_patterns('.git'))

    # 检出PR后版本并保存
    subprocess.run(['git', 'checkout', merge_sha], cwd=temp_clone)
    shutil.copytree(temp_clone, after_dir,
                    symlinks=True,  # 添加这个参数
                    ignore=shutil.ignore_patterns('.git'))

    # 清理临时目录
    shutil.rmtree(temp_clone)

    print("版本提取完成!")
    print(f"PR前版本保存在: {before_dir}")
    print(f"PR后版本保存在: {after_dir}")

    return before_dir, after_dir


import re
import time
import json
from typing import Iterator, Tuple, Set

# 假设这个函数已经在你的代码里定义好了：
# def get_pr_versions(repo: str, pr_number: str):
#     ...

# 正则：匹配 GitHub PR URL 或 owner/repo/pull/number 形式
PR_URL_RE = re.compile(
    r"""(?xi)
    (?:https?://github\.com/)?            # 可选的 https://github.com/
    (?P<owner>[^/\s]+)/(?P<repo>[^/\s]+)  # owner/repo
    /pull/                                # /pull/
    (?P<number>\d+)                       # PR number
    (?:/.*)?                              # 可选的其余路径（例如 /files）
    """
)

def parse_pr_line(line: str) -> Tuple[str, str]:
    """
    从一行文本中解析出 (owner/repo, pr_number)。
    如果无法解析，抛出 ValueError。
    """
    s = line.strip()
    if not s:
        raise ValueError("empty line")
    m = PR_URL_RE.search(s)
    if not m:
        raise ValueError(f"无法解析 PR URL: {s}")
    owner = m.group("owner")
    repo = m.group("repo")
    number = m.group("number")
    repo_full = f"{owner}/{repo}"
    return repo_full, number

def iter_prs_from_file(filepath: str) -> Iterator[Tuple[str, str]]:
    """
    从文件逐行产生 (repo_full, pr_number)。
    会跳过空行和无法解析的行（并在 stderr 打印警告）。
    """
    with open(filepath, "r", encoding="utf-8") as f:
        for lineno, raw in enumerate(f, start=1):
            line = raw.strip()
            if not line:
                continue
            try:
                yield parse_pr_line(line)
            except ValueError as e:
                print(f"[warning] line {lineno}: {e}")

def process_prs_file(filepath: str,
                     deduplicate: bool = True,
                     delay_secs: float = 0.0,
                     max_calls: int | None = None):
    """
    读取 filepath，按行解析并循环调用 get_pr_versions(repo, pr_number)。

    参数:
      - filepath: 存放 URL 的文本文件路径（每行一个 URL）
      - deduplicate: 是否去重相同 (repo, pr)（默认 True）
      - delay_secs: 每次调用后的等待秒数（默认 0；如要防止速率限制可设为 0.5 等）
      - max_calls: 若非 None，最多处理的 PR 数量（方便调试）

    注意: 本函数假设 get_pr_versions 已在其它地方定义并可直接被调用。
    """
    seen: Set[Tuple[str, str]] = set()
    count = 0

    for repo_full, pr_number in iter_prs_from_file(filepath):
        key = (repo_full, pr_number)
        if deduplicate and key in seen:
            print(f"[info] 跳过已处理: {repo_full} #{pr_number}")
            continue

        try:
            # 调用用户提供的函数
            print(f"[info] 处理中: {repo_full} #{pr_number} ...")
            get_pr_versions(repo_full, pr_number, github_token=os.environ.get("GITHUB_TOKEN"))
            seen.add(key)
            count += 1
        except Exception as ex:
            # 不要因为单条失败而终止整个批处理
            print(f"[error] 处理 {repo_full} #{pr_number} 失败: {ex}")
        if max_calls is not None and count >= max_calls:
            print(f"[info] 已达到 max_calls={max_calls}，中止处理。")
            break
        if delay_secs > 0:
            time.sleep(delay_secs)



def debug_pr_response(repo_path, pr_number):
    """
    调试GitHub PR API响应,查看实际返回的数据结构
    """
    url = f"https://api.github.com/repos/{repo_path}/pulls/{pr_number}"

    print(f"正在请求: {url}\n")

    # 如果你有GitHub token,建议添加以避免rate limit
    GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
    print("GITHUB_TOKEN",GITHUB_TOKEN)
    headers = {
        'Authorization': f'token {GITHUB_TOKEN}'
    }

    response = requests.get(url, headers=headers)

    print(f"状态码: {response.status_code}")
    print(f"Rate Limit 剩余: {response.headers.get('X-RateLimit-Remaining', 'N/A')}")
    print("-" * 80)

    if response.status_code == 200:
        pr_data = response.json()

        # 打印关键字段
        print("PR数据关键字段:")
        print(f"  - 'state': {pr_data.get('state', 'NOT FOUND')}")
        print(f"  - 'merged': {pr_data.get('merged', 'NOT FOUND')}")
        print(f"  - 'base' 存在: {'base' in pr_data}")
        print(f"  - 'head' 存在: {'head' in pr_data}")

        if 'base' in pr_data:
            print(f"  - base.sha: {pr_data['base'].get('sha', 'NOT FOUND')}")

        if 'head' in pr_data:
            print(f"  - head.sha: {pr_data['head'].get('sha', 'NOT FOUND')}")

        print("\n所有顶层键:")
        print(json.dumps(list(pr_data.keys()), indent=2))

        # 保存完整响应到文件以便详细检查
        with open(f'pr_debug_{pr_number}.json', 'w', encoding='utf-8') as f:
            json.dump(pr_data, f, indent=2)
        print(f"\n完整响应已保存到: pr_debug_{pr_number}.json")

        return pr_data
    else:
        print(f"错误: {response.status_code}")
        print(f"响应: {response.text}")
        return None

def func_debug():
    # 先调试有问题的PR
    print("=" * 80)
    print("调试 huggingface/transformers PR #38480")
    print("=" * 80)
    debug_pr_response("huggingface/transformers", "38480")



if __name__ == "__main__":
    # debug_pr_response("huggingface/transformers", "38480")
    # 示例用法：把你的 txt 路径放这里
    path_to_txt = "ListOptTestItself.txt"

    # 示例：去重、每次调用后等 0.2 秒，最多处理 None（全部）
    process_prs_file(path_to_txt, deduplicate=True, delay_secs=0.2, max_calls=None)





