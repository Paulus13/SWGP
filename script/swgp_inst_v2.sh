#!/bin/bash

# https://github.com/database64128/swgp-go

list_port_serv_def=20220
list_port_cli_def=20222

json_serv_path_type1="/etc/swgp-go/config.json"
json_cli_path_type1="/etc/swgp-go/config.json"

# json_serv_path_type2="/etc/swgp-go/server0.json"
json_serv_path_type2_unitfile='/etc/swgp-go/%i.json'
json_cli_path_type2="/etc/swgp-go/client.json"

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
ipt_ver=$(iptables --version 2>/dev/null)

if [[ -z $bc_ver || -z $wget_ver || -z $tar_ver || -z $git_ver || -z $curl_ver || -z $ipt_ver ]]; then
	apt update
	apt install -y bc wget tar git curl iptables
fi
}

function checkCompiledBin {
os_version_main=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | cut -d '.' -f 1)
# os_version_main=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.' | cut -c 1-2)

if [[ $os_version_main -le 20 ]]; then
	os_version_main2=20
else
	os_version_main2=22
fi

checkArchType
case "$arch_type" in
	"x86-64") 
	arch_part="amd64"
	bit_type="64-bit"
	exec_type="x86-64"
	;;
	"arm64") 
	arch_part="arm64"
	bit_type="64-bit"
	exec_type="aarch64"
	;;
	"arm") 
	arch_part="arm"
	bit_type="32-bit"
	exec_type="arm,"	
	;;		
	*)
	echo "Unknown architecture. Exit."
	Exit
esac

if [[ $arch_part == "arm64" ]]; then
	bin_file="swgp-go_arm64"
elif [[ $arch_part == "amd64" ]]; then
	# bin_file="swgp-go_amd64_ub${os_version_main2}"
	bin_file="swgp-go_amd64"
elif [[ $arch_part == "arm" ]]; then
	bin_file="swgp-go_arm"
fi

if [[ -f $bin_file ]]; then
	exec_check=$(file $bin_file | grep -i $bit_type | grep -i $exec_type)
	if [[ ! -z $exec_check ]]; then
		echo
		echo -e "${green}PreCompiled bin file $bin_file exists!${plain}"
		echo -e "${green}Platform checked - OK!${plain}"
		precomp_exist=1
		precomp_good=1		
	else
		echo
		echo -e "${red}PreCompiled bin file $bin_file exists but it not suitable for this platform!${plain}"
		precomp_exist=1
		precomp_good=0
	fi
else
	echo
	echo -e "${red}PreCompiled Bin file $bin_file does not exist!${plain}"
	# echo -e "${red}Download it and put in current folder.${plain}"
	precomp_exist=0
	precomp_good=0
	return
fi
}

function checkCompiledBin2 {
os_version_main=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | cut -d '.' -f 1)
# os_version_main=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.' | cut -c 1-2)

if [[ $os_version_main -le 20 ]]; then
	os_version_main2=20
else
	os_version_main2=22
fi

checkArchType
case "$arch_type" in
	"x86-64") 
	arch_part="amd64"
	bit_type="64-bit"
	exec_type="x86-64"
	;;
	"arm64") 
	arch_part="arm64"
	bit_type="64-bit"
	exec_type="aarch64"
	;;
	"arm") 
	arch_part="arm"
	bit_type="32-bit"
	exec_type="arm,"	
	;;			
	*)
	precomp_exist=0
	precomp_good=0
	return
esac

if [[ $arch_part == "arm64" ]]; then
	bin_file="swgp-go_arm64"
elif [[ $arch_part == "amd64" ]]; then
	# bin_file="swgp-go_amd64_ub${os_version_main2}"
	bin_file="swgp-go_amd64"
elif [[ $arch_part == "arm" ]]; then
	bin_file="swgp-go_arm"
fi

if [[ -f $bin_file ]]; then
	exec_check=$(file $bin_file | grep -i $bit_type | grep -i $exec_type)
	if [[ ! -z $exec_check ]]; then
		precomp_exist=1
		precomp_good=1
	else
		precomp_exist=1
		precomp_good=0
	fi
else
	precomp_exist=0
	precomp_good=0
fi
}

function downloadSWGPbin() {
bin_type=$1

dl_url="https://github.com/Paulus13/SWGP/raw/main/bin/swgp-go_${bin_type}"
wget $dl_url
}

function checkBinInstalled {
if [[ -f /usr/bin/swgp-go ]]; then
	echo
	selectYesNo "File /usr/bin/swgp-go already exists. Replace it?" "N"
	replace_bin=$t_select
	# if [[ "$replace_bin" =~ ^[nN]*$ ]]; then
		# echo "Exit"
		# return
	# fi
else
	replace_bin='Y'
fi
}

function checkBinInstalled2 {
if [[ -f /usr/bin/swgp-go ]]; then
	bin_inst=1
else
	bin_inst=0
fi
}

