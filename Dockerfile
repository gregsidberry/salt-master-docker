FROM ubuntu:16.04

CMD ["/bin/bash"]
SHELL ["/bin/bash", "-c"]

#update apt, add repos, and install packages to make life easier
RUN apt-get update
RUN apt-get install -y apt-transport-https ca-certificates curl software-properties-common

#add key
RUN curl -k -ssl https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -

#add repo
RUN add-apt-repository "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main"

#update
RUN apt-get update

#debian repo for dumb-init
#http://ftp.us.debian.org/debian/pool/main/d/dumb-init/

RUN curl -k -ssl -O http://ftp.us.debian.org/debian/pool/main/d/dumb-init/dumb-init_1.2.0-1_amd64.deb
RUN dpkg -i dumb-init_*.deb


#Salt time

#install
RUN apt-get install -y openssh-server salt-master ntp salt-ssh salt-cloud

#SEC / Will work on later (harden ssh, user)

#todo - fix permissons
#RUN mkdir -p /var/run/sshd

#add admin user
RUN useradd -ms /bin/bash  admin

#Set new passwords
RUN echo "root:password" | chpasswd
RUN echo "admin:password" | chpasswd

#Downgrade from root user
#USER admin

#todo - config ssh, sudo, firehol
#RUN apt-get install -y sudo firehol

#Expose Salt Master ports
EXPOSE 4505 4506


CMD ["dumb-init","/usr/bin/salt-master" ]  

