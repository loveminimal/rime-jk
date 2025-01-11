# update-cn_dicts.sh
# by Jack Liu <https://aituyaa.com>
# 用来同步转换最新的万象拼音词库为拼音+五笔前二辅助码词库
# 
CURRENT_DIR=$(pwd)
OUT_DICTS='cn_dicts'

cd D:/sourcecode/sc_rime/rime_wanxiang_pro
echo -e "\e[32m🔜 正在拉取万象拼音词库最近更新 »»»»»»»»»»»»»»»»»\e[0m"
git pull
echo -e "\e[42m✅  万象拼音词库已拉取最近更新                   \e[0m"

cd D:/sourcecode/sc_rime/rime-utils
echo -e "\e[32m🔜 正在转换为拼音+五笔前二词库  「 $OUT_DICTS 」\e[0m"
py scripts/wx2custom_8105_4_wx_dict.py
echo -e "\e[42m✅ 万象+五笔前二词库已转换完成  「 $OUT_DICTS 」\e[0m"

cd C:/Users/jack/AppData/Roaming/Rime
echo -e "\e[32m🔜 开始复制为万象+五笔前二词库  「 $OUT_DICTS 」\e[0m"
echo -e "正在复制 20% »»»»                          「 $OUT_DICTS 」"
echo -e "正在复制 63% »»»»»»»»»»»»»»»»              「 $OUT_DICTS 」"
echo -e "正在复制 99% »»»»»»»»»»»»»»»»»»»»»»»»»»»»»»「 $OUT_DICTS 」"
if [ -d "$OUT_DICTS" ]
then
    rm -rf $OUT_DICTS
fi
cp -r D:/sourcecode/sc_rime/rime-utils/dicts/rime-wx/$OUT_DICTS ./
cp -f py.dict.wx.yaml py.dict.yaml
echo -e "\e[42m✅ 万象+五笔前二词库已复制完成  「 $OUT_DICTS 」\e[0m"
# cd D:/sourcecode/sc_rime/rime-utils
cd $CURRENT_DIR