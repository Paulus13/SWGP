#!/bin/bash

# https://github.com/database64128/swgp-go

red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
plain='\033[0m'

git_checkout_last_tag=1

function initialCheck() {
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
else
	echo "This script for Ubuntu 18.04 or higher. For other OS use other script or edit this according needed OS"
	exit
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
	echo -e "${red}Ubuntu 18.04 or higher is required to use this installer.${plain}"
	echo -e "${red}This version of Ubuntu is too old and unsupported.${plain}"
	exit
fi
}

function checkNeededSoft() {
bc_ver=$(bc --version 2>/dev/null)
wget_ver=$(wget --version 2>/dev/null)
tar_ver=$(tar --version 2>/dev/null)
git_ver=$(git --version 2>/dev/null)
curl_ver=$(curl --version 2>/dev/null)

if [[ -z $bc_ver || -z $wget_ver || -z $tar_ver || -z $git_ver || -z $curl_ver ]]; then
	apt update
	apt install -y bc wget tar git curl
fi
}

function checkBinInstalled {
if [ -f /usr/bin/swgp-go ]; then
	echo
	read -p  "File /usr/bin/swgp-go already exists. Replace it? [y/N]: " replace_bin
	if [ -z $replace_bin ]
	then
		 replace_bin='N'
	fi

	until [[ "$replace_bin" =~ ^[yYnN]*$ ]]; do
		echo "$replace_bin: invalid selection."
		read -p "Replace bin file? [y/n]: " replace_bin
	done
else
	replace_bin='Y'
fi
}

function checkBinInstalled2 {
if [ -f /usr/bin/swgp-go ]; then
	bin_inst=1
else
	bin_inst=0
fi
}

function checkGoInstalled() {
go_installed=$(go version 2>/dev/null)
if [[ -z $go_installed ]]; then
	go_installed=0
	echo
	echo -e "${green}Go not installed${plain}"
else
	go_installed=1
	go_inst_ver=$(go version | awk '{print $3}' | sed 's/^go//')
	trunkGoVersion $go_inst_ver
	go_inst_ver_trank=$trunk_go_ver
	echo
	echo -e "${green}Go installed, version $go_inst_ver${plain}"
fi
}

function trunkGoVersion() {
t_go_ver=$1
dot_num=$(echo $t_go_ver | tr -cd '.' | wc -c)
if [ $dot_num -gt 1 ]; then
	go_ver_1=$(echo $t_go_ver |  awk -F. '{print $1}')
	go_ver_2=$(echo $t_go_ver |  awk -F. '{print $2}')
	go_ver_3=$(echo $t_go_ver |  awk -F. '{print $3}')
	trunk_go_ver="${go_ver_1}.${go_ver_2}${go_ver_3}"
else
	trunk_go_ver=$t_go_ver
fi
}

function compareGoVer() {

bc_installed=$(bc -v 2>/dev/null)
git_installed=$(git --version 2>/dev/null)

if [[ -z $bc_installed || -z $git_installed ]]; then
	apt update
	apt install -y bc wget tar git curl
fi

go_need_ver=$(curl -s "https://raw.githubusercontent.com/database64128/swgp-go/main/go.mod" | grep "go [1-9]." | awk '{print $2}')
go_ver=$1

trunkGoVersion $go_ver
go_ver_trunk=$trunk_go_ver

trunkGoVersion $go_need_ver
go_need_ver_trunk=$trunk_go_ver

if [ 1 -eq "$(echo "${go_ver_trunk} < ${go_need_ver_trunk}" | bc)" ]
then  
	ver_enough=0
else
	ver_enough=1
fi	
}

function getGoLang {
checkGoInstalled

if [ $go_installed -eq 1 ]; then
	compareGoVer $go_inst_ver
	if [ $ver_enough -eq 1 ]; then
		echo -e "${green}Installed Go ver. $go_inst_ver is enough${plain}"
		read -p  "Update it to the latest? [y/N]: " update_go
		if [ -z $update_go ]
		then
			 update_go='N'
		fi

		until [[ "$update_go" =~ ^[yYnN]*$ ]]; do
			echo "$update_go: invalid selection."
			read -p "Update Go vesion? [y/n]: " update_go
		done

		if [[ "$update_go" =~ ^[nN]*$ ]]; then
			return
		fi
	else
		echo -e "${green}Installed Go ver. $go_inst_ver is not enough${plain}"
		read -p  "Update it to the latest? [Y/n]: " update_go
		if [ -z $update_go ]
		then
			 update_go='Y'
		fi

		until [[ "$update_go" =~ ^[yYnN]*$ ]]; do
			echo "$update_go: invalid selection."
			read -p "Update Go vesion? [y/n]: " update_go
		done

		if [[ "$update_go" =~ ^[nN]*$ ]]; then
			return
		fi		
		
		echo
		echo -e "${green}Updating it to the latest version${plain}"
	fi
else
	read -p  "Install GoLang? [Y/n]: " inst_go
	if [ -z $inst_go ]
	then
		 inst_go='Y'
	fi

	until [[ "$inst_go" =~ ^[yYnN]*$ ]]; do
		echo "$inst_go: invalid selection."
		read -p "Install GoLang? [y/n]: " inst_go
	done

	if [[ "$inst_go" =~ ^[nN]*$ ]]; then
		echo
		echo -e "${red}GoLang not installed${plain}"
		return
	fi	
fi

checkArchType
case "$arch_type" in
	"x86-64") 
	os_part="amd64"
	;;
	"arm64") 
	os_part="arm64"
	;;
	"arm") 
	os_part="armv6l"
	;;	
	*)
	echo
	echo -e "${red}Unknown architecture${plain}"
	echo -e "${red}GoLang not installed${plain}"
	exit
