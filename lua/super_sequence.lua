-- 万象拼音方案新成员，手动自由排序
-- 一个基于快捷键计数偏移量来手动调整排序的工具
-- 这个版本是db数据库支持的版本,可能会支持更多的排序记录,作为一个备用版本留存
-- ctrl+j左移 ctrl+k左移  ctrl+0移除排序信息,固定词典其实没必要删除,直接降权到后面
-- 排序算法可能还不完美,有能力的朋友欢迎帮忙变更算法
-- 序列化并写入文件的函数
local tiger_code_table = require("tiger_code_table")

function table_len(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function utf8_sub(str, start_char, end_char)
    local start_byte = utf8.offset(str, start_char)
    local end_byte = utf8.offset(str, end_char + 1) or #str + 1
    return string.sub(str, start_byte, end_byte - 1)
end

function get_tiger_code(word)
    -- 将汉字转换为虎码编码
    local len = utf8.len(word)
    if len == 1 then
        return tiger_code_table[word]
    elseif len == 2 then
        return string.sub(tiger_code_table[utf8_sub(word, 1, 1)], 1, 2) ..
                   string.sub(tiger_code_table[utf8_sub(word, 2, 2)], 1, 2)
    elseif len == 3 then
        return string.sub(tiger_code_table[utf8_sub(word, 1, 1)], 1, 1) ..
                   string.sub(tiger_code_table[utf8_sub(word, 2, 2)], 1, 1) ..
                   string.sub(tiger_code_table[utf8_sub(word, 3, 3)], 1, 2)
    elseif len >= 4 then
        return string.sub(tiger_code_table[utf8_sub(word, 1, 1)], 1, 1) ..
                   string.sub(tiger_code_table[utf8_sub(word, 2, 2)], 1, 1) ..
                   string.sub(tiger_code_table[utf8_sub(word, 3, 3)], 1, 1) ..
                   string.sub(tiger_code_table[utf8_sub(word, len, len)], 1, 1)
    end

    return ""
end

function write_word_to_file(env, record_type)
    local filename = rime_api.get_user_data_dir() .. "/lua/seq_words.lua"
    if not filename then
        return false
    end
    local serialize_str = "" -- 返回数据部分
    -- 遍历表中的每个元素并格式化
    for phrase, _ in pairs(env.seq_words) do
        local code = get_tiger_code(phrase)
        serialize_str = serialize_str .. string.format('    ["%s"] = "%s",\n', phrase, code)
    end
    -- 构造完整的 record 内容
    local record = "local seq_words = {\n" .. serialize_str .. "}\nreturn seq_words"
    -- 打开文件进行写入
    local fd = assert(io.open(filename, "w"))
    fd:setvbuf("line")
    -- 写入完整内容
    fd:write(record)
    fd:close() -- 关闭文件
end

local P = {}
function P.init(env)
    env.seq_words = require("seq_words") -- 加载文件中的 seq_words
end

-- P 阶段按键处理
function P.func(key_event, env)
    local context = env.engine.context
    local input_text = context.input
    local segment = context.composition:back()
    if not segment then
        return 2
    end
    if not key_event:ctrl() or key_event:release() then
        return 2
    end
    local selected_candidate = context:get_selected_candidate()
    local phrase = selected_candidate.text
    -- 判断按下的键
    -- 单字无需处理
    if utf8.len(phrase) < 2 then
        return 2
    end

    if key_event.keycode == 0x6A then -- ctrl + j (移除)
        env.seq_words[phrase] = nil
    elseif key_event.keycode == 0x6B then -- ctrl + k (添加)
        env.seq_words[phrase] = get_tiger_code(phrase)
    else
        return 2
    end
    -- 实时更新 Lua 表序列化并保存
    write_word_to_file(env, "seq") -- 使用统一的写入函数
    -- context.clear()
    -- os.execute('"C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselDeployer.exe" /deploy')
    -- os.execute('C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselServer.exe')
    os.execute('cmd /c start "" "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\小狼毫输入法\\小狼毫算法服务"')
    context:refresh_non_confirmed_composition()
    context.clear()
    return 1
end

function hasKey(tbl, key)
    if tbl == nil then
        return false
    end
    for k, _ in pairs(tbl) do
        if k == key then
            return true
        end
    end
    return false
end

function reverse_seq_words(seq_words)
    local new_dict = {}

    for word, code in pairs(seq_words) do
        if not new_dict[code] then
            new_dict[code] = {word}
        else
            table.insert(new_dict[code], word)
        end
    end

    return new_dict
end

local F = {}
local MAX_CANDIDATES = 300

function F.init(env)
    log.warning('-------------------------')
    env.seq_words = require("seq_words") or {}
    -- seq_words_dict 为 seq_words 的变形，其结构如下
    -- {
    --     ["fsss"] = { "一步步", "正步" },
    --     ["drjd"] = { "中国人民" },
    --     ["dgrn"] = { "中国" },
    --     ["yymg"] = { "小小狗" },
    -- }
    env.seq_words_dict = reverse_seq_words(env.seq_words)
    log.warning('FFF ➭ ' .. table_len(env.seq_words_dict))
end

function F.func(input, env)
    local input_code = env.engine.context.input
    local code_len = #input_code

    local is_in_table = hasKey(env.seq_words_dict, input_code)
    local new_candidates = {}

    log.warning(tostring(is_in_table))
    env.seq_words = require("seq_words") or {}

    -- 如果没有匹配的简码或输入长度不符，直接返回原始候选
    if not is_in_table then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    for cand in input:iter() do
        for code, phrases in pairs(env.seq_words_dict) do
            log.warning("键:" .. code)

            -- 遍历当前键对应的词组列表
            for _, phrase in ipairs(phrases) do
                log.warning("值:" .. phrase)

                if input_code == code then
                    local new_cand = Candidate("word", cand.start, cand._end, phrase, "*")
                    table.insert(new_candidates, new_cand)
                end
            end
        end
        table.insert(new_candidates, cand)
    end

    -- 输出重新排序后的候选
    for _, cand in ipairs(new_candidates) do
        yield(cand)
    end
end

return {
    F = F,
    P = P
}
