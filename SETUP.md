# Setup the Pi

If you're starting from scratch, start here at Step 1.


1. Prepare the memory card with the latest [Rasbian xxx Lite](https://www.raspberrypi.org/downloads/raspbian/) image. (This process has been tested with "Buster").
2. Add HDMI, power and keyboard connections and turn it on. (You don't need a mouse for this, but add one if you're feeling so inclined).
3. The boot process ends at a login screen. The default credentials are `pi` / `raspberry`.
4. Login.
5. Now we'll perform the basic customisation steps:
6. Run `sudo raspi-config`.
7. Select `(4) Localisation Options` then:
    * `(I3) - change keyboard layout`
    I've never needed to do anything but accept the defaults here. I found the Pi stopped responding for >10s after selecting "no compose key", so just wait for it and it will take you back to the main page.
8. Return to (4) and set `(I2) the timezone`. Select the appropriate options and you'll be returned to the menu.
9. Select `(5) - Interfacing Options`
    * `(P2) Enable SSH` and at the prompt "Would you like the SSH server to be enabled?" change the selection to `<Yes>` and hit return, then return again at the `OK`.
10. If you're building this onto a Pi with a wired network connection instead of WiFi, skip the next step. Resume at Step 14.
11. Select `(2) Network Options` and `Hostname` and give the Pi a recognisable hostname.
12. Navigate to `Finish` and DECLINE the prompt to reboot.
13. Run `ifconfig`. In the output, look under "eth0" for wired and "wlan0" for WiFi. There should be a line starting with "inet" followed by an IP address. The absence of this means you're not on a network.

14. Assuming success above, you'll probably want to set a static IP. If you're OK with a dynamic IP (or at least are for the time being) jump to Step 16.
15. Run `sudo nano /etc/dhcpcd.conf`. Add the lines shown, customising the addresses to suit your network:

```txt
interface wlan0
static ip_address=192.168.1.10/24
static routers=192.168.1.254
static domain_name_servers=192.168.1.254
```
> If you have more than one DNS server, add them on the same line with each separated by a space
16. Reboot the Pi to pickup its new IP address and lock in all the changes made above, including the change to the hostname: `sudo reboot now`

17. After it reboots, check it's on the network OK by typing `ifconfig` and check the output now shows the entries you added in Step 15.
(Alternatively, just see if it responds to pings and you can SSH to it on its new IP).

## Remote config via SSH

At this point I abandoned the keyboard and monitor, continuing the config steps from my PC.

18. SSH to the Pi using your preferred client. If you're using Windows 10 you can just do this from a PowerShell window: `ssh <TheIpAddressFromStep18> -l pi` (Note that's a lower-case L).
19. You should see something like this:
```txt
The authenticity of host '192.168.1.10 (192.168.1.10)' can't be established.
ECDSA key fingerprint is SHA256:Ty0Bw6IZqg1234567899006534456778sFKT6QakOZ5PdJk.
Are you sure you want to continue connecting (yes/no)?
```
20. Enter `yes` and press Return
21. The response should look like this:
```txt
Warning: Permanently added '192.168.1.10' (ECDSA) to the list of known hosts.
pi@192.168.1.10's password:
```
22. Enter the password and press Return.
23. It's STRONGLY recommended that you change the password. Run `passwd` and follow your nose.

## Here's where all the software modules are installed. This might take a while:

24. First let's make sure the Pi is all up-to-date:
```txt
sudo apt-get update && sudo apt-get upgrade -y
```

> If this ends with an error "Some index files failed to download. They have been ignored, or old ones used instead." just press up-arrow and return to retry the command. You want to be sure the Pi is healthy and updated before continuing.

25. `sudo reboot now`

Your SSH session will end here. Wait for the Pi to reboot, sign back in again and continue.

26. We need to install Subversion so we can download *just* the needed bits of the repo from GitHub:
```txt
sudo apt-get install subversion -y
```
27. This downloads the repo, dropping the structure into the home directory:
```txt
svn export https://github.com/greiginsydney/Homebridge-cbus-installer/trunk/code/ ~ --force
```

> Advanced tip: if you're testing code and want to install a new branch direct from the repo, replace "/trunk/" in the link above with `/branches/<TheBranchName>/`

28. All the hard work is done by a script in the repo, but it needs to be made executable first:
```txt
sudo chmod +x setup.sh
```
29. Now run it! (Be careful here: the switches are critical. "-E" ensures your user path is passed to the script. Without it the software will be moved to the wrong location, or not at all. "-H" passes the Pi user's home directory.)
```txt
sudo -E -H ./setup.sh step1
```

> If any step fails, the script will abort and on-screen info should reveal the component that failed. You can simply re-run the script at any time (up-arrow / return) and it will simply skip over those steps where no changes are required. There are a lot of moving parts in the Raspbian/Linux world, and sometimes a required server might be down or overloaded. Time-outs aren't uncommon, hence why simply wait and retry is a valid remediation action.

30. If all goes well, you'll be presented with a prompt to reboot:
```txt
Exited step 1 OK.
Reboot now? [Y/n]:
```
Pressing return or anything but n/N will cause the Pi to reboot.

31. After the Pi has rebooted, sign back in again and resume. The next step is to re-run the script, but with a new switch:
```txt
sudo -E ./setup.sh step2
```

32. The script will now move some of the supporting files from the repo to their final homes, and edit some of the default config in the Pi. 

It will output its progress to the screen:
```txt
pi@raspberrypi:~ $ sudo -E ./setup.sh step2
'homebridge.service' -> '/etc/systemd/system/homebridge.service'
'homebridge.timer' -> '/etc/systemd/system/homebridge.timer'
'homebridge' -> '/etc/nginx/sites-available/homebridge'
```
