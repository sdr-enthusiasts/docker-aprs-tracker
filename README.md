# sdr-enthusiasts/docker-aprs-tracker

Table of Contents

- [sdr-enthusiasts/docker-aprs-tracker](#sdr-enthusiastsdocker-aprs-tracker)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Multi Architecture Support](#multi-architecture-support)
  - [Software Installation](#software-installation)
    - [Base, barebones Linux image](#base-barebones-linux-image)
    - [Creation of a new non-root user](#creation-of-a-new-non-root-user)
    - [Installation of Docker](#installation-of-docker)
    - [Downloading a template `docker-compose.yml` config file](#downloading-a-template-docker-composeyml-config-file)
    - [Configuration of your data](#configuration-of-your-data)
      - [MUST CHANGE parameters](#must-change-parameters)
      - [OPTIONAL parameters](#optional-parameters)
      - [OTHER parameters](#other-parameters)
  - [Logging](#logging)
  - [Acknowledgements](#acknowledgements)
  - [Getting Help](#getting-help)
  - [Summary of License Terms](#summary-of-license-terms)

Join us on Discord - [![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

## Introduction

NOTE - DO NOT USE - NOT YET READY FOR PRIMETIME / DEPLOYMENT. CHECK LATER IF THIS MESSAGE IS REMOVED

Docker container for a mobile / stand-alone APRS tracker. Contains:

- [WB2OSZ's excellent APRS software TNC "DireWolf"](https://github.com/wb2osz/direwolf/)
- GPSD for receiving location information from a GPS dongle and for maintaining the device time
- Chrony for setting the device time

## Prerequisites

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

- `arm32v7`, `armv7l`, `armhf`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3/4 32-bit)
- `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)
- `amd64`, `x86_64`: X86 64-bit Linux (Linux PC)

Other architectures (Windows, Mac) are not currently supported, but feel free to see if the container builds and runs for these.

## Software Installation

If you already have a device with Linux running, you can jump straight to one of these two sections:

- [Installation of Docker](#installation-of-docker)
- [Downloading a template `docker-compose.yml` config file](#downloading-a-template-docker-composeyml-config-file)

If you need help installing Linux, read on...

### Base, barebones Linux image

- Start with a minimalist Debian image that works for your hardware device. Personally, I like [DietPi](https://dietpi.com/), but in the absense of this, you can use Raspberry Pi OS (lite) or a standard Debian build. Make sure to pick one that is as barebones as possible; no need for Desktop applications, etc.
- Burn the image to a SD card, and go through the initial setup

### Creation of a new non-root user

- While setting things up, make sure you are connected to the internet!
- If your Linux distribution doesn't do so, please create a non-root user account, for example with `sudo adduser aprs` . (We're using username `aprs`, but you can change this to your liking). Note -- if you use DietPi, the system will create a default user `dietpi`. You can use this account instead of creating a new user.
- Make sure that the user `aprs` is set up for `sudo` access; see the code snippet below. (If approriate, change `aprs` to `dietpi` or whatever the username is you are using)
- then log out from the `root` account and log back in with the username and password you just created.

```bash
sudo usermod -aG sudo aprs  # this adds the user to the sudo group
echo "aprs ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-aprs-privileges >/dev/null
sudo chmod 0440 /etc/sudoers.d/90-aprs-privileges
```

Then you can set the system's timezone with this command (follow the instructions on the screen):

```bash
sudo dpkg-reconfigure tzdata
```

### Installation of Docker

Once you are logged in as user `aprs`, you are ready to install Docker. Use the following commands; you can copy and paste them all at once, or paste them line by line:

```bash
# First download the docker installation script and run it:
wget -q https://raw.githubusercontent.com/sdr-enthusiasts/docker-install/main/docker-install.sh
chmod +x docker-install.sh
./docker-install.sh no-chrony
rm -f ./docker-install.sh

# Last, let's make sure that there's no NTP, GPSD or Time Sync client installed on your system
# because these will interfere with the docker container.
# The docker container will use the connected GPS to update the system time.
# You can ignore any error messages like "Failed to disable unit: Unit file xxx.service does not exist."
# These error messages simply mean that your system didn't have the service to begin with.
sudo systemctl disable systemd-timesyncd -q --now 
sudo systemctl disable chrony -q --now
sudo systemctl disable ntpd -q --now
sudo systemctl disable gpsd -q --now
```

### Downloading a template `docker-compose.yml` config file

Now let's download a basic the docker-compose.yml file:

```bash
sudo mkdir -p -m 777 /opt/aprs
cd /opt/aprs
wget https://raw.githubusercontent.com/sdr-enthusiasts/docker-aprs-tracker/main/docker-compose.yml
```

### Configuration of your data

The configuration of your data is done entirely through "environment variables" in the `docker-compose.yml` file. Edit this file:

```bash
cd /opt/aprs
nano docker-compose.yml
```

Most of the data can stay the same. Here are the parameters that you can configure in the `environment:` section, categorized by "MUST CHANGE", "OPTIONAL", and "PROBABLY WON'T EVER NEED TO CHANGE".

Please be aware that the document is in `yaml` format. This format determines the "level" of the directive by the spacing in front of the line. BE VERY CAREFUL NOT TO MESS UP SPACING. Do not replace spaces by tabs, etc. This is the largest source of errors we come across by new users.

#### MUST CHANGE parameters

You MUST set these parameters. Without them, DireWolf will not work.

| Environment Variable | Purpose                         | Default |
| -------------------- | ------------------------------- | ------- |
| `MYCALL` | Set the callsign and suffix used in APRS broadcasts, for example `AA0ZZ-10` | Unset |

#### OPTIONAL parameters

For these parameters, the default values are generally good as a starting point, but you may have to adapt them to your situation.

| Environment Variable | Purpose                         | Default |
| -------------------- | ------------------------------- | ------- |
| `AUDIOCARD` | The number of the "audiocard" of your soundcard. If unset, the system will try to detect the value automatically. If this doesn't work, you may have to set it manually \* | Unset |
| `SUBDEVICE` | The number of the "subdevice" of your soundcard. If unset, the system will try to detect the value automatically. If this doesn't work, you may have to set it manually \* | Unset |
| `AUDIOLEVEL_RX` | The audio level of the input of your soundcard (for reception), in percent (`0`=off; `100`=maximum) \*\* | `90` (%) |
| `AUDIOLEVEL_TX` | The audio level of the output of your soundcard (for transmission), in percent (`0`=off; `100`=maximum) \*\* | `50` (%) |
| `SYMBOL` | The symbol of your vehicle in the tracking broadcast. We strongly suggest using a (partial) description from [this list](https://github.com/nwdigitalradio/direwolf/blob/master/symbols-new.txt) rather than using the 2-character value. | `"normal car"` |
| `OVERLAY` | Single letter or number that is overlaid on top of your vehicle symbol | Unset |
| `VERBOSE` | If set to `yes`/`on`/`1`/`true`, produce more verbose output | Unset |
| `DW_DEBUG` | Sets debug verbosity for DireWolf. For accepted values, see `docker exec -it direwolf --help` | Unset |
| `DW_EXTRA_CMDLINEARGS` | Any extra command line arguments you want to pass to DireWolf | Unset |

\* If the automatic setting doesn't work, you can show which audio devices, cards and subdevices are available on your system with the following command:

```bash
$ docker exec -it aprs arecord --list-devices

**** List of CAPTURE Hardware Devices ****
card 0: Device [USB PnP Sound Device], device 0: USB Audio [USB Audio]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

In this case, we should use `AUDIOCARD=0` and `SUBDEVICE=0`.

\*\* The container tries to use the `Speaker Playback Switch` / `PCM Playback Switch` and `Speaker Playback Volume` / `PCM Playback Volume` capabilities of your soundcard. If this doesn't work, please open an [issue](https://github.com/sdr-enthusiasts/docker-aprs-tracker/issues) and tell us what the equivalent capability of your sound card is called. We can add this within a reasonably short turn around time.

#### OTHER parameters

The default values for these parameters are almost always such that they do not need changing, but you may have to set them to fit your particular situation if you are using a non-standard setup.

| Environment Variable | Purpose                         | Default |
| -------------------- | ------------------------------- | ------- |
| `DWCONFIGFILE:` | Location of the `direwolf.conf` file | `/run/direwolf/direwolf.conf` |
| `VIA` | `VIA` parameter for beacon transmissions. See DireWolf documentation for exact definition | `WIDE1-1,WIDE2-1` |
| `SMARTBEACONING` | `SMARTBEACONING` parameter for beacon transmissions. See DireWolf documentation for exact definition | `70 1:00 5: 5:00 0:15 30 255` |
| `DW_EXTRA_CONFIGS` | Additional parameters to be added or changed in the `direwolf.conf` file. See format below. | Unset |

The `DW_EXTRA_CONFIGS` parameter can be used to add or change additional parameters in your `direwolf.conf` file. You can set this parameter as follows:

```yaml
...
environment:
    DW_EXTRA_CONFIGS=
       PARAM1=value string "here";
       PARAM2=;
       PARAM3;
       PARAM4=remove
...
```

In this case:

- `PARAM1` is uncommented (if needed) and set with `value string "here"` (replacing any existing values if they exist)
- `PARAM2` is uncommented (if needed) and set with no value string (any existing values are removed)
- `PARAM3` is uncommented (if needed) and leaving any existing value string in place
- `PARAM4` is commented out

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Acknowledgements

Without the help, advice, testing, and kicking the tires of these people, things wouldn't have happened:

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-direwolf/issues) on the project's GitHub.
I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse. The #ais-catcher channel is appropriate for conversations about this package.

## Summary of License Terms

This container is Copyright (C) 2023, Ramon F. Kolb (kx1t)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
