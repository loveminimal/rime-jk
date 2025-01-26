local function yield_cand(seg, text)
    local cand = Candidate('', seg.start, seg._end, text, 'from_test')
    cand.quality = 100
    yield(cand)
end


local function test(input, seg, env)
    -- JK 个性化时间日期插入（整合）
    if (input == 'ttt') then
        local current_time = os.time()
        yield_cand(seg, os.date('%Y-%m-%d %H:%M', current_time))
        yield_cand(seg, '翻译器')
        yield_cand(seg, 'test translator')
    end
end

return test
