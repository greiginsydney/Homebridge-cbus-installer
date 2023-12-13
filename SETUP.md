# Setup the Pi

## Pre-req's

- You'll need a Pi and memory card.
- A network connection (either wired or Wifi depending on your preference).

> If you're using a wired network, you'll need to be able to query your DHCP server so you can find the IP address that gets allocated to the Pi. (In a simple home setup, your internet gateway device or WiFi router will also be your DHCP server.)

- Your C-Bus network's "tags file". (This will be named after your project name and have a .xml extension).
- Some software that will let you transfer the tags file to the Pi. I use [WinSCP](https://winscp.net/eng/index.php), but there are plenty of alternatives.
- Software that will let you connect via SSH to the Pi. (Windows 10 now does this natively.)

- Java 8. This can no longer be done for you programmatically, as it now requires an authentication step (thank you Oracle).

### Java 8

1. Browse to [Java SE 8 Archive Downloads (JDK 8u211 and later)](https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html).
2. Click to download the latest version of the "Linux ARM32 Hard Float ABI".
3. Jump through the hoops to create a login & authenticate yourself.
4. Obtain the download. It should be called something like `jdk-8u381-linux-arm32-vfp-hflt.tar.gz`. Put it somewhere that you will be able to transfer it to the Pi. (Target dir = `/home/pi/`).

> It doesn't NEED to be this version. The script will attempt to install the first file it finds that matches "jdk*.gz" in /home/pi.

[Reference](https://forums.raspberrypi.com/viewtopic.php?t=231460) - and thank you Daryl.

## Start here

If you're starting from scratch, start here at Step 1.

1. Prepare the memory card with the [32-bit Homebridge Raspbian](https://www.raspberrypi.org/software/operating-systems/) image.

> The ["Raspberry Pi Imager"](https://www.raspberrypi.org/software/) app can download and write the image to a memory card for you quickly and easily.

<p align="center">
<img src="https://github.com/greiginsydney/Homebridge-cbus-installer/assets/11004787/9980e248-777e-489d-b656-0d523adc8d0f" width="50%">
</p>
<br>

<p align="center">
<img src="https://github.com/greiginsydney/Homebridge-cbus-installer/assets/11004787/7551acb3-1f0b-463c-95fc-8b6c6334bf6f" width="50%">
</p>
<br>

 <p align="center">
<img src="https://github.com/greiginsydney/Homebridge-cbus-installer/assets/11004787/9cdfd375-8e83-4968-ac0e-b31254f9dc53" width="50%">
</p>
<br>

<p align="center">
<img src="https://github.com/greiginsydney/Homebridge-cbus-installer/assets/11004787/09681b4b-6086-4be5-a1dd-4ef1cb815a13" width="50%">
</p>
 
2. If you're building a Pi with a wired network connection, make sure it's connected before proceeding.

> You don't need to connect a monitor or keyboard, although if you have one, a monitor will display some extra info that might help if you're having problems connecting to the Pi in the later steps.

3. Add power and turn it on.
4. Wait a minute or two for the Pi to boot.
5. __If you're building the Pi on a wired network, jump to Step 10.__
6. The Pi will create a WiFi network called "Homebridge WiFi Setup". Connect to it from a computer or your phone:

<table>
  <tr>
    <th>Mobile</th>
    <th>PC</th>
  </tr>
  <tr>
    <td>
      <p align="center">
      <img src="https://user-images.githubusercontent.com/11004787/89696847-ff336b80-d95c-11ea-9f16-a4b793761ab8.png" width="40%">
      </p>
    </td>
    <td>
      <p align="center">
      <img src="https://user-images.githubusercontent.com/11004787/89696867-09ee0080-d95d-11ea-8103-e557a61e2c7f.png" width="40%">
      </p>
    </td>
  </tr>
</table>

7. A browser window should open prompting you for the details of your normal WiFi network. Enter its SSID, passphrase and tap/click Connect:

<table>
  <tr>
    <th>Mobile</th>
    <th>PC</th>
  </tr>
  <tr>
    <td>
      <p align="center">
      <img src="https://user-images.githubusercontent.com/11004787/89696959-5df8e500-d95d-11ea-9782-27a53eee3baf.png" width="40%">
      </p>
    </td>
    <td>
      <p align="center">
      <img src="https://user-images.githubusercontent.com/11004787/89696964-66512000-d95d-11ea-9726-7207273ea1fb.png" width="40%">
      </p>
    </td>
  </tr>
</table>

8. The Pi will now attempt to connect to that WiFi network. If it is unable to (bad password?) it will revert to its "Homebridge WiFi Setup" network for you to try again:

<p align="center">
    <img src="https://user-images.githubusercontent.com/11004787/89697114-09a23500-d95e-11ea-9aaf-319841e5b85d.png" width="40%">
</p>

> The success of the above will be indicated by the "Homebridge WiFi Setup" network disappearing from the list of available networks.

9. Reconnect to your normal WiFi network.

10. Launch a browser to http://homebridge.local & sign in with the default credentials of admin/admin:

<p align="center">
<img src="https://user-images.githubusercontent.com/11004787/89697356-29862880-d95f-11ea-92ff-1ea033e72e9f.png" width="60%">
</p>

11. The address bar will update to reveal the IP address of the Pi. Note this for the next steps:

<p align="center">
<img src="https://user-images.githubusercontent.com/11004787/89698093-a49d0e00-d962-11ea-852c-44367f960147.png" width="60%">
</p>

## Copy the Tags file

12. Your C-bus network's "Tags file" is a file you'll find where-ever your C-bus network's current instance of "C-Gate" lives. It's essentially a dictionary file, matching the human-readable names you've given the inputs and outputs to the "Group Addresses" that C-Bus uses on the network.

On Windows, the default path for it is `C:\Clipsal\C-Gate2\tag\` and it will be called \<YourNetworkName\>.xml".
  
> Make sure the filename is the name of your network, because the script uses the filename to populate several places in the config where C-Gate and Homebridge need to know the network name.  
  
  13. Copy this file to the Pi, placing it in the /home/pi/ directory. Here's a screen-grab of ["WinSCP"](https://winscp.net/eng/index.php) which I use for this purpose. (You may have or prefer a different application.)
  
<p align="center">
  <img src="https://user-images.githubusercontent.com/11004787/89698371-2c374c80-d964-11ea-94f2-2deb6bc32467.png" width="60%">
</p>

## Copy Java

You downloaded Java 8 in the pre-req's earlier. Now's the time to copy it across to the Pi (if you haven't already).
 
If it's not found in `/home/pi/` when the script runs it will abort.


## Remote config via SSH

14. SSH to the Pi using your preferred client. If you're using Windows 10 you can just do this from a PowerShell window:

```ssh <TheIpAddressFromStep11> -l pi``` (Note that's a lower-case L).


15. You should see something like this:
```txt
The authenticity of host '10.10.17.15 (10.10.17.15)' can't be established.
ECDSA key fingerprint is SHA256:Ty0Bw6IZqg1234567899006534456778sFKT6QakOZ5PdJk.
Are you sure you want to continue connecting (yes/no)?
```
16. Enter `yes` and press Return.
17. The response should look like this:
```txt
Warning: Permanently added '10.10.17.15' (ECDSA) to the list of known hosts.
pi@10.10.17.15's password:
```
18. Enter the password ('raspberry') and press Return.
19. It's STRONGLY recommended that you change the password. Run `passwd` and follow your nose.

## Here's where all the software is updated and installed:

20. First let's make sure the Pi is all up-to-date:
```txt
sudo apt-get update && sudo apt-get upgrade -y
```

> If this ends with an error "Some index files failed to download. They have been ignored, or old ones used instead." just press up-arrow and return to retry the command. You want to be sure the Pi is healthy and updated before continuing.

21. `sudo reboot now`.

Your SSH session will end here. Wait for the Pi to reboot, sign back in again and continue.

22. Manually install Homebridge-CBus plugin
```txt
sudo hb-shell
sudo hb-service add homebridge-cbus
exit
```

23. This downloads the repo, dropping the structure into a subdirectory called `Homebridge-cbus-installer`:
```txt
cd ~
sudo rm -rf Homebridge-cbus-installer
git clone --depth=1 https://github.com/greiginsydney/Homebridge-cbus-installer
```

> Advanced tip: if you're testing code and want to install a new branch direct from the repo, add `-b <branchName>` on the end of the line.

24. Now we need to move the setup.sh script file into its final location:

```txt
mv -fv Homebridge-cbus-installer/code/setup.sh ~
``` 

25. All the remaining work is done by the above script, but it needs to be made executable first:
```txt
sudo chmod +x setup.sh
```
26. Now run it! (Be careful here: the switches are critical. "-E" ensures your user path is passed to the script. Without it the software will be moved to the wrong location, or not at all. "-H" passes the Pi user's home directory.)
```txt
sudo -E -H ./setup.sh step1
```

> If any of the script's steps fail, the script will abort and on-screen info should reveal the component that failed. You can simply re-run the script at any time (up-arrow / return) and it will simply skip over those steps where no changes are required. There are a lot of moving parts in the Raspbian/Linux world, and sometimes a required server might be down or overloaded. Time-outs aren't uncommon, hence why simply wait and retry is a valid remediation action.

27. Having installed C-Gate, we now need to edit one of the security files to ensure authorised remote machines - like the one you'll run Toolkit from - are allowed to connect.
    
28. The script prompts the user, autofilling a guess at your local network, based upon the IP address of the Pi. Backspace if you want to edit this, or just press return if the value is correct and you want to whitelist that whole network:

```txt
=======================================
C-Gate won't let remote clients connect to it if they're not in the file
/usr/local/bin/cgate/config/access.txt.
Add your Admin machine's IP address here, or to whitelist an entire network
add it with '255' as the last octet. e.g.:
192.168.1.7 whitelists just the one machine, whereas
192.168.1.255 whitelists the whole 192.168.1.x network.
The more IPs you whitelist, the less secure C-Gate becomes.

Enter an IP or network address to allow/whitelist : 10.10.17.255
Enter an IP or network address to allow/whitelist :
```

29. This menu will loop, allowing you to enter extra IPs. Press Return on its own to break out of this loop.

30. If you overlooked copying the tags file in Step 12, or put it in the wrong location on the Pi, the script will exit:

```
Copy your tags file (i.e. "<ProjectName>.xml)" to /home/pi/ and then run Step2
(If you don't know how to do this, I use WinSCP)

pi@homebridge:~ $ 
```

31. Do not pass Go, etc. Return to Step 12, then manually run step2:

```txt
sudo -E ./setup.sh step2
```

32. Step 32 here picks up with the output from the script's "step2". (Yes, I probably need to rename them to make this less confusing.)

33. __If everything went OK after step 30, the script proceeds to run step2 automatically.__

34. The script will now move some of the supporting files from the repo to their final homes, and edit some of the default config in the Pi. 

35. It will output its progress to the screen. You'll see it's gone with "19P" which is my network name:

```txt
pi@raspberrypi:~ $ sudo -E ./setup.sh step2
>> Assuming project name = 19P, and setting C-Gate project.start & project.default values accordingly.
renamed 'homebridge.timer' -> '/etc/systemd/system/homebridge.timer'
Added "homebridge-cbus.CBus" to /var/lib/homebridge/config.json OK
Removed /etc/systemd/system/multi-user.target.wants/homebridge.service.
Created symlink /etc/systemd/system/multi-user.target.wants/homebridge.timer → /etc/systemd/system/homebridge.timer.
>> Exited step 2 OK.

Reboot now? [Y/n]:
```
Pressing Return or anything but Y/y will cause the Pi to reboot.

36. Once the Pi reboots, C-Gate and Homebridge will come up. It's this stage that populates your "my-platform.json" file, and this is likely to take a few minutes.

37. If you're the curious type, sign back in and enable logging. Hopefully it will output a lot of messages as Homebridge discovers all the units on your network:
```txt
sudo journalctl -u homebridge.service -f
```

You should see an output like this for every unit. All those "19P" references will change in your setup to be whatever your network name is:
```txt
Dec 27 15:10:15 homebridge homebridge[504]: 2019-12-27T04:10:15.425Z cbus:client rx event { time: '20191227-151015', code: 753, processed: false, message: '//19P/254 87303760-0a8c-1038-9483-ee3a5c1da2ab Net Sync: synchronizing unit 5 of 23 at address 6', type: 'event', raw: '#e# 20191227-151015 753 //19P/254 87303760-0a8c-1038-9483-ee3a5c1da2ab Net Sync: synchronizing unit 5 of 23 at address 6' }
```
(Control-C to abort this once you've seen enough or it stops).

## Tweak the config

38. At this point you have an almost working Homebridge setup, but some tweaking and fine-tuning is required.

39. The script's "step2" created an empty file called "my-platform.json" in /home/pi, and following the reboot in Step 35 it will be populated with the details of all the Group Addresses ('GAs') that were reported by C-Gate. The type of device has been _guessed_ by Homebridge-cbus, and some of these will need correcting.

Review the ["Functional example config.json" file](https://github.com/anthonywebb/homebridge-cbus#functional-example-configjson), and compare that with both yours (/var/lib/homebridge/config.json) and your "my-platform.json".

If you have a small C-Bus network and there aren't a lot of GAs, it's a simple matter to copy and paste from one text file to another, but if your network's larger or more complicated, the script should make it easier for you.

40. To use the script, re-run it with the new 'copy' switch:
```txt
sudo -E ./setup.sh copy
```

41. If the script exits with "Done" immediately, the mostly likely reason is that you've not given Homebridge enough time to populate the my-platform.json file. Wait a couple of minutes and try again.
```txt
sudo -E ./setup.sh copy
Done

The PIN to enter in your iDevice is 031-45-154

Restart Homebridge? [Y/n]:
```

42. Assuming the file has been populated OK, the script will now read through all the GAs in my-platform.json, and if they don't exist in config.json, prompt you one-by-one to Add them, Skip them, and where the "type" of channel is reported as unknown or was guessed incorrectly, Change them to one of the possible types.

43. Where the Group's details are correct, pressing Return will accept the default, Add, which is highlighted in green:
```txt
"type": "dimmer", "id": 18, "name": "Lounge room"
[A]dd, [s]kip, [C]hange & enable, [q]uit?
Added
```

44. All that are reported as "unknown" are highlighted in yellow, and pressing Return defaults to show the Change sub-menu. Choose the highlighted letter of the appropriate type and press Return:
```txt
"type": "unknown", "id": 21, "name": "Exhaust fan"
[a]dd, [s]kip, [C]hange & enable, [q]uit?
Change to:
[l]ight, s[w]itch, [d]immer, [s]hutter, [m]otion, s[e]curity, [t]rigger, [c]ontact: w
Changed to switch
```

45. Press "s" and return to Skip any spare, unknown or unwanted GAs, and then "q" once you're done:
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

46. Pressing return or anything but Y/y will restart Homebridge to pick up the new settings.

![setup.sh-copy.png](/images/setup.sh-copy.png)

47. At this point you can turn to your iDevice, launch Home and select "Add Accessory".

48. Click the button "I Don't Have a Code or Cannot Scan", then under the Manual Code heading on the next screen click the "Enter code..." link and enter the PIN shown on-screen at the end of Step 45. You should be able to follow your nose from there.

49. You're free to repeat step 40 at any time. You won't be prompted for any of the GAs you added before, so if you want to change the "type" of an existing GA you'll need to do this by hand (`sudo nano /var/lib/homebridge/config.json`). Any GAs that you've recently added to the network or you may have subsequently decided to include can now be added to config.json just by responding to the prompts.

<br>

\- Greig.

