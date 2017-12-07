#!/usr/bin/env bash
# Author Siddhartha Sankar Sinha
# SAMPLE COMMAND I USE FOR MANUAL CREATION
#
cd /tmp
rm -f /tmp/tmp_vm_list 2>/dev/nul
rm -f /tmp/sc1-vmhosts
touch /tmp/tmp_vm_list 
for VMHOST in {01..20}
	do
		ssh -q -t -o connecttimeout=2 sc1-vmhost-${VMHOST}.pdlab.com "qm list" 1>&2 >>/tmp/tmp_vm_list 
    	ssh -q -t -o connecttimeout=2 sc1-vmhost-${VMHOST}.pdlab.com "vztop -n 1 | col -bx ">/tmp/sc1-vmhost-${VMHOST}.load
    	[ -s /tmp/sc1-vmhost-${VMHOST}.load ] || rm -f /tmp/sc1-vmhost-${VMHOST}.load
    	[ -e /tmp/sc1-vmhost-${VMHOST}.load ] && 
#    		head -1 /tmp/sc1-vmhost-${VMHOST}.load | awk '{print $(NF-2)}' | sed -e 's/\,//g' | awk '{printf "%.0f",$1}' \
#			 > /tmp/sc1-vmhosts.${VMHOST}
			if [ -e /tmp/sc1-vmhost-${VMHOST} ]; then 
				echo -n "sc1-vmhost-${VMHOST} " >> /tmp/sc1-vmhosts
				head -1 /tmp/sc1-vmhost-${VMHOST}.load | awk '{print $(NF-2)}' | sed -e 's/\,//g' |  \
				awk '{printf "%.0f",$1}' >> /tmp/sc1-vmhosts 2>/dev/null
				echo  "" >> /tmp/sc1-vmhosts
				sed -i '/^$/d' sc1-vmhosts
    			[ -s /tmp/sc1-vmhost-${VMHOST} ] || rm -f /tmp/sc1-vmhost-${VMHOST}
    		fi
    	
  	done

ssh -q -t -o connecttimeout=2 sc1-hydrajong-01.pdlab.com "qm list" 1>&2 >>/tmp/tmp_vm_list

sed -i "/VMID/d" /tmp/tmp_vm_list
sort -k1  /tmp/tmp_vm_list> /tmp/new_vm_list && mv -f /tmp/new_vm_list /tmp/tmp_vm_list
LAST_VMID=$(sort -k1  /tmp/tmp_vm_list|tail -1|awk '{print $1}')
NEW_VMID=$(expr ${LAST_VMID} + 1)
export NEW_VMID
echo -n "Type the Host Name::"
read "VM_NAME"
echo -n "Type the brief description[Use _ instead of space]:"
read DESC

SELECT_HOST () {

VMHOST=$(sort -g /tmp/sc1-vmhosts -k 2 | sed -e '1q' |awk '{print $1}')
echo "I will create ${VM_NAME} on ${VMHOST}."

export VMHOST
	
}

BUILD_SERVER () {


#qm create 215 --ide2 local:iso/CentOS-6.8-x86_64-bin-DVD1.iso --cores 2 --memory 16384 --name SIDTESTVM   \
#--net0 e1000,bridge=vmbr0 --ostype l26 --sockets 1 --virtio0 local:72,format=qcow2 -autostart 1 -description ${DESC}  -onboot 1


ssh -t -q -o connecttimeout=10 ${VMHOST} "qm create ${NEW_VMID} --ide2 local:iso/CentOS-6.8-x86_64-bin-DVD1.iso --cores 2 --memory 16384 --name ${VM_NAME} --net0 e1000,bridge=vmbr0 --virtio0 local:72,format=qcow2 --autostart 1 --description ${DESC}  -onboot 1" 


}

SELECT_HOST 
BUILD_SERVER


