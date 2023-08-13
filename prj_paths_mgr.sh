#! /bin/bash

# binary="./cmake-build-debug/PathsMgr_run"
PATHS_MGR_BIN=${DEBUG_PATHS_MGR_BIN:-PathsMgr_run}

function url_decode() {
	: "${*//+/ }"
	echo -e "${_//%/\\x}"
}

function select_menu() {
	echo "遇到相同的名字，请选择一个路径："
	select item; do
		if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ]; then
			echo "切换路径到：""$item"
			cd $item
			break
		else
			echo "请输入数字 1-$#"
		fi
	done
}

function change_dir() {
    # 获取程序的输出内容
	strFromBinary=$($PATHS_MGR_BIN $1)
	if [ $? -ne 0 ]; then
		echo "切换路径出现错误，请检查参数是否正确"
	else
	    # 从strFromBinary解析目录path
		strFromBinary=${strFromBinary##*;}
		path=$(url_decode $strFromBinary)

		echo "切换路径到："$path
		cd $path
	fi
}

function change_dir_by_cd() {
    local dir_name str_from_binary
	dir_name=$1
	str_from_binary=$($PATHS_MGR_BIN "cd" "$dir_name")

	if [ $? -ne 0 ]; then
		echo "切换路径出现错误，请检查参数是否正确"
	else
		str_from_binary=${str_from_binary##*;}
		IFS=$':' read -r -a array <<<"$str_from_binary"

		for ((i = 0; i < ${#array[@]}; i++)); do
			array[i]=$(url_decode ${array[i]})
		done

		if [ ${#array[@]} -eq 1 ]; then
			echo "切换路径到："${array[0]}
			cd ${array[0]}
		else
			select_menu ${array[@]}
		fi
	fi
}

function paths_mgr() {
    if [[ ${DEBUG_PATHS_MGR_BIN} && ${DEBUG_PATHS_MGR_BIN-x} ]]; then
        echo "bin path:"$DEBUG_PATHS_MGR_BIN
    fi

	if [[ $1 =~ ^[0-9]+$ && $# == 1 ]]; then
		change_dir $1
	elif [[ $1 == "cd" && $# == 2 ]]; then
		change_dir_by_cd $2
	else
		# 把所有参数再传递下去，$(echo $*)奇怪的写法
		$PATHS_MGR_BIN $(echo $*)
	fi
}

# todo 有没有别的办法对二级命令做补全判断的
function paths_mgr_completions() {
	# echo " comp words count:" ${#COMP_WORDS[@]} " comp cword:" $COMP_CWORD
	oldIfs=$IFS
	prefixStr=${COMP_WORDS[COMP_CWORD]}
	if [[ ${#COMP_WORDS[@]} == 2 ]]; then
		strFromBinary=$($PATHS_MGR_BIN "subcommands")
		if [ $? -ne 0 ]; then
			echo $strFromBinary
			echo "切换路径出现错误，请检查参数是否正确"
		else
			strFromBinary=${strFromBinary##*;}
			IFS=$':' read -r -a array <<<"$strFromBinary"
			for ((i = 0; i < ${#array[@]}; i++)); do
				if [[ "${array[i]}" =~ ^${prefixStr}.* ]]; then
					COMPREPLY+=(${array[i]})
				fi
			done
		fi
	elif [[ ${#COMP_WORDS[@]} == 3 ]]; then
		subCommand=${COMP_WORDS[1]}
		prefixStr=${COMP_WORDS[COMP_CWORD]}

		if [[ $subCommand == "cd" ]]; then
			strFromBinary=$($PATHS_MGR_BIN "predict" "$prefixStr")
			if [ $? -ne 0 ]; then
				echo $strFromBinary
				echo "切换路径出现错误，请检查参数是否正确"
			else
				strFromBinary=${strFromBinary##*;}
				IFS=$':' read -r -a array <<<"$strFromBinary"

				for ((i = 0; i < ${#array[@]}; i++)); do
					array[i]=$(url_decode ${array[i]})
					COMPREPLY+=(${array[i]})
				done
			fi
		fi
	fi
	IFS=$oldIfs
}

alias pa="paths_mgr"

complete -F paths_mgr_completions pa
