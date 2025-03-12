import subprocess

# 定义命令路径
weasel_deployer_path = "C:/Program Files/Rime/weasel-0.16.3/WeaselDeployer.exe"

# 执行同步命令
def sync_rime():
    print('\n☑️  === 开始同步 Rime 最新配置 ===')
    try:
        result = subprocess.run([weasel_deployer_path, "/sync"], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅  » Rime 同步成功")
            print(result.stdout)
        else:
            print("🚫  » Rime 同步失败")
            print(result.stderr)
    except Exception as e:
        print(f"执行同步命令时出错: {e}")

# 主程序
if __name__ == "__main__":
    sync_rime()    # 执行同步