function useCompiledBin {
checkCompiledBin
if [[ $precomp_good -eq 0 ]]; then
	echo
	echo "Try download bin file"
	downloadSWGPbin $arch_part
fi

# bin_file="swgp-go_${arch_part}"
if [[ -f $bin_file ]]; then
	exec_check=$(file $bin_file | grep -i $bit_type | grep -i $exec_type)
	if [[ -z $exec_check ]]; then
		echo
		echo "File not good."
		return
	fi
else
	echo
	echo "Download unsuccessfull."
	return
fi

checkBinInstalled
if [[ "$replace_bin" =~ ^[nN]*$ ]]; then
	# echo "Exit"
	echo -e "${green}File $bin_file not used${plain}"
	return
fi	
	
cp $bin_file /usr/bin/swgp-go
chmod +x /usr/bin/swgp-go

echo -e "${green}File $bin_file copied to /usr/bin/swgp-go${plain}"
echo -e "${green}Exec permitions added${plain}"
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
if [[ $dot_num -gt 1 ]]; then
	go_ver_1=$(echo $t_go_ver |  awk -F. '{print $1}')
	go_ver_2=$(echo $t_go_ver |  awk -F. '{print $2}')
	go_ver_3=$(echo $t_go_ver |  awk -F. '{print $3}')
	trunk_go_ver="${go_ver_1}.${go_ver_2}${go_ver_3}"	
else
	trunk_go_ver=$t_go_ver
fi
}

function compareGoVer() {
go_need_ver=$(curl -s "https://raw.githubusercontent.com/database64128/swgp-go/main/go.mod" | grep "go [1-9]." | awk '{print $2}')
go_ver=$1

trunkGoVersion $go_ver
go_ver_trunk=$trunk_go_ver

trunkGoVersion $go_need_ver
go_need_ver_trunk=$trunk_go_ver

if [[ 1 -eq "$(echo "${go_ver_trunk} < ${go_need_ver_trunk}" | bc)" ]]
then  
	ver_enough=0
else
	ver_enough=1
fi	
}

function latestRelSWGP() {

# this function not needed
wget https://github.com/database64128/swgp-go/releases/latest 2>/dev/null
latest_rel=$(grep Release latest | head -n1 | awk '{print $2}')
latest_rel_alt=$(curl -s "https://github.com/database64128/swgp-go/releases" | grep "swgp-go/releases/tag/" | head -n1 | awk '{print $7}' | awk -F/ '{print $6}' | sed 's/"//')
rm latest
}

function checkArchType() {
arch_type=$(hostnamectl status | grep -i architecture | awk '{print $2}')
}

function getGoLang {
checkGoInstalled

if [[ $go_installed -eq 1 ]]; then
	compareGoVer $go_inst_ver
	if [[ $ver_enough -eq 1 ]]; then
		echo -e "${green}Installed Go ver. $go_inst_ver is enough${plain}"
		selectYesNo "Update it to the latest?" "N"
		update_go=$t_select
		
		if [[ "$update_go" =~ ^[nN]*$ ]]; then
			return
		fi
	else
		echo -e "${green}Installed Go ver. $go_inst_ver is not enough${plain}"
		echo -e "${green}Updating it to the latest version${plain}"
	fi
else
	selectYesNo "Install GoLang?" "Y"
	inst_go=$t_select
	
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
	*)
	echo
	echo -e "${red}Unknown architecture${plain}"
	echo -e "${red}GoLang not installed${plain}"
	exit
esac

if [[ -d /usr/local/go ]]; then
	rm -rf /usr/local/go
fi

dl_url1="https://go.dev"
dl_url2=$(curl -s "https://go.dev/dl/" | grep linux | grep $os_part | grep download | head -n1 | awk '{print $4}' | cut -d '=' -f 2 | sed 's/.$//' | sed 's/.$//' | sed 's/^.//')

dl_url="${dl_url1}${dl_url2}"

wget -O go.tar.gz $dl_url

tar -zxvf go.tar.gz -C /usr/local/
rm go.tar.gz
go_path_prof=$(grep "/usr/local/go/bin" $HOME/.profile)

if [[ -z $go_path_prof ]]; then
	echo "export PATH=/usr/local/go/bin:\$PATH" | sudo tee -a $HOME/.profile
	source $HOME/.profile

	echo
	echo -e "${green}Please run this command:"
	echo -e "source $HOME/.profile"
	echo -e "for apply PATH variable in current session${plain}"	
fi
}

function compileSWGP {
checkBinInstalled
if [[ "$replace_bin" =~ ^[nN]*$ ]]; then
	echo
	echo "${red}Compile Aborted${plain}"
	return
fi

checkGoInstalled
if [[ $go_installed -eq 0 ]]; then
	echo -e "${green}Install it before compile SWGP.${plain}"
	echo
	return
fi

if [[ -d swgp-go ]]; then
	cd swgp-go
	rm ./swgp-go 2>/dev/null
	git pull
else
	git clone https://github.com/database64128/swgp-go.git
	cd swgp-go
fi

git_main_str=$(git status | grep "origin/main")
if [[ ! -z $git_main_str ]]; then
	git_main=1
else
	git_main=0
fi

if [[ $git_checkout_last_tag -eq 1 ]]; then
	last_tag=$(git tag | tail -n 1)
	git checkout $last_tag
else
	if [[ $git_main -eq 0 ]]; then
		git switch main
	fi
	git pull
fi

echo
echo -e "${green}Now we are here:${plain}"
git log --max-count=1
echo
	
export CGO_ENABLED=0 
go build -o swgp-go cmd/swgp-go/main.go

if [[ -f /lib/systemd/system/swgp-go.service ]]; then
	systemctl stop swgp-go.service
	cp swgp-go /usr/bin
	systemctl start swgp-go.service
else
	cp swgp-go /usr/bin
fi

cd ..
}

