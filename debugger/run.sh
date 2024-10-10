#!/bin/sh
set -eu

export MAINAPP_PID=$(sh -c 'pgrep /usr/bin/java')
export DEBUGGER_ROOT=/.debugger

# make debugger fs easily accessible to main container
DEBUGGER_PID=$(sh -c 'echo $PPID')
rm -f /proc/${MAINAPP_PID}/root${DEBUGGER_ROOT}
ln -s /proc/${DEBUGGER_PID}/root/ /proc/${MAINAPP_PID}/root${DEBUGGER_ROOT}

# inject some extra tools to main container (optional)
mkdir -p /proc/${MAINAPP_PID}/root/tools
cp -r /tools/* /proc/${MAINAPP_PID}/root/tools || true 2>/dev/null

# run sh with main container's root fs
cat > /.debugger.sh <<EOF
#!/bin/sh
export PATH=$PATH:$DEBUGGER_ROOT/bin:$DEBUGGER_ROOT/usr/bin:$DEBUGGER_ROOT/sbin:$DEBUGGER_ROOT/usr/sbin:$DEBUGGER_ROOT/usr/local/bin:$DEBUGGER_ROOT/usr/local/sbin
chroot /proc/${MAINAPP_PID}/root sh
EOF

exec sh /.debugger.sh
