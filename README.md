# Instalace Quartus II do virtuálního stroje
Linux Mint je mou oblíbenou linuxovou distribucí pro desktop u které jsem se po letech zkoušení nakonec usadil. Poslední dobou ke své práci potřebuji vývojové prostředí Quartus II (ve verzi 18.1), které je dostupné pro Windows a Linux. Na Windows je instalace snadná, ale chtěl jsem se mu vyhnout. Oficiální podporu má Quartus pro RHEL 6 a 7. Když jsem zkusmo nainstaloval Quarus na můj Mint 19.2, tak jsem zjistil, že je problém s verzemi spousty knihoven. To zapříčinilo nefunkčnost konfigurátoru IP jader. Proto jsem přeinstaloval na Fedoru 30. Quartus po doinstalování pár knihoven na ní fungoval bez problémů, ale já si na ni nemohl zvyknout.

Rozhodl jsem se tedy pro nový scénář. Na Linux Mint vytvořím virtuální stroj. Na kterém poběží Fedora Server 30. Serverovou verzi jsem zvolil proto, aby počítač nebyl zbytečně zatěžován virtualizováním kompletního grafického systému, ze kterého by se využívalo jedno okno. K virtuálnímu stroji se bude v rámci vnitřní sítě počítače (localhost) připojovat přes SSH. Na serveru bude nainstalován X Server, který bude grafiku pro vykreslení okna SSH tunelem předávat na X server desktopu.

