--[[
keep_one_level_simplified_code_filter: 保持五笔的一级简码排在最前
by Jack Liu <https://aituyaa.com>
--]] 


local one_level_simplified_code_char = '一地在要工上是中国同和的有人我主产不为这民了发以经'

local function filter(input)
    local l = {}
    for cand in input:iter() do
        if (utf8.len(cand.text) == 1 and string.match(one_level_simplified_code_char, cand.text)) then
            yield(cand)
        else
            table.insert(l, cand)
        end
    end
    for i, cand in ipairs(l) do
        yield(cand)
    end
end

return filter
