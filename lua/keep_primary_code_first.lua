--[[ 
keep_primary_code_first: 保持五笔 86 的一级简码对应的汉字在候选列表首位
by Jack Liu <https://aituyaa.com>
--]]

local primary_code_table = {
    ["g"] = "一", ["f"] = "地", ["d"] = "在", ["s"] = "要", ["a"] = "工",
    ["h"] = "上", ["j"] = "是", ["k"] = "中", ["l"] = "国", ["m"] = "同",
    ["t"] = "和", ["r"] = "的", ["e"] = "有", ["w"] = "人", ["q"] = "我",
    ["y"] = "主", ["u"] = "产", ["i"] = "不", ["o"] = "为", ["p"] = "这",
    ["n"] = "民", ["b"] = "了", ["v"] = "发", ["c"] = "以", ["x"] = "经"
}

-- 定义过滤器函数
function keep_primary_code_first(input, env)
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
return keep_primary_code_first
