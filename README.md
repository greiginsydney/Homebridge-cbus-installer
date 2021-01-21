# Homebridge-cbus-installer

#### A bash script & companion files to make it as easy as possible to install [Homebridge-cbus](https://github.com/anthonywebb/homebridge-cbus) on your Raspberry Pi.

Based on [the definitive setup documentation](https://onedrive.live.com/?authkey=%21ANlD74Wg0RsHv98&id=142E343EE7CCA768%2119603&cid=142E343EE7CCA768) created by [Daryl McDougall](https://github.com/DarylMc).

All you need to get underway is:
- a Raspberry Pi with microSD card, power supply and box.
- a wired or wireless network connection
- A C-Bus network!
- A Clipsal CNI ethernet interface (5500CN2) or other ethernet interface that connects to the C-Bus network
- The "tags" file from your network's C-Gate.

[SETUP.md](SETUP.md) takes you through all the steps. 

The easy to follow setup process:
- shows you how to get the Pi on your network, from first power-on.
- updates your Pi.
- downloads this repo and its supporting files, then the setup script (in this repo) takes over and automates all that's possible, including some useful tools and hitherto unseen shortcuts.

## Static IP addressing

Homebridge defaults to DHCP for its IP address. If you want to change to a static IP address, launch the NetworkManager Terminal UI from a terminal window in the browser, or an SSH connection. See ["How To Set A Static IP Address](https://github.com/homebridge/homebridge-raspbian-image/wiki/How-To-Set-A-Static-IP-Address) on the project's Wiki for the details.

## Issues?

If you encounter any problems, the trick is to figure out if it's a bug in the script, or a bug in the _process_.

If you're not sure, jump to the [Issues](https://github.com/greiginsydney/Homebridge-cbus-installer/issues) tab here. Check out the Open and Closed ones - someone might have already reported the same problem. If your issue hasn't been captured here before, log it and we'll have a look at it.

## Credits

This repo is really just adding a scripted wrapper around Anthony's [Homebridge-cbus](https://github.com/anthonywebb/homebridge-cbus) & Daryl's [brilliant setup documentation](https://onedrive.live.com/?authkey=%21ANlD74Wg0RsHv98&id=142E343EE7CCA768%2119603&cid=142E343EE7CCA768).

These guys - and all who've contributed to the project over several years - deserve bountiful credit.

## Contributions?

See [CONTRIBUTING.md](CONTRIBUTING.md).


<br/>


\- Greig.
