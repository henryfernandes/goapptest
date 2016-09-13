#!/bin/bash
sudo yum remove epel-release -y
rm -rf epel-releas*
wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

sudo rpm -ivh epel-release-6-8.noarch.rpm
rm -rf epel-releas*

sudo yum install ansible -y
sudo yum install git -y

#sudo adduser --home /home/deployer --shell /bin/bash deployer
sudo groupadd -g 1000 -r deployer
sudo useradd -m -d /home/deployer -s /bin/bash -u 1000 -g 1000 deployer
sudo echo dep123 | passwd deployer --stdin

#sudo mkdir /home/deployer/.ssh
if sudo grep -q "deployer" /etc/sudoers
   then
     echo "already added to sudoers"
else 
      sudo sed -i '/NOPASSWD/ a deployer	ALL=(ALL)      NOPASSWD: ALL' /etc/sudoers
     echo "not exist"
fi

sudo su - deployer  <<'EOF'
echo "#Get godeploy git repo" #Get godeploy git repo
git clone https://github.com/henryfernandes/godeploy2.git

echo "Create SSH keys"#Create SSH keys
mkdir -p ~/godeploy2/files; cd ~/godeploy2/files; rm -rf id_rsa.pub id_rsa authorized_keys
ssh-keygen -t rsa -b 4096 -N "" -f ~/godeploy2/files/id_rsa
cp ~/godeploy2/files/id_rsa.pub  ~/godeploy2/goapp/authorized_keys -R


echo "#run playbook" #run playbook
cd ~/godeploy2/playbooks/
ansible-playbook -i hosts  -c local -s localsetup.yml

host1=`sudo docker inspect app1 | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;
host2=`sudo docker inspect app2 | grep IPA | grep -v Sec | awk -F"\"" '{print $4}'`;

sed -i "s/host1/${host1}/g" ~/godeploy2/nginx/default.conf
sed -i "s/host2/${host2}/g" ~/godeploy2/nginx/default.conf

ansible-playbook -i hosts  -c local nginxserver.yml


EOF
