--- by wubi86_jidian_single_char_first_filter.lua
--- modified by Jack Liu <https://aituyaa.com>
--- 过滤器：单字在先
local function single_char_first(input)
    local l = {}
    for cand in input:iter() do
        if (utf8.len(cand.text) == 1) then
            yield(cand)
        else
            table.insert(l, cand)
        end
    end
    for i, cand in ipairs(l) do
        yield(cand)
    end
end

return single_char_first
