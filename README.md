# Survival Server

A tuned [Paper](https://papermc.io) server for Minecraft **26.1.2** on Windows, with a
public address through [playit.gg](https://playit.gg), so no port forwarding is needed.

This repo holds only scripts and settings. `setup.ps1` downloads Java, Paper and the
plugins and verifies their checksums. The world, passwords, whitelist and tunnel address
are never committed.

## Joining a server someone else is hosting

1. Set your game to exactly **26.1.2**. Other versions cannot connect.
2. Ask the host to whitelist your username, and ask for the server address.
3. Add the address under Multiplayer and join.
4. The first time, run `/register <password> <password>`. After that, run `/login <password>`
   each time you join. Passwords need at least 8 characters.

The server runs in offline mode, so non-official launchers work. Don't reuse a password
from anywhere else.

## Hosting

Requires Windows 10 or 11, about 5 GB of free memory and a few GB of disk.

### First-time setup

```bash
powershell -ExecutionPolicy Bypass -File setup.ps1
```

This asks you to accept the [Minecraft EULA](https://aka.ms/MinecraftEULA). Java is kept
inside the project, so nothing is installed system-wide.

### Starting the server

Run `start.bat` and wait for the `Done` line. To stop it, type `stop` in that window
rather than closing it, so the world saves properly.

### Adding players

The whitelist is on, so nobody can join until added. Type these in the server window:

```
whitelist add <username>
op <username>
```

`op` makes someone an admin, so use it only for people who run the server. Each player
should run `/register` as soon as they are added. Until then, anyone who connects with
that name can claim it.

### Giving friends an address

1. Create a free account at [playit.gg](https://playit.gg).
2. Run `tunnel.bat` and open the link it prints to link the agent to your account.
3. On the playit.gg site, add a **Minecraft Java** tunnel pointing to `127.0.0.1:25565`.
4. Give the address only to people you're playing with. Keep it out of this repo.

Keep both `start.bat` and `tunnel.bat` running while people play. If you play on the same
computer, connect to `localhost`.

**VPN or proxy tools:** if you run one in tunnel mode (Xray, for example), it may interfere
with playit. If friends can't connect, try excluding `playit.exe` from it.

### Playing on the same computer

Set your game to **4 GB** of memory in your launcher. The server uses a fixed 4 GB, and on
a 16 GB machine a larger game allocation causes heavy paging and stutter.

### Backups

Stop the server, then run:

```bash
powershell -ExecutionPolicy Bypass -File backup.ps1
```

This writes a zip to `backups/`. Old backups are not deleted automatically.

## Moving the world to another host

Only one person should host at a time, or the worlds diverge.

1. The current host stops the server, runs `backup.ps1`, and sends the zip privately.
2. The new host runs `setup.ps1`, then extracts the zip into `server/`.

Worlds are not stored in this repo. Player passwords are not in the zip either, so players
would register again on the new host unless `server/plugins/AuthMe/authme.db` is also sent
privately. Never publish that file.

## What's tuned

| Area | Setting |
|---|---|
| Memory | Fixed 4 GB heap, G1 flags based on Aikar's set (`start.bat`) |
| Distances | View distance 8, simulation distance 6 |
| Disk | Fewer chunks autosaved per tick, asynchronous chunk writes |
| Redstone | Alternate Current implementation |
| Mobs | Lower spawn limits, shorter activation ranges, spawn range 6 |
| Items | Wider item and XP merging, arrows despawn faster |
| Hoppers | Less frequent checks, move event disabled |

Tuned files are in `config/`. `setup.ps1` copies them to `server/` without overwriting
files that already exist, so edit the copy in `server/` once a server is set up.

Some of these settings change gameplay slightly: fewer mobs, and sensitive redstone or
mob farms may behave differently. Raise the values in `spigot.yml`, `bukkit.yml` or
`config/paper-world-defaults.yml` if something you built stops working.

## Security

Offline mode means the server cannot verify who owns a username, so AuthMe passwords and
the whitelist are what protect accounts. Keep `authme.db`, `whitelist.json`, `ops.json`,
the playit secret and the tunnel address out of Git.
