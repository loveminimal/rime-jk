--[[ 
作用：用来添加、删除自定义词语
-- by Jack Liu <https://aituyaa.com>

支持虎码、五笔、小鹤音形，感兴趣的朋友可以按需扩展
--]] 

-- 配制项 --
-- ① ➭ auto_reload_service
-- ¹ true 添加、删除操作之后「自动重启」服务，卡顿 
-- ² false  添加、删除操作之「手动重启」服务，不卡顿
-- - ²¹ ❌ 手动点击重启服务选项
-- - ²² ❌ rime_jk 方案可通过 ~rrr 触发重启服务「 不推荐 」新版本会崩溃
-- - ²³ ❌ 已经引入 ahk 调用外部命令（通过绑定 ctrl+p）解决重启服务
-- - ²⁴ 🎉〔 推荐 〕好消息，已经升级 ahk ，监听到文件变化后会自动重启服务
local auto_reload_service = false

-- ② ➭ auto_generate_dict
-- ¹ true  同步生成与 user_words.lua 相对应的字典 - user_words.dict.yaml
-- ² false 不生成
local auto_generate_dict  = false

-- ③ ➭ keep_user_words_top
-- ¹ true 自造词升序排在前面
-- ² false 排在后面
local keep_user_words_top = false

-- ④ 此处可以指定你的方案 schema_id
local schema_id_table = {
    ["pinyin"] = "jk_pinyin",
    ["tiger"] = "jk_tiger",
    ["wubi"] = "jk_wubi",
    ["flyyx"] = "jk_flyyx",
}

local cur_code_table = {}
local tiger_code_table = require("tiger_code_table")
local wubi86_code_table = require("wubi86_code_table")
local flyyx_code_table = require("flyyx_code_table")

