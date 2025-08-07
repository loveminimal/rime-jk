--[[ 
作用：用于辅助四码定长的形码进一步选重
-- by Jack Liu <https://aituyaa.com>

支持小鹤音形、魔然字词，默认使用鹤形作为筛选表
支持虎码、五笔，默认使用鹤音作为筛选表

感兴趣的朋友可以按需扩展
--]] 

-- local logger = require("logger")

local schema_id_table = {
    ["pinyin"] = "jk_pinyin",
    ["tiger"] = "jk_tiger",
    ["wubi"] = "jk_wubi",
    ["flyyx"] = "jk_flyyx",
}

local aux_code_table = {}
local aux_code_hy_table = require("data/aux_code_hy_table")
local aux_code_hx_table = require("data/aux_code_hx_table")

local A = {}

local function startsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

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

local function reverse_seq_words(user_words)
    local new_dict = {}

    for word, code in pairs(user_words) do
        if not new_dict[code] then
            new_dict[code] = {word}
        else
            table.insert(new_dict[code], word)
        end
    end

    return new_dict
end

local old_candidates = {}
-- 初始化符号输入的状态
function A.init(env)
    -- 初始化操作
    old_candidates = {}
    local config = env.engine.schema.config
    env.chars = config:get_string("chars/prefix")
    env.pinyin = config:get_string("pinyin/prefix")
    env.reverse_lookup = config:get_string("reverse_lookup/prefix")
    -- logger.info(pinyin .. ' ' .. chars)

    local cur_schema = env.engine.schema.schema_id
    -- logger.info('➭ ' .. cur_schema)
    if startsWith(cur_schema, schema_id_table["tiger"])then
        env.schema_type = "tiger"
        aux_code_table = aux_code_hy_table
    elseif startsWith(cur_schema, schema_id_table["flyyx"]) then
        env.schema_type = "flyyx"
        aux_code_table = aux_code_hx_table
    end

    -- 同样对 user_words 中的候选项进行选重
    env.user_words = require("user_words") or {}
    env.seq_words_dict = reverse_seq_words(env.user_words)
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
            -- logger.info('4 -- ' .. cand.text)
            table.insert(old_candidates, cand)
            yield(cand)
        end

        -- 循环遍历 user_words 创建新的候选
        for code, phrases in pairs(env.seq_words_dict) do
            -- logger.info("键:" .. code)
            -- 遍历当前键对应的词组列表
            for _, phrase in ipairs(phrases) do
                -- logger.info("值:" .. phrase)
                -- if code == input_code then
                -- if #input_code == 4 and string.find(code, input_code) then
                if string.find(code, input_code) then
                    local new_cand = Candidate("word", 1, 4, phrase, "*")
                    table.insert(old_candidates, new_cand)
                end
            end
        end

        return
    end

    -- 默认使用 4 码后的两码作为辅助码用以筛选缓存的四码候选
    -- 且排除拼音反查的情况
    if code_len == 5 or code_len == 6 then
        -- logger.info('input_code ➭ ' .. input_code)
        local aux_code = string.sub(input_code, 5)
        -- logger.info('aux_code ➭ ' .. aux_code)
        local aux_list = aux_code_table[aux_code] or {}

        -- 排除以 ow、oc（小鹤）¦ Z、C（形码）¦ ~~（字符反查）为引导词的副编译器「 拼音反查时 」
        local f_code = string.sub(input_code, 1, 1)
        local fs_code = string.sub(input_code, 1, 2)
        if fs_code == env.chars or fs_code == env.pinyin or 
            -- f_code == env.reverse_lookup or fs_code == env.reverse_lookup or 
            string.find("ABCDEFGHIJKLMNOPQRSTUVWXYZ~`;'/", f_code) then

            for cand in input:iter() do
                yield(cand)
            end
            return
        end

        for _, cand in ipairs(old_candidates) do
            local cand_text = cand.text
            -- logger.info(cand_text)
            local len = utf8.len(cand_text)
            local last_char = utf8_sub(cand_text, len, len)
            -- logger.info('last_char → ' .. last_char)

            if is_in_array(last_char, aux_list) then
                -- logger.info('new_candidates → ' .. cand_text)
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