function getExeFile() {

# this function not needed
if [[ -f /usr/bin/swgp-go ]]; then
	echo "Bin file already exists. Exit."
	return
fi

latestRelSWGP
checkArchType

case "$arch_type" in
	"x86-64") 
	os_part="linux-x86-64-v2"
	;;
	"arm64") 
	os_part="linux-arm64"
	;;
	*)
	echo "Unknown architecture. Exit."
	Exit
esac

d_url="https://github.com/database64128/swgp-go/releases/download/${latest_rel}/swgp-go-${latest_rel}-${os_part}.tar.zst"
d_file="swgp-go-${latest_rel}-${os_part}.tar.zst"

wget $d_url 2>/dev/null
if [[ ! -f /usr/bin/zstd ]]; then
	apt update -q
	apt install -qy zstd
fi

tar -I zstd -xvf $d_file
rm $d_file

cp swgp-go /usr/bin
}

function checkInstalled() {
if [[ -f /lib/systemd/system/swgp-go.service || -f /lib/systemd/system/swgp-go@.service ]]; then
	swgpInst=1
else
	swgpInst=0
fi
}

function checkWGInstalled() {
if [[ -f /lib/systemd/system/wg-quick@.service ]]; then
	wgInst=1
else
	wgInst=0
fi
}

function getServType {
if [[ -z $1 ]]; then
	t_silent=0
else
	t_silent=$1
fi

if [[ -f /lib/systemd/system/swgp-go.service ]]; then
	serv_type=1
	return
elif [[ -f /lib/systemd/system/swgp-go@.service ]]; then
	serv_type=2
	return
elif [[ -f /etc/swgp-go/client.json ]]; then
	serv_type=2
	return
elif [[ $(ls /etc/swgp-go/server*.json 2>/dev/null | wc -l) -gt 0 ]]; then
	serv_type=2
	return	
fi

if [[ $t_silent -eq 0 ]]; then
	servtypeMenu
else
	serv_type=0
fi
}

function servtypeMenu {
	MENU_OPTION="menu"
	echo 
	echo "What service type you want use?"
	echo "   1) Classic single service with one config"
	echo "   2) Multiple service with many configs (default)"
	until [[ $MENU_OPTION =~ ^[1-2]$ || -z $MENU_OPTION ]]; do
		read -rp "Select an option [1-2]: " MENU_OPTION
	done

	case $MENU_OPTION in
	1)
		echo
		echo -e "${green}Create single service${plain}"
		serv_type=1
		;;
	2|"")
		echo
		echo -e "${green}Create multiple service${plain}"
		serv_type=2
		;;
	esac
}

