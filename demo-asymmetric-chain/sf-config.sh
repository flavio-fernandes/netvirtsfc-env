#!/usr/bin/env bash

set -e
hostnum=${HOSTNAME#"netvirtsfc"}
sw="sw$hostnum"

if [ "$hostnum" -eq "3" ]; then
    TUNNEL=0xC0A83247
elif [ "$hostnum" -eq "5" ]; then
    TUNNEL=0xC0A83249
else
    echo "Invalid SF for this demo";
    exit
fi

sudo ovs-vsctl add-br $sw
sudo ovs-vsctl add-port $sw $sw-vxlangpe-0 -- set interface $sw-vxlangpe-0 type=vxlan options:remote_ip=flow options:dst_port=6633 options:nshc1=flow options:nshc2=flow options:nshc3=flow options:nshc4=flow options:nsp=flow options:nsi=flow options:key=flow

sudo ovs-ofctl --strict del-flows $sw priority=0
sudo ovs-ofctl add-flow $sw "priority=1000,nsi=255 actions=move:NXM_NX_NSH_C1[]->NXM_NX_NSH_C1[],move:NXM_NX_NSH_C2[]->NXM_NX_NSH_C2[],move:NXM_NX_TUN_ID[0..31]->NXM_NX_TUN_ID[0..31],load:$TUNNEL->NXM_NX_TUN_IPV4_DST[],set_nsi:254,IN_PORT" -OOpenFlow13
sudo ovs-ofctl add-flow $sw "priority=1000,nsi=254 actions=move:NXM_NX_NSH_C1[]->NXM_NX_NSH_C1[],move:NXM_NX_NSH_C2[]->NXM_NX_NSH_C2[],move:NXM_NX_TUN_ID[0..31]->NXM_NX_TUN_ID[0..31],load:$TUNNEL->NXM_NX_TUN_IPV4_DST[],set_nsi:253,IN_PORT" -OOpenFlow13
