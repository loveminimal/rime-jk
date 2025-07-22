#Requires AutoHotkey v2.0

; # → Win 键
; ! → Alt 键
; ^ → Ctrl 键
; + → Shift 键

; 获取 Rime 版本号 ;;;;;;
GetRimeVersion() {
    yamlPath := A_ScriptDir "\..\installation.yaml"
    if !FileExist(yamlPath) {
        MsgBox "配置文件不存在：" yamlPath
        return ""
    }

    version := ""
    Loop Read, yamlPath {
        if RegExMatch(A_LoopReadLine, "^\s*distribution_version:\s*(.+)", &m) {
            version := Trim(m[1])
            break
        }
    }
    return version
}


; 获取 Rime 执行路径 ;;;;;;
GetWeaselPath(type) {
    version := GetRimeVersion()
    if version = "" {
        MsgBox "无法读取 Rime 版本号"
        return ""
    }

    if type = "server" {
        return "C:\Program Files\Rime\weasel-" version "\WeaselServer.exe"
    }

    if type = "deployer" {
        return "C:\Program Files\Rime\weasel-" version "\WeaselDeployer.exe"
    }

    if type = "setup" {
        return "C:\Program Files\Rime\weasel-" version "\WeaselSetup.exe"
    }
}


; 获取执行路径 ;;;;;;
weaselServerPath := GetWeaselPath('server')
; if weaselServerPath != "" {
;     MsgBox "Weasel 路径为: " weaselServerPath
;     ; Run weaselServerPath ; 如果需要运行
; }
weaselDeployerPath := GetWeaselPath('deployer')
weaselSetupPath := GetWeaselPath('setup')


; === 绑定快捷键 ===
; --------------------------------------------------------
; 重启 Rime 服务
^p::
{
    Run weaselServerPath
    return
}

; 重新部署
+!d::
{
    Run weaselDeployerPath " /deploy"
    return
}

; 用户资料同步
+!a::
{
    Run weaselDeployerPath " /sync"
    return
}

; 打开输入法设定
+!c::
{
    Run weaselSetupPath
    return
}

; 添加用户词
+!u::
{
    Run "notepad.exe " A_AppData "\Rime\lua\user_words.lua"
    return
}

; 插入定制词
+!i::
{
    Run "notepad.exe " A_AppData "\Rime\custom_pinyin.txt"
    return
}


; === 监听脚本 ===
; --------------------------------------------------------
; 多文件监听函数 ;;;;;;
WatchFiles(filesToWatch, callbackFunc) {
    static watchedFiles := Map()
    ; 初始化文件监听
    for filePath in filesToWatch {
        if !FileExist(filePath) {
            MsgBox "文件不存在: " filePath
            continue
        }
        watchedFiles[filePath] := FileGetTime(filePath)
    }
    
    ; 设置定时器检查文件变化
    SetTimer CheckFiles, 1000
    CheckFiles() {
        for filePath, lastModified in watchedFiles {
            currentModified := FileGetTime(filePath)
            if currentModified != lastModified {
                watchedFiles[filePath] := currentModified
                callbackFunc.Call(filePath)
            }
        }
    }
    ; 保持脚本运行
    Persistent
}

; 定义要监听的文件列表
filesToWatch := [
    A_AppData "\Rime\lua\user_words.lua",
    A_AppData "\Rime\custom_pinyin.txt",
]

; 定义回调函数
FileChangedCallback(filePath) {
    ; MsgBox "文件已更新: " filePath
    ; 在这里执行你的操作，比如重启服务
    Run weaselServerPath
}

; 开始监听文件
WatchFiles(filesToWatch, FileChangedCallback)
