#!/usr/bin/env bash
# manage quartus virtual machine
# wykys 2019

VM="quartus"                                       # virtual machine name
USER="wykys"                                       # user name
IDE="/opt/intelFPGA_lite/18.1/quartus/bin/quartus" # quartus bin path

run_ide () {
  ssh -X -p2222 $USER@localhost $IDE
}

if [ "$1" = "-h" ]; then
    echo "usage: quartus [-h] [-p] [-r] [-o]"
    echo ""
    echo "This script makes it easy to control a virtual machine and"
    echo "run the Quartus II IDE on it."
    echo ""
    echo "    quartus       starts the virtual machine and then starts quartus,"
    echo "                  or just starts quartus when the virtual machine is"
    echo "                  running"
    echo ""
    echo "    quartus -p    power off the virtual machine"
    echo ""
    echo "    quartus -r    reboot the virtual machine"
    echo ""
    echo "    quartus -o    it only starts the virtual machine"
    echo ""
    echo "    quartus -h    show this help message and exit"    
elif VBoxManage list runningvms | grep $VM > /dev/null ; then    
    if [ "$1" = "-r" ]; then
        VBoxManage controlvm $VM reset        
    elif [ "$1" = "-p" ]; then
        VBoxManage controlvm $VM poweroff        
    elif [ "$1" != "-o" ]; then
        run_ide
    fi
else
    VBoxManage startvm $VM --type headless
    if [ "$1" != "-o" ]; then
        run_ide
    fi
fi
