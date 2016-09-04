#!/bin/bash
sudo yum remove epel-release -y

wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

sudo rpm -ivh epel-release-6-8.noarch.rpm

sudo yum install ansible -y
sudo yum install git -y

sudo adduser --home /home/deployer --shell /bin/bash deployer
sudo echo dep123 | passwd deployer --stdin

sudo mkdir /home/deployer/.ssh
sudo sed -i '/NOPASSWD/ a deployer ALL=(ALL)      NOPASSWD: ALL' /etc/sudoers

sudo su - deployer  <<'EOF'
echo "Create SSH keys"#Create SSH keys
rm -rf ~/.ssh/*
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
cp ~/.ssh/id_rsa.pub  ~/.ssh/authorized_keys
echo "#Get godeploy git repo" #Get godeploy git repo
git clone https://github.com/henryfernandes/godeploy.git

echo "#run playbook" #run playbook
cd godeploy/playbooks/
ansible-playbook -i hosts  -c local localsetup.yml

host1=`sudo docker inspect app1 | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;
host2=`sudo docker inspect app2 | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;

sed -i "/appserver/a ${host2}" hosts
sed -i "/appserver/a ${host1}" hosts

sed -i "s/host1/${host1}/g" /home/deployer/godeploy/nginx/default.conf
sed -i "s/host2/${host2}/g" /home/deployer/godeploy/nginx/default.conf


ansible-playbook -i hosts  -c local nginxserver.yml

nix1=`sudo docker inspect gonginx | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;
sed -i "/nginxserver/a ${nix1}" hosts

EOF
