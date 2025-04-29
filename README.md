# Cornucopias File Node Installer For Ubuntu
An easy to use installer for the copi file node to take the complexity out of deploying on Ubuntu using the terminal.

# Instructions
Copy and paste the code below into the terminal of your Ubuntu vps/node and follow the on-screen instructions.  If you need to paste code into terminal use Ctrl + Shift + V or right click on the terminal can work too.  If you do something wrong and want to quit and start again just press Ctrl + C to cancel and then you can run the uninstall code below, before starting all over again with the Install code.

This is barely even beta code so there might be issues which will be worked on and fixed as we go.

Cheers!

# Install File Node
```
rm -rf installfilenode.sh
wget -O installfilenode.sh https://raw.githubusercontent.com/Geordie-R/copi-file-node/refs/heads/main/installfilenode.sh
chmod +x installfilenode.sh
./installfilenode.sh
```

# Upgrade File Node
```
rm -rf upgradefilenode.sh
wget -O upgradefilenode.sh https://raw.githubusercontent.com/Geordie-R/copi-file-node/refs/heads/main/upgradefilenode.sh
chmod +x upgradefilenode.sh
./upgradefilenode.sh
```


# Uninstall File Node
```
rm -rf uninstallfilenode.sh
wget -O uninstallfilenode.sh https://raw.githubusercontent.com/Geordie-R/copi-file-node/refs/heads/main/uninstallfilenode.sh
chmod +x uninstallfilenode.sh
./uninstallfilenode.sh
```
