--[[ 
-- by Jack Liu <https://aituyaa.com>

作用：用来添加、删除自定义词语

-- 配制项 --
➭ auto_reload_service = true
添加、删除操作之后强制重启 Rime 服务，存在几秒左右卡顿 
➭ auto_reload_service = false
添加、删除操作之手动重启服务，不卡顿
¹ 手动点击重启服务选项
² ~rrr → rime_jk 方案可通过 ~rrr 触发重启服务
➭ auto_generate_dict = false
¹ true  同步生成与 user_words.lua 相对应的字典 - user_words.dict.yaml
² false 不生成
--]] 
local auto_reload_service = false
local auto_generate_dict = false

local filename = rime_api.get_user_data_dir() .. "/user.yaml"
local fd = assert(io.open(filename, "r"))
local content = fd:read("*a")
fd:close()

-- 提取 user.yaml:/var/previously_selected_schema 的值 - 当指使用方案
-- jk_wubi、jk_tiger……
local cur_schema = content:match("previously_selected_schema:%s*([%w_]+)")
-- log.warning(cur_schema)

local code_table = {}
if cur_schema == 'jk_wubi' then
    code_table = require("wubi86_code_table")
elseif cur_schema == 'jk_tiger' then
    code_table = require("tiger_code_table")
end

