cd D:/sourcecode/sc_rime/rime-frost
echo -e "\e[32m🔜 正在拉取白霜拼音词库最近更新 »»»»»»»»»»»»»»»»\e[0m"
git pull
echo -e "\e[42m✅ 白霜拼音词库已拉取最近更新                   \e[0m"

cd D:/sourcecode/sc_rime/rime-utils
echo -e "\e[32m🔜 正在转换为白霜万象词库      「 cn_dicts_wx 」\e[0m"
py scripts/py2wx_8105.py
echo -e "\e[42m✅ 白霜万象词库已转换成功      「 cn_dicts_wx 」\e[0m"

echo -e "\e[32m🔜 正在转换为白霜万象鹤形词库  「 flypy_dicts 」\e[0m"
py scripts/wx2custom_8105.py
echo -e "\e[42m✅ 白霜万象鹤形词库已转换完成  「 flypy_dicts 」\e[0m"

cd C:/Users/jack/AppData/Roaming/Rime
echo -e "\e[32m🔜 开始复制为白霜万象鹤形词库  「 flypy_dicts 」\e[0m"
echo -e "\e[32m正在复制 20% »»»»               「 flypy_dicts 」\e[0m"
echo -e "\e[32m正在复制 63% »»»»»»»»»»         「 flypy_dicts 」\e[0m"
echo -e "\e[32m正在复制 99% »»»»»»»»»»»»»»»»»»»「 flypy_dicts 」\e[0m"
if [ -d "flypy_dicts" ]
then
    rm -rf flypy_dicts
fi
cp -r D:/sourcecode/sc_rime/rime-utils/dicts/rime-frost/flypy_dicts ./
echo -e "\e[42m✅ 白霜万象鹤形词库已复制完成  「 flypy_dicts 」\e[0m"

# cd D:/sourcecode/sc_rime/rime-utils
