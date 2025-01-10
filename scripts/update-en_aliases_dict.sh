cd ~/.shell
echo -e "\e[32m🔜 正在拉取脚本最近更新           「 ~/.shell 」\e[0m"
git pull
echo -e "\e[42m✅ 已拉取最近更新                               \e[0m"

cd D:/sourcecode/sc_rime/rime-utils
cp ~/.shell/.bash_aliases dicts/en_dicts/
echo -e "\e[32m🔜 正在转换别名脚本为别名词库   「 en_aliases 」\e[0m"
py scripts/bash_alias2en_aliases_dict.py
echo -e "\e[42m✅ 别名词库已转换成功           「 en_aliases 」\e[0m"


cd C:/Users/jack/AppData/Roaming/Rime
if [ -f "dicts/en_aliases.dict.yaml" ]
then
    rm dicts/en_aliases.dict.yaml
fi
cp D:/sourcecode/sc_rime/rime-utils/out/en_aliases.dict.yaml ./dicts/
echo -e "\e[42m✅ 别名词库已更新完成           「 en_aliases 」\e[0m"

# cd D:/sourcecode/sc_rime/rime-utils
