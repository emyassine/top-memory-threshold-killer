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

Will be added later : 

* Turn it into a proper daemon tool
* Graceful SIGTERM before SIGKILL
* Exponential backoff
* Hardening for production servers
* Integrating in the nadim CLI
