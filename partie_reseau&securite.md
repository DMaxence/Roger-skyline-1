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

# Autoriser HTTP
sudo iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT

# Autoriser HTTPS
sudo iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 8443 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT

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

Les sixieme et septieme points autorisent la connexion sur les ports HTTP (80) et HTTPS (443)

Le dernier point va autoriser les connexions au DNS, aussi bien sur le protocole TCP qu'UDP

#5 **Protection DOS**

```
# Bloque les paquets invalides
iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

# Bloque les paquets non synchronisé
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# Bloque les valeurs MSS anormal
iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

# Limite les nouvelles connexions
sudo iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
sudo iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

# Limite les connections
sudo iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# Protection Synflood
sudo iptables -A INPUT -p tcp --syn -m limit --limit 2/s --limit-burst 30 -j ACCEPT

# Protection Pingflood
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

```

Le premier point bloque les paquets invalides sur tous les ports

Le deuxieme point bloque les paquets non synchronises (nouveaux paquets, non present sur la connexion deja etablie)

Le troisieme point bloque les valeurs MSS (Maximum Segment Size), c'est la quantite d'octets qu'un appareil peut contenir dans un seul paquet non fragmente.
Au dela de cette MSS on sait que c'est un paquet errone

Le quatrieme point limite le nombre de nouvelle connexions qu’un client peut établir par seconde

Le cinquieme point limite le nombre de connexions a 25 par minute

Le sixieme point effectue une protection contre les attaques de type Synflood

Le septieme point effectue une protection contre les attaques de type Pingflood

#6 **Protection de scans de ports**

```
# Protection scan de ports
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 1/h -j ACCEPT
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j ACCEPT
```

Ces deux lignes protegent le scan de ports
