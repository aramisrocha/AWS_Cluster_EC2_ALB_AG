#!/bin/bash 
    sudo su 
    yum update -y 
    yum install httpd -y 
    systemctl start httpd 
    systemctl enable httpd 
    echo "<html><h1> Bem vindo ao LAB01 do Aramis você esta no host $(hostname -f) </h1></html>" >> /var/www/html/index.html 