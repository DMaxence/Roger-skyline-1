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
	address 192.168.1.101
	netmask 255.255.255.252
```

#3 **Changer le port SSH**

editer le fichier `/etc/ssh/sshd_config`
modifier la ligne `#Port 22` pour mettre le port voulu
redemarrer le service ssh avec la commande suivante `sudo /etc/init.d/ssh restart`
generer une **publick keys** a l'aide de la commande `ssh-keygen`
