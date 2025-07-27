--[[ 
作用：用于辅助四码定长的形码进一步选重
-- by Jack Liu <https://aituyaa.com>

支持小鹤音形，感兴趣的朋友可以按需扩展（如虎码、五笔、魔然字词）
--]] 

local aux_code_table = require("aux_code_table")
local A = {}

-- 正确的中文切片函数
-- lua 对中文的支持相当不友好 😡
local function utf8_sub(str, start_char, end_char)
    local start_byte = utf8.offset(str, start_char)
    local end_byte = utf8.offset(str, end_char + 1) or #str + 1
    return string.sub(str, start_byte, end_byte - 1)
end

-- 检查是否在数组中
local function is_in_array(value, array)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

local old_candidates = {}
-- 初始化符号输入的状态
function A.init(env)
    -- 初始化操作
    old_candidates = {}
    local config = env.engine.schema.config
    env.chars = config:get_string("chars/prefix")
    env.pinyin = config:get_string("pinyin/prefix")
    -- log.error(pinyin .. ' ' .. chars)
end

-- 处理符号和文本的重复上屏逻辑
function A.func(input, env)
    local context = env.engine.context
    local input_code = context.input -- 当前输入的字符串
    local code_len = #input_code

    local new_candidates = {}

    if code_len < 4 then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- 收集 4 码时的候选用以后续筛选
    if code_len == 4 then
        old_candidates = {}
        for cand in input:iter() do
            -- log.error('4 -- ' .. cand.text)
            table.insert(old_candidates, cand)
            yield(cand)
        end
        return
    end

    -- 默认使用 4 码后的两码作为辅助码用以筛选缓存的四码候选
    -- 且排除拼音反查的情况
    if code_len == 5 or code_len == 6 then
        -- log.error('input_code ➭ ' .. input_code)
        local aux_code = string.sub(input_code, 5)
        -- log.error('aux_code ➭ ' .. aux_code)
        local aux_list = aux_code_table[aux_code] or {}

        -- 排除以 ow、oc 为引导词的副编译器「 拼音反查时 」
        local fs_code = string.sub(input_code, 1, 2)
        if fs_code == env.chars or fs_code == env.pinyin then
            for cand in input:iter() do
                yield(cand)
            end
            return
        end

        for _, cand in ipairs(old_candidates) do
            local cand_text = cand.text
            -- log.error(cand_text)
            local len = utf8.len(cand_text)
            local last_char = utf8_sub(cand_text, len, len)
            -- log.error('last_char → ' .. last_char)

            if is_in_array(last_char, aux_list) then
                -- log.error('new_candidates → ' .. cand_text)
                local new_cand = Candidate("word", 1, 6, cand_text, "〆")
                table.insert(new_candidates, new_cand)
            end
        end

        for _, cand in ipairs(new_candidates) do
            yield(cand)
        end
        return
    end

    -- 其它长度（>6）直接使用当前 input 候选
    for cand in input:iter() do
        yield(cand)
    end
end

-- 导出到 RIME
return A