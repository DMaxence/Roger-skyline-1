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

Copier les commandes suivantes dans un fichier, executer ensuite le script cree en root

```bash
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

Le cinquieme point va interdire le ICMP (Internet Control Message Protocol), le Ping

Le sixieme point va autoriser la connexion SSH sur le port SSH definit dans un point precedent

Les septieme et huitieme points autorisent la connexion sur les ports HTTP (80) et HTTPS (443)

Le dernier point va autoriser les connexions au DNS, aussi bien sur le protocole TCP qu'UDP

## #6 **Protection DOS**

Copier les commandes suivantes dans un fichier, executer ensuite le script cree en root

```bash
# Bloque les paquets invalides
iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

# Bloque les nouveaux paquets qui n'ont pas le flag tcp syn
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# Bloque les valeurs MSS anormal
iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

# Limite les nouvelles connexions
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

# Limite les nouvelles connexions si un client possede deja 80 connexions
iptables -A INPUT -p tcp -m connlimit --connlimit-above 80 -j REJECT --reject-with tcp-reset

# Limite les connections
iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# Protection Synflood
iptables -A INPUT -p tcp --syn -m limit --limit 2/s --limit-burst 30 -j ACCEPT

# Protection Pingflood
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
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

Copier les commandes suivantes dans un fichier, executer ensuite le script cree en root

```bash
# Protection scan de ports
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j ACCEPT
```

Ces deux lignes protegent le scan de ports

Afin de sauvegarder toutes ces regles et de les executer au demarrage de la machine, on doitu tiliser un package externe.

L'installer avec la commande `sudo apt-get install iptables-persistent`

Et cliquer sur `Yes` lorsque le packet demande d'enregistrer les regles dans l'iptable

## #8 **Arreter les services**

Installation graphique avec aucun services superflus installes, rien a arreter

## #9 **Script de mise a jour des packages**

Editer le script :

`sudo nano /root/scripts/script_log.sh`

Et y mettre les lignes suivantes :

```bash
#!/bin/bash
apt-get update >> /var/log/update_script.log
apt-get upgrade >> /var/log/update_script.log
```

Ne pas oublier de lui attribuer les droits d'execution :

`sudo chmod 755 /root/scripts/script_log.sh`

Ainsi que de lui donner l'utilisateur root afin qu'il n'y ai pas besoin d'utiliser sudo :

`sudo chown root /root/scripts/script_log.sh`

Afin d'automatiser son execution, on modifie le fichier crontab en root avec la commande `crontab -e`

Pour y mettre les lignes suivantes :

```
0 4 * * wed root /root/scripts/script_log.sh
@reboot root /root/scripts/script_log.sh
```

## #10 **Script de surveillance du fichier crontab**

Editer le script :

`sudo nano /root/scripts/script_crontab.sh`

Et y mettre les lignes suivantes :

```sh
#!/bin/sh

CRON_FILE=/etc/crontab
CHECK_FILE=/root/.crontab-checker

if [ ! -f $CHECK_FILE ] || [ "`md5sum < $CRON_FILE`" != "`cat $CHECK_FILE`" ]
then
    echo "The crontab file has been modified !" | mail -s "root: crontab modified" root
    md5sum < $CRON_FILE > $CHECK_FILE;
    chmod 700 $CHECK_FILE;
fi
```

Ne pas oublier de lui attribuer les droits d'execution :

`sudo chmod 755 /root/scripts/script_crontab.sh`

Ainsi que de lui donner l'utilisateur root afin qu'il n'y ai pas besoin d'utiliser sudo :

`sudo chown root /root/scripts/script_crontab.sh`

Afin d'automatiser son execution, on modifie le fichier crontab en root avec la commande `crontab -e`

Pour y mettre les lignes suivantes :

```
0 0 * * * root /root/scripts/script_crontab.sh
```

# **BONUS WEB**

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

```html
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

Puis l'activer a l'aide des commandes suivantes : 

```bash
cd /etc/apache2/sites-enabled
sudo rm 000-default.conf
sudo ln -s ../sites-available/init.login.fr.conf ./
sudo service apache2 restart
```

Afin d'activer le certificat SSL, aller dans le dossier `/etc/ssl/crt/` puis utilise la commande suivante `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout roger.key -out roger.crt`

Puis editer le fichier `/etc/apache2/sites-available/init.login.fr.conf` pour y ajouter :

```
<VirtualHost *:443>
    DocumentRoot /var/www/init.login.fr/html
    ServerName init.login.fr
    SSLEngine on
    SSLCertificateFile /etc/ssl/crt/roger.crt
    SSLCertificateKeyFile /etc/ssl/crt/roger.key
</VirtualHost>
```

Lancer la commande suivante `sudo a2enmod ssl` afin d'activer le module SSL d'apache, puis redemarrer le serveruweb `systemctl restart apache2`


# **BONUS Deploiement**

## **Installation dependances**

Installation de git `sudo apt-get install git`

Creation du dossier de git `sudo mkdir /git`

Creation du user git `sudo adduser git`

Attribution du dossier git a l'utilisateur git `sudo chown git:git /git`
Attribution du dossier html a l'utilisateur git `sudo chown git:git /var/www/init.login.fr/html`

Connexion a l'utilisateur git `su - git`

Creation d'un depot de type **bare** dans le dossier /git `git init --bare roger-skyline.git`

Ajout clef ssh dans le dossier git (en etant connecte avec l'utilisateur git)
```bash
cd ~
cp -R /home/[user_principal]/.ssh/ ~/
```

Ajout script deploiement web auto
```bash
cd /git/roger-skyline.git/hooks
nano post-receive
```

Y coller : 
```bash
#!/bin/bash

while read oldrev newrev ref
do
    if [[ $ref =~ .*/master$ ]];
    then
        echo "Deploying master branch to production..."
        git --work-tree=/var/www/init.login.fr/html --git-dir=/git/roger-skyline.git checkout -f
    else
        echo "Only master branch will be deployed to production"
    fi
done
```

Puis `chmod +x post-receive`


Afin de tester, on clone sur la machine hote de la VM `git clone git@192.168.1.2:/git/roger-skyline.git roger`