## Instalace virtualizačního software
Pro virtualizace použiji [VirtualBox]([https://www.virtualbox.org) v aktuální verzi 6.0.10. Pro instalaci této verze je třeba přidat do systému nový PPA repozitáře.
```bash
# přidání ppa repozitářů
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
# aktualizovat databázi balíčků
sudo apt update
```
Poté instalace probíhá klasickou cestou pomocí správce balíčků
```bash
# instalace VirtualBoxu
sudo apt install virtualbox-6.0
```

Následně je dobré [stáhnout](https://download.virtualbox.org/virtualbox/6.0.10/Oracle_VM_VirtualBox_Extension_Pack-6.0.10.vbox-extpack) VirtualBox Extension Pack, abychom mohli používat USB 2.0.
```bash
# instalace rozšíření
virtualbox Oracle_VM_VirtualBox_Extension_Pack-6.0.10.vbox-extpack 
```

## Vytvoření virtuálního stroje
Stáhneme si ISO obraz [Fedora Server 30 (64-bit)](https://download.fedoraproject.org/pub/fedora/linux/releases/30/Server/x86_64/iso/Fedora-Server-netinst-x86_64-30-1.2.iso).
Spustíme VirtualBox a kliknutím na tlačítko `Nový` vytvoříme virtuální stroj s následujícími parametry:

| Jémo     | quartus         |
|----------|-----------------|
| Umístění | výchozí         |
| Typ      | Linux           |
| Verze    | Fedora (64-bit) |

V dalším kroku vytvoříme virtuální disk. Formát disku ponecháme výchozí `*.vdi`. Typ také výchozí, tedy flexibilní a velikost na 64GB. __Rozhodně nenastavovat velikost pod 20GB__, neboť by se na něj instalace nevešla!

## Nastavení virtuálního stroje
1. V nastavení přidělíme našemu virtuálnímu stroji podle možností procesorová jádra a paměť RAM.
2. Do CD virtuální mechaniky vložíme instalační ISO pro Fedora Server.
3. Přejdeme do nastavení sítě, necháme zde výchozí volbu NAT. Rozklikneme `Pokročilé` -> `Předávání portů`.

VirtualBox se v našem nastavení tedy chová jako NAT. Abychom mohli se serverem v rámci localhost komunikovat je třeba nastavit překlad pro SSH. Takže si vytvoříme nové pravidlo podle následující tabulky:

| Název | Protokol | IP adresa hostitele | Port hostitele | IP adresa hosta | Port hosta |
|-------|----------|---------------------|----------------|-----------------|------------|
| SSH   | TCP      | 127.0.0.1           | 2222           | 10.0.2.15       | 22         |

NAT virtuálnímu stroji přidělí adresu 10.0.2.15. SSH na hostiteli používá výchozí port 22. Adresa virtuálního stroje však bude přeložena na adresu localhost. Došlo by ke konfliktu na portech, proto je třeba nastavit předávání portu hosta 22 na port hostitele 2222. Číslo portu 2222 můžete změnit, na jakýkoliv jiný volný port.

## Instalace virtuálního stroje

### Instalace operačního systému
Virtuální stroj spustíme a nainstalujeme Fedora Server. Při instalaci je důležité si dát __pozor jakým způsobem instalátor rozdělí virtuální disk__. Pokud jej ponecháme na automatické vytvoří se kořenový oddíl o pouhé velikosti 15GB a instalace se na něj nevleze. Proto jsem vytvořil jediný kořenový oddíl přes celý disk se souborovým systémem ext4.

Po instalaci nezapomeňte vysunout z virtuální mechaniky obraz instalačního disku.

### Přejmenování virtuálního stoje
Tento bod není nezbytný, ale pokud se připojujete k více strojům může vám zpříjemnit život.
```bash
# místo quartus můžete použít libovolný název
hostnamectl set-hostname quartus
```

### SSH
K serveru je možné se připojovat pomocí SSH jen je třeba zvolit správný port.
```bash
# připojení pomocí hesla k SSH na portu 2222
ssh -p2222 wykys@localhost
```
Používání SSH usnadňují klíče, díky nim nemusíte neustále zadávat heslo. Pokud nemáte klíč vygenerován provedete to následujícím příkazem:
```bash
# vygenerování RSA klíčového páru
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# spuštění ssh agenta
eval "$(ssh-agent -s)"
# registrace vygenerovaného klíče
ssh-add ~/.ssh/id_rsa
```

Když máte svůj SSH klíč můžete jej přidat na virtuální server.
```bash
# nahraní veřejného klíče na server
ssh-copy-id wykys@localhost
```


### Instalace rozšíření hosta
Rozšíření pro hosta optimalizují jádro pro běh ve virtuálním stroji, dále umožní sdílet složky mezi hostitelským strojem a hostem a mnoho dalšího.

Pro jejich instalaci je nejprve potřeba do mechaniky vložit obraz z rozšířeními. To provedeme pomocí `Zažízení`->`Vložit obraz CD disku s přídavky pro hosta...` Které najdeme v nástrojové liště běžícího virtuálního okna.

Příkazy je nutné zadávat se správcovskými právy.

```bash
# aktualizace kernelu
dnf update kernel*
# instalace potřebných balíčků
dnf install gcc kernel-devel kernel-headers dkms make bzip2 perl libxcrypt-compat
# vytvoření proměnné s cestou k jádru
KERN_DIR=/usr/src/kernels/`uname -r`
# export proměnné
export KERN_DIR
# namountování rozšízení
mount -r /dev/cdrom /media
# změna složky
cd /media
# instalace rozšíření
./VBoxLinuxAdditions.run
# restart
reboot
```

Po instalaci je vhodné virtuální stroj restartovat aby bylo možné nabootovat optimalizované jádro a vysunout z mechaniky obraz z rozšířeními.

### Sdílené složky
Pokud potřebujete s hostitelským systémem sdílet nějaké soubory VirtualBox umožňuje v nastavení sdílet složky. Aby mohl uživatel ke sdílené složce připojované při spuštění přistoupit je nutné aby  byl členem skupiny vboxsf.
```bash
# přidání uživateli práva přistupovat ke sdíleným složkám
usermod -aG vboxsf wykys
```

### Instalace X serveru
X Server nám umožní spouštět na serveru grafické aplikace a jejich GUI přenášet pomocí SSH tunelu na hostující systém.

```bash
# instalace potřebných balíčků
dnf install  xorg-x11-server-Xorg xorg-x11-xauth xorg-x11-apps
# povolení předávání
echo "X11Forwarding yes" >> /etc/ssh/sshd_config
# resrart ssh deamona
systemctl restart sshd
```

Funkčnost si můžeme ověřit. Pokud se vče povede, tak vás bude sledovat pár očí.
```bash
# parametr -X povolí GUI
ssh -X -p2222 wykys@localhost xeyes
```

## Instalace Quastus II
Tak pomalu se blížíme do finále. Quartus potřebuje pro svůj běh doinstalovat pár knihoven a také mít nainstalovanou anglickou lokalizaci.

Ke stažení Quartus II je třeba registrace na stránkách intelu, proto zde neuvádím přímí odkaz ke stažení.

```bash
# instalace potřebných balíčků
dnf install libnsl libpng12
# instalace anglické lokalizace, potřebné jen pokud systém nemáte v angličtině
dnf install langpacks-en
# instalace Quartus II ve složce do které jsme Quartus stáhli
./setup.sh
```

Cíl instalace nastavím do `/opt/intelFPGA_lite/18.1/`

### Instalace USB Blaster
Nejprve je třeba umožnit přístup uživateli VirtualBoxu spuštěného z hostitelského počítače přístup k USB zařízením. Toho lze dosáhnout přidáním hostitelského uživatele do vhodné skupiny.
```bash
# přidání do skupiny uživatelů VirtualBoxu
sudo usermod -aG vboxusers wykys
# aby se změna projevila je třeba se znovu přihlásit nebo restart
sudo reboot
```

Poté je třeba v `Nastavení` virtuálního stroje v záložce `USB` nastavit `USB 3.0 (xHCI) řadič` a na sdílet `USB-Blaster`.

```bash
# ověření že jse nám podařilo propojit USB-Blaster s virtuálním strojem
lsusb | grep Blaster
# pokud je vše nastavené dobře uvidíme Blaster ve výpisu
# Bus 001 Device 005: ID 09fb:6001 Altera Blaster
```


Následně je potřeba nastavit ve virtuálním stroji práva pro používání USB Blasteru. K tomu stačí na server do složky `/etc/udev/rules.d/` umístit soubor `92-usbblaster.rules`.
```bash
# zkopírování pravidel pro USB Blaster na server přes SSH
scp -P2222 92-usbblaster.rules root@localhost:/etc/udev/rules.d/
```

JTAG deamon potřebuje pro svůj běh knihovnu `libudev.so.0`, ale ta v systému není a není ani v repozitářích. Dá se to ale obejít vytvořením symbolického odkazu na `libudec.so.1` knihovnu který v systému žu je.
```bash
# přechod do složky se systémovými knihovnami
cd /lib64
# vytvoření knihovny libudev.so.0 odkazem na libudev.so.1
ln -s libudev.so.1 libudev.so.0
```

Teď můžeme ověřit funkci programátoru.
```bash
# spuštění konfigurace programátoru
/opt/intelFPGA_lite/18.1/quartus/bin/jtagconfig 
# pokud je programátor rozpoznám získáme následující výpis
# 1) USB-Blaster [1-2]
#   020F10DD   10CL006(Y|Z)/10CL010(Y|Z)/..

```

### Použití
Quartus jednoduše můžeme spustit pomocí SSH tunelu.
```bash
# spuštní IDE Quartus II
ssh -X -p2222 wykys@localhost /opt/intelFPGA_lite/18.1/quartus/bin/quartus --64bit
```

Pokud vám překáží okno virtuálního stroje lze ho zapnout na pozadí následujícím příkazem a nebo podržením klávesy shift při spouštění s GUI VirtualBoxu.
```bash
# spuštní virtuálního stroje na pozadí
VBoxManage startvm quartus --type headless
```

## Skript `quartus.sh`
Pro jednodušší ovládání můžete použít můj skript `quartus.sh`, který umožňuje snadné spouštění a vypínání virtuálního stroje i Quartus II IDE.

### Instalace skriptu
Odkaz na skript je vhodné umístit do složky kterou máte zahrnutou v proměnné prostředí `$PATH`.
Já mám skript umístěný v `~/.local/bin`

```bash
git clone git@github.com:wykys/quartus.git
cd quartus
ln -s `pwd`/quartus.sh ~/.local/bin/quartus
```

### Help
```bash
usage: quartus [-h] [-p] [-r] [-o] [-s]

This script makes it easy to control a virtual machine and
run the Quartus II IDE on it.

    quartus       starts the virtual machine and then starts quartus,
                  or just starts quartus when the virtual machine is
                  running

    quartus -p    power off the virtual machine

    quartus -r    reboot the virtual machine

    quartus -o    it only starts the virtual machine

    quartus -s    opens ssh connection with a virtual machine

    quartus -h    show this help message and exit
```


### Demo
Po spuštění počítače automaticky spustí virtuální stroj na pozadí a zapne Quartus II Pokud Quartus II vypneme virtuální stroj zůstává zapnutý zopakování příkazu pouze zapne Quartus II.
```bash
# základní použití
quartus
# vypnutí virtuálního stroje 
quartus -p
```