function createService {
if [[ -f /lib/systemd/system/swgp-go.service ]]; then
	echo -e "${green}Service alresdy exists. Exit.${plain}"
	serv_type=1
	return
fi

if [[ -f /lib/systemd/system/swgp-go@.service ]]; then
	echo -e "${green}Service alresdy exists. Exit.${plain}"
	serv_type=2
	return
fi

getServType

if [[ $serv_type -eq 2 ]]; then
	selectWGIntForClients
	wg_int_num=$(echo $t_sel_wg | sed 's/wg//g')
	
	serv_name="server${wg_int_num}"
	serv_name_full="swgp-go@${serv_name}"

	json_serv_path_type2="/etc/swgp-go/${serv_name}.json"
else
	serv_name_full="swgp-go.service"
fi
setJsonPath

if [[ $serv_type -eq 1 ]]; then
cat > /lib/systemd/system/swgp-go.service << EOF
[Unit]
Description=Simple WireGuard Proxy Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/swgp-go -confPath /etc/swgp-go/config.json -zapConf systemd

[Install]
WantedBy=multi-user.target
EOF
elif [[ $serv_type -eq 2 ]]; then
cat > /lib/systemd/system/swgp-go@.service << 'EOF'
[Unit]
Description=Simple WireGuard Proxy Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/swgp-go -confPath /etc/swgp-go/%i.json -zapConf systemd

[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload
systemctl start $serv_name_full
systemctl enable $serv_name_full
}

function getServPort {
if [[ -f $json_serv_path ]]; then
	list_port=$(grep proxyListen $json_serv_path | awk '{print $2}' | sed 's/"//g' | sed 's/://' | sed 's/,//')
	serv_conf=1
else
	echo
	echo -e "${red}SWGP server not configured${plain}"
	serv_conf=0
	return
fi
}

function getServPSK {
if [[ -f $json_serv_path ]]; then
	t_psk=$(grep proxyPSK $json_serv_path | awk '{print $2}' | sed 's/"//g' | sed 's/://' | sed 's/,//')
else
	echo -e "${red}SWGP server not configured${plain}"
	return
fi
}

function selectPort {
if [[ ! -z "$1" ]]; then 
	def_port=$1
else
	def_port=$list_port_serv_def
fi

echo
read -rp "Enter Port what SWGP listen ([ENTER] set to default: $def_port): " list_port
if [[ -z $list_port ]]; then
	list_port=$def_port
fi

validPort $list_port
until [[ $? -eq 0 ]]; do
	echo $list_port "looks like not good Port"
	read -p "Enter the Port: " list_port
	validPort $list_port
done
}

function validPort() {
if [[ -z "$1" ]]; then 
	return 1
fi

port=$1
isNumber $port

if [[ $? -eq 0 ]] && [[ $port -gt 0 ]] && [[ $port -lt 65535 ]]; then
	valid_port=1
	return 0
else
	valid_port=0
	return 1
fi
}

function isNumber() {
if [[ -z "$1" ]]; then 
	return 1
fi

var=$1
if [[ -n "$var" ]] && [[ "$var" -eq "$var" ]] 2>/dev/null; then
  #echo number
  is_num=1
  return 0
else
  #echo not a number
  is_num=0
  return 1
fi
}

function selectPSK {
read -rp "Enter PSK for SWGP ([ENTER] - Generate PSK): " t_psk
if [[ -z $t_psk ]]; then
	generatePSK
	t_psk=$gen_psk
fi
echo
echo "PSK: $t_psk"
echo
}

function getLocalWGPort {
getServType 1
if [[ $serv_type -eq 2 ]]; then
	if [[ -z $1 ]]; then
		selectWGIntForClients
	else
		t_sel_wg=$1
	fi
fi

local_wg_port=$(cat /etc/wireguard/${t_sel_wg}.conf | grep -i listen | awk '{print $3}')

wg_int_num=$(echo $t_sel_wg | sed 's/wg//g')
json_serv_path_type2="/etc/swgp-go/server${wg_int_num}.json"

# if [[ -f /usr/bin/wg ]]; then
	# if [[ -f /etc/wireguard/wg0.conf ]]; then
		# local_wg_port=$(cat /etc/wireguard/wg0.conf | grep -i listen | awk '{print $3}')
	# elif [[ -f /etc/wireguard/wg1.conf ]]; then
		# local_wg_port=$(cat /etc/wireguard/wg1.conf | grep -i listen | awk '{print $3}')
	# elif [[ -f /etc/wireguard/wg2.conf ]]; then
		# local_wg_port=$(cat /etc/wireguard/wg2.conf | grep -i listen | awk '{print $3}')
	# # else
	# # 	local_wg_port=$(wg | grep -A 4 wg0 | grep listening | awk '{print $3}')
	# fi
# else
	# # local_wg_port=0
	# read -rp "Enter Port what WG server ([ENTER] set to default: 53420): " local_wg_port
	# if [ -z $local_wg_port ]; then
		# local_wg_port=53420
	# fi

	# validPort $local_wg_port
	# until [[ $? -eq 0 ]]; do
		# echo $local_wg_port "looks like not good Port"
		# read -p "Enter the Port: " local_wg_port
		# validPort $local_wg_port
	# done	
# fi
}

function selectWGHostPort {
read -rp "Enter WG server Host : " wg_host

read -rp "Enter WG (swgp-go) server port ([ENTER] set to default: $list_port_serv_def): " wg_port
if [[ -z $wg_port ]]; then
	wg_port=$list_port_serv_def
fi
}

function generatePSK {
if [[ ! -f /usr/bin/openssl ]]; then
	apt install -y openssl
fi

gen_psk=$(openssl rand -base64 32)
}

function selectWGIntForClients {
if [[ -z $1 ]]; then
	t_silent=0
else
	t_silent=$1
fi

wg_conf_num=$(ls /etc/wireguard/wg*.conf 2>/dev/null | wc -l)
if [[ $wg_conf_num -eq 0 ]]; then
	t_sel_wg=""
	echo
	echo -e "${red}No WG interface exist.${plain}"
	return
fi

wg_int_list_num=$(wg | grep interface | wc -l)
wg_int_def=$(wg | grep interface | head -1 | awk '{print $2}')

if [[ $wg_int_list_num -eq 1 ]]; then
	t_sel_wg=$(wg | grep interface | awk '{print $2}')
else
	createWGIntListForClients
	if [[ $j -eq 1 ]]; then
		t_wg_int=$t_list
	else
		if [[ $t_silent -eq 0 ]]; then
			echo 
			echo "This WG interfaces exist: $t_list"
			read -p "What interface use? default - $def_int_cl: " t_wg_int
			if [ -z $t_wg_int ]; then
				t_wg_int=$def_int_cl
			fi
		else
			t_wg_int=$def_int_cl
		fi
	fi
	checkWGIntExist $t_wg_int
	until [[ $wg_int_exist -eq 1 ]]; do
		echo "$t_wg_int: invalid selection."
		read -p "What interface use? " t_wg_int
		checkWGIntExist $t_wg_int
	done
	t_sel_wg=$t_wg_int
fi
}

function createWGIntListForClients {
t_list=""
j=0

readarray myArr <<< $(wg | grep interface | awk '{print $2}')
for i in ${myArr[@]}
do 
	t_int=${i}
	checkWGIntForClients $t_int
	if [[ $wg_for_cl -eq 1 ]]; then
		if [[ -z $t_list ]]; then
			t_list=$t_int
		else
			t_list="$t_list $t_int"
		fi
		
		j=$j+1
		if [[ $j -eq 1 ]]; then
			def_int_cl=$t_int
		fi
	fi
done
}

function checkWGIntExist {
t_int=$1
t_wg_line=$(wg | grep interface | grep $t_int)

if [[ -z $t_wg_line ]]; then
	wg_int_exist=0
else
	wg_int_exist=1
fi
}

function checkWGIntForClients {
t_wg_int_cl=$1
wg_conf_ep_line=$(grep Endpoint /etc/wireguard/${t_wg_int_cl}.conf)
wg_conf_obfus_line=$(grep ObfuscateKey /etc/wireguard/${t_wg_int_cl}.conf)
if [[ ! -z $wg_conf_ep_line || ! -z $wg_conf_obfus_line ]]; then
	wg_for_cl=0
else
	wg_for_cl=1
fi
}

function createSWGPConf {
MENU_OPTION=0
checkBinInstalled2
if [[ $bin_inst -eq 1 ]]; then
	echo
	echo "How to configure SWGP?"
	echo "   1) As Server (default)"	
	echo "   2) As Client"
	echo "   3) Cancel (return to main menu)"

	until [[ $MENU_OPTION =~ ^[1-3]$ || -z $MENU_OPTION ]]; do
		read -rp "Select an option [1-3]: " MENU_OPTION
	done

	case $MENU_OPTION in
	1|"")
		echo
		echo -e "${green}Create server config${plain}"
		createServerConf
		;;	
	2)
		echo
		echo -e "${green}Create client config${plain}"
		createClientConf
		;;
	3)
		return
		;;	
	esac
