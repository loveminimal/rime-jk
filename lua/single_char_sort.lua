--[[ 
    - 单字重排：单字在先？or 单字居后！
    - 此处限制单字编码长度大于 3 时才激活重排，避免一、二、三简单字被排在后面
    - by Jack Liu <https://aituyaa.com>
--]]

local is_front = true

local function create_filter(is_front)
    return function(input, env)
        local s_table = {} -- 单字存储表
        local m_table = {} -- 多字存储表

        local input_code = env.engine.context.input
        local code_len = #input_code

        for cand in input:iter() do
            -- 
            if (#input_code > 3 and utf8.len(cand.text) == 1) then
                table.insert(s_table, cand)
            else
                table.insert(m_table, cand)
            end
        end

        local _cands = {}
        if is_front then
            -- 单字排在前面
            _cands = s_table
            for i = 1, #m_table do
                _cands[#s_table + 1] = m_table[i]
            end
        else
            -- 单字排在后面
            _cands = m_table
            for i = 1, #s_table do
                _cands[#m_table + 1] = s_table[i]
            end
        end

        -- 输出重新排序后的候选
        for i, cand in ipairs(_cands) do
            yield(cand)
        end
    end
end

local F = { func = create_filter(true) }
local E = { func = create_filter(false)}

return {
    F = F,
    E = E,
    func = E.func
}