esac

if [ -d /usr/local/go ]; then
	rm -rf /usr/local/go
fi

dl_url1="https://go.dev"
# dl_url2=$(curl -s "https://go.dev/dl/" | grep linux | grep $os_part | grep download | head -n1 | awk '{print $4}' | cut -d '=' -f 2 | sed 's/.$//' | sed 's/.$//' | sed 's/^.//')
dl_url2=$(curl -s "https://go.dev/dl/" | grep linux | grep $os_part | grep download | head -n1 | awk '{print $4}' | cut -d '=' -f 2 | cut -d '>' -f 1 | sed 's/"//g')

dl_url="${dl_url1}${dl_url2}"

wget -O go.tar.gz $dl_url

tar -zxf go.tar.gz -C /usr/local/
rm go.tar.gz
go_path_prof=$(grep "/usr/local/go/bin" $HOME/.profile)

if [[ -z $go_path_prof ]]; then
	echo "export PATH=/usr/local/go/bin:\$PATH" | sudo tee -a $HOME/.profile
	source $HOME/.profile
	
	echo
	echo -e "${green}Please run this command:"
	echo -e "source $HOME/.profile"
	echo -e "for apply PATH variable in current shell session${plain}"
fi
}

function checkArchType() {
arch_type=$(hostnamectl status | grep -i architecture | awk '{print $2}')
}

function compileSWGP {
checkBinInstalled
if [[ "$replace_bin" =~ ^[nN]*$ ]]; then
	echo
	echo "${red}Compile Aborted${plain}"
	return
fi
	
checkGoInstalled
if [ $go_installed -eq 0 ]; then
	echo -e "${green}Install GoLang before compile SWGP.${plain}"
	echo
	return
fi

if [ -d swgp-go ]; then
	cd swgp-go
	rm ./swgp-go
	git pull
else
	git clone https://github.com/database64128/swgp-go.git
	cd swgp-go
fi

if [[ $git_checkout_last_tag -eq 1 ]]; then
	last_tag=$(git tag | tail -n 1)
	git checkout $last_tag
	echo
	echo -e "${green}Now we are here:${plain}"
	echo
	git log --max-count=1
	echo
fi

export CGO_ENABLED=0 
go build -o swgp-go cmd/swgp-go/main.go

if [ -f /lib/systemd/system/swgp-go.service ]; then
	systemctl stop swgp-go.service
	cp swgp-go /usr/bin
	systemctl start swgp-go.service
else
	cp swgp-go /usr/bin
fi

cd ..
}

function compileMenu {
	latest_go_ver=$(curl -s "https://go.dev/dl/" | grep -A 5 'Stable versions' | grep toggleVisible | awk '{print $3}' | cut -d '"' -f 2 | sed 's/^go//')
	go_ver=$(go version 2>/dev/null)
	if [[ -z $go_ver ]]; then
		go_inst=0
		inst_menu="${green}   1) Install Go binary${plain}"
	else
		go_inst=1
		go_inst_ver=$(go version | awk '{print $3}' | sed 's/^go//')
		
		if [ $go_inst_ver == $latest_go_ver ]; then
			inst_menu="${yellow}   1) Update Go binary (latest version installed - $go_inst_ver)${plain}"
		else
			inst_menu="${green}   1) Update Go binary $go_inst_ver > $latest_go_ver${plain}"
		fi		
	fi
	
	checkBinInstalled2	
	if [ $bin_inst -eq 1 ]; then
		comp_menu="${yellow}   2) Compile SWGP binary using GoLang (file exist /usr/bin/swgp-go)${plain}"
	else
		comp_menu="${green}   2) Compile SWGP binary using GoLang${plain}"
	fi
	
	exit_menu="${green}   3) Exit${plain}"
	
	echo
	echo -e "${green}Compiling SWGP${plain}"
	echo
	echo -e "${green}What do you want to do?${plain}"
	echo -e $inst_menu	
	echo -e $comp_menu
	echo -e $exit_menu
	until [[ $MENU_OPTION =~ ^[1-3]$ ]]; do
		read -rp "Select an option [1-3]: " MENU_OPTION
	done

	case $MENU_OPTION in
	1)
		getGoLang
		MENU_OPTION=0
		compileMenu
		;;	
	2)
		# getGoLang
		compileSWGP
		MENU_OPTION=0
		compileMenu
		;;
	3|"")
		MENU_OPTION=0
		exit
		;;
	esac
}

initialCheck
checkNeededSoft
compileMenu