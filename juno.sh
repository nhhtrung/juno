#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 3
echo -e '\n\e[42mSet up swapfile\e[0m\n'
curl -s https://api.nodes.guru/swap4.sh | bash
echo -e '\n\e[42mInstall dependencies\e[0m\n' && sleep 1
sudo apt update
curl https://deb.nodesource.com/setup_14.x | sudo bash
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt install make clang pkg-config libssl-dev build-essential git curl ntp jq llvm protobuf-compiler nodejs -y < "/dev/null"
echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
wget -O go1.16.3.linux-amd64.tar.gz https://golang.org/dl/go1.16.3.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.16.3.linux-amd64.tar.gz && rm go1.16.3.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
echo -e '\n\e[42mGo version:\e[0m'
echo $(go version)&& sleep 1
echo -e '\n\e[42mInstall Git LFS\e[0m' && sleep 1
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs -y < "/dev/null"
git lfs install
echo -e '\n\e[42mClone repo\e[0m' && sleep 1
git clone https://github.com/tendermint/starport
echo -e '\n\e[42mBuild repo\e[0m' && sleep 1
cd starport && git checkout develop
make
echo -e '\n\e[42mSet chain id\e[0m' && sleep 1
echo 'export junoChainID=lucina' >> $HOME/.bash_profile && . $HOME/.bash_profile
source $HOME/.bash_profile
echo -e '\n\e[42mjunoChainID:\e[0m'
echo $junoChainID && sleep 1
echo -e '\n\e[42mPreparation finished!\e[0m'
echo -e '\n\e[42mInstalling Juno...\e[0m'
cd $HOME
git clone https://github.com/CosmosContracts/Juno
cd Juno
starport chain build
wget -O .juno/config/genesis.json https://raw.githubusercontent.com/CosmosContracts/testnets/main/lucina/genesis.json
shasum -a 256 .juno/config/genesis.json
sed -i "s/log_level *=.*/log_level = \"info\"/g" .juno/config/config.toml
junod unsafe-reset-all
sudo tee <<EOF >/dev/null /etc/systemd/system/junod.service
[Unit]
Description=Juno daemon
After=network-online.target
[Service]
User=root
ExecStart=$HOME/go/bin/junod start --p2p.laddr tcp://0.0.0.0:26656 --home $HOME/.juno
Restart=on-failure
RestartSec=3
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl restart junod
echo -e '\n\e[42mDone!\e[0m'
