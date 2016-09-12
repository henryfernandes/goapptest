#!/bin/bash
sudo yum remove epel-release -y
rm -rf epel-releas*
wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

sudo rpm -ivh epel-release-6-8.noarch.rpm

sudo yum install ansible -y
sudo yum install git -y

#sudo adduser --home /home/deployer --shell /bin/bash deployer
sudo groupadd -g 9999 -r deployer
sudo useradd -m -d /home/deployer -s /bin/bash -u 999 -g 9999 deployer
sudo echo dep123 | passwd deployer --stdin

#sudo mkdir /home/deployer/.ssh
sudo sed -i '/NOPASSWD/ a deployer	ALL=(ALL)      NOPASSWD: ALL' /etc/sudoers

sudo su - deployer  <<'EOF'
echo "#Get godeploy git repo" #Get godeploy git repo
git clone https://github.com/henryfernandes/godeploy.git

echo "Create SSH keys"#Create SSH keys
cd ~/godeploy/files; rm -rf id_rsa.pub id_rsa authorized_keys
ssh-keygen -t rsa -b 4096 -N "" -f ~/godeploy/files/id_rsa
cp ~/godeploy/files/id_rsa.pub  ~/godeploy/files/authorized_keys -R
cp ~/godeploy/files/id_rsa.pub  ~/godeploy/goapp/authorized_keys -R
cp ~/godeploy/files/id_rsa.pub  ~/godeploy/jenkins/authorized_keys -R


echo "#run playbook" #run playbook
cd ~/godeploy/playbooks/
ansible-playbook -i hosts  -c local -s localsetup.yml

host1=`sudo docker inspect app1 | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;
host2=`sudo docker inspect app2 | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;

sed -i "/appserver/a ${host2}" hosts
sed -i "/appserver/a ${host1}" hosts

sed -i "s/host1/${host1}/g" ~/godeploy/nginx/default.conf
sed -i "s/host2/${host2}/g" ~/godeploy/nginx/default.conf

sed -i "s/host1/${host1}/g" ~/godeploy/jenkins/Dockerfile
sed -i "s/host2/${host2}/g" ~/godeploy/jenkins/Dockerfile


ansible-playbook -i hosts  -c local nginxserver.yml
ansible-playbook -i hosts  -c local jenkinsserver.yml

nix1=`sudo docker inspect gonginx | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;
sed -i "/nginxserver/a ${nix1}" hosts

EOF
