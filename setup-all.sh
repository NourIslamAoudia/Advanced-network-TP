#!/bin/bash

PREFIX="clab-leaf-spine-datacenter"

echo "🚀 Configuration complète de la topologie..."
echo ""

echo "⏳ Attente que les conteneurs soient prêts (20 secondes)..."
sleep 20
echo "✅ Prêt à configurer"
echo ""

# ========================================
# Configuration Spine-1
# ========================================
echo "📡 [1/5] Configuration Spine-1..."

docker exec ${PREFIX}-Spine-1 sh -c '
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
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
/etc/init.d/frr restart > /dev/null 2>&1
'
echo "✅ Spine-1 OK"
sleep 2

# ========================================
# Configuration Spine-2
# ========================================
echo "📡 [2/5] Configuration Spine-2..."

docker exec ${PREFIX}-Spine-2 sh -c '
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
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
/etc/init.d/frr restart > /dev/null 2>&1
'
echo "✅ Spine-2 OK"
sleep 2

# ========================================
# Configuration Leaf-1
# ========================================
echo "🌿 [3/5] Configuration Leaf-1..."

docker exec ${PREFIX}-Leaf-1 sh -c '
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
ip addr add 10.255.1.1/32 dev lo
ip addr add 10.0.1.1/31 dev eth1
ip addr add 10.0.1.5/31 dev eth2
ip link add link eth3 name eth3.10 type vlan id 10
ip addr add 192.168.10.1/24 dev eth3.10
ip link set eth3.10 up
ip link add link eth4 name eth4.20 type vlan id 20
ip addr add 192.168.20.1/24 dev eth4.20
ip link set eth4.20 up
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
/etc/init.d/frr restart > /dev/null 2>&1
'
echo "✅ Leaf-1 OK"
sleep 2

# ========================================
# Configuration Leaf-2
# ========================================
echo "🌿 [4/5] Configuration Leaf-2..."

docker exec ${PREFIX}-Leaf-2 sh -c '
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
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
/etc/init.d/frr restart > /dev/null 2>&1
'
echo "✅ Leaf-2 OK"
sleep 2

# ========================================
# Configuration Edge-Router
# ========================================
echo "🛡️  [5/5] Configuration Edge-Router..."

docker exec ${PREFIX}-Edge-Router sh -c '
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
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
/etc/init.d/frr restart > /dev/null 2>&1
'
echo "✅ Edge-Router OK"
sleep 2

# ========================================
# Configuration Serveurs/Clients
# ========================================
echo ""
echo "💻 Configuration des serveurs et clients..."

echo "  [6/9] Server-1..."
docker exec ${PREFIX}-Server-1 sh -c '
ip addr add 192.168.10.10/24 dev eth1
ip route add default via 192.168.10.1
'
echo "  ✅ Server-1 OK"

echo "  [7/9] Server-2..."
docker exec ${PREFIX}-Server-2 sh -c '
ip addr add 192.168.20.10/24 dev eth1
ip route add default via 192.168.20.1
'
echo "  ✅ Server-2 OK"

echo "  [8/9] Client-1..."
docker exec ${PREFIX}-Client-1 sh -c '
ip addr add 192.168.30.10/24 dev eth1
ip route add default via 192.168.30.1
'
echo "  ✅ Client-1 OK"

echo "  [9/9] Internet..."
docker exec ${PREFIX}-Internet sh -c '
ip addr add 203.0.113.2/30 dev eth1
ip route add 10.0.0.0/8 via 203.0.113.1
ip route add 192.168.0.0/16 via 203.0.113.1
'
echo "  ✅ Internet OK"

echo ""
echo "⏳ Attente de convergence BGP (30 secondes)..."
sleep 30

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🔍 VÉRIFICATIONS RAPIDES                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "1️⃣  BGP Summary (Spine-1):"
docker exec ${PREFIX}-Spine-1 vtysh -c "show ip bgp summary" 2>/dev/null | grep -A 10 "Neighbor"

echo ""
echo "2️⃣  Test Ping Server-1 → Gateway:"
docker exec ${PREFIX}-Server-1 ping -c 3 -W 2 192.168.10.1 2>/dev/null && echo "  ✅ OK" || echo "  ❌ FAIL"

echo ""
echo "3️⃣  Test Ping Server-1 → Server-2 (Inter-VLAN):"
docker exec ${PREFIX}-Server-1 ping -c 3 -W 2 192.168.20.10 2>/dev/null && echo "  ✅ OK" || echo "  ❌ FAIL"

echo ""
echo "4️⃣  Test Ping Server-1 → Client-1:"
docker exec ${PREFIX}-Server-1 ping -c 3 -W 2 192.168.30.10 2>/dev/null && echo "  ✅ OK" || echo "  ❌ FAIL"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ CONFIGURATION TERMINÉE !                              ║"
echo "║                                                            ║"
echo "║  🧪 Lancez maintenant : sudo ./test-network.sh            ║"
echo "╚════════════════════════════════════════════════════════════╝"
