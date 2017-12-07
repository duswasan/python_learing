#!/usr/bin/env bash
# Author: Siddhartha Sinha
# Purpose: Find the server in the cluster with lowest load average and build the VM in that server 
echo "I am collecting some information for you. Get IP Information handy."
#
#
cd /tmp
rm -f /tmp/tmp_ct_list 2>/dev/nul
rm -f /tmp/sc1-vmhosts
touch /tmp/tmp_ct_list 
for VMHOST in {01..20}
  	do
		ssh -q -t -o connecttimeout=2 sc1-vmhost-${VMHOST}.pdlab.com "vzlist" 1>&2 >>/tmp/tmp_ct_list
    	ssh -q -t -o connecttimeout=2 sc1-vmhost-${VMHOST}.pdlab.com "vztop -n 1 | col -bx ">/tmp/sc1-vmhost-${VMHOST}.load
    	[ -s /tmp/sc1-vmhost-${VMHOST}.load ] || rm -f /tmp/sc1-vmhost-${VMHOST}.load
    	[ -e /tmp/sc1-vmhost-${VMHOST}.load ] && 
#    		head -1 /tmp/sc1-vmhost-${VMHOST}.load | awk '{print $(NF-2)}' | sed -e 's/\,//g' | awk '{printf "%.0f",$1}' > /tmp/sc1-vmhosts.${VMHOST}
			if [ -e /tmp/sc1-vmhost-${VMHOST} ]; then 
				echo -n "sc1-vmhost-${VMHOST} " >> /tmp/sc1-vmhosts
				head -1 /tmp/sc1-vmhost-${VMHOST}.load | awk '{print $(NF-2)}' | sed -e 's/\,//g' | awk '{printf "%.0f",$1}' >> /tmp/sc1-vmhosts 2>/dev/null
				echo  "" >> /tmp/sc1-vmhosts
				sed -i '/^$/d' sc1-vmhosts
    			[ -s /tmp/sc1-vmhost-${VMHOST} ] || rm -f /tmp/sc1-vmhost-${VMHOST}
    		fi
    	
  	done


sed -i "/CTID/d" /tmp/tmp_ct_list
sort -k5  /tmp/tmp_ct_list> /tmp/new_ct_list && mv -f /tmp/new_ct_list /tmp/tmp_ct_list
LAST_CTID=$(sort -k5  /tmp/tmp_ct_list|tail -1|awk '{print $1}')
NEW_CTID=$(expr ${LAST_CTID} + 1)
export NEW_CTID
echo -n "Type the User Name here (no Space allowed):"
read "USER_NAME"
echo -n "Enter the IP Address:"
read IPADDRESS
export IPADDRESS

SELECT_HOST () {

VMHOST=$(sort -g /tmp/sc1-vmhosts -k 2 | sed -e '1q' |awk '{print $1}')
echo "I will create sc1-ct-${NEW_CTID}.pdlab.com on ${VMHOST}  and the IP Address is ${IPADDRESS}."

export VMHOST
	
}


BUILD_SERVER() {

ssh -t -q -o connecttimeout=10 ${VMHOST} "pvectl create ${NEW_CTID} /var/lib/vz/template/cache/centos-6.9-custom-x86_64.tar.gz -cpus 2 -description ${USER_NAME}  -disk 100 -hostname sc1-ct-${NEW_CTID}.pdlab.com -ip_address $IPADDRESS -memory 16384 && vzctl set $NEW_CTID --features 'nfs:on' --save &&  vzctl start $NEW_CTID " 

}

SELECT_HOST 
BUILD_SERVER
