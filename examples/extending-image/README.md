Image extending example
===================================

See image [README.md](https://github.com/sclorg/mongodb-container/blob/master/3.2/root/usr/share/container-scripts/mongodb/README.md) for decription how to extend image using s2i.


What this example configuration does:
```
├── mongodb-cfg
│   └── mongod.conf			# Configuration file for mongod server
├── mongodb-init
│   ├── 11-init-backup-user.sh		# Create special user for backups
│   └── 50-initial-store.sh		# Store information in database
├── mongodb-pre-init
│   ├── 11-check-additional-user.sh	# Check that credentials for backups are provided
│   └── 20-setup-wiredtiger-cache.sh	# Overwrites default script for configuring wiredTiger cache
└── README.md
```
