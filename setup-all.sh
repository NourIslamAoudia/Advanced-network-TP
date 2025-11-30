#!/bin/bash

PREFIX="clab-leaf-spine-datacenter"

echo "🚀 Configuration complète de la topologie..."
echo ""

# ========================================
# Configuration Spine-1
# ========================================
echo "📡 [1/5] Configuration Spine-1..."
docker exec ${PREFIX}-Spine-1 sh -c '
ip addr add 10.255.0.1/32 dev lo
ip addr add 10.0.1.0/31 dev eth1
ip addr add 10.0.1.2/31 dev eth2
ip addr add 10.0.2.0/31 dev eth3
sed -i "s/bgpd=no/bgpd=yes/g" /etc/frr/daemons
cat > /etc/frr/frr.conf << "EOFFRR"
frr version 8.0
frr defaults traditional
hostname Spine-1
no ipv6 forwarding
service integrated-vtysh-config
!
router bgp 65000
 bgp router-id 10.255.0.1
 neighbor 10.0.1.1 remote-as 65001
 neighbor 10.0.1.3 remote-as 65002
 neighbor 10.0.2.1 remote-as 65100
 !
 address-family ipv4 unicast
  network 10.255.0.1/32
  neighbor 10.0.1.1 activate
  neighbor 10.0.1.3 activate
  neighbor 10.0.2.1 activate
 exit-address-family
!
EOFFRR
/etc/init.d/frr start
'
echo "✅ Spine-1 OK"

# ========================================
# Configuration Spine-2
# ========================================
echo "📡 [2/5] Configuration Spine-2..."
docker exec ${PREFIX}-Spine-2 sh -c '
ip addr add 10.255.0.2/32 dev lo
ip addr add 10.0.1.4/31 dev eth1
ip addr add 10.0.1.6/31 dev eth2
ip addr add 10.0.2.2/31 dev eth3
sed -i "s/bgpd=no/bgpd=yes/g" /etc/frr/daemons
cat > /etc/frr/frr.conf << "EOFFRR"
frr version 8.0
frr defaults traditional
hostname Spine-2
no ipv6 forwarding
service integrated-vtysh-config
!
router bgp 65000
 bgp router-id 10.255.0.2
 neighbor 10.0.1.5 remote-as 65001
 neighbor 10.0.1.7 remote-as 65002
 neighbor 10.0.2.3 remote-as 65100
 !
 address-family ipv4 unicast
  network 10.255.0.2/32
  neighbor 10.0.1.5 activate
  neighbor 10.0.1.7 activate
  neighbor 10.0.2.3 activate
 exit-address-family
!
EOFFRR
/etc/init.d/frr start
'
echo "✅ Spine-2 OK"

# ========================================
# Configuration Leaf-1
# ========================================
echo "🌿 [3/5] Configuration Leaf-1..."
docker exec ${PREFIX}-Leaf-1 sh -c '
ip addr add 10.255.1.1/32 dev lo
ip addr add 10.0.1.1/31 dev eth1
ip addr add 10.0.1.5/31 dev eth2
ip link add link eth3 name eth3.10 type vlan id 10
ip link add link eth3 name eth3.20 type vlan id 20
ip addr add 192.168.10.1/24 dev eth3.10
ip addr add 192.168.20.1/24 dev eth3.20
ip link set eth3.10 up
ip link set eth3.20 up
sed -i "s/bgpd=no/bgpd=yes/g" /etc/frr/daemons
cat > /etc/frr/frr.conf << "EOFFRR"
frr version 8.0
frr defaults traditional
hostname Leaf-1
no ipv6 forwarding
service integrated-vtysh-config
!
router bgp 65001
 bgp router-id 10.255.1.1
 neighbor 10.0.1.0 remote-as 65000
 neighbor 10.0.1.4 remote-as 65000
 !
 address-family ipv4 unicast
  network 10.255.1.1/32
  network 192.168.10.0/24
  network 192.168.20.0/24
  neighbor 10.0.1.0 activate
  neighbor 10.0.1.4 activate
 exit-address-family
!
EOFFRR
/etc/init.d/frr start
'
echo "✅ Leaf-1 OK"

# ========================================
# Configuration Leaf-2
# ========================================
echo "🌿 [4/5] Configuration Leaf-2..."
docker exec ${PREFIX}-Leaf-2 sh -c '
ip addr add 10.255.1.2/32 dev lo
ip addr add 10.0.1.3/31 dev eth1
ip addr add 10.0.1.7/31 dev eth2
ip link add link eth3 name eth3.30 type vlan id 30
ip addr add 192.168.30.1/24 dev eth3.30
ip link set eth3.30 up
sed -i "s/bgpd=no/bgpd=yes/g" /etc/frr/daemons
cat > /etc/frr/frr.conf << "EOFFRR"
frr version 8.0
frr defaults traditional
hostname Leaf-2
no ipv6 forwarding
service integrated-vtysh-config
!
router bgp 65002
 bgp router-id 10.255.1.2
 neighbor 10.0.1.2 remote-as 65000
 neighbor 10.0.1.6 remote-as 65000
 !
 address-family ipv4 unicast
  network 10.255.1.2/32
  network 192.168.30.0/24
  neighbor 10.0.1.2 activate
  neighbor 10.0.1.6 activate
 exit-address-family
!
EOFFRR
/etc/init.d/frr start
'
echo "✅ Leaf-2 OK"

# ========================================
# Configuration Edge-Router
# ========================================
echo "🛡️  [5/5] Configuration Edge-Router..."
docker exec ${PREFIX}-Edge-Router sh -c '
ip addr add 10.255.255.1/32 dev lo
ip addr add 10.0.2.1/31 dev eth1
ip addr add 10.0.2.3/31 dev eth2
ip addr add 203.0.113.1/30 dev eth3
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 192.168.0.0/16 -j ACCEPT
iptables -P FORWARD DROP
sed -i "s/bgpd=no/bgpd=yes/g" /etc/frr/daemons
cat > /etc/frr/frr.conf << "EOFFRR"
frr version 8.0
frr defaults traditional
hostname Edge-Router
no ipv6 forwarding
service integrated-vtysh-config
!
router bgp 65100
 bgp router-id 10.255.255.1
 neighbor 10.0.2.0 remote-as 65000
 neighbor 10.0.2.2 remote-as 65000
 !
 address-family ipv4 unicast
  network 10.255.255.1/32
  network 203.0.113.0/30
  neighbor 10.0.2.0 activate
  neighbor 10.0.2.2 activate
 exit-address-family
!
EOFFRR
/etc/init.d/frr start
'
echo "✅ Edge-Router OK"

echo ""
echo "⏳ Attente de convergence BGP (30 secondes)..."
sleep 30

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ CONFIGURATION TERMINÉE !                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Vérifications rapides :"
docker exec ${PREFIX}-Spine-1 vtysh -c "show ip bgp summary" 2>/dev/null | grep -E "Neighbor|10.0"
echo ""
docker exec ${PREFIX}-Server-1 ping -c 2 192.168.30.10
