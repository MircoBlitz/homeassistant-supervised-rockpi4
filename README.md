# homeassistant-supervised-rockpi4

just a script that installs homeassistant on a rockpi 4a+ (in my case) running debian bookworm or bullseye

not perfekt, simply does everything I would do manual without check code around

Check the versions in the code

Install:
* get you latest debian for rockpi here (note for a and b you need to take the links below direct downloads (https://www.armbian.com/rockpi4/)
* burn it to an sd card
* short pins 23 and 25
* boot from sd
* with nand-sata-install move the system to nvme (prefered) or emmc
* reboot without sd (I belive with the first boot, pin 23 and 25 still need to be shorted)
* install git (apt update && apt install -y git
* checkout this repo
* run (bash ./homeassistant-rockpi-supervised.sh)
* wait untill all docker spun up
* goto http://[rockPiIP]:8123
* have fun