else
	echo
	echo -e "${red}Bin file /usr/bin/swgp-go does not exist${plain}"
	echo -e "${red}Use PreCompiled bin (menu point 1)" 
	echo -e "Or compile it from source code (menu point 2)${plain}"
	return
fi
}

function createServerConf {
getServType
selectWGIntForClients
setJsonPath
if [[ -f $json_serv_path ]]; then
	selectYesNo "Configuration already exists. Reconfigure?" "N"
	reconf=$t_select
	
	if [[ "$reconf" =~ ^[nN]*$ ]]; then
		echo "Exit"
		exit
	fi
fi

if [[ ! -d /etc/swgp-go ]]; then
	mkdir /etc/swgp-go
fi

selectPort $list_port_serv_def
getLocalWGPort
checkFirewall
selectPSK

cat > $json_serv_path << EOF
{
    "servers": [
        {
            "name": "server",
            "proxyListen": ":$list_port",
            "proxyMode": "zero-overhead",
            "proxyPSK": "$t_psk",
            "proxyFwmark": 0,
            "proxyTrafficClass": 0,
            "wgEndpoint": "127.0.0.1:$local_wg_port",
            "wgFwmark": 0,
            "wgTrafficClass": 0,
            "mtu": 1500,
            "batchMode": "",
            "relayBatchSize": 0,
            "mainRecvBatchSize": 0,
            "sendChannelCapacity": 0
        }
    ]
}
EOF

showCliConf $local_wg_port $t_psk

echo
selectYesNo "Create service?" "Y"
if [[ "$t_select" =~ ^[yY]*$ ]]; then
	createService
fi
}

function selectYesNo {
t_select=""
t_quest=$1

if [[ -z $2 ]]; then
	t_def_sel="Y"
else
	t_def_sel=$2
fi

case $t_def_sel in
"y"|"Y")
	t_sel_var="[Y/n]"
	;;	
"n"|"N")
	t_sel_var="[y/N]"
	;;
*)
	t_def_sel="Y"
	t_sel_var="[Y/n]"
	;;
esac

read -p  "${t_quest} ${t_sel_var}: " t_select
if [ -z $t_select ]
then
	t_select=$t_def_sel
fi

until [[ "$t_select" =~ ^[yYnN]*$ ]]; do
	echo "$t_select: invalid selection."
	read -p "${t_quest} [y/n]: " t_select
done
}

