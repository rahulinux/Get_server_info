#!/bin/bash
# 
# Script Name    : get_server_details.sh
# Created On     : Tue Nov 19 17:35:33 IST 2013
# Author         : Rahul Patil<http://www.linuxian.com>
# Purpose        : Fetch server details using ssh and generate report in csv format
# Report Bugs    : https://github.com/rahulinux/get_server_info/issues/new
# 

#set -e
# username to connect via ssh
USER=test
WINUSER=rahul 
WINPASSWORD=password

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



GetWindowsDetails() {
	IP=$1
	wincmd() {
        	winexe -U ${WINUSER}%${WINPASSWORD}  //$IP "${@}"
	}        
	a=$( wincmd "fsutil fsinfo drives" | awk '{ $1=""; print}')
        volums=( ${a//\\/ })
        FS=()
        temp_file=$(mktemp)
        info_temp=/tmp/info.temp
        free_size=()
        total_size=()
        for v in ${volums[@]}
        do
                [[  "${#v}" == 1 ]] && continue
                Partitions_cmd="wincmd \"fsutil fsinfo volumeinfo ${v}\\\\\""
                eval $Partitions_cmd > $temp_file
                cat -A $temp_file | sed 's/\^M^M\$//g' > $info_temp
                FS+=( "$( awk '/File System Name/ {print $NF}' $info_temp)" )
                cmd="wincmd \"fsutil volume diskfree ${v}\\\\\""
                eval $cmd > $temp_file
                cat -A $temp_file | sed 's/\^M^M//g' > $info_temp
                total_size+=( "$(awk '/Total # of bytes/ { print int($NF/1024/1024/1024)}'      $info_temp)" )
                free_size+=( "$(awk '/Total # of free bytes/ { print int($NF/1024/1024/1024)}'  $info_temp)" )
                > $info_temp
        done

	# Fetch system info in file
	wincmd "systeminfo" > $temp_file
	sysinfo=$(mktemp)
	cat -A $temp_file | sed 's/\^M\$//g' > $sysinfo
	# Then Extract required Details :
	# Hostname
	Hostname=$( awk '/Host Name/ { print $3}' $sysinfo )
	# Total CPU
	Total_CPU=$(awk '/Processor/ {print $2}' $sysinfo)
	# Total Memory
	Total_Memory=$( awk '/Total Physical Memory/ { print int($(NF -1)) }' $sysinfo  )
	[[ -r $temp_file ]] && rm -f $temp_file
	[[ -r $sysinfo ]] && rm -f $sysinfo
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

	csv_header 
	fetch_details_in_array=()
	exec 5<${servers_list}
	while read -u 5 -r srv ostype;
	do
		echo "Fetching Details of Host: $srv..... OS $ostype"
		case $ostype in
		[Uu][nN][iI][xX]) 
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
			;;
		  [wW][iI][nN])
			
			GetWindowsDetails $srv
			{
			printf ${srv},${Hostname},${Total_CPU},${Total_Memory}
			n=0
			for f in ${!volums[@]};
			do
				[[ -z ${FS[$f]} ]] && continue
        			#       Filesystem  Size  Used Avail Use% Mounted on
			        used=$( awk -v a=${total_size[$f]} -v b=${free_size[$f]} "BEGIN{ print a - b }" )
			        used_per=$( awk -v t=${total_size[$f]} -v u=$used "BEGIN{ print int((u/t)*100) }" )
				[[ $n -ge 1 ]] && c=',,,' || n=0
			        echo -e ${c},${FS[$f]},${total_size[$f]},$used,${free_size[$f]},${used_per}%,${volums[$f]}
				((n++))
			done } >> $output_csv
			;;
			*) echo "Please specify OS type in $servers_list for $srv"
			;;
		esac

	done  
	echo "All Servers Reports has been created..."
	echo "You can find the same at ${output_csv}"
}


Main
