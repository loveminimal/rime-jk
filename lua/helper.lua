-- helper.lua
-- List features and usage of the schema.
local T = {}

function T.func(input, seg, env)
    local composition = env.engine.context.composition
    local segment = composition:back()
    if seg:has_tag("helper") or (input == "~hh") or (input == "hH") then
        local table = {
            { "帮助菜单", "→ ~hh | hH" },
            { "二三四选", "→ ; ' / 键" },
            { "上下翻页", "→ , .   键" },
            { "临时拼音", "→ Z     键" },
            { "分词按键", "→ ~     键" },
            { "符号快插", "→ ~     键" },
            { "英文释义", "→ ~~    键" },
            { "日期插入", "→ ~d    键" },
            { "方案选单", "→ Ctrl + m" },
            { "方案快切", "→ Ctrl + ," },
            { "简繁转换", "→ Ctrl + [" },
            { "中译英文", "→ Ctrl + ]" },
            { "拆分隐显", "→ Ctrl + \\" },
            { "向下移动", "→ Ctrl + j" },
            { "向上移动", "→ Ctrl + k" },
            { "快符   ~", "→ Ctrl + '" },
            -- { "简繁转换", "→ Ctrl + u" },
            -- { "中译英文", "→ Ctrl + i" },
            -- { "拆分隐显", "→ Ctrl + o" },
            -- { "快符   _", "→ Ctrl + u" },
            -- { "快符   -", "→ Ctrl + i" },
            -- { "快符   =", "→ Ctrl + o" },
            -- { "快符   +", "→ Ctrl + p" },
            -- { "快符   ~", "→ ,.  并击" },
            -- { "快符   {", "→ ;'  并击" },
            -- { "快符   }", "→ ./  并击" },
            -- { "快符   |", "→ ;,  并击" },
            -- { "快符   &", "→ ;.  并击" },
            -- { "快符——", "→ ',  并击" },
            -- { "快符   +", "→ '.  并击" },
            -- { "快符   !", "→ ,/  并击" },
            -- { "快符脚本", "→ ……    " },
            -- { "项目地址", "→ " .. "loveminimal/rime-jk" },
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