-- 获取键值对 table 长度
local function table_len(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 正确的中文切片函数
-- lua 对中文的支持相当不友好 😡
local function utf8_sub(str, start_char, end_char)
    local start_byte = utf8.offset(str, start_char)
    local end_byte = utf8.offset(str, end_char + 1) or #str + 1
    return string.sub(str, start_byte, end_byte - 1)
end

local function hasSemi(str)
    return string.find(str, ";")
end

local function remove_duplicates(input_str)
    local seen = {}      -- 用于记录已出现的子串
    local result = {}    -- 存储去重后的结果
    local parts = {}     -- 临时存储分割后的子串

    -- 按分号分割字符串
    for part in string.gmatch(input_str, "([^;]+)") do
        table.insert(parts, part)
    end

    -- 去重逻辑
    for _, item in ipairs(parts) do
        if not seen[item] then
            seen[item] = true
            table.insert(result, item)
        end
    end

    -- 重新拼接为字符串
    return table.concat(result, ";")
end

-- 将汉字转换为虎码、五笔、小鹤音形编码
-- 不再分情况，直接使用暴力循环，并不会影响性能，放心使用
local function get_code(word)
    local CODE = ''

    -- first、seconde、third、last
    local f_char = ''
    local s_char = ''
    local t_char = ''
    local l_char = ''

    local len = utf8.len(word)
    if len == 1 then
        return remove_duplicates(cur_code_table[word])

    elseif len == 2 then
        f_char = utf8_sub(word, 1, 1)
        s_char = utf8_sub(word, 2, 2)

        local f_char_code = cur_code_table[f_char]
        local s_char_code = cur_code_table[s_char]

        for _code in string.gmatch(f_char_code, "([^;]+)") do 
            for _codes in string.gmatch(s_char_code, "([^;]+)") do
                CODE = CODE .. string.sub(_code, 1, 2) .. string.sub(_codes, 1, 2) .. ';'
            end
        end
        return remove_duplicates(CODE:sub(1, -2))

    elseif len == 3 then
        f_char = utf8_sub(word, 1, 1)
        s_char = utf8_sub(word, 2, 2)
        t_char = utf8_sub(word, 3, 3)

        local f_char_code = cur_code_table[f_char]
        local s_char_code = cur_code_table[s_char]
        local t_char_code = cur_code_table[t_char]

        for _code in string.gmatch(f_char_code, "([^;]+)") do 
            for _codes in string.gmatch(s_char_code, "([^;]+)") do 
                for _codet in string.gmatch(t_char_code, "([^;]+)") do 
                    -- 这里针对三字词，我们追加三简，如：动不动 → dbd
                    CODE = CODE .. string.sub(_code, 1, 1) .. string.sub(_codes, 1, 1) .. string.sub(_codet, 1, 1) .. ';'
                    -- 四码全码
                    CODE = CODE .. string.sub(_code, 1, 1) .. string.sub(_codes, 1, 1) .. string.sub(_codet, 1, 2) .. ';'
                end
            end
        end
        return remove_duplicates(CODE:sub(1, -2))        

    elseif len >= 4 then
        f_char = utf8_sub(word, 1, 1)
        s_char = utf8_sub(word, 2, 2)
        t_char = utf8_sub(word, 3, 3)
        l_char = utf8_sub(word, len, len)

        local f_char_code = cur_code_table[f_char]
        local s_char_code = cur_code_table[s_char]
        local t_char_code = cur_code_table[t_char]
        local l_char_code = cur_code_table[l_char]
        
        for _code in string.gmatch(f_char_code, "([^;]+)") do 
            for _codes in string.gmatch(s_char_code, "([^;]+)") do 
                for _codet in string.gmatch(t_char_code, "([^;]+)") do 
                    for _codel in string.gmatch(l_char_code, "([^;]+)") do 
                        CODE = CODE .. string.sub(_code, 1, 1) .. string.sub(_codes, 1, 1) .. string.sub(_codet, 1, 1) .. string.sub(_codel, 1, 1) .. ';'
                    end
                end
            end
        end
        return remove_duplicates(CODE:sub(1, -2))
    end

    return ""
end

-- 写入当前候选到 user_words.lua 中
local function write_word_to_file(env)
    local filename = rime_api.get_user_data_dir() .. "/lua/user_words.lua"
    if not filename then
        return false
    end

    local phrases = {}
	for phrase, _ in pairs(env.user_words) do
	    table.insert(phrases, phrase)
	end
	-- 对 phrases 按照你想要的方式排序（例如按字典序）
	table.sort(phrases)  -- 默认按字典序排序
	-- 使用排序后的顺序生成 serialize_str
    local serialize_str = "" -- 返回数据部分

	for _, phrase in ipairs(phrases) do
        
        local code = get_code(phrase)

        -- todo 先放这里，没啥用
        -- for _code in string.gmatch(code, "([^;]+)") do
        --     print(_code)
        -- end
	    serialize_str = serialize_str .. string.format('    ["%s"] = "%s",\n', phrase, code)
	end

    -- 构造完整的 record 内容
    local record_header = "-- type: " .. env.schema_type .. "\n-- top: " .. tostring(keep_user_words_top) .. "\n"
    local record = record_header .. "local user_words = {\n" .. serialize_str .. "}\nreturn user_words"
    -- 打开文件进行写入
    local fd = assert(io.open(filename, "w"))
    fd:setvbuf("line")
    -- 写入完整内容
    fd:write(record)
    fd:close() -- 关闭文件
end

local function write_word_to_dict(env)
    local filename = rime_api.get_user_data_dir() .. "/dicts/user_words.dict.yaml"
    if not filename then
        return false
    end

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
        "---\nname: user_words\n" ..
        "type: " .. env.schema_type .. "\n" ..
        "version: 2025.05\nsort: by_weight\nuse_preset_vocabulary: false\n...\n" -- 返回数据部分
	for _, phrase in ipairs(phrases) do
	    local code = get_code(phrase)
        if hasSemi(code) then
            for _code in string.gmatch(code, "([^;]+)") do 
	            serialize_str = serialize_str .. string.format('%s\t%s\t%d\n', phrase, _code, keep_user_words_top and 100000000 or 1)
            end
        else
            serialize_str = serialize_str .. string.format('%s\t%s\t%d\n', phrase, code, keep_user_words_top and 100000000 or 1)
        end
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

local function startsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- ❶ 添加、删除候选项 ---
-- ------------------------------------------------------------------
local P = {}
local user_words_lua = rime_api.get_user_data_dir() .. "/lua/user_words.lua"
function P.init(env)
    -- 如果不存在 user_words.lua ，创建并初始化
    if not file_exists(user_words_lua) then
        local file, err = io.open(user_words_lua, "w")
        if not file then
            return
        end
        file:write("-- type: flyyx\n-- top: false\nlocal user_words = {\n    [\"出\"] = \"iuvk\",\n}\nreturn user_words")
        file:close()
    end

    env.user_words = require("user_words") -- 加载文件中的 user_words
    local cur_schema = env.engine.schema.schema_id
    -- log.warning('➭ ' .. cur_schema)
    -- 鉴于有时候虎码方案隐藏候选框使用，故此处允许 jk_pinyin 方案添加「 自造词 」
    if startsWith(cur_schema, schema_id_table["tiger"])then
        env.schema_type = "tiger"
        cur_code_table = tiger_code_table
    elseif startsWith(cur_schema, schema_id_table["wubi"]) then
        env.schema_type = "wubi"
        cur_code_table = wubi86_code_table
    elseif startsWith(cur_schema, schema_id_table["flyyx"]) or startsWith(cur_schema, schema_id_table["pinyin"]) then
        env.schema_type = "flyyx"
        cur_code_table = flyyx_code_table
    end
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
    -- if utf8.len(phrase) < 2 then
    --     return 2
    -- end

    -- ​组合键​​	​​键码（十六进制）​​	​​ASCII 码（十进制）​​
    -- Ctrl + a	0x61	97
    -- Ctrl + b	0x62	98
    -- Ctrl + c	0x63	99
    -- Ctrl + d	0x64	100
    -- Ctrl + e	0x65	101
    -- Ctrl + f	0x66	102
    -- Ctrl + g	0x67	103
    -- Ctrl + h	0x68	104
    -- Ctrl + i	0x69	105
    -- Ctrl + j	0x6A	106
    -- Ctrl + k	0x6B	107
    -- Ctrl + l	0x6C	108
    -- Ctrl + m	0x6D	109
    -- Ctrl + n	0x6E	110
    -- Ctrl + o	0x6F	111
    -- Ctrl + p	0x70	112
    -- Ctrl + q	0x71	113
    -- Ctrl + r	0x72	114
    -- Ctrl + s	0x73	115
    -- Ctrl + t	0x74	116
    -- Ctrl + u	0x75	117
    -- Ctrl + v	0x76	118
    -- Ctrl + w	0x77	119
    -- Ctrl + x	0x78	120
    -- Ctrl + y	0x79	121
    -- Ctrl + z	0x7A	122

    if key_event.keycode == 0x6F then -- ctrl + o (移除 out)
        env.user_words[phrase] = nil
    elseif key_event.keycode == 0x69 then -- ctrl + i (添加 in)
        env.user_words[phrase] = get_code(phrase)
        env.engine:commit_text(phrase)  -- 上屏当前候选项
    else
        return 2
    end

    context:clear()  -- 清除无用编码及候选框

    -- 实时更新 Lua 表序列化并保存
    -- log.warning(env.schema_type)
    write_word_to_file(env) -- 使用统一的写入函数
    if auto_generate_dict then
        write_word_to_dict(env) -- 使用统一的写入函数生成对应的词典
    end

    -- ❌ 该操作可以废弃，已通过 AHK 在监听到文件变化后从外部重启服务，避免卡死
    if auto_reload_service then
        os.execute('cmd /c start "" "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\小狼毫输入法\\小狼毫算法服务"')
        context:refresh_non_confirmed_composition()
        context.clear()
    end
    return 1
end

local function hasKey(tbl, key)
    if tbl == nil then
        return false
    end
    for k, _ in pairs(tbl) do
        -- if #key == 4 and string.find(k, key) then
        -- 此处对三字词添加三简支持
        if #key >= 3 and string.find(k, key) then
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
    -- log.error('FFF ➭ ' .. table_len(env.seq_words_dict))
end

function F.func(input, env)
    local input_code = env.engine.context.input
    local code_len = #input_code

    local is_in_table = hasKey(env.seq_words_dict, input_code)
    local old_candidates = {}
    local new_candidates = {}
    -- log.error(tostring(is_in_table))

    -- 如果没有匹配的简码或输入长度不符，直接返回原始候选
    if not is_in_table then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    -- log.warning('--- in table ---')
    -- 循环遍历 user_words 创建新的候选
    for code, phrases in pairs(env.seq_words_dict) do
        -- log.error("键:" .. code)
        -- 遍历当前键对应的词组列表
        for _, phrase in ipairs(phrases) do
            -- log.warning("值:" .. phrase)
            -- if code == input_code then
            -- if #input_code == 4 and string.find(code, input_code) then
            if string.find(code, input_code) then
                -- 过滤掉 - 输入码长度为 3 且候选项长为 2 或大于 3 的情况
                -- 如，实施、事实 → uiu[i] ，以此与转换到词典后是使用体验保持一致
                -- 实际上，我们只为三字词语追加了三简
                if not (#input_code == 3 and (utf8.len(phrase) == 2 or utf8.len(phrase) > 3)) then
                    local new_cand = Candidate("word", 1, 4, phrase, "*")
                    -- table.insert(new_candidates, new_cand)
                    table.insert(new_candidates, new_cand)
                end
            end
        end
    end
    -- 整理已有候选（用于后续排序）
    for cand in input:iter() do
        table.insert(old_candidates, cand)
    end

    table.sort(new_candidates, function(a, b)
        -- 自定义排序逻辑
        return a.text < b.text  -- 按候选词文本升序排序
    end)

    local _cands = {}
    if keep_user_words_top then
        -- ^¹ 自造词排在前面
        _cands = new_candidates
        for i = 1, #old_candidates do
            _cands[#new_candidates + 1] = old_candidates[i]
        end
    else
        -- ^² 自造词排在后面
        _cands = old_candidates
        for i = 1, #new_candidates do
            _cands[#old_candidates + 1] = new_candidates[i]
        end
    end

    -- 输出重新排序后的候选
    for _, cand in ipairs(_cands) do
        yield(cand)
    end
end

return {
    F = F,
    P = P
}
