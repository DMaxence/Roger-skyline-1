#1 : Creation dossier dans le sgoinfre
	mkdir /Volumes/Storage/goinfre/<login>/vagrant
	echo 'export VAGRANT_HOME=/Volumes/Storage/goinfre/<login>/vagrant' >> ~/.zshrc

#2 : Creation du VagrantFile
	cd /Volumes/Storage/goinfre/maduhoux/vagrant
	vagrant init Debian/stretch64
	vagrant plugin install vagrant-disksize
	vim VagrantFile
	[ajouter juste avant la ligne end]
		config.disksize.size = "8GB"
		config.vm.synced_folder ".", "/git"

#3 : changer le dossier par defaut des VMs VirtualBox
	ouvrir les parametres
	changer le chemin dans General>Default

#3 : Commandes vagrant a lancer
	vagrant plugin install vagrant-vbguest
	vagrant up
	vagrant vbguest

#4 : connexion a la VM
	lancer 'vagrant ssh' afin de se connecter
