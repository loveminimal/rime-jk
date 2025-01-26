--[[
single_char_filter: 候选项重排序，使单字优先
--]]

local function logg(text)
   log.warning(text)
end

local function filter(input)
   logg('--- 开始测试 FILTER ---')
   local l = {}
   for cand in input:iter() do

      -- 增强一下英文词典反查 将释义放在注释中---
      local cand_text = cand.text
      logg('cand.text >>> ' .. cand_text) 

      if string.find(cand_text, "^[😄]") then
            yield(cand)
            goto continue
         end

      -- 排除包含路径字符或命令符号的字符串 - 全部放候选
      -- 此类字符基本源自 en_aliases 的命令别名
      -- 如 cd ~/AppData/Roaming/Rime && source scripts/update-cn_dicts_wx.sh
      if string.find(cand_text, "^[%a%d%&%-%_%~%/%.%s%:%=%*]+$") then
      -- if true then
         -- yield(cand:get_genuine())
         yield(cand)
         goto continue
      end

      -- 正确格式输出英文词典 - 候选 + 释义注释
      -- local cand_text = "China n.    中国 adj. 中国的 中国制造的"
      -- local word, pos, meaning = string.match(cand_text, "(%a+)%s+(%a+%.%s*)(.+)")
      local word, pos, meaning = string.match(cand_text, "(%a+)%s+([%a&%.]+)%s*(.+)")

      if word then                
            -- log.warning("Word:" .. word)        -- 输出: Word: China
            -- log.warning("POS:" .. pos)          -- 输出: POS: n.    
            -- log.warning("Meaning:" .. meaning)  -- 输出: Meaning: 中国 adj. 中国的 中国制造的

            cand.text = word
            cand.comment = pos .. meaning

            local new_cand = Candidate(cand.type, cand.start, cand._end, word, cand.comment)
            yield(new_cand) -- 使用 yield 替换原始候选项
            -- yield(cand)
      end

      ::continue::
   end
   -- for i, cand in ipairs(l) do
   --    yield(cand)
   -- end
   logg('--- END ---')
end

return filter
