#!/bin/bash
# 
# Script Name    : get_server_details.sh
# Created On     : Tue Nov 19 17:35:33 IST 2013
# Author         : Rahul Patil<http://www.linuxian.com>
# Purpose        : Fetch server details using ssh and generate report in csv format
# Report Bugs    : loginrahul90@gmail.com
# 

set -e
# username to connect via ssh
USER=root
# destintion path/filename to save results to
output_csv='/opt/serverinfo.csv'
# source list of hostnames to read from
servers_list='/opt/servers.list'

func_ssh() {

	local Ipaddr=$1
	local Cmd="${@:2}"
	# if you don't have ssh key based authenticaion setup and if you want manually specify password
	# then you can install `sshpass` package and uncomment following line 
	
	# For sshpass 
	# sshpass -p 'password' ssh -q -o "ConnectTimeout 5" -o "StrictHostKeyChecking no" -l $USER $Ipaddr "${Cmd}" ||
        # printf "${Ipaddr}\tUnable to connect to host\n"
	
	#-----------------------------------------------
	# For key based auth
	ssh -q -o "BatchMode yes" -o "ConnectTimeout 5" -o "StrictHostKeyChecking no" -l $USER $Ipaddr "${Cmd}" ||
	printf "${Ipaddr}\tUnable to connect to host\n" 
}

csv_header() {

	echo 'IPaddr,Hostname,CPU count,Total Memory,FileSystem,Size,Used,Avail,Used%,Mount' >\
	${output_csv}

}

GetFQDN='hostname -f'
GetCPUcount="awk '/processor/{a++} END{print a}'  /proc/cpuinfo"
GetMemoryDetails='free -m | awk "/Mem:/{ print \$2 }"'
GetDiskUsage="df -hP"

ParseDiskUsage() {
	local usage="$1"
	a=0
 	awk '!/Filesystem/' $1 |
        while read -a line;
        do
		[[ $a = 1 ]] && printf ',,,,'
                for (( i=0;$i<${#line[@]};i++));
                do
                        printf "%s," ${line[$i]};
			[[ $i = 0 ]] && a=1
                done
                echo ''
        done
}


# Iterate through line items in servers_list and
# execute ssh, if we connected successfully
# Fetch proc/info and free to find memory/cpu alloc
# write it to output_csv path/file
# if we dont connect successfully, 

Main(){
	[[ -f $servers_list ]] || { echo "Error: server list does not exists ${servers_list}" >&2; exit 1; }
	fetch_details_in_array=()
	csv_header 
	for srv in $(< $servers_list );
	do
		echo "Fetching Details of Host: $srv....."
		fetch_details_in_array+=( "${srv}" )
		fetch_details_in_array+=( "$( func_ssh $srv $GetFQDN  )" )
		fetch_details_in_array+=( "$( func_ssh $srv $GetCPUcount )" )
		fetch_details_in_array+=( "$( func_ssh $srv $GetMemoryDetails )" )
		df_out=$(mktemp)
		func_ssh $srv $GetDiskUsage >$df_out 
		{
			printf "%s," ${fetch_details_in_array[@]}
			ParseDiskUsage $df_out
		} >> $output_csv
		echo "Done"
		fetch_details_in_array=()

	done
	echo "All Servers Reports has been created..."
	echo "You can find the same at ${output_csv}"
	echo "Thanks for using this script..."
	echo "The Linuxian."
}


Main
