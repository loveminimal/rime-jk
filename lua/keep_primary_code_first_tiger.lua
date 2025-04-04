--[[ 
keep_primary_code_first: 保持虎码的一级简码对应的汉字在候选列表首位
by Jack Liu <https://aituyaa.com>
--]]

local primary_code_table = {
    ["q"] = "都", ["w"] = "得", ["e"] = "也", ["r"] = "了", ["t"] = "我", ["y"] = "到", ["u"] = "的", ["i"] = "为", ["o"] = "是", ["p"] = "行",
        ["a"] = "来", ["s"] = "说", ["d"] = "中", ["f"] = "一", ["g"] = "就", ["h"] = "道", ["j"] = "人", ["k"] = "能", ["l"] = "而", 
            ["z"] = "可", ["x"] = "和", ["c"] = "不", ["v"] = "要", ["b"] = "如", ["n"] = "在", ["m"] = "大"
}

-- 定义过滤器函数
function keep_primary_code_first_tiger(input, env)
    -- 获取用户输入的编码
    local input_code = env.engine.context.input
    -- 仅处理单字符输入
    if #input_code == 1 then
        -- 从一级简码表中获取对应字符
        local primary_char = primary_code_table[input_code]
        if primary_char then
            local new_candidates = {}
            local found = false
            local count = 0
            -- 遍历前 4 个候选项
            for cand in input:iter() do
                count = count + 1
                if cand.text == primary_char then
                    -- 若找到一级简码字符，将其置于新候选列表首位
                    table.insert(new_candidates, 1, cand)
                    found = true
                else
                    -- 其他候选词依次添加到新候选列表
                    table.insert(new_candidates, cand)
                end
                if count >= 4 then
                    break
                end
            end
            -- 若找到一级简码字符，输出新候选列表
            if found then
                for _, cand in ipairs(new_candidates) do
                    yield(cand)
                end
                return
            end
        end
    end
    -- 若未找到一级简码字符或输入非单字符，输出原始候选列表
    for cand in input:iter() do
        yield(cand)
    end
end

-- 导出过滤器函数
return keep_primary_code_first_tiger
