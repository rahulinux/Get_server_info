Get_server_info
===============

# Why this kolaveri di ?
To fetch server details like Total CPU, Memory, Disk Usage, etc.. from central linux box and store in CSV format using Bash Script. 

# Requirements

  - There are two option for remote server authentication 
    - If you have ssh password less authentication, then you can use this script without any changes
    - if you don't have above option then you can install `sshpass` package and uncomment sshpass option in script

  - If you want details of windows server, then you must install WMI tool on your Linux Box and need some modification on windows server also. Refer [this](http://linuxian.com/2013/12/03/how-to-run-windows-commands-from-linux-box/) page to install WMI. 

# Features
  - It Supports Following OS:
    - Linux
    - Windows
    - AIX ( under-construstion )

# How to use it?
```
wget https://raw.github.com/rahulinux/get_server_info/master/get_srv_info.sh
chmod +x get_srv_info.sh
# Add server ip's in server list
echo '127.0.0.1  unix' >> /opt/servers.list
echo '192.168.1.10  win' >> /opt/servers.list
./get_srv_info.sh
```

# Sample Output Report
![OUTPUT](https://raw.github.com/rahulinux/get_server_info/master/output_sample.PNG)

# Contribute
Report issues on [github issue page](https://github.com/rahulinux/Get_server_info/issues) or fork the project (let me know if you do).

# LICENSE 
This Script is provided as-is under the [MIT License](https://github.com/rahulinux/Get_server_info/blob/master/LICENSE)

