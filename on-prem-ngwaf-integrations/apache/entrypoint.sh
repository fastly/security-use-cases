# Start the agent. Run in the background
/usr/sbin/sigsci-agent &

# Start Apache
apache2ctl -D FOREGROUND
