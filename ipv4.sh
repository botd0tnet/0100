#!/bin/bash



## Colours variables for the installation script
RED='\033[1;91m' # WARNINGS
YELLOW='\033[1;93m' # HIGHLIGHTS
WHITE='\033[1;97m' # LARGER FONT
LBLUE='\033[1;96m' # HIGHLIGHTS / NUMBERS ...
LGREEN='\033[1;92m' # SUCCESS
NOCOLOR='\033[0m' # DEFAULT FONT

## required packages list
install_essentials='curl ufw sudo git pkg-config build-essential libssl-dev pwgen base58'
apt-get install ${install_essentials} -y > /dev/null 2>&1

## Prints the Nym banner to stdout from hex
printf "%b\n" "0D0A2020202020205F205F5F20205F2020205F205F205F5F205F5F5F0D0A20202020207C20275F205C7C207C207C207C20275F205C205F205C0D0A20202020207C207C207C207C207C5F7C207C207C207C207C207C207C0D0A20202020207C5F7C207C5F7C5C5F5F2C207C5F7C207C5F7C207C5F7C0D0A2020202020202020202020207C5F5F5F2F0D0A0D0A2020202020202020202020202028696E7374616C6C6572202D2076657273696F6E20302E31302E30290D0A" | xxd -p -r


## display usage if the script is not run as root user
if [[ $USER != "root" ]]
then
    printf "%b\n\n\n" "${WHITE} This script must be run as ${YELLOW} root ${WHITE} or with ${YELLOW} sudo!"
	exit 1
fi


## Full install, config and launch of the nym-mixnode

cd ~	
while [ ! -d /home/nym ] ; 
do
	useradd -U -m -s /sbin/nologin nym
	printf "%b\n\n\n"
	printf "%b\n\n\n" "${YELLOW} Creating ${WHITE} nym user\n\n"
	if ls -a /home/ | grep nym > /dev/null 2>&1
	then
		printf "%b\n\n\n" "${WHITE} User ${YELLOW} nym ${LGREEN} created ${WHITE} with a home directory at ${YELLOW} /home/nym/"
	else
		printf "%b\n\n\n" "${WHITE} Something went ${RED} wrong ${WHITE} and the user ${YELLOW} nym ${WHITE}was ${RED} not created."
	fi
done
	
cd /home/nym/ || printf "%b\n\n\n" "${WHITE}failed sorry"
if [ ! -e /home/nym/nym-mixnode_linux_x86_64 ] ; 
then
	if	
		cat /etc/passwd | grep nym > /dev/null 2>&1
	then
		printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
		printf "%b\n\n\n" "${YELLOW} Downloading ${WHITE} nym-mixnode binaries for the nym user ..."
		cd /home/nym && curl -LO https://github.com/nymtech/nym/releases/download/v0.10.1/nym-mixnode_linux_x86_64
		printf "%b\n\n\n"
		printf "%b\n\n\n" "${WHITE} nym-mixnode binaries ${LGREEN} successfully downloaded ${WHITE}!"
	else
		printf "%b\n\n\n"
		printf "%b\n\n\n" "${WHITE} Download ${RED} failed..."
	fi
fi

#    nym_chmod			
if ls -la /home/nym/ | grep nym-mixnode_linux_x86_64 > /dev/null 2>&1
then
	printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
	printf "%b\n\n\n" "${WHITE} Making the nym binary ${YELLOW} executable ..."
	chmod 755 /home/nym/nym-mixnode_linux_x86_64
	printf "%b\n\n\n" "${LGREEN} Successfully ${WHITE} made the file ${YELLOW} executable !"
else
	printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
	printf "%b\n\n\n" "${WHITE} Something went ${RED} wrong, wrong path..?"
fi
		
#    nym_chown
chown -R nym:nym /home/nym/
printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
printf "%b\n\n\n" "${WHITE} Changed ownership of all conentes in ${YELLOW}/home/nym/ ${WHITE} to ${YELLOW}nym:nym"
	 	 
#    nym_init
ip_addr=`curl -sS ipv4.icanhazip.com`
	
printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
printf "%b\n\n\n" "${YELLOW} Configuration ${WHITE} file and keys: "
if
    pwd | grep /home/nym > /dev/null 2>&1
