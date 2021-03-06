#!/bin/bash

### get config
this_file_path=$(eval "realpath $0")
this_dir_path=$(eval "dirname $this_file_path")
source "$this_dir_path/../../../config/main.conf"

### datetime path
datetime_path="$app_dir_path/bin/datetime.sh"

### get datetime
datetime_res=$(eval $datetime_path)

### if achieve number of try times to get data, do exit
datetime_sec=$(eval "date --date='$datetime_res' '+%S'")

### mine path
mine_path="$app_dir_path/bin/mine/mine.sh"

### reboot path
reboot_path="$app_dir_path/bin/reboot/reboot.sh"

### get current hashrate
current_hashrate=0
if [ "$pool" == "nanopool.org" ] ### nanopool.org
then
   json=$(eval "wget -qO - 'https://api.nanopool.org/v1/eth/hashrate/$pool_wallet_id'")
   current_hashrate=$(echo $json | jq '.data')
   if [ "$current_hashrate" == "null" ] || [ "$current_hashrate" == "" ]
   then
      if [ "$current_hashrate_log_try_times" == "0" ] || [ "$current_hashrate_log_try_times" -ge "$datetime_sec" ]
      then
         sleep 1
         "$(eval "realpath $0")"
         exit
      else
         current_hashrate="-1"
      fi
   fi
elif [ "$pool" == "miningpoolhub.com" ] ### miningpoolhub.com
then
   json=$(eval "wget -qO - 'https://ethereum.miningpoolhub.com/index.php?page=api&action=getuserhashrate&api_key=$pool_api_key'")
   current_hashrate=$(echo $json | jq '.getuserhashrate.data')
   if [ "$current_hashrate" == "null" ] || [ "$current_hashrate" == "" ]
   then
      if [ "$current_hashrate_log_try_times" == "0" ] || [ "$current_hashrate_log_try_times" -ge "$datetime_sec" ]
      then
         sleep 1
         "$(eval "realpath $0")"
         exit
      else
         current_hashrate="-1"
      fi
   else
      current_hashrate=$(eval "bc <<< 'scale=2; $current_hashrate/1024'")
   fi
elif [ "$pool" == "ethermine.org" ] ### ethermine.org
then
   json=$(eval "wget -qO - 'https://api.ethermine.org/miner/$pool_wallet_id/currentStats'")
   api_status=$(echo $json | jq '.status')
   if [ "$api_status" == "\"OK\"" ]
   then
      current_hashrate=$(echo $json | jq '.data.currentHashrate')
      current_hashrate=$(eval "bc <<< 'scale=2; $current_hashrate/(1000*1000)'")
   else
      if [ "$current_hashrate_log_try_times" == "0" ] || [ "$current_hashrate_log_try_times" -ge "$datetime_sec" ]
      then
         sleep 1
         "$(eval "realpath $0")"
         exit
      else
         current_hashrate="-1"
      fi
   fi
else ### other pools not implemented yet
   current_hashrate=0
fi

### log current hashrate
if [ "$current_hashrate" == "-1" ]
then
   echo "$datetime_res | Unavailable Data, Try($current_hashrate_log_try_times)" >> $current_hashrate_log_path
else
   echo "$datetime_res | $current_hashrate Mh/s" >> $current_hashrate_log_path
   ###
   if [ "$current_hashrate_continuously_zero_times" != "0" ] && [ "$current_hashrate" == "0" ]
   then
      ### get current_hashrate_zero_counter
      if [ -e "$current_hashrate_zero_counter_path" ]
      then
         current_hashrate_zero_counter=$(eval "cat $current_hashrate_zero_counter_path")
      else
         current_hashrate_zero_counter=0
      fi
      ### inc current_hashrate_zero_counter
      let current_hashrate_zero_counter=current_hashrate_zero_counter+1

      ### check action conditions
      uptime_in_minute=$(eval "echo $(awk '{print $1}' /proc/uptime) / 60 | bc")
      if [ "$current_hashrate_zero_counter" -ge "$current_hashrate_continuously_zero_times" ] && [ "$uptime_in_minute" -ge "$current_hashrate_continuously_zero_uptime" ]
      then
         ### do action restart_mining/reboot_system
         if [ "$current_hashrate_continuously_zero_action" == "restart_mining" ]
         then
            echo "0" > $current_hashrate_zero_counter_path
            $mine_path "current hashrate (hashrate $current_hashrate_zero_counter times was zero)"
         elif [[ "$current_hashrate_continuously_zero_action" == "reboot_system"* ]]
         then
            echo "0" > $current_hashrate_zero_counter_path
            reboot_type=$(eval "echo $current_hashrate_continuously_zero_action | cut -d '/' -f 2")
            $reboot_path "current hashrate (hashrate $current_hashrate_zero_counter times was zero)" "$reboot_type"
         fi
      else
         echo "$current_hashrate_zero_counter" > $current_hashrate_zero_counter_path
      fi
   else
      echo "0" > $current_hashrate_zero_counter_path
   fi
fi
