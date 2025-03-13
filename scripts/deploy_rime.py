# 跨平台支持终端命令部署 Rime 最新配置
# by Jack Liu <https://aituyaa.com>
# 
import subprocess
from progress import progress

# 定义命令路径
weasel_deployer_path = "C:/Program Files/Rime/weasel-0.16.3/WeaselDeployer.exe"

# 执行部署命令
def deploy_rime():
    print('\n🔜  === 重新部署 Rime 最新配置 ===')
    try:
        result = subprocess.run([weasel_deployer_path, "/deploy"], capture_output=True, text=True)
        if result.returncode == 0:
            progress('正在部署')
            print("\n✅  » Rime 部署成功")
            print(result.stdout)
        else:
            print("🚫  » Rime 部署失败")
            print(result.stderr)
    except Exception as e:
        print(f"执行部署命令时出错: {e}")


# 主程序
if __name__ == "__main__":
    deploy_rime()  # 执行部署
