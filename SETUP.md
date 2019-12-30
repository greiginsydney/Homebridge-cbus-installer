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
10. If you're building this onto a Pi with a wired network connection instead of WiFi, skip the next step. Resume at Step 12.
11. Select `(2) Network Options` and `WiFi`. When prompted:
    * Select your country
    * Enter the local SSID and passphrase (password). Note that the Pi Zero W's radio is limited to 2.4G, so any attempts to connect to a 5G network will fail.
12. Select `(2) Network Options` and `Hostname` and give the Pi a recognisable hostname.
13. Navigate to `Finish` and DECLINE the prompt to reboot.
14. Run `ifconfig`. In the output, look under "eth0" for wired and "wlan0" for WiFi. There should be a line starting with "inet" followed by an IP address. The absence of this means you're not on a network.
15. Assuming success above, you'll probably want to set a static IP. If you're OK with a dynamic IP (or at least are for the time being) jump to Step 17.
16. Run `sudo nano /etc/dhcpcd.conf`. Look for lines starting with `interface wlan0` (for WiFi), or `interface eth0` for a wired connection, customising the addresses to suit your network:

```txt
interface eth0
static ip_address=192.168.1.10/24
static routers=192.168.1.254
static domain_name_servers=192.168.1.254
```
> If you have more than one DNS server, add them on the same line with each separated by a space
17. Reboot the Pi to pickup its new IP address and lock in all the changes made above, including the change to the hostname: `sudo reboot now`.

18. After it reboots, check it's on the network OK by typing `ifconfig` and check the output now shows the entries you added in Step 16.
(Alternatively, just see if it responds to pings and you can SSH to it on its new IP).

## Remote config via SSH

At this point I abandoned the keyboard and monitor, continuing the config steps from my PC.

19. SSH to the Pi using your preferred client. If you're using Windows 10 you can just do this from a PowerShell window: `ssh <TheIpAddressFromStep18> -l pi` (Note that's a lower-case L).
20. You should see something like this:
```txt
The authenticity of host '192.168.1.10 (192.168.1.10)' can't be established.
ECDSA key fingerprint is SHA256:Ty0Bw6IZqg1234567899006534456778sFKT6QakOZ5PdJk.
Are you sure you want to continue connecting (yes/no)?
```
21. Enter `yes` and press Return
22. The response should look like this:
```txt
Warning: Permanently added '192.168.1.10' (ECDSA) to the list of known hosts.
pi@192.168.1.10's password:
```
23. Enter the password and press Return.
24. It's STRONGLY recommended that you change the password. Run `passwd` and follow your nose.

## Here's where all the software is updated and installed:

25. First let's make sure the Pi is all up-to-date:
```txt
sudo apt-get update && sudo apt-get upgrade -y
```

> If this ends with an error "Some index files failed to download. They have been ignored, or old ones used instead." just press up-arrow and return to retry the command. You want to be sure the Pi is healthy and updated before continuing.

26. `sudo reboot now`.

Your SSH session will end here. Wait for the Pi to reboot, sign back in again and continue.

27. We need to install Subversion so we can download *just* the needed bits of the repo from GitHub:
```txt
sudo apt-get install subversion -y
```
28. This downloads the repo, dropping the structure into the home directory:
```txt
svn export https://github.com/greiginsydney/Homebridge-cbus-installer/trunk/code/ ~ --force
```

> Advanced tip: if you're testing code and want to install a new branch direct from the repo, replace "/trunk/" in the link above with `/branches/<TheBranchName>/`

