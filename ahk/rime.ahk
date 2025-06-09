#Requires AutoHotkey v2.0

; # → Win 键
; ! → Alt 键
; ^ → Ctrl 键
; + → Shift 键

; 重启 Rime 服务
^o::
{
    Run "C:\Program Files\Rime\weasel-0.16.3\WeaselServer.exe"
    return
}

; 重新部署
+!d::
{
    Run '"C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselDeployer.exe" /deploy'
    return
}

; 用户资料同步
+!s::
{
    Run '"C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselDeployer.exe" /sync'
    return
}
