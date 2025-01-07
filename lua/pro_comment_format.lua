--@amzxyz https://github.com/amzxyz/rime_wanxiang_pinyin
--由于comment_format不管你的表达式怎么写，只能获得一类输出，导致的结果只能用于一个功能类别
--如果依赖lua_filter载入多个lua也只能实现一些单一的、不依赖原始注释的功能，有的时候不可避免的发生一些逻辑冲突
--所以此脚本专门为了协调各式需求，逻辑优化，实现参数自定义，功能可开关，相关的配置跟着方案文件走，如下所示：
--将如下相关位置完全暴露出来，注释掉其它相关参数--
--  comment_format: {comment}   #将注释以词典字符串形式完全暴露，通过pro_comment_format.lua完全接管。
--  spelling_hints: 10          # 将注释以词典字符串形式完全暴露，通过pro_comment_format.lua完全接管。
--在方案文件顶层置入如下设置--
--#Lua 配置: 超级注释模块
--pro_comment_format:                   # 超级注释，子项配置 true 开启，false 关闭
--  fuzhu_code: true                    # 启用辅助码提醒，用于辅助输入练习辅助码，成熟后可关闭
--  candidate_length: 3                 # 候选词辅助码提醒的生效长度，0为关闭  但同时清空其它，应当使用上面开关来处理    
--  fuzhu_type: zrm                     # 用于匹配对应的辅助码注释显示，可选显示类型有：moqi, flypy, zrm, jdh, cj, tiger, wubi,选择一个填入，应与上面辅助码类型一致


-- #########################
-- # 辅助码提示模块 (Fuzhu)
-- #########################

local FZ = {}


function FZ.run(cand, env, initial_comment)
    local length = utf8.len(cand.text)
    local final_comment = nil

    -- 确保候选词长度检查使用从配置中读取的值
    if env.settings.fuzhu_code_enabled and length <= env.settings.candidate_length then
        local fuzhu_comments = {}

        -- 先用空格将注释分成多个片段
        local segments = {}
        for segment in initial_comment:gmatch("[^%s]+") do
            table.insert(segments, segment)
        end

        -- 定义 fuzhu_type 与匹配模式的映射表
        local patterns = {
            
            en = "[^a-z]*$)",
            wubi = "[^a-z]*$)",  -- 匹配原生五笔码表
            flypy = "[^;]*;([^;]*);",
            -- moqi = "[^;]*;([^;]*);",
            -- flypy = "[^;]*;[^;]*;([^;]*);",
            -- zrm = "[^;]*;[^;]*;[^;]*;([^;]*);",
            -- jdh = "[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
            -- cj = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
            -- tiger = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
            -- wubi = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
            -- hx    = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);"
        }

        -- 获取当前 fuzhu_type 对应的模式
        local pattern = patterns[env.settings.fuzhu_type]

        if pattern then
            -- 提取匹配内容
            for _, segment in ipairs(segments) do
                local match = segment:match(pattern)
                if match then
                    table.insert(fuzhu_comments, match)
                end
            end
        else
            -- 如果类型不匹配，返回空字符串
            return ""
        end

        -- 将提取的拼音片段用空格连接起来
        if #fuzhu_comments > 0 then
            final_comment = table.concat(fuzhu_comments, "/")
        end
    else
        -- 如果候选词长度超过指定值，返回空字符串
        final_comment = ""
    end

    return final_comment or ""  -- 确保返回最终值
end
-- #########################
-- 主函数：根据优先级处理候选词的注释
-- #########################
local C = {}
function C.init(env)
    local config = env.engine.schema.config

    if (config:get_map("pro_comment_format") ~= nil) then
        -- 获取 pro_comment_format 配置项
        env.settings = {
            corrector_enabled = config:get_bool("pro_comment_format/corrector") or false,  -- 错音错词提醒功能
            corrector_type = config:get_string("pro_comment_format/corrector_type") or "{comment}",  -- 提示类型
            fuzhu_code_enabled = config:get_bool("pro_comment_format/fuzhu_code") or false,  -- 辅助码提醒功能
            candidate_length = tonumber(config:get_string("pro_comment_format/candidate_length")) or 1,  -- 候选词长度
            fuzhu_type = config:get_string("pro_comment_format/fuzhu_type") or ""  -- 辅助码类型
        }
    else
        log.info("env.settings = nil")
        env.settings = nil
    end
    
end 
function C.func(input, env)
    -- 调用全局初始共享环境
    C.init(env)

    local processed_candidates = {}  -- 用于存储处理后的候选词
    local deal_count = 1
    if (env.settings == nil) then
        for cand in input:iter() do
            yield(cand)
        end
    else
        -- 遍历输入的候选词
        for cand in input:iter() do
            if cand.type == 'completion' then
                yield(cand)
                goto continue
            end
            deal_count = deal_count + 1
            -- log.info(cand.type)
            -- log.info(cand.text)
            local initial_comment = cand.comment  -- 保存候选词的初始注释
            local final_comment = initial_comment  -- 初始化最终注释为初始注释
            -- 处理辅助码提示
            if env.settings.fuzhu_code_enabled then
                local fz_comment = FZ.run(cand, env, initial_comment)
                if fz_comment then
                    final_comment = fz_comment
                end
            else
                -- 如果辅助码显示被关闭，则清空注释
                final_comment = ""
            end

            -- 更新最终注释
            if final_comment ~= initial_comment then
                cand:get_genuine().comment = final_comment
            end
            
            yield(cand)
            ::continue::
        end

        -- 输出处理后的候选词
        -- for _, cand in ipairs(processed_candidates) do
        --     yield(cand)
        -- end
    end
end
return {
    FZ = FZ,
    C = C,
    func = C.func
}