then
	printf "%b\n\n\n" "${WHITE} Your node name will be ${YELLOW} 'NymMixNode'. ${WHITE} Use it nextime if you restart your server or the node is not running"
	printf "%b\n\n\n"
	sleep 2
	sleep 1     
	layer=(1 2 3)   
	rand1=$[$RANDOM % ${#layer[@]}]
	layer1=${layer[$rand1]}
	printf "%b\n\n\n" "${WHITE} Layer: ${YELLOW} ${layer1} "
	sleep 1      
	sudo -u nym -H ./nym-mixnode_linux_x86_64 init --id 'NymMixNode' --host $ip_addr --layer $layer1 
	printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
	# borrows a shell for nym user to initialize the node config.
	printf "%b\n\n\n"
	printf "%b\n\n\n" "${WHITE}  Your node has id ${YELLOW} 'NymMixNode' ${WHITE} with ip ${YELLOW} $ip_addr ${WHITE}... "
	printf "%b\n\n\n" "${WHITE} Config was ${LGREEN} built successfully ${WHITE}!"
else
	printf "%b\n\n\n" "${WHITE} Something went ${RED} wrong {WHITE}..."
	exit 2
fi

#	nym_systemd_print
printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
printf "%b\n\n\n" "${YELLOW} Creating ${WHITE} a systemd service file to run nym-mixnode in the background: "
directory='NymMixNode'
	printf '%s\n' "[Unit]" > /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "Description=Nym Mixnode (0.11.0)" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "[Service]" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "User=nym" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "ExecStart=/home/nym/nym-mixnode_linux_x86_64 run --id NymMixNode" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "KillSignal=SIGINT" >> /etc/systemd/system/nym-mixnode.service				
	printf '%s\n' "Restart=on-failure" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "RestartSec=30" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "StartLimitInterval=350" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "StartLimitBurst=10" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "LimitNOFILE=65535" >> /etc/systemd/system/nym-mixnode.service			
	printf '%s\n' "" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "[Install]" >> /etc/systemd/system/nym-mixnode.service
	printf '%s\n' "WantedBy=multi-user.target" >> /etc/systemd/system/nym-mixnode.service

	kitu=$(pwgen 14 1)
	telegram=@${kitu}
	location=(Nuremberg Helsinki CapeTown Dubai Iowa Frankfurt Toronto Netherlands Berlin Bayern London Toulouse Amsterdam Nuremberg Virginia Montreal Miami Stockholm Tokyo Barcelona Singapore)
	rand=$[$RANDOM % ${#location[@]}]
	location1=${location[$rand]}	
	printf '%s\n' "nym" >> /root/data.txt
	printf '%s\n' "${kitu}" >> /root/data.txt
	printf '%s\n' "$(grep -v ^- /home/nym/.nym/mixnodes/NymMixNode/data/public_identity.pem |  openssl base64 -A -d | base58 ; echo)" >> /root/data.txt
	printf '%s\n' "$(grep -v ^- /home/nym/.nym/mixnodes/NymMixNode/data/public_sphinx.pem |  openssl base64 -A -d | base58 ; echo)" >> /root/data.txt
	printf '%s\n' "${ip_addr}:1789" >> /root/data.txt
	printf '%s\n' "$(sudo cat /home/nym/.nym/mixnodes/NymMixNode/config/config.toml | grep layer | cut -d'=' -f 2)" >> /root/data.txt
	printf '%s\n' "${location1}" >> /root/data.txt	
	printf '%s\n' "$(sudo /home/nym/nym-mixnode_linux_x86_64  sign --id /home/nym/.nym/mixnodes/NymMixNode --text ${telegram} | grep -i "/claim")" >> /root/data.txt
	printf '%s\n' "" >> /root/data.txt
  	printf '%s\n' "---" >> /root/data.txt	
  	printf '%s\n' "" >> /root/data.txt
if [ -e /etc/systemd/system/nym-mixnode.service ]
then
	printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
	printf "%b\n\n\n" "${WHITE} Your node with id ${YELLOW} $directory ${WHITE} was ${LGREEN} successfully written ${WHITE} to the systemd.service file \n\n\n"
	printf "%b\n\n\n" " ${LGREEN} Enabling ${WHITE} it for you"
	systemctl enable nym-mixnode
	printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
	printf "%b\n\n\n" "${WHITE}   nym-mixnode.service ${LGREEN} enabled!"
else
	printf "%b\n\n\n" "${WHITE} something went wrong"
	exit 2
fi
					
printf "%b\n\n\n"
printf "%b\n\n\n" "${YELLOW} Launching NymMixNode ..."
systemctl start nym-mixnode.service

## Check if the node is running successfully
if
	systemctl status nym-mixnode | grep -e "active (running)" > /dev/null 2>&1
then
	printf "%b\n\n\n"
	printf "%b\n\n\n" "${WHITE} Your node ${YELLOW} ${service_id} ${WHITE} is ${LGREEN} up ${WHITE} and ${LGREEN} running!!!!"
else
	printf "%b\n\n\n" "${WHITE} Node is ${RED} not running ${WHITE} for some reason ...check it ${LBLUE} ./nym-install.sh -s [--status]"
fi	

	
printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
printf "%b\n" "${WHITE}                           			  NYM ! "
printf "%b\n\n\n"
printf "%b\n" "${LGREEN}                            https://nymtech.net/docs/"
printf "%b\n\n\n"
printf "%b\n" "${WHITE}                              Check the dashboard"
printf "%b\n\n\n"
printf "%b\n" "${LBLUE}                     https://testnet-finney-explorer.nymtech.net"
printf "%b\n\n\n"
printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
