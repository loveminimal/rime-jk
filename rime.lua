-- Rime Lua 扩展 https://github.com/hchunhui/librime-lua
-- 文档 https://github.com/hchunhui/librime-lua/wiki/Scripting

-- translators:

-- 日期时间，可在方案中配置触发关键字。
date_translator = require("date_translator")

-- 暴力 GC
-- 详情 https://github.com/hchunhui/librime-lua/issues/307
-- 这样也不会导致卡顿，那就每次都调用一下吧，内存稳稳的
function force_gc()
    -- collectgarbage()
    collectgarbage("step")
end
