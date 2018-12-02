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
# Efface toutes les regles et tables deja existantes
sudo iptables -t filter -P FORWARD DROP
sudo iptables -t filter -P OUTPUT DROP

# Garder les connexions etablies
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Autoriser loopback
sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A OUTPUT -i lo -j ACCEPT

# Autoriser ICMP
sudo iptables -t filter -A INPUT -p icmp -j ACCEPT
sudo iptables -t filter -A OUTPUT -p icmp -j ACCEPT

# Autoriser SSH
sudo iptables -t filter -A INPUT -p tcp --dport [port ssh] -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport [port ssh] -j ACCEPT

# Autoriser DNS
sudo iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
```

Les deux premieres lignes vont supprimer toutes les regles et tables deja existantes

Le deuxieme point va garder les connexions deja etablies

Le troisieme point va autoriser les loopback (systeme qui renvoie un signal recu vers son envoyeur sans traitement)

Le quatrieme point va aurotiser le ICMP (Internet Control Message Protocol), protocole de gestion d'erreur de transmission

Le cinquieme point va autoriser la connexion SSH sur le port SSH definit dans un point precedent

Le dernier point va autoriser les connexions au DNS, aussi bien sur le protocole TCP qu'UDP
