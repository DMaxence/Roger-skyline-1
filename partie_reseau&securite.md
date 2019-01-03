# **Partie obligatoire**

## #1 : **Mettre a jour les paquets**

`sudo apt-get update`

`sudo apt-get upgrade`

`sudo apt-get install sudo`

## #2 : **Creation d'un user & se connecter**

`sudo adduser [user]`

`su - [user]`

ajout de l'utilisateur dans le fichier `sudoers` qui lui permettra d'utiliser la commande **sudo**

`usermod -aG sudo [user]`

## #3 : **Configuration Interfaces Reseaux**

editer le fichier `/etc/network/interfaces`

modifier la derniere ligne de `iface eth0 inet dhcp` a `iface eth0 inet static`

modifier la partie #Primary network interfaces pour :
```
auto enp0s3
iface enp0s3 inet static
->	address 192.168.1.1
->	netmask 255.255.255.252
```

puis effectuer la commande `ip a` afin de lister les interfaces reseaux, noter le nom de la 2e interface pour ajouter
```
auto [2e interface]
iface [2e interface] inet dhcp
```

la 2e interface sert a donner l'acces internet a la VM

Puis redemarrer la VM

## #4 **Changer le port SSH**

editer le fichier `/etc/ssh/sshd_config`

modifier la ligne `#Port 22` pour mettre le port voulu (sans le #)

modifier la ligne `#PermitRootLogin [...]` vers `PermitRootLogin no`

modifier la ligne `#PasswordAuthentication [...]` vers `PasswordAuthentication no`

redemarrer le service ssh avec la commande suivante `sudo /etc/init.d/ssh restart`

generer une **publick keys** depuis l'hote de la VM a l'aide de la commande `ssh-keygen`

copier le contenu du fichier `~/.ssh/id_rsa.pub` depuis la machine hote vers la VM dans le fichier `~/.ssh/authorized_keys` depuis la session a laquelle on souhaite se connecter

## #5 **Firewall**

Effectuer les commandes suivantes :

```
#Nettoyage des règles existantes
iptables -t filter -F
iptables -t filter -X

# Blocage total
sudo iptables -t filter -P INPUT DROP
sudo iptables -t filter -P FORWARD DROP
sudo iptables -t filter -P OUTPUT DROP

# Garder les connexions etablies
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Autoriser loopback
sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A OUTPUT -i lo -j ACCEPT

# Refuser les requetes ICMP (ping)
sudo iptables -t filter -A INPUT -p icmp -j DROP
sudo iptables -t filter -A OUTPUT -p icmp -j DROP

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

Le deuxieme point va bloquer par defaut toutes les connexions

Le troisieme point va garder les connexions deja etablies

Le quatrieme point va autoriser les loopback (systeme qui renvoie un signal recu vers son envoyeur sans traitement)

Le cinquieme point va aurotiser le ICMP (Internet Control Message Protocol), protocole de gestion d'erreur de transmission

Le sixieme point va autoriser la connexion SSH sur le port SSH definit dans un point precedent

Les septieme et huitieme points autorisent la connexion sur les ports HTTP (80) et HTTPS (443)

Le dernier point va autoriser les connexions au DNS, aussi bien sur le protocole TCP qu'UDP

## #6 **Protection DOS**

```
# Bloque les paquets invalides
iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

# Bloque les nouveaux paquets qui n'ont pas le flag tcp syn
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

## #7 **Protection de scans de ports**

```
# Protection scan de ports
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j ACCEPT
```

Ces deux lignes protegent le scan de ports

## #8 **Arreter les services**

??

## #9 **Script de mise a jour des packages**

Editer le script :

`sudo nano /var/log/script_log.sh`

Et y mettre les lignes suivantes :

```
#!/bin/bash
apt-get dist-upgrade >> /var/log/update_script.log
apt-get update >> /var/log/update_script.log
```

Ne pas oublier de lui attribuer les droits d'execution :

`sudo chmod 755 /var/log/script_log.sh`

Ainsi que de lui donner l'utilisateur root afin qu'il n'y ai pas besoin d'utiliser sudo :

`sudo chown root /var/log/script_log.sh`

Afin d'automatiser son execution, on utilisa la commande crontab suivante :

`??`

## #10 **Script de surveillance du fichier crontab**

Editer le script :

`sudo nano /etc/script_crontab.sh`

Et y mettre les lignes suivantes :

```
#!/bin/bash

if [ -f /etc/crontab_md5 ]
then
	oldmd5=`cat /etc/crontab_md5`
	testmd5=`md5sum /etc/crontab`
	if [ $oldmd5 -ne $testmd5 ]
		mail -s 'Crontab modification' root
	fi
else
	md5sum /etc/crontab > /etc/crontab_md5
	chmod 644 /etc/crontab_md5
fi
exit
```

Ne pas oublier de lui attribuer les droits d'execution :

`sudo chmod 755 /etc/script_crontab.sh`

Ainsi que de lui donner l'utilisateur root afin qu'il n'y ai pas besoin d'utiliser sudo :

`sudo chown root /etc/script_crontab.sh`

Afin d'automatiser son execution, on utilisa la commande crontab suivante :

`??`

# **BONUS**

## **Installation Apache**

`sudo apt-get install apache2`

Puis lancer le servie apache

`sudo systemctl start apache2`

## **Mise en place d'un virtual host**

Creation du dossier avec le nom du host voulu

`sudo mkdir -p /var/www/init.login.fr/html`

Changement des droits lie au dossier

`sudo chown -R $USER:$USER /var/www/init.login.fr/html`

Puis pour s'assurer que le dossier possede tous les droits :

`sudo chmod -R 755 /var/www/init.login.fr`

Creation d'un fichier pour tester la bonne fonctionnalite du sereveur :

`nano /var/www/init.login.fr/html/index.html`

Pour y mettre le code suivant :

```
<html>
    <head>
        <title>Roger-Skyline</title>
    </head>
    <body>
        <h1>Super ! Le serveur est fonctionnel</h1>
    </body>
</html>
```

Afin de permettre a apache fournir ce contenu, il fautl lui attribuer les bonnes instructions :

`sudo nano /etc/apache2/sites-available/init.login.fr.conf`

Et y mettre a l'interieur :

```
<VirtualHost *:80>
    ServerAdmin admin@example.com
    ServerName init.login.fr
    ServerAlias init.login.fr
    DocumentRoot /var/www/init.login.fr/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
