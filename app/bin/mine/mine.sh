#!/bin/bash

### get config
this_file_path=$(eval "realpath $0")
this_dir_path=$(eval "dirname $this_file_path")
source "$this_dir_path/../../../config/main.conf"

### datetime path
datetime_path="$app_dir_path/bin/datetime.sh"

### gpu global vars path
gpu_global_vars_path="$app_dir_path/bin/mine/gpu_global_vars.sh"

### overclock path
overclock_path="$app_dir_path/bin/mine/overclock.sh"

### start mine path
start_mine_path="$app_dir_path/bin/mine/start_mine.sh"

### stop mine path
stop_mine_path="$app_dir_path/bin/mine/stop_mine.sh"

### get datetime
datetime_res=$(eval $datetime_path)

###
caller_proc=""
if [ $# -eq 1 ]
then
   caller_proc=$1
else
   caller_proc="manual"
fi

### Do Not Run If On Running
pid_file="/tmp/mine.sh.pid"
if [ -f $pid_file ]
then
   echo "$datetime_res | Miner | $caller_proc | Failed" >> $mine_log_path
   exit
fi
trap "rm $pid_file 2>/dev/null" EXIT
echo $$ > $pid_file

### Stop
$stop_mine_path

### mv
mv $mining_log_path $mining_old_log_path

### run gpu global vars
$gpu_global_vars_path 2> $gpu_global_vars_log_path

### Start
$start_mine_path 1> $mining_log_path 2> $mining_log_path &
sleep 120

### run overclock
$overclock_path 2> $overclock_log_path

###
echo "$datetime_res | Miner | $caller_proc | Successed" >> $mine_log_path
