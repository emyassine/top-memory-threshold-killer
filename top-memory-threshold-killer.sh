#!/bin/bash

# Default threshold in MB
DEFAULT_LIMIT_MB=976

# Allow override via environment variable
if [ -n "$MEMORY_LIMIT_MB" ]; then
    LIMIT_MB="$MEMORY_LIMIT_MB"
# Allow override via first CLI argument
elif [ -n "$1" ]; then
    LIMIT_MB="$1"
else
    LIMIT_MB="$DEFAULT_LIMIT_MB"
fi

# Convert MB to KB (RSS is in KB)
THRESHOLD=$((LIMIT_MB * 1024))

LOG="/home/$USER/dangerous-process.txt"
EXCLUDE="systemd|sshd|bash|dbus|kworker|kdeinit|Xorg|gnome|plasmashell|watchdog|login"

mkdir -p "$(dirname "$LOG")"
touch "$LOG"
chmod 644 "$LOG"

echo "[OK] Memory monitoring active. Threshold: ${LIMIT_MB} MB"

trace_parents() {
  local pid=$1
  echo "Parent process tree:"
  while [ "$pid" -gt 1 ]; do
    local info=$(ps -p "$pid" -o pid,ppid,comm,args --no-headers)
    echo "-> $info"
    pid=$(awk '/^PPid:/ {print $2}' /proc/$pid/status 2>/dev/null)
  done
}

while true; do
  TOP_PID=$(ps -eo pid,%mem,comm,args --sort=-%mem | awk -v exclude="$EXCLUDE" 'NR>1 && $3 !~ exclude {print $1; exit}')

  if [ -z "$TOP_PID" ]; then
    sleep 2
    continue
  fi

  TOP_INFO=$(ps -p "$TOP_PID" -o pid,rss,comm,args --no-headers)
  MEM_USED=$(echo "$TOP_INFO" | awk '{print $2}')

  if [ -z "$MEM_USED" ]; then
    sleep 2
    continue
  fi

  if [ "$MEM_USED" -gt "$THRESHOLD" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    SOURCE_FILE=$(readlink -f /proc/$TOP_PID/exe)
    CMDLINE=$(tr '\0' ' ' < /proc/$TOP_PID/cmdline)
    USER_LAUNCHER=$(ps -o user= -p "$TOP_PID")
    CWD=$(readlink -f /proc/$TOP_PID/cwd)
    PARENT_PID=$(awk '/^PPid:/ {print $2}' /proc/$TOP_PID/status)
    PARENT_CMD=$(ps -p "$PARENT_PID" -o comm,args --no-headers)
    NUM_CHILDREN=$(pgrep -P "$TOP_PID" | wc -l)
    SOFTWARE_NAME=$(ps -p "$TOP_PID" -o comm=)

    if [[ "$PARENT_CMD" =~ bash|zsh|sh ]]; then
      TRIGGER="Interactive shell"
    elif [[ "$PARENT_CMD" =~ php|python|node ]]; then
      TRIGGER="Script"
    elif [[ "$PARENT_CMD" =~ systemd ]]; then
      TRIGGER="Systemd service"
    else
      TRIGGER="Unknown or indirect trigger"
    fi

    {
      echo "[ALERT] $TIMESTAMP | $TOP_INFO"
      echo "User              : $USER_LAUNCHER"
      echo "Working directory : $CWD"
      echo "Executed file     : $SOURCE_FILE"
      echo "Command line      : $CMDLINE"
      echo "Parent            : $PARENT_PID -> $PARENT_CMD"
      echo "Trigger           : $TRIGGER"
      echo "Fork count        : $NUM_CHILDREN"
      trace_parents "$TOP_PID"
      echo "--------------------------------------------------"
    } >> "$LOG"

    notify-send -u critical -t 10000 "Memory overload detected" "$TOP_INFO" 2>/dev/null

    kill -9 "$TOP_PID"

    echo "[KILLED] $TIMESTAMP | PID: $TOP_PID | Software: $SOFTWARE_NAME | RSS: ${MEM_USED} KB"

    sleep 5
  else
    sleep 2
  fi
done
