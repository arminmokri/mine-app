#!/bin/bash

### get config
this_file_path=$(eval "realpath $0")
this_dir_path=$(eval "dirname $this_file_path")
source "$this_dir_path/../../config/main.conf"

### reboot path
reboot_path="$app_dir_path/bin/reboot/reboot.sh"

### mine path
mine_path="$app_dir_path/bin/mine/mine.sh"

if [ -f $web_pipe_file_path ]
then
   action=$(eval "cat $web_pipe_file_path")
   rm $web_pipe_file_path
   if [[ "$action" == "reboot_system"* ]] ### reboot_system
   then
      reboot_type=$(eval "echo $action | cut -d '/' -f 2")
      $reboot_path "web" "$reboot_type"
   elif [ "$pool" == "restart_mining" ] ### restart_mining
   then
      $mine_path "web"
   fi
fi