function setJsonPath {
if [[ -z $1 ]]; then
	t_silent=0
else
	t_silent=$1
fi

if [[ $serv_type -eq 1 ]]; then
	json_cli_path=$json_cli_path_type1
	json_serv_path=$json_serv_path_type1
elif [[ $serv_type -eq 2 ]]; then
	json_cli_path=$json_cli_path_type2
	if [[ -z $json_serv_path_type2 ]]; then
		if [[ -z $t_sel_wg ]]; then
			selectWGIntForClients $t_silent
		fi
		wg_int_num=$(echo $t_sel_wg | sed 's/wg//g')
		json_serv_path_type2="/etc/swgp-go/server${wg_int_num}.json"
		# json_serv_path_type2=$(ls /etc/swgp-go/server*.json | head -1)
	fi
	json_serv_path=$json_serv_path_type2
else
	json_exist=$(ls /etc/swgp-go/*.json 2>/dev/null | wc -l)
	if [[ $json_exist -gt 0 ]]; then
		json_type1=$(ls /etc/swgp-go/config.json 2>/dev/null)
		json_type2_cli=$(ls /etc/swgp-go/client.json 2>/dev/null)
		json_type2_srv=$(ls /etc/swgp-go/server*.json 2>/dev/null | head -1)
		if [[ ! -z $json_type1 ]]; then
			json_cli_path=$json_cli_path_type1
			json_serv_path=$json_serv_path_type1
		elif [[ ! -z $json_type2_srv ]]; then
			# json_type2_srv_num=$(ls $json_type2_srv | awk -F/ '{print $4}' | sed 's/server//' | sed 's/.json//')
			if [[ -z $t_sel_wg ]]; then
				selectWGIntForClients $t_silent
			fi
			t_wg_num=$(echo $t_sel_wg | sed 's/wg//')
			t_json_srv="/etc/swgp-go/server${t_wg_num}.json"
			
			json_cli_path=$json_cli_path_type2
			json_serv_path=$t_json_srv
		else
			json_cli_path=$json_cli_path_type2
			json_serv_path=""			
		fi
	fi
fi
}

function showCliConf {
ext_ip=$(dig @resolver4.opendns.com myip.opendns.com +short -4)

list_port=$list_port_cli_def
if [[ -f $json_serv_path ]]; then
	list_port_real=$(grep proxyListen $json_serv_path | awk '{print $2}' | sed 's/"//g' | sed 's/://' | sed 's/,//')
else
	list_port_real=$list_port
fi

wg_host=$ext_ip
wg_port=$1
t_psk=$2

if [[ -f tmp_cli_config.json ]]; then
	rm tmp_cli_config.json
fi

cat > tmp_cli_config.json << EOF
{
    "clients": [
        {
            "name": "client",
            "wgListen": ":$list_port",
            "wgFwmark": 0,
            "wgTrafficClass": 0,
            "proxyEndpoint": "$wg_host:$list_port_real",
            "proxyMode": "zero-overhead",
            "proxyPSK": "$t_psk",
            "proxyFwmark": 0,
            "proxyTrafficClass": 0,
            "mtu": 1500,
            "batchMode": "",
            "relayBatchSize": 0,
            "mainRecvBatchSize": 0,
            "sendChannelCapacity": 0
        }
    ]
}
EOF

echo
echo -e "${green}Use this config for client side (change SWGP listen port if needed)${plain}"
echo -e "${green}Config saved to the file 'tmp_cli_config.json'${plain}"
echo

cat ./tmp_cli_config.json
# rm ./tmp_cli_config.json
}

function showCliConfMenu {
getServType 1
if [[ $serv_type -eq 1 ]]; then
	selectWGIntForClients
	setJsonPath
	if [[ ! -f $json_serv_path ]]; then
		echo
		echo -e "${green}SWGP server not configured${plain}"
		return
	fi
elif [[ $serv_type -eq 2 ]]; then
	selectWGIntForClients
	wg_int_num=$(echo $t_sel_wg | sed 's/wg//g')
	
	serv_name="server${wg_int_num}"
	json_serv_path_type2="/etc/swgp-go/${serv_name}.json"
	setJsonPath
fi

conf_serv_line=$(grep servers $json_serv_path)
if [[ -z $conf_serv_line ]]; then
	echo
	echo -e "${green}SWGP server not configured${plain}"
	return
fi

getServPSK
getLocalWGPort $t_sel_wg
showCliConf $local_wg_port $t_psk
}

function createClientConf {
getServType
setJsonPath

if [[ -f $json_cli_path ]]; then
	selectYesNo "Configuration already exists. Reconfigure SWGP?" "N"
	reconf=$t_select
	
	if [[ "$reconf" =~ ^[nN]*$ ]]; then
		exit
	fi
fi

if [[ ! -d /etc/swgp-go ]]; then
	mkdir /etc/swgp-go
fi

if [[ -f config.json ]]; then
	selectYesNo "File 'config.json' exists. Use it?" "Y"
	use_tmp_conf=$t_select

	if [[ "$use_tmp_conf" =~ ^[yY]*$ ]]; then
		cp config.json $json_cli_path
		return
	fi
elif [[ -f tmp_cli_config.json ]]; then
	selectYesNo "File 'tmp_cli_config.json' exists. Use it?" "Y"
	use_tmp_conf=$t_select

	if [[ "$use_tmp_conf" =~ ^[yY]*$ ]]; then
		cp tmp_cli_config.json $json_cli_path
		return
	fi
fi

selectPort $list_port_cli_def
selectWGHostPort
selectPSK

cat > $json_cli_path << EOF
{
    "clients": [
        {
            "name": "client",
            "wgListen": ":$list_port",
            "wgFwmark": 0,
            "wgTrafficClass": 0,
            "proxyEndpoint": "$wg_host:$wg_port",
            "proxyMode": "zero-overhead",
            "proxyPSK": "$t_psk",
            "proxyFwmark": 0,
            "proxyTrafficClass": 0,
            "mtu": 1500,
            "batchMode": "",
            "relayBatchSize": 0,
            "mainRecvBatchSize": 0,
            "sendChannelCapacity": 0
        }
    ]
}
EOF

selectYesNo "Create service?" "Y"
if [[ "$t_select" =~ ^[yY]*$ ]]; then
	createService
fi
}

function checkFirewall {
if [[ $serv_conf -eq 0 ]]; then
	return
fi

fw_conf=$(iptables-save | grep INPUT)

if [[ -z $fw_conf ]]; then
	echo
	echo -e "${red}Firewall not configured${plain}"
	return
fi

echo
echo -e "${green}Local WG port - $local_wg_port${plain}"
echo -e "${green}SWGP listen port - $list_port${plain}"
echo

iptab_inst=$(iptables-save | grep $local_wg_port)
iptab_conf=$(iptables-save | grep $list_port)

if [[ ! -z $iptab_inst && -z $iptab_conf ]]; then
	echo -e "${green}Add iptables rule:${plain}"
	echo -e "${green}-A INPUT -p udp -m udp --dport $list_port -j ACCEPT${plain}"
	iptables -A INPUT -p udp -m udp --dport $list_port -j ACCEPT
	
	if [[ -f /etc/iptables/rules.v4 ]]; then
		echo -e "${green}Update FW rules files${plain}"
		netfilter-persistent save
		netfilter-persistent reload
	fi
else
	echo -e "${green}Iptables configuration not needed${plain}"
	if [[ ! -z $iptab_conf ]]; then
		echo -e "${green}Lines exists:${plain}"
		echo -e "${green}$iptab_inst${plain}"
		echo -e "${green}$iptab_conf${plain}"
	fi
fi
}

function removeSWGP {
json_files_num=$(ls /etc/swgp-go/*.json | wc -l)
try_num=$(( try_num+1 ))

if [[ ! -f /usr/bin/swgp-go || $json_files_num -eq 0 ]]; then
	echo
	echo -e "${red}SWGP not installed${plain}"
	echo -e "${red}Nothing to remove${plain}"
	return
fi

if [[ $try_num -lt 3 ]]; then
	return
fi

selectYesNo "Remove SWGP?" "N"
rem_soft=$t_select

if [[ "$rem_soft" =~ ^[nN]*$ ]]; then
	echo
	echo -e "${green}SWGP not removed${plain}"
	return
else
	echo
	echo -e "${green}Remove SWGP...${plain}"
fi

getServType 1
if [[ $serv_type -eq 1 ]]; then
	systemctl stop swgp-go.service
	systemctl disable swgp-go.service
	systemctl unmask swgp-go.service
elif [[ $serv_type -eq 2 ]]; then
	readarray myArr <<< $(systemctl | grep swgp | grep service | awk '{print $1}')
	for i in ${myArr[@]}
	do 
		t_serv=${i}
		systemctl stop $t_serv
		systemctl disable $t_serv
		systemctl unmask $t_serv
	done
fi

checkCompiledBin2
if [[ $precomp_good -eq 0 ]]; then
	mv /usr/bin/swgp-go ./$bin_file
else
	rm /usr/bin/swgp-go
fi

if [[ $serv_type -eq 1 ]]; then
	rm /lib/systemd/system/swgp-go.service
elif [[ $serv_type -eq 1 ]]; then
	rm /lib/systemd/system/swgp-go@.service
fi

# Config not delete
# rm /etc/swgp-go/config.json

systemctl daemon-reload

if [ -d swgp-go ]; then
	rm -rf swgp-go
fi

echo
echo -e "${green}SWGP removed${plain}"
}

function manageMenu {
	MENU_OPTION=0
	echo
	echo -e "${green}Installation SWGP${plain}"
	echo
	echo -e "${green}What do you want to do?${plain}"
	# echo "   1) Check PreCompiled SWGP binary"	
	# echo "   2) Use PreCompiled SWGP binary"
	# echo "   3) Compile SWGP binary using GoLang"
	# echo "   4) Configure SWGP"
	# echo "   5) Create swgp-go service"	
	# echo "   6) Check Firewall"
	# echo "   7) Show client config for existing server side"
	# echo "   8) Remove SWGP"
	# echo "   9) Exit"
	
	getServType 1
	setJsonPath 1
	
	checkCompiledBin2
	if [[ $precomp_exist -eq 1 && $precomp_good -eq 1 ]]; then
		use_precomp_menu="${green}   1) Use PreCompiled SWGP binary${plain}"
	elif [[ $precomp_exist -eq 1 && $precomp_good -eq 0 ]]; then
		use_precomp_menu="${red}   1) Use PreCompiled SWGP binary (binary not compatible with $arch_type)${plain}"
	else
		use_precomp_menu="${red}   1) Use PreCompiled SWGP binary (bin file not exist in current folder)${plain}"
	fi
	
	if [[ -f /usr/bin/swgp-go ]]; then
		use_precomp_menu="${yellow}   1) Use PreCompiled SWGP binary (file exist /usr/bin/swgp-go)${plain}"
	fi
	
	checkBinInstalled2	
	if [[ $bin_inst -eq 1 ]]; then
		comp_menu="${yellow}   2) Compile SWGP binary using GoLang (file exist /usr/bin/swgp-go)${plain}"
	else
		comp_menu="${green}   2) Compile SWGP binary using GoLang${plain}"
	fi
	
	if [[ $bin_inst -eq 0 ]]; then
		config_menu="${red}   3) Configure SWGP (bin file not exist in /usr/bin)${plain}"
	elif [[ -f $json_serv_path ]]; then
		config_menu="${yellow}   3) Configure SWGP (config exist)${plain}"
	else
		config_menu="${green}   3) Configure SWGP${plain}"
	fi
	
	if [[ $bin_inst -eq 0 ]]; then
		create_service_menu="${red}   4) Create swgp-go service (bin file not exist in /usr/bin)${plain}"
	elif [[ -f /lib/systemd/system/swgp-go.service || -f /lib/systemd/system/swgp-go@.service ]]; then
		create_service_menu="${yellow}   4) Create swgp-go service (service exist)${plain}"
	else
		create_service_menu="${green}   4) Create swgp-go service${plain}"
	fi
	
	# getServType 1
	if [[ $serv_type -eq 0 ]]; then
		change_serv_menu="${red}   5) Change service type (service not installed)${plain}"
	elif [[ $serv_type -eq 1 ]]; then
		change_serv_menu="${green}   5) Change service type (1 > 2)${plain}"
	elif [[ $serv_type -eq 2 ]]; then
		change_serv_menu="${red}   5) Change service type (changing 2 > 1 not allowed)${plain}"
	fi
	
	fw_conf=$(iptables-save | grep INPUT)
	if [[ -z $fw_conf ]]; then
		check_firewall_menu="${red}   6) Check Firewall (Firewall not configured)${plain}"
	elif [[ -f $json_serv_path ]]; then
		check_firewall_menu="${green}   6) Check Firewall${plain}"
	else
		check_firewall_menu="${red}   6) Check Firewall (SWGP not configured)${plain}"
	fi
	
	if [[ -f $json_serv_path ]]; then
		show_client_config_menu="${green}   7) Show client config for existing server side${plain}"
	else
		show_client_config_menu="${red}   7) Show client config for existing server side (SWGP server not configured)${plain}"
	fi	
	
	service_running=$(systemctl | grep swgp-go | grep service | grep running)
	if [[ -z $service_running ]]; then
		remove_menu="${red}   8) Remove SWGP (SWGP not installed)${plain}"
	else
		remove_menu="${green}   8) Remove SWGP${plain}"
	fi

	exit_menu="${green}   9) Exit${plain}"
	
	echo -e $use_precomp_menu
	echo -e $comp_menu
	echo -e $config_menu
	echo -e $create_service_menu
	echo -e $change_serv_menu
	echo -e $check_firewall_menu
	echo -e $show_client_config_menu
	echo -e $remove_menu
	echo -e $exit_menu
	
	until [[ $MENU_OPTION =~ ^[1-9]$ ]]; do
		read -rp "Select an option [1-9]: " MENU_OPTION
	done

	case $MENU_OPTION in

	1)
		useCompiledBin
		MENU_OPTION=0
		manageMenu
		;;					
	2)
		MENU_OPTION=0
		compileMenu
		;;	
	3)
		createSWGPConf
		MENU_OPTION=0
		manageMenu
		;;	
	4)
		# echo "serv_type: $serv_type"
		# echo "json_serv_path: $json_serv_path"
		if [[ ! -f $json_serv_path ]]; then
			echo
			echo -e "${red}You must configure SWGP before create service.${plain}"
			createSWGPConf		
		fi
		
		if [[ $bin_inst -eq 1 ]]; then
			createService
			# systemctl start $serv_name_full
			# systemctl enable $serv_name_full
		fi
		MENU_OPTION=0
		manageMenu
		;;
	5)
		changeServType
		MENU_OPTION=0
		manageMenu
		;;				
	6)
		getServPort
		getLocalWGPort
		checkFirewall
		MENU_OPTION=0
		manageMenu
		;;	
	7)
		showCliConfMenu
		MENU_OPTION=0
		manageMenu		
		;;			
	8)
		removeSWGP
		MENU_OPTION=0
		manageMenu
		;;

	9|"")
		exit 0
		;;
	esac
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
		
		if [[ $go_inst_ver == $latest_go_ver ]]; then
			inst_menu="${yellow}   1) Update Go binary (latest version installed - $go_inst_ver)${plain}"
		else
			inst_menu="${green}   1) Update Go binary $go_inst_ver > $latest_go_ver${plain}"
		fi		
	fi
	
	checkBinInstalled2	
	if [[ $bin_inst -eq 1 ]]; then
		comp_menu="${yellow}   2) Compile SWGP binary using GoLang (file exist /usr/bin/swgp-go)${plain}"
	else
		comp_menu="${green}   2) Compile SWGP binary using GoLang${plain}"
	fi
	
	exit_menu="${green}   3) Exit to main menu${plain}"
	
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
		manageMenu
		;;
	esac
}

function changeServType {
getServType 1
if [[ $serv_type -eq 0 ]]; then
	echo
	echo -e "${red}Service not installed${plain}"	
	return
elif [[ $serv_type -eq 1 ]]; then
	json_type_server=$(cat $json_serv_path_type1 | grep '"servers":')
	json_type_client=$(cat $json_cli_path_type1 | grep '"clients":')

	systemctl stop swgp-go.service
	systemctl disable swgp-go.service
	systemctl unmask swgp-go.service
	
	sed -i 's,ExecStart=/usr/bin/swgp-go -confPath /etc/swgp-go/config.json -zapConf systemd,ExecStart=/usr/bin/swgp-go -confPath /etc/swgp-go/%i.json -zapConf systemd,' /lib/systemd/system/swgp-go.service
	mv /lib/systemd/system/swgp-go.service /lib/systemd/system/swgp-go@.service
	systemctl daemon-reload
	
	if [[ ! -z $json_type_server ]]; then
		t_wg_int_num=$(ls /etc/wireguard/wg*.conf 2>/dev/null | wc -l)
		if [[ $t_wg_int_num -eq 1 ]]; then
			t_wg_int=$(ls /etc/wireguard/wg*.conf | sed 's,/etc/wireguard/,,' | sed 's,.conf,,')
		elif [[ $t_wg_int_num -gt 1 ]]; then
			t_wg_port=$(cat $json_serv_path_type1 | grep wgEndpoint | awk '{print $2}' | awk -F: '{print $2}' | sed 's/",$//')
			t_wg_int=$(grep ListenPort /etc/wireguard/wg*.conf | grep $t_wg_port | awk -F: '{print $1}' | sed 's,/etc/wireguard/,,' | sed 's,.conf,,')
		fi
		wg_int_num=$(echo $t_wg_int | sed 's/wg//g')
		json_serv_file="server${wg_int_num}"
		json_serv_path_type2="/etc/swgp-go/${json_serv_file}.json"
		
		mv $json_serv_path_type1 $json_serv_path_type2
		systemctl enable swgp-go@${json_serv_file}
		systemctl start swgp-go@${json_serv_file}		
	elif [[ ! -z $json_type_client ]]; then
		mv $json_cli_path_type1 $json_cli_path_type2
		systemctl enable swgp-go@client
		systemctl start swgp-go@client
	fi	
elif [[ $serv_type -eq 2 ]]; then
	echo
	echo -e "${red}Changing type 2 -> 1 not allowed${plain}"
	return
fi
}

initialCheck
checkNeededSoft
manageMenu