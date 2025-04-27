-- === 日程表小助手 ===
-- Modified by ksqsf for Project Moran
-- AMZ 万象新增节日候选,格式化问候语,重写农历倒计时
-- Simplified by Jack Liu <https://aituyaa.com>
-- 生成日程表候选，如：
--[[
    嗨，我是您的日程小助手，晚上好!  
    ---------------------------------------
    今天：2025年03月06日 星期四  
    农历：乙巳年(蛇) 二月初七    
    时间：19点31分42秒  
    ---------------------------------------
    2025  年进度：▒▒▒▒░░░░░░░░░░░░░ 17.8%  
    距离 2026 年：还有 300 天  
    ---------------------------------------
    今天是 2025 年的第 10 周，3 月的第 1 周  
    今年已度过 64 天，今天是第 65 天  
    ---------------------------------------
    距离: 妇女节 2025-03-08 	 < [ 02 ]天  
    距离: 植树节 2025-03-12 	 < [ 06 ]天  
    ---------------------------------------
    距离: 春分 2025-03-20 	     < [ 14 ]天  
    距离: 清明 2025-04-04 	     < [ 29 ]天  
    ---------------------------------------
]]--

require("lunar_lib")

-- +++ 主函数 +++
local function schedule(input, seg, env)
    local engine = env.engine
    local context = engine.context

    if (input == "~jc") then

        -- ---〔 ❶ 问候语 〕---
        local function get_greeting()
            local current_hour = tonumber(os.date("%H"))
            local greeting = ""

            if current_hour >= 0 and current_hour < 6 then
                greeting = "晚安!"
            elseif current_hour >= 6 and current_hour < 12 then
                greeting = "早上好!"
            elseif current_hour >= 12 and current_hour < 14 then
                greeting = "午安!"
            elseif current_hour >= 14 and current_hour < 18 then
                greeting = "下午好!"
            else
                greeting = "晚上好!"
            end

            return greeting
        end
        local greeting = get_greeting()


        -- ---〔 ❷ 获取当前时间 〕---
        -- 今天
        local now = os.time()
        local year = tonumber(os.date("%Y", now))
        local month = tonumber(os.date("%m", now))
        local day = tonumber(os.date("%d", now))
        local week_day_str = chinese_weekday2(os.date("%w"))                -- 获取中文星期（例如 "星期三"）
        -- 农历
        local lunar_info_str = Date2LunarDate(os.date("%Y%m%d"))            -- 获取农历的天干地支和生肖等
        -- 时间 ... 


        -- ---〔 ❸ 时间进度 〕---
        local day_of_year = tonumber(os.date("%j", now))                    -- 今年的第几天
        local days_in_year = IsLeap(year)                                   -- 若为闰年 - 366
        local year_progress = (day_of_year / days_in_year) * 100            -- 今年进度

        -- 模拟四舍五入
        local function round(x)
            if x - math.floor(x) < 0.5 then
                return math.floor(x)
            else
                return math.ceil(x)
            end
        end

        -- 进度条格式化
        local function generate_progress_bar(percentage)
            local filled_blocks = round(percentage / 10)
            local empty_blocks = 10 - filled_blocks
            return string.rep("▒", filled_blocks) .. string.rep("░", empty_blocks) ..
                       string.format(" %.1f%%", percentage)
        end
        local progress_bar = generate_progress_bar(year_progress)


        -- ---〔 ❹ 周天倒计时 〕---
        -- 倒计周
        local week_of_year = tonumber(os.date("%W", now)) + 1               -- 今年的第几周
        local week_of_month = math.ceil(tonumber(os.date("%d", now)) / 7)   -- 当月的第几周
        -- 计算距离下一年1月1日的天数
        local next_year = year + 1
        local new_year_time = os.time({
            year = next_year,
            month = 1,
            day = 1
        })
        local diff_days_next_year = math.floor((new_year_time - now) / (24 * 3600))


        -- ---〔 ❺ 节日倒计时 〕---
        -- --- 遍历前三个节日并返回节日名称、日期、倒计时天数 ---
        local upcoming_holidays = get_upcoming_holidays() or {}
        local holiday_data = {}

        local filtered_holidays = {}
        -- 当今天就是节日时
        local zero_holiday = '' 
        local zero_found = false

        for i = 1, math.min(3, #upcoming_holidays) do
            local holiday = upcoming_holidays[i]

            if holiday[3] == 0 then
                -- 记录当天的节日名称
                zero_holiday = holiday[1] 
                zero_found = true
            else
                table.insert(filtered_holidays, holiday)
            end
        end

        if zero_found then
            -- 当今天是节日时，顺排存储后两个节日
            for i = math.max(1, #filtered_holidays - 1), #filtered_holidays do
                local holiday = filtered_holidays[i]
                local year, month, day = holiday[2]:match("^(%d+)年(%d+)月(%d+)日")

                if year and month and day then
                    local formatted_date = string.format("%04d-%02d-%02d", tonumber(year), tonumber(month),
                        tonumber(day))
                    table.insert(holiday_data, {holiday[1], formatted_date, holiday[3]})
                end
            end
        else
            -- 今天不是节日时，存储前两个节日
            for i = 1, math.min(2, #filtered_holidays) do
                local holiday = filtered_holidays[i]
                local year, month, day = holiday[2]:match("^(%d+)年(%d+)月(%d+)日")

                if year and month and day then
                    local formatted_date = string.format("%04d-%02d-%02d", tonumber(year), tonumber(month),
                        tonumber(day))
                    table.insert(holiday_data, {holiday[1], formatted_date, holiday[3]})
                end
            end
        end


        -- ---〔 ❻ 节气倒计时 〕---
        -- --- 获取最近的三个节气 ---
        local jqs = GetNowTimeJq(os.date("%Y%m%d", now))
        local upcoming_jqs = {}
        local zero_jieqi = ''                                               -- 记录今天的节气

        -- 计算距离某个节气的天数
        local function days_until_jieqi(jieqi)
            local jieqi_date = jieqi:match("(%d+-%d+-%d+)$")                -- 提取节气日期部分
            local target_time = jieqi_date:gsub("-", "")
			local diff_days = days_until(target_time)

            return diff_days
        end

        -- 遍历最近的 4 个节气
        for i = 1, math.min(3, #jqs) do
            local jieqi = jqs[i]
            local diff_days = days_until_jieqi(jieqi)

            if diff_days < 0 then
                zero_jieqi = ' '
            elseif diff_days == 0 then
                -- 记录今天的节气
                zero_jieqi = jieqi:match("^(%S+)")
            elseif diff_days > 0 then
                table.insert(upcoming_jqs, jieqi)
            end
        end

        -- if zero_jieqi and zero_jieqi ~= '' then
        -- -- if zero_jieqi then
        --     -- 今天是节气时，取后两个节气
        --     upcoming_jqs = {jqs[3], jqs[4]}
        -- else
        --     -- 今天不是节气，取前两个节气
        --     upcoming_jqs = {jqs[2], jqs[3]}
        -- end

        -- 获取每个节气的距离天数
        local jieqi_days = {}
        for _, jieqi in ipairs(upcoming_jqs) do
            table.insert(jieqi_days, days_until_jieqi(jieqi))
        end
        

        -- --- 生成自定义长度的符号线 ---
        local function generate_line(length)
            -- return string.rep("—", length)
            return string.rep("--", length)
        end
        -- 控制符号线的宽度为 15
        local line = generate_line(29) 


        -- ---〔 ⓿ 信息串 〕--- 
        -- --- 生成最终信息字符串 ---
        local summary = 
            string.format("\n嗨，我是您的日程小助手，%s  \n", greeting) .. 
            line .. "  \n" ..
            string.format("今天：%d年%02d月%02d日 %s  \n", year, month, day, week_day_str) ..
            string.format("农历：%s %s %s  \n", lunar_info_str, zero_jieqi, zero_holiday) ..
            string.format("时间：%s  \n", os.date('%H点%M分%S秒', now)) .. 
            line .. "  \n" ..
            string.format("%d  年进度：%s  \n", year, progress_bar) ..
            string.format("距离 %d 年：还有 %d 天  \n", next_year, diff_days_next_year) .. 
            line .. "  \n" ..
            string.format("今天是 %d 年的第 %d 周，%d 月的第 %d 周  \n", year, week_of_year, month, week_of_month) ..
            string.format("今年已度过 %d 天，今天是第 %d 天  \n", day_of_year - 1, day_of_year) .. 
            line .. "  \n" ..
            string.format("距离: %s %s \t< [ %02d ]天  \n", holiday_data[1][1], holiday_data[1][2], holiday_data[1][3]) ..
            string.format("距离: %s %s \t< [ %02d ]天  \n", holiday_data[2][1], holiday_data[2][2], holiday_data[2][3]) .. 
            line .. "  \n" ..
            string.format("距离: %s \t< [ %02d ]天  \n", upcoming_jqs[1], jieqi_days[1]) ..
            string.format("距离: %s \t< [ %02d ]天  \n", upcoming_jqs[2], jieqi_days[2]) .. 
            line .. "  \n" ..
            "将喜欢的一切留在身边，这便是努力的意义！ \n" .. 
            ''

        -- 使用 generate_candidates 函数生成候选项
        local candidates = { 
            -- {summary, "日期信息整合"}
            {summary, ""}
        }

        generate_candidates("day_summary", seg, candidates)
    end
end

return schedule
