-- Created by @amzxyz <https://github.com/amzxyz/rime_wanxiang_pro>
-- -------------------------------------
-- Simplified by Jack Liu <https://aituyaa.com>
--
-- 使用方式加入到函数 - lua_processor@*quick_symbol
-- recognizer/patterns/quick_symbol: "^;.*$"
-- -------------------------------------
-- 定义符号映射表
local mapping = {
    q = "!" ,  w = "@"   , e = "#"     , r = "$"     , t = "%"   , y = "^"      ,  u = "_"  , i = "-"   , o = "="   , p = "\\"  ,
    a = "&" ,  s = "("   , d = "{"     , f = "["     , g = "?"   , h = "*"      ,  j = "+"  , k = ","   , l = "."   ,
    z = "|" ,  x = ")"   , c = "}"     , v = "]"     , b = "`"   , n = "<"      ,  m = ">"  
}

-- 初始化符号输入的状态
local function init(env)
    -- 读取 RIME 配置文件中的引导符号模式
    local config = env.engine.schema.config
    -- 动态读取符号和文本重复的引导模式
    local quick_symbol_pattern = config:get_string("recognizer/patterns/quick_symbol") or "^;.*$"
    -- 提取配置值中的第二个字符作为引导符
    local quick_symbol = string.sub(quick_symbol_pattern, 2, 2) or ";"
    -- 生成单引导符和双引导符模式
    env.single_symbol_pattern = "^" .. quick_symbol .. "([a-zA-Z])$"
end

-- 处理符号和文本的重复上屏逻辑
local function processor(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input -- 当前输入的字符串

    -- 检查当前输入是否匹配单引导符符号模式 ;q、;w 等
    local match = string.match(input, env.single_symbol_pattern)
    if match then
        local symbol = mapping[match] -- 获取匹配的符号
        if symbol then
            -- 将符号直接上屏并保存到符号历史
            engine:commit_text(symbol)
            context:clear() -- 清空输入
            return 1 -- 捕获事件，处理完成
        end
    end
    return 2 -- 未处理事件，继续传播
end

-- 导出到 RIME
return {
    init = init,
    func = processor
}

