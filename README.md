# sdr-enthusiasts/docker-aprs-tracker

Table of Contents

- [sdr-enthusiasts/docker-aprs-tracker](#sdr-enthusiastsdocker-aprs-tracker)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Multi Architecture Support](#multi-architecture-support)
  - [Up-and-Running with Docker Compose](#up-and-running-with-docker-compose)
  - [Runtime Environment Variables](#runtime-environment-variables)
    - [General parameters](#general-parameters)
  - [Logging](#logging)
  - [Acknowledgements](#acknowledgements)
  - [Getting Help](#getting-help)
  - [Summary of License Terms](#summary-of-license-terms)

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

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

## Up-and-Running with Docker Compose

An example `docker-compose.yml` can be found [here](docker-compose.yml).

Make sure to map the `/data` directory to a volume, as per the [example file](docker-compose.yml). If you forget to do this, the ships database will be erased upon container recreation, and a new notification will be sent for every ship that is heard after restart. This will probably spam your Mastodon account!

## Runtime Environment Variables

There are a series of available environment variables:

### General parameters

| Environment Variable | Purpose                         | Default | Mandatory? |
| -------------------- | ------------------------------- | ------- | ---------- |

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Acknowledgements

Without the help, advice, testing, and kicking the tires of these people, things wouldn't have happened:

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-direwolf/issues) on the project's GitHub.
I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse. The #ais-catcher channel is appropriate for conversations about this package.

## Summary of License Terms

Copyright (C) 2022-2023, Ramon F. Kolb (kx1t)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
