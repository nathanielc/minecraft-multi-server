# Minecraft Server

This project defines a template systemd service unit file for hosting several minecraft servers.
Since once you have one you are going to want another ;)

# Install

This system runs the minecraft server in a docker container as such you must first install docker.

Run `make install` as root and the files will be copied to the appropriate locations.

You should also create a minecraft user to own the server files.

```
useradd minecraft
```

NOTE: `grep` and `sed` are also required in order to watch the minecraft logs for various events.

## AUR Package

An AUR package is in the works...

# Usage

With this project installed you can run multple different minecraft worlds on the same host.
Each is given a name and can be configured in an `/etc/minecraft/<name>` file.

## EULA

Minecraft requires that you accept the EULA in order to run a server.
Either add `EULA=true` to all your `/etc/minecraft/<name>` files, or edit the `minecraftctl.sh` script to set `EULA=true` for all worlds.

## Running a server

To start a new server run:

```
sudo systemctl start minecraftd@survival.service
```

To enable the server on boot run:

```
sudo systemctl enable minecraftd@survival.service
```

## Custom Config

You can customize the configuration of a server by setting environment vars in `/etc/minecraft/<name>`

For example to run on a different port and version you could use:

```
PORT=25566
VERSION=1.8.9
```

in the file `/etc/minecraft/survival`.

All `server.properties` are available to be set.

## Ephemeral server

If you want to host a specific puzzle or adventure world you can use both the `EPHEMERAL` and `WORLD` vars.

```
EPHEMERAL=true
WORLD=http://minecraft.example.com/myworld.zip
```

Now everytime the server is started is will download a fresh copy of the world and launch it.
Without the `EPHEMERAL` var the world will only be downloaded to first time.

## Backups

Along with the service template a systemd.timer is provided to run backups of a server.

For example:

```
sudo systemctl enable minecraftd-backup@survival.timer
```

this will enable weekly backups of the `survival` server.
Backups are stored in the default `$DATA_DIR/$BACKUP_DIR` which is `/srv/minecraft/<name>/backups` if you want to copy them offsite you will need to manage that yourself.


## Further custimization

Not everything that is possible to customize has been mentioned here.
Take a look at the `minecraftctl.sh` script as it is written to be extensible.

# Portability

These scripts work on my host ;) (arch linux).
I have not tested them anywhere else, if you run into a bug please file on issue here on github or better yet submit a PR.

# Thanks

This project leverages the work of the https://hub.docker.com/r/itzg/minecraft-server/ docker container for minecraft.
Also many of these concepts in the `minecraftctl.sh` script where inspired by https://aur.archlinux.org/packages/minecraft-server/.
Many thanks to both projects for making this one possible.

