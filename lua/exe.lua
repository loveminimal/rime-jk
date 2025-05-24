-- Source:https://github.com/hchunhui/librime-lua/issues/35
-- 通过特定命令启动外部程序
--

local function generic_open(dest)
    if os.execute('start "" ' .. dest) then
        return true
    elseif os.execute('open ' .. dest) then
        return true
    elseif os.execute('xdg-open ' .. dest) then
        return true
    end
end

local function exe(key, env)
    local engine = env.engine
    local context = engine.context
    local kNoop = 2

    if (context.input == "~ship") then
        generic_open("https://aituyaa.com/ship")
        context:clear()

    elseif (context.input == "~nav") then
        generic_open("https://aituyaa.com/nav")
        context:clear()

    elseif (context.input == "~site") then
        generic_open("https://aituyaa.com")
        context:clear()

    elseif (context.input == "~hub") then
        generic_open("https://github.com/loveminimal")
        context:clear()

    elseif (context.input == "~rime") then
        generic_open("C:\\Users\\jack\\AppData\\Roaming\\Rime")
        context:clear()

    elseif (context.input == "~dazi") then
        generic_open("https://typer.owenyang.top")
        context:clear()

    elseif (context.input == "~aidazi") then
        generic_open("https://www.52dazi.cn")
        context:clear()

    elseif (context.input == "~hu") then
        generic_open("https://tiger-code.com/")
        context:clear()

    elseif (context.input == "~ddr") then
        os.execute('"C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselDeployer.exe" /deploy')
        context:clear()

    elseif (context.input == "~ssr") then
        os.execute('"C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselDeployer.exe" /sync')
        context:clear()

    elseif (context.input == "~rrr") then
        -- os.execute('"C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselServer.exe"')
        -- generic_open("C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\小狼毫输入法\\小狼毫算法服务")
        os.execute('cmd /c start "" "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\小狼毫输入法\\小狼毫算法服务"')
        context:clear()

    end

    return kNoop
end

return exe
