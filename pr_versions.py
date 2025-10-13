# pr_versions.py
import requests
import subprocess
import os
import shutil


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
    repo_name = repo.split('/')[-1]  # 获取 quant-mind
    versions_dir = f"versions/{repo_name}"
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
    shutil.copytree(temp_clone, before_dir, ignore=shutil.ignore_patterns('.git'))

    # 检出PR后版本并保存
    subprocess.run(['git', 'checkout', merge_sha], cwd=temp_clone)
    shutil.copytree(temp_clone, after_dir, ignore=shutil.ignore_patterns('.git'))

    # 清理临时目录
    shutil.rmtree(temp_clone)

    print("版本提取完成!")
    print(f"PR前版本保存在: {before_dir}")
    print(f"PR后版本保存在: {after_dir}")

    return before_dir, after_dir


# 使用示例
if __name__ == "__main__":
    get_pr_versions("LLMQuant/quant-mind", "58")