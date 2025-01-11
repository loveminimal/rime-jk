# update-cn_dicts.sh
# by Jack Liu <https://aituyaa.com>
# 用来同步转换最新的白霜拼音词库为小鹤双拼+五笔前二词库
# 
CURRENT_DIR=$(pwd)
OUT_DICTS='cn_dicts'

cd D:/sourcecode/sc_rime/rime-frost
echo -e "\e[32m🔜 正在拉取白霜拼音词库最近更新 »»»»»»»»»»»»»»»»\e[0m"
git pull
echo -e "\e[42m✅ 白霜拼音词库已拉取最近更新                   \e[0m"

cd D:/sourcecode/sc_rime/rime-utils
echo -e "\e[32m🔜 正在转换为白霜万象词库      「 cn_dicts_wx 」\e[0m"
py scripts/py2wx_8105.py
echo -e "\e[42m✅ 白霜万象词库已转换成功      「 cn_dicts_wx 」\e[0m"

echo -e "\e[32m🔜 正在转换为白霜万象五笔词库  「 $OUT_DICTS 」 \e[0m"
py scripts/wx2custom_8105.py
echo -e "\e[42m✅ 白霜万象鹤形词库已转换完成  「 $OUT_DICTS 」 \e[0m"

cd C:/Users/jack/AppData/Roaming/Rime
echo -e "\e[32m🔜 开始复制为白霜万象五笔词库  「 $OUT_DICTS 」 \e[0m"
echo -e "正在复制 20% »»»»                          「 $OUT_DICTS 」"
echo -e "正在复制 63% »»»»»»»»»»»»»»»»              「 $OUT_DICTS 」"
echo -e "正在复制 99% »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»「 $OUT_DICTS 」"
if [ -d "$OUT_DICTS" ]
then
    rm -rf $OUT_DICTS
fi
cp -r D:/sourcecode/sc_rime/rime-utils/dicts/rime-frost/$OUT_DICTS ./
cp -f py.dict.frost.yaml py.dict.yaml
echo -e "\e[42m✅ 白霜万象鹤形词库已复制完成  「 $OUT_DICTS 」\e[0m"

# cd D:/sourcecode/sc_rime/rime-utils
cd $CURRENT_DIR