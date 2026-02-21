# Top Memory Threshold Killer

Have you ever found your machine completely frozen less than one minute after boot because a background task silently consumed all available memory ?

Have you ever watched your system crash while a rogue process kept allocating RAM without limits?

I built this tool after a Webkernel application with aggressive background tasks saturated my memory in under a minute after startup. The machine became unusable. Everything crashed. It drove me insane. This script was born out of that nightly frustration.

Top Memory Threshold Killer continuously monitors memory usage and immediately terminates the highest memory-consuming eligible process when it exceeds a defined RSS threshold.

It is a lightweight userspace safety net.

---

# Run Examples

Default 976 MB:

```bash
./top-memory-threshold-killer.sh
```

Custom 1500 MB:

```bash
./top-memory-threshold-killer.sh 1500
```

Or:

```bash
MEMORY_LIMIT_MB=2048 ./top-memory-threshold-killer.sh
```

---

# Run as systemd (User Service)

## 1. Move script

```bash
mkdir -p ~/.local/bin
mv top-memory-threshold-killer.sh ~/.local/bin/
chmod +x ~/.local/bin/top-memory-threshold-killer.sh
```

---

## 2. Create user service

Create file:

```bash
~/.config/systemd/user/top-memory-threshold-killer.service
```

Content:

```bash
[Unit]
Description=Top Memory Threshold Killer
After=default.target

[Service]
ExecStart=/home/YOUR_USERNAME/.local/bin/top-memory-threshold-killer.sh
Restart=always
RestartSec=3
Environment=MEMORY_LIMIT_MB=976

[Install]
WantedBy=default.target
```

Replace YOUR_USERNAME.

---

## 3. Enable

```bash
systemctl --user daemon-reload
systemctl --user enable top-memory-threshold-killer
systemctl --user start top-memory-threshold-killer
```

Check:

```bash
systemctl --user status top-memory-threshold-killer
```

---

Here is a log example : 

```bash

--------------------------------------------------
[ALERT] 2026-02-21 00:53:17 |  641218 1256120 Isolated Web Co /usr/lib/firefox-esr/firefox-esr -contentproc -isForBrowser -prefsHandle 0:46254 -prefMapHandle 1:277392 -jsInitHandle 2:242716 -parentBuildID 20251009121631 -sandboxReporter 3 -chrootClient 4 -ipcHandle 5 -initialChannelId {78cefbb2-e65f-44a1-9b94-4175f16e0082} -parentPid 340735 -crashReporter 6 -crashHelper 7 -greomni /usr/lib/firefox-esr/omni.ja -appomni /usr/lib/firefox-esr/browser/omni.ja -appDir /usr/lib/firefox-esr/browser 103 tab
User              : yassine
Working directory : 
Executed file     : /usr/lib/firefox-esr/firefox-esr
Command line      : /usr/lib/firefox-esr/firefox-esr -contentproc -isForBrowser -prefsHandle 0:46254 -prefMapHandle 1:277392 -jsInitHandle 2:242716 -parentBuildID 20251009121631 -sandboxReporter 3 -chrootClient 4 -ipcHandle 5 -initialChannelId {78cefbb2-e65f-44a1-9b94-4175f16e0082} -parentPid 340735 -crashReporter 6 -crashHelper 7 -greomni /usr/lib/firefox-esr/omni.ja -appomni /usr/lib/firefox-esr/browser/omni.ja -appDir /usr/lib/firefox-esr/browser 103 tab 
Parent            : 340735 -> firefox-esr     /usr/lib/firefox-esr/firefox-esr
Trigger           : Unknown or indirect trigger
Fork count        : 0
Parent process tree:
->  641218  340735 Isolated Web Co /usr/lib/firefox-esr/firefox-esr -contentproc -isForBrowser -prefsHandle 0:46254 -prefMapHandle 1:277392 -jsInitHandle 2:242716 -parentBuildID 20251009121631 -sandboxReporter 3 -chrootClient 4 -ipcHandle 5 -initialChannelId {78cefbb2-e65f-44a1-9b94-4175f16e0082} -parentPid 340735 -crashReporter 6 -crashHelper 7 -greomni /usr/lib/firefox-esr/omni.ja -appomni /usr/lib/firefox-esr/browser/omni.ja -appDir /usr/lib/firefox-esr/browser 103 tab
->  340735    8321 firefox-esr     /usr/lib/firefox-esr/firefox-esr
->    8321       1 systemd         /usr/lib/systemd/systemd --user
--------------------------------------------------

```

---

Will be added later : 

* Turn it into a proper daemon tool
* Graceful SIGTERM before SIGKILL
* Exponential backoff
* Hardening for production servers
* Integrating in the nadim CLI
