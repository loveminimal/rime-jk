-- helper.lua
-- List features and usage of the schema.
local T = {}

function T.func(input, seg, env)
    local composition = env.engine.context.composition
    local segment = composition:back()
    if seg:has_tag("helper") or (input == "~help") or (input == "hH") then
        local table = {
            { "帮助菜单", "→ ~help|hH" },
            { "二三四选", "→ ; ' / 键" },
            { "上下翻页", "→ , [   键" },
            { "拼音反查", "→ z     键" },
            { "分词符号", "→ ~     键" },
            { "符号反查", "→ ~     键" },
            { "英文反查", "→ ~~    键" },
            { "日期插入", "→ ~d    键" },
            { "方案选单", "→ Ctrl + m" },
            { "方案快切", "→ Ctrl + ," },
            { "简繁转换", "→ Ctrl + [" },
            { "中译英文", "→ Ctrl + ]" },
            { "拆分隐显", "→ Ctrl + \\" },
            { "向下移动", "→ Ctrl + j" },
            { "向上移动", "→ Ctrl + k" },
            { "快符   ~", "→ Ctrl + ." },
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
