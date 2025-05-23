--[[ 
-- by Jack Liu <https://aituyaa.com>

① 英译中词典候选注释改造
词典格式如下：
    able  a.能干的;能够的	able
    ablebodied  a.强壮的;强健的	ablebodied

候选词仅保留单词主体部分，如 able
释义部分放在注释中，如 a.能干的;能够的

② 排除自定义别名和 Emoji 及标点符号
--]] 

-- 定义日志输出
local function logg(text)
    log.warning(text)
end

local function parse_definitions(text)
    local definitions = {}
    -- for pos_def in string.gmatch(text, "([%a%.]+%.[^%a%.]+)") do
    for pos_def in string.gmatch(text, "([%a]+%.[^%a]+)") do
        table.insert(definitions, pos_def)
    end
    return definitions
end


local function filter(input)
    -- logg('--- 开始测试 FILTER ---')
    local l = {}
    for cand in input:iter() do

        -- 增强一下英文词典反查 将释义放在注释中---
        local cand_text = cand.text
        -- logg('cand.text >>> ' .. cand_text)

        -- --- 自定义指令 ---
        -- 排除包含路径字符或命令符号的字符串 - 全部放候选
        -- 此类字符基本源自 en_aliases 的命令别名
        -- 如 cd ~/AppData/Roaming/Rime && source scripts/update-cn_dicts_wx.sh
        if string.find(cand_text, "^[%a%d%&%-%_%~%/%.%s%:%=%*\"%'%|]+$") then
            -- cand:get_genuine().comment = ''
            yield(cand)
            goto continue
        end

        -- --- 字典注释 ---
        -- 正确格式输出英文词典 - 候选 + 释义注释
        -- local cand_text = "China n.    中国 adj. 中国的 中国制造的"
        -- local word, pos, meaning = string.match(cand_text, "(%a+)%s+(%a+%.%s*)(.+)")
        local word, pos, meaning = string.match(cand_text, "(%a+)%s+([%a&%.]+)%s*(.+)")

        if word then
            -- log.warning("Word:" .. word)        -- 输出: Word: China
            -- log.warning("POS:" .. pos)          -- 输出: POS: n.    
            -- log.warning("Meaning:" .. meaning)  -- 输出: Meaning: 中国 adj. 中国的 中国制造的
            cand.text = word
            cand.comment = pos .. meaning

            -- 按词性分词，避免有些词释义过长，导致候选框太长
            -- 解析词典条目
            local definitions = {}
            -- 仅注释词长超过 26 的进行分词展示
            if (utf8.len(cand.comment) > 26) then
                definitions = parse_definitions(cand.comment)
            else
                definitions = {cand.comment}
            end
            -- 输出结果
            for _, pos_def in ipairs(definitions) do
                local new_cand = Candidate(cand.type, cand.start, cand._end, word .. string.rep(' ', _ - 1), pos_def)
                yield(new_cand)
            end

            -- local new_cand = Candidate(cand.type, cand.start, cand._end, word, cand.comment)
            -- -- 使用 yield 替换原始候选项
            -- yield(new_cand)
            -- yield(cand)
            goto continue
        end

        -- --- emoji 及标点符号 ---
        local emoji_pattern = "[\xE2\x98\x80-\xE2\x9F\xBF\xF0\x9F\x8C\x80-\xF0\x9F\xA4\x9F%p\xE2\x80\x80-\xE2\x81\xBF\xE2\xB8\x80-\xE2\xB9\xBF\xE3\x80\x80-\xE3\x80\xBF]"
        if string.find(cand_text, emoji_pattern) then

            -- 移除那令人讨厌的 ☯ 注释
            if cand.comment:find('☯') then
                -- cand:get_genuine().comment = '💭'
                cand:get_genuine().comment = '+'
            end

            yield(cand)
            goto continue
        end

        ::continue::
    end

    -- logg('--- END ---')
end

return filter
