--- by wubi86_jidian_single_char_only.lua
--- modified by Jack Liu <https://aituyaa.com>
--- 过滤器：只显示单字

local function single_char_only(input, env)
    local is_char_only = env.engine.context:get_option( 'char_only' ) or false
    local input_str = tostring(env.engine.context.input or "")  -- 类型安全转换

    -- 如果未开启单字模式，直接返回所有候选（不处理）
    if not is_char_only or (input_str ~= "" and string.sub(input_str, 1, 1) == "~") then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- 单字模式：仅筛选长度为1的候选
    for cand in input:iter() do
        if (utf8.len(cand.text) == 1) then
            yield(cand)
        end
    end
end

return single_char_only
