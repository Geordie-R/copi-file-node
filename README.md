# Cornucopias File Node Installer For Ubuntu
An easy to use installer, uninstaller and upgrader for the copi file node to take the complexity out of deploying on Ubuntu using the terminal.

# Instructions
If you have come here just for the upgrade code, do not run the installer and uninstaller code.

Connect to your node and then once you are in, copy and paste the code you need below into the terminal of your Linux/Ubuntu node and follow the on-screen instructions.  If you need to paste code into terminal use Ctrl + Shift + V or right click on the terminal can work too.  If you do something wrong and want to quit and start again just press Ctrl + C to cancel and then you can run the uninstall code below, before starting all over again with the Install code.

If you just want to upgrade your node and replace the pool access key ONLY use the Upgrade File Node script.

Cheers!

# Install File Node
```
rm -rf installfilenode.sh
wget -O installfilenode.sh https://raw.githubusercontent.com/Geordie-R/copi-file-node/refs/heads/main/installfilenode.sh
chmod +x installfilenode.sh
./installfilenode.sh
```

# Upgrade File Node
Video here (no sound got it done in a rush): https://geordier.co.uk/downloads/copi_linux_upgrade_nosound.mp4
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
