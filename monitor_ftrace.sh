#!/bin/bash
COUNT=0
RCOUNT=0

DEBUGFS=$(grep debugfs /proc/mounts | awk '{ print $2; }')

INSTANCE=$1
IP=$2

function prepare_tracer {
        #select tracer
        echo 'function' > ${DEBUGFS}/tracing/current_tracer
        #filter function
        echo kvm* > ${DEBUGFS}/tracing/set_ftrace_filter
        echo virtio* >> ${DEBUGFS}/tracing/set_ftrace_filter
        echo vhost* >> ${DEBUGFS}/tracing/set_ftrace_filter
        #filter PID
        PID=$(grep '<domstatus' /var/run/libvirt/qemu/${INSTANCE}.xml | awk -F \' '{print $6}')
	echo $PID
        echo $PID > ${DEBUGFS}/tracing/set_ftrace_pid
        #enable stacktrace
        #echo 1 > ${DEBUGFS}/tracing/options/func_stack_trace
}

function get_vm_ip {
        # Manager PID
        PID=$(grep '<domstatus' /var/run/libvirt/qemu/${INSTANCE}.xml | awk -F \' '{print $6}')
        # vCPU PIDs
        VCPUPIDS=$(grep '<vcpu pid' /var/run/libvirt/qemu/${INSTANCE}.xml | awk -F \' '{print $2}' | tr "\n" ' ')
}

prepare_tracer
while true; do
        ping -c1 -w1 $IP > /dev/null
        if [[ $? -eq 0 ]]; then COUNT=0; else COUNT=$(echo "$COUNT + 1" | bc); fi
        if [[ $COUNT -gt 4 ]]; then echo "$1 is down after $RCOUNT reboots"; exit 1; fi
        echo 1 > /sys/kernel/debug/tracing/tracing_on
        /home/ubuntu/scripts/winrm_exec.py -f ./reboot.ps1 -x86 $IP > /dev/null
        RCOUNT=$(echo "$RCOUNT + 1" | bc)
        sleep 120
        cat /sys/kernel/debug/tracing/trace > /home/ubuntu/${INSTANCE}.txt
        echo 0 > /sys/kernel/debug/tracing/tracing_on
        sleep 30
	echo $RCOUNT
done

