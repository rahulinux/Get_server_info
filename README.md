get_server_info
===============

# Purpose 
Fetch server details like Total CPU, Memory, Disk Usage and store in CSV format using Bash Script. 

# Requirements

There are two option for remote server authentication 

  - If you have ssh password less authentication, then you can use this script without any changes
  - if you don't have above option then you can install `sshpass` package and uncomment sshpass option in script 


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

