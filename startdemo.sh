#!/usr/bin/env bash

set -e

demo=${1%/}

echo $demo

if [ -f "demo.lock" ]; then
    echo "There is already a demo running:"
    cat demo.lock
    exit
fi

cp $demo/infrastructure_config.py .

if [ -f $demo/sf-config.sh ]; then
    cp $demo/sf-config.sh .
fi

echo "Starting demo from $demo with vars:"
echo "Number of nodes: " $NUM_NODES
echo "Opendaylight Controller: " $ODL
echo "Base subnet: " $SUBNET

for i in `seq 1 $NUM_NODES`; do
#for i in 1 6; do
  hostname="netvirtsfc"$i
  echo $hostname
  vagrant ssh $hostname -c "sudo -E /vagrant/infrastructure_launch.py"
done

sleep 5
echo "Clean l2switch flows"
for i in 1 2 4 6; do
  hostname="netvirtsfc"$i
  sw="sw"$i
  echo $hostname
  vagrant ssh $hostname -c "sudo ovs-ofctl -O OpenFlow13 --strict del-flows br-int priority=1,arp"
  vagrant ssh $hostname -c "sudo ovs-ofctl -O OpenFlow13 --strict del-flows $sw priority=1,arp"
done

echo "Configuring controller..."
./$demo/rest.py

echo "Post-controller configuration..."
cp $demo/get-nsps.py .
for i in `seq 1 $NUM_NODES`; do
  hostname="netvirtsfc"$i
  echo $hostname
  vagrant ssh $hostname -c "sudo -E /vagrant/get-nsps.py"
done

sleep 5
for i in 1 6; do
  hostname="netvirtsfc"$i
  sw="sw"$i
  echo $hostname
  vagrant ssh $hostname -c "sudo ovs-vsctl show; sudo ovs-ofctl -O OpenFlow13 dump-flows $sw"
done

echo "$demo" > demo.lock

