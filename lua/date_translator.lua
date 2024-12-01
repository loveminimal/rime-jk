-- 精简自 rime-ice 的时间日期插件，如下：
-- https://github.com/iDvel/rime-ice/blob/main/lua/date_translator.lua
-- 日期时间

-- 提高权重的原因：因为在方案中设置了大于 1 的 initial_quality，导致 rq sj xq dt ts 产出的候选项在所有词语的最后。
local function yield_cand(seg, text)
    local cand = Candidate('', seg.start, seg._end, text, '')
    cand.quality = 100
    yield(cand)
end

local M = {}

function M.init(env)
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub('^*', '')
    M.jk_datetime = config:get_string(env.name_space .. '/jk_datetime') or 'iii'
end

function M.func(input, seg, env)
    -- JK 个性化时间日期插入（整合）
    if (input == M.jk_datetime) then
        local current_time = os.time()
        yield_cand(seg, os.date('%Y-%m-%d %H:%M', current_time))
        yield_cand(seg, os.date('%Y-%m-%d', current_time))
        yield_cand(seg, os.date('%H:%M', current_time))
        yield_cand(seg, os.date('`> %Y-%m-%d %H:%M`', current_time))
        local week_tab = {'日', '一', '二', '三', '四', '五', '六'}
        local text = week_tab[tonumber(os.date('%w', current_time) + 1)]
        yield_cand(seg, '星期' .. text)
    end
end

return M
