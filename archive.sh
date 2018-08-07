#!/bin/sh
chmod +x ./archive.sh
#在 xy位置输出字符串并换行
function xy ()
{
	_R=$1
	_C=$2
	_TEXT=$3
	tput  cup $_R $_C
	echo  $_TEXT
}

function colour ()
{
	case $1 in
		black_green)
			echo '\033[32m';;
		black_yellow)
			echo '\033[33m';;
		black_white)
			echo  '\033[37m';;
		black_cyan)
			echo  '\033[36m';;
		black_red)
			echo  '\033[31m';;
		colour_default)
			echo  '\033[0m';;
	esac
}
#清除格式
function clearprint () 
{
	echo "\033[0m"
}

function clear () 
{
	echo "\033[2J"	
}

#打印系统边框
function printsqure(){
	clear
	colour black_red 
	xy 3 12  "╔══════════════════════════════════════════════════════╗"
	for((x=4;x<=23;x++))
	do
		xy $x 12 "‖"
		xy $x 67 "‖"
	done
	xy 24 12 "╚══════════════════════════════════════════════════════╝"

}

#欢迎界面
function welcom(){
	printsqure
	xy 5 27 "\033[33;41m\033[1m❀《平安施工》快捷发布系统❀"
	clearprint
	colour black_red
	xy 8 33 "\033[1m选择发布方式 ：[ ]"
	colour black_green
	xy 10 32 "\033[1m1.app-store"
	xy 12 32 "\033[1m2.蒲公英"
	xy 14 32 "\033[1m3.Fir(测试环境)"
	xy 16 32 "\033[1m4.退出系统"
	xy 19 32 "version : 1.0.0"
	xy 21 25 "© Copyright Reserved :DKJone"
	xy 9 42 ""
    ##
    tput cup 8 49
}

#进入脚本所在文件夹并生成临时文件夹
cd `dirname $0 `
if [ ! -d ./IPADir ];
then
mkdir -p IPADir;
fi

# 服务器配置选项
host=ReleaseHost

#工程绝对路径
project_path=$(cd `dirname $0`; pwd)

#工程名 将XXX替换成自己的工程名
project_name=XXX

#scheme名 将XXX替换成自己的sheme名
scheme_name=XXX

#打包模式 Debug/Release
development_mode=Release

#build文件夹路径
build_path=${project_path}/build

#plist文件所在路径
exportOptionsPlistPath=${project_path}/exportTest.plist

#导出.ipa文件所在路径
exportIpaPath=${project_path}/IPADir/${development_mode}

welcom
read number
while([[ $number > 4 ]] || [[ $number < 1 ]])
do
	tput cup 8 49 
  	read number
done

if [ $number == 4 ];then
	clear
	exit 0 
elif [ $number == 1 ];then
	1
	development_mode=Release
	exportOptionsPlistPath=${project_path}/exportAppstore.plist
elif [ $number == 2 ];then
	host=ReleaseHost
	development_mode=Debug
	exportOptionsPlistPath=${project_path}/exportTest.plist
elif [ $number == 3 ];then
	host=DebugHost
	development_mode=Debug
	exportOptionsPlistPath=${project_path}/exportTest.plist
fi
clear

:<<EOF
echo '-----------------------------'
echo '| 正在修改配置文件 APIDefine.h |'
echo '-----------------------------'

sed -i '' '14c\
#define '${host}'\
' safeness/Common/APIDefine.h
EOF

echo '-----------------------------'
echo '|        正在清理工程		  |'
echo '-----------------------------'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit


echo '-----------------------------'
echo '|         清理完成	  |'
echo '-----------------------------'
echo ''

echo '-----------------------------'
echo '| 正在编译工程:'${development_mode}'|'
echo '-----------------------------'
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit

echo '-----------------------------'
echo '|		 编译完成		  |'
echo '-----------------------------'
echo ''

echo '-----------------------------'
echo '| 	开始ipa打包	    | '
echo '-----------------------------'
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo '-----------------------------'
echo '| 	ipa包已导出	  |'
echo '-----------------------------'
open $exportIpaPath
else
echo '-----------------------------'
echo '| 	ipa包导出失败	  |'
echo '-----------------------------'
fi
echo '-----------------------------'
echo '| 	打包ipa完成  	  |'
echo '-----------------------------'
echo ''

echo '-----------------------------'
echo '| 	开始发布ipa包 	 |'
echo '-----------------------------'

if [ $number == 1 ];then

#验证并上传到App Store
# 将-u 后面的XXX替换成自己的AppleID的账号，-p后面的XXX替换成自己的密码
	altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
	"$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u XXX -p XXX -t ios --output-format xml
	"$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u XXX -p XXX -t ios --output-format xml
elif [ $number == 2 ];then
# 上传IPA到蒲公英 将第208和209行  XXX换成你在蒲公英获取的`uKey` 和 `_api_key`
	echo '-----------------------------'
	echo '| 	上传IPA到蒲公英   |'
	echo '-----------------------------'
	curl -F "file=@"${exportIpaPath}"/"${scheme_name}.ipa \
	-F "uKey=XXX" \
	-F "_api_key=XXX" \
	https://www.pgyer.com/apiv2/app/upload
#	open https://www.pgyer.com
elif [ $number == 3 ];then
#上传到Fir  将第218行的XXX换成 你的fir的登录Token
	echo '-----------------------------'
	echo '| 	上传到fir   |'
	echo '-----------------------------'

	fir login -T XXX
	fir publish $exportIpaPath/$scheme_name.ipa
#	open http://fir.im

fi

exit 0