29. All the hard work is done by a script in the repo, but it needs to be made executable first:
```txt
sudo chmod +x setup.sh
```
30. Now run it! (Be careful here: the switches are critical. "-E" ensures your user path is passed to the script. Without it the software will be moved to the wrong location, or not at all. "-H" passes the Pi user's home directory.)
```txt
sudo -E -H ./setup.sh step1
```

> If any of the script's steps fail, the script will abort and on-screen info should reveal the component that failed. You can simply re-run the script at any time (up-arrow / return) and it will simply skip over those steps where no changes are required. There are a lot of moving parts in the Raspbian/Linux world, and sometimes a required server might be down or overloaded. Time-outs aren't uncommon, hence why simply wait and retry is a valid remediation action.

31. Having installed C-Gate, we now need to edit one of the security files to ensure authorised remote machines - like the one you'll run Toolkit from - are allowed to connect.

32. The script prompts the user, autofilling a guess at your local network, based upon the IP address of the Pi. Backspace if you want to edit this, or just press return if the value is correct and you want to whitelist that whole network:

```txt
=======================================
C-Gate won't let remote clients connect to it if they're not in the file
/usr/local/bin/cgate/config/access.txt.
Add your Admin machine's IP address here, or to whitelist an entire network
add it with '255' as the last octet. e.g.:
192.168.1.7 whitelists just the one machine, whereas
192.168.1.255 whitelists the whole 192.168.1.x network.
The more IPs you whitelist, the less secure C-Gate becomes.

Enter an IP or network address to allow/whitelist : 10.10.16.255
```

33. If all goes well, you'll be presented with a prompt to reboot:
```txt
>> Exited step 1 OK. A reboot is required to kick-start C-Gate and prepare for Step 2.
Reboot now? [Y/n]:
```
Pressing return or anything but Y/y will cause the Pi to reboot.

34. While you wait for the Pi to reboot, copy the tagsfile ("something.xml") from your existing C-Bus setup to /home/pi/. On a default Windows installation of C-Gate/Toolkit the file will be in C:\Clipsal\C-Gate2\tag\. (I use [WinSCP](https://winscp.net/eng/download.php) for this.)

> Make sure the filename is the name of your network, because the script uses the filename to populate several places in the config where C-Gate and Homebridge need to know the network name.

35. After the Pi has rebooted, sign back in again and resume. The next step is to re-run the script, but with a new switch:
```txt
sudo -E ./setup.sh step2
```

36. The script will now move some of the supporting files from the repo to their final homes, and edit some of the default config in the Pi. 

It will output its progress to the screen. You'll see it's gone with "19P" which is my network name:
```txt
pi@raspberrypi:~ $ sudo -E ./setup.sh step2
>> Assuming project name = 19P, and setting C-Gate project.start & project.default values accordingly.
renamed 'homebridge' -> '/etc/default/homebridge'
renamed 'homebridge.service' -> '/etc/systemd/system/homebridge.service'
renamed 'homebridge.timer' -> '/etc/systemd/system/homebridge.timer'
mkdir: created directory '/var/lib/homebridge'
renamed 'config.json' -> '/var/lib/homebridge/config.json'
Created symlink /etc/systemd/system/multi-user.target.wants/homebridge.timer → /etc/systemd/system/homebridge.timer.
>> Exited step 2 OK.

Reboot now? [Y/n]:
```
Pressing return or anything but Y/y will cause the Pi to reboot.

37. Once the Pi reboots, C-Gate and homebridge will come up. It's this stage that populates your "my-platform.json" file, and this is likely to take a few minutes.

38. If you're the curious type, sign back in and enable logging. Hopefully it will output a lot of messages as homebridge discovers all the units on your network:
```txt
sudo journalctl -u homebridge.service -f
```

You should see an output like this for every unit. All those "19P" references will change in your setup to be whatever your network name is:
```txt
Dec 27 15:10:15 homebridge homebridge[504]: 2019-12-27T04:10:15.425Z cbus:client rx event { time: '20191227-151015', code: 753, processed: false, message: '//19P/254 87303760-0a8c-1038-9483-ee3a5c1da2ab Net Sync: synchronizing unit 5 of 23 at address 6', type: 'event', raw: '#e# 20191227-151015 753 //19P/254 87303760-0a8c-1038-9483-ee3a5c1da2ab Net Sync: synchronizing unit 5 of 23 at address 6' }
```
(Control-C to abort this once you've seen enough or it stops).

## Tweak the config

39. At this point you have an almost working Homebridge setup, but some tweaking and fine-tuning is required.

40. "Step 2" created an empty file called "my-platform.json" in /home/pi, and following the reboot in Step 36 it will be populated with  the details of all the Group Addresses ('GAs') that were reported by C-Gate. The type of device has been _guessed_ by Homebridge-cbus, and some of these will need correcting.

Review the ["Functional example config.json" file](https://github.com/anthonywebb/homebridge-cbus#functional-example-configjson), and compare that with both yours (/var/lib/homebridge/config.json) and your "my-platform.json".

If you have a small C-Bus network and there aren't a lot of GAs, it's a simple matter to copy and paste from one text file to another, but if your network's larger or more complicated, the script can do this for you.

41. To use the script, re-run it with the new 'copy' switch:
```txt
sudo -E ./setup.sh copy
```

42. If the script exits with "Done" immediately, the mostly likely reason is that you've not given homebridge enough time to populate the my-platform.json file. Wait a couple of minutes and try again.
```txt
sudo -E ./setup.sh copy
Done

The PIN to enter in your iDevice is 031-45-154

Restart Homebridge? [Y/n]:
```

43. Assuming the file has been populated OK, the script will now read through all the GAs in my-platform.json, and if they don't exist in config.json, prompt you one-by-one to Add them, Skip them, and where the "type" of channel is reported as unknown or was guessed incorrectly, Change them to one of the possible types.

44. Where the Group's details are correct, pressing Return will accept the default, Add, which is highlighted in green:
```txt
"type": "dimmer", "id": 18, "name": "Lounge room"
[A]dd, [s]kip, [C]hange & enable, [q]uit?
Added
```

45. All that are reported as "unknown" are highlighted in yellow, and pressing Return defaults to show the Change sub-menu. Choose the highlighted letter of the appropriate type and press Return:
```txt
"type": "unknown", "id": 21, "name": "Exhaust fan"
[a]dd, [s]kip, [C]hange & enable, [q]uit?
Change to:
[l]ight, s[w]itch, [d]immer, [s]hutter, [m]otion, s[e]curity, [t]rigger, [c]ontact: w
Changed to switch
```

46. Press "s" and return to Skip any spare, unknown or unwanted GAs, and then "q" once you're done:
```txt
"type": "light", "id": 22, "name": "Ceiling GPO"
[A]dd, [s]kip, [C]hange & enable, [q]uit? s
Skipped

"type": "unknown", "id": 23, "name": "Group 23"
[a]dd, [s]kip, [C]hange & enable, [q]uit? q
Done

The PIN to enter in your iDevice is 031-45-154

Restart Homebridge? [Y/n]:
```

47. Pressing return or anything but Y/y will restart Homebridge to pick up the new settings.

![setup.sh-copy.png](/images/setup.sh-copy.png)

48. At this point you can turn to your iDevice, launch Home and select "Add Accessory".

49. Click the button "I Don't Have a Code or Cannot Scan", then under the Manual Code heading on the next screen click the "Enter code..." link and enter the PIN shown on-screen at the end of Step 46. You should be able to follow your nose from there.

49. You're free to repeat step 41 at any time. You won't be prompted for any of the GAs you added before, so if you want to change the "type" of an existing GA you'll need to do this by hand (`sudo nano /var/lib/homebridge/config.json`). Any GAs that you've recently added to the network or you may have subsequently decided to include can now be added to config.json just by responding to the prompts.

<br>

\- Greig.

