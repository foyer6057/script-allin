#!/bash/sh


size=$(($1*1024))

dd if=/dev/zero of=/swapfile bs=1M count=$size

chmod 600 /swapfile

mkswap /swapfile

swapon/swapfile

cat <<EOF >>/etc/fstab
/swapfile swap swap defaults 0 0
EOF

free -h