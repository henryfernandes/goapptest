echo "Remove folders from deployer user"
sudo rm -rf /home/deployer/godeploy2 
echo "Stop running docker containers"
sudo docker stop gonginx app1 app2
echo "Remove docker containers"
sudo docker rm gonginx app1 app2
echo "Remove all docker images"
sudo docker rmi ginix goapp golang ubuntu

