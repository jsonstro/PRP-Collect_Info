# PRP-Collect_Info

This script is intended as both a data collection tool and a "helping hand" for sysadmins who know the pleasure of managing/tuning 40GE or 100GE hosts in a multi-vendor, multi-NIC, multi-OS environment. The intended OS at the moment is Centos 6/7. 

There are two scripts, both of which just take space separated list of NICs as their input. The first version (collect_info.sh) outputs into human readable format and is good for initial testing on a host before trying the export script. I have also found it valuable in validating that multiple hosts (or multiple NICs on one host) have identical tuning. The second version (collect_info_csv.sh) outputs into a Google Doc style single-line CSV format which can be imported directly into a google doc using the import tool from the file menu.
