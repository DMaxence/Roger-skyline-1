#1 : **Mettre a jour les paquets**

`sudo apt-get update`

`sudo apt-get upgrade`

#2 : **Creation d'un user & se connecter**

`sudo adduser [user]`

`su - [user]`

#3 : **Configuration DHCP**

editer le fichier `/etc/network/interfaces`

modifier la derniere ligne de `iface eth0 inet dhcp` a `iface eth0 inet static`

ajouter en dessous les lignes
```
iface eth0 inet static
->	address 192.168.1.101
->	netmask 255.255.255.252
```

#3 **Changer le port SSH**

editer le fichier `/etc/ssh/sshd_config`

modifier la ligne `#Port 22` pour mettre le port voulu

modifier la ligne `#PermitRootLogin [...]` vers `#PermitRootLogin no`

redemarrer le service ssh avec la commande suivante `sudo /etc/init.d/ssh restart`

generer une **publick keys** a l'aide de la commande `ssh-keygen`

#4 **Firewall**

Effectuer les commandes suivantes :

```
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport [port ssh defini dans un point precedent] -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport [port ssh defini dans un point precedent] -m state --state ESTABLISHED -j ACCEPT
```

Les deux premieres lignes vont supprimer tous les champs deja existant dans le fichier iptables

Les deux lignes du milieu vont ajouter en regle INPUT le port a accepter uniquement, on l'occurence le port SSH

Les deux lignes du bas vont ajouter en regle OUTPUT le port a accepter uniquement, on l'occurence le port SSH


/******************************************************
*******************************************************
******************PARTIE BOLDO*************************
*******************************************************
******************************************************/
