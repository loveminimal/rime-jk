-- helper.lua
-- List features and usage of the schema.
local T = {}

function T.func(input, seg, env)
    local composition = env.engine.context.composition
    local segment = composition:back()
    if seg:has_tag("helper") or (input == "/oh") or (input == "oH") then
        local table = {
            { "帮助菜单", "→ ~hh | hH" },
            { "二三四选", "→ ;'/   键" },
            { "上下翻页", "→ ,.    键" },
            { "拼音反查", "→ Z     键" },
            { "分词按键", "→ ~     键" },
            { "表情快查", "→ ~     键" },
            { "英文快查", "→ ~~    键" },
            { "历史上屏", "→ ~hs | hS" },
            { "方案选单", "→ Ctrl+m  " },
            { "方案快切", "→ Ctrl+,  " },
            { "简繁转换", "→ Ctrl+[  " },
            { "翻译快切", "→ Ctrl+]  " },
            { "拆分隐显", "→ Ctrl+\\ " },
            { "日期快输", "→ iii     " },
            { "日期时间", "→ " .. "date | time | /wd | /wt" },
            { "农历星期", "→ " .. "lunar | week | /nl | /wk" },
            { "项目地址", "→ " .. "loveminimal/rime-jk" },
        }
        segment.prompt = "〔帮助·菜单〕"
        for _, v in ipairs(table) do
            local cand = Candidate("help", seg.start, seg._end, v[1], " " .. v[2])
            cand.quality = 999
            yield(cand)
        end
    end
end

return T