-- 获取键值对 table 长度
function table_len(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 正确的中文切片函数
-- lua 对中文的支持相当不友好 😡
function utf8_sub(str, start_char, end_char)
    local start_byte = utf8.offset(str, start_char)
    local end_byte = utf8.offset(str, end_char + 1) or #str + 1
    return string.sub(str, start_byte, end_byte - 1)
end

-- 将汉字转换为虎码编码
function get_tiger_code(word)
    local len = utf8.len(word)
    if len == 1 then
        return code_table[word]
    elseif len == 2 then
        return string.sub(code_table[utf8_sub(word, 1, 1)], 1, 2) .. string.sub(code_table[utf8_sub(word, 2, 2)], 1, 2)
    elseif len == 3 then
        return
            string.sub(code_table[utf8_sub(word, 1, 1)], 1, 1) .. string.sub(code_table[utf8_sub(word, 2, 2)], 1, 1) ..
                string.sub(code_table[utf8_sub(word, 3, 3)], 1, 2)
    elseif len >= 4 then
        return
            string.sub(code_table[utf8_sub(word, 1, 1)], 1, 1) .. string.sub(code_table[utf8_sub(word, 2, 2)], 1, 1) ..
                string.sub(code_table[utf8_sub(word, 3, 3)], 1, 1) ..
                string.sub(code_table[utf8_sub(word, len, len)], 1, 1)
    end

    return ""
end

-- 写入当前候选到 user_words.lua 中
function write_word_to_file(env, record_type)
    local filename = rime_api.get_user_data_dir() .. "/lua/user_words.lua"
    if not filename then
        return false
    end

    -- 遍历表中的每个元素并格式化
    -- for phrase, _ in pairs(env.user_words) do
    --     local code = get_tiger_code(phrase)
    --     serialize_str = serialize_str .. string.format('    ["%s"] = "%s",\n', phrase, code)
    -- end
    local phrases = {}
	for phrase, _ in pairs(env.user_words) do
	    table.insert(phrases, phrase)
	end
	-- 对 phrases 按照你想要的方式排序（例如按字典序）
	table.sort(phrases)  -- 默认按字典序排序
	-- 使用排序后的顺序生成 serialize_str
    local serialize_str = "" -- 返回数据部分
	for _, phrase in ipairs(phrases) do
	    local code = get_tiger_code(phrase)
	    serialize_str = serialize_str .. string.format('    ["%s"] = "%s",\n', phrase, code)
	end

    -- 构造完整的 record 内容
    local record = "local user_words = {\n" .. serialize_str .. "}\nreturn user_words"
    -- 打开文件进行写入
    local fd = assert(io.open(filename, "w"))
    fd:setvbuf("line")
    -- 写入完整内容
    fd:write(record)
    fd:close() -- 关闭文件
end

function write_word_to_dict(env, record_type)
    local filename = rime_api.get_user_data_dir() .. "/dicts/user_words.dict.yaml"
    if not filename then
        return false
    end

    -- 遍历表中的每个元素并格式化
    -- for phrase, _ in pairs(env.user_words) do
    --     local code = get_tiger_code(phrase)
    --     serialize_str = serialize_str .. string.format('%s	%s	%d\n', phrase, code, 100000000)
    -- end
    local phrases = {}
	for phrase, _ in pairs(env.user_words) do
	    table.insert(phrases, phrase)
	end
	-- 对 phrases 按照你想要的方式排序（例如按字典序）
	table.sort(phrases)  -- 默认按字典序排序
	-- 使用排序后的顺序生成 serialize_str
    local serialize_str =
        "# Rime dictionary - user_word.dict.yaml\n# encoding: utf-8\n" .. 
        "# \n# --- 说明 ---\n# 该字典是基于 word_words.lua 同步生成的用户词典\n# \n" .. 
        "---\nname: user_words\nversion: 2025.05\nsort: by_weight\nuse_preset_vocabulary: false\n...\n" -- 返回数据部分
	for _, phrase in ipairs(phrases) do
	    local code = get_tiger_code(phrase)
	    serialize_str = serialize_str .. string.format('%s\t%s\t%d\n', phrase, code, 100000000)
	end

    -- 构造完整的 record 内容
    local record = serialize_str
    -- 打开文件进行写入
    local fd = assert(io.open(filename, "w"))
    fd:setvbuf("line")
    -- 写入完整内容
    fd:write(record)
    fd:close() -- 关闭文件
end

-- ❶ 添加、删除候选项 ---
-- ------------------------------------------------------------------
local P = {}
function P.init(env)
    env.user_words = require("user_words") -- 加载文件中的 user_words
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
        env.user_words[phrase] = nil
    elseif key_event.keycode == 0x6B then -- ctrl + k (添加)
        env.user_words[phrase] = get_tiger_code(phrase)
    else
        return 2
    end
    -- 实时更新 Lua 表序列化并保存
    write_word_to_file(env, "seq") -- 使用统一的写入函数
    if auto_generate_dict then
        write_word_to_dict(env, "seq") -- 使用统一的写入函数生成对应的词典
    end
    -- os.execute('"C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselDeployer.exe" /deploy')
    -- os.execute('C:\\Program Files\\Rime\\weasel-0.16.3\\WeaselServer.exe')

    if auto_reload_service then
        os.execute('cmd /c start "" "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\小狼毫输入法\\小狼毫算法服务"')
        context:refresh_non_confirmed_composition()
        context.clear()
    end
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

function reverse_seq_words(user_words)
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

-- ❷ 读取、排序候选项 ---
-- ------------------------------------------------------------------
local F = {}

function F.init(env)
    env.user_words = require("user_words") or {}
    -- seq_words_dict 为 user_words 的变形，其结构如下
    -- {
    --     ["fsss"] = { "一步步", "正步" },
    --     ["drjd"] = { "中国人民" },
    --     ["dgrn"] = { "中国" },
    --     ["yymg"] = { "小小狗" },
    -- }
    env.seq_words_dict = reverse_seq_words(env.user_words)
    -- log.warning('FFF ➭ ' .. table_len(env.seq_words_dict))
end

function F.func(input, env)
    local input_code = env.engine.context.input
    local code_len = #input_code

    local is_in_table = hasKey(env.seq_words_dict, input_code)
    local new_candidates = {}
    -- log.warning(tostring(is_in_table))

    -- 如果没有匹配的简码或输入长度不符，直接返回原始候选
    if not is_in_table then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    for cand in input:iter() do
        -- 先插入已有匹配选项，将自造词语加在其后
        table.insert(new_candidates, cand)
        for code, phrases in pairs(env.seq_words_dict) do
            -- log.warning("键:" .. code)
            -- 遍历当前键对应的词组列表
            for _, phrase in ipairs(phrases) do
                -- log.warning("值:" .. phrase)
                if input_code == code then
                    local new_cand = Candidate("word", cand.start, cand._end, phrase, "*")
                    table.insert(new_candidates, new_cand)
                end
            end
        end
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
