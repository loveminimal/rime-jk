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

    elseif (context.input == "~ziyuan") then
        generic_open("https://zi.tools")
        context:clear()

    end

    return kNoop
end

return exe
