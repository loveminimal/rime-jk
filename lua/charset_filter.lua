--[[ 
作用：开关过滤扩区字集
-- by Jack Liu <https://aituyaa.com>
--]]
local logger = require("logger")
local general_chars_table = require("data/wubi86_code_table")

local charsfilter = {}

-- 判断字符是否为汉字
local function is_chinese_char(text)
    local codepoint = utf8.codepoint(text)
    return (codepoint >= 0x4E00 and codepoint <= 0x9FFF)  -- basic
        or (codepoint >= 0x3400 and codepoint <= 0x4DBF)  -- ext a
        or (codepoint >= 0x20000 and codepoint <= 0x2A6DF) -- ext b
        or (codepoint >= 0x2A700 and codepoint <= 0x2B73F) -- ext c
        or (codepoint >= 0x2B740 and codepoint <= 0x2B81F) -- ext d
        or (codepoint >= 0x2B820 and codepoint <= 0x2CEAF) -- ext e
        or (codepoint >= 0x2CEB0 and codepoint <= 0x2EBE0) -- ext f
        or (codepoint >= 0x30000 and codepoint <= 0x3134A) -- ext g
        or (codepoint >= 0x31350 and codepoint <= 0x323AF) -- ext h
        or (codepoint >= 0x2EBF0 and codepoint <= 0x2EE5F) -- ext i
        or (codepoint >= 0xF900 and codepoint <= 0xFAFF)  -- CJK Compatibility
        or (codepoint >= 0x2F800 and codepoint <= 0x2FA1F) -- Compatibility Supplement
        or (codepoint >= 0x2E80 and codepoint <= 0x2EFF)  -- CJK Radicals Supplement
        or (codepoint >= 0x2F00 and codepoint <= 0x2FDF)  -- Kangxi Radicals
end

-- 检查字符是否为单个汉字
local function is_general_char(text)
    return utf8.len(text) == 1 and is_chinese_char(text)
end


function charsfilter.func(t_input, env)
    local is_extended = env.engine.context:get_option("charset_filter") -- 是否扩集
    -- logger.info(is_extended)
    local cur_table = {}
    if is_extended then
        -- 开启扩集
        for cand in t_input:iter() do
            yield(cand)
        end
    else
        -- 通规字集
        for cand in t_input:iter() do
            local cand_text = cand.text

            -- 对于非汉字字符，直接放行
            if not is_general_char(cand_text) then
                yield(cand)
            end

            -- 遍历候选项，移除包含扩集的字词
            for i, c in utf8.codes(cand_text) do
                -- logger.info(i .. " ➭ " .. c .. " ➭ " .. utf8.char(c))
                -- 这里需要注意 utf8.char(c) 而不是 c
                if general_chars_table[utf8.char(c)] then
                    yield(cand)
                end
            end
        end
    end
end

return charsfilter
