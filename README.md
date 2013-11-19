get_server_info
===============

# Why ?
Fetch server details like Total CPU, Memory, Disk Usage and store in CSV format using Bash Script 

# Requirements
SSH Password less authentication required 
[ You can modify script for use tool like `sshpass` ]


# How to use it?
```
wget https://raw.github.com/rahulinux/get_server_info/master/get_srv_info.sh
chmod +x get_srv_info.sh
# Add server ip's in server list
echo '127.0.0.1' >> /opt/servers.list
./get_srv_info.sh
```

# Sample Output Report
![OUTPUT](https://raw.github.com/rahulinux/get_server_info/master/output_sample.PNG)

