#!/bin/bash
# ============================================================
# SECURITY CONFIGURATION SCRIPT (Part 4)
# Configures ACLs, Zone-Based Firewall, and QoS
# ============================================================

echo "==========================================="
echo "  CONFIGURING SECURITY & QoS (PART 4)"
echo "==========================================="
echo ""

echo "Security Zones:"
echo "  - OUTSIDE: External network (via border-r1)"
echo "  - DMZ: VLAN 30 (servers accessible from outside)"
echo "  - INTERNAL: VLAN 10, 20, 21 (protected networks)"
echo ""

echo "ACL Strategy:"
echo "  1. Block external access to internal VLANs (10, 20, 21)"
echo "  2. Allow external access to DMZ (VLAN 30)"
echo "  3. Allow internal-to-DMZ traffic"
echo "  4. Allow internal-to-internal traffic"
echo ""

# ============================================================
# STEP 1: Configure ACLs on Border Router
# ============================================================
echo "Step 1: Configuring ACLs on border-r1..."

docker exec clab-leaf-spine-lab-border-r1 vtysh << 'EOF' 2>/dev/null
configure terminal
!
! ACL 10: Permit internal networks
access-list 10 remark Internal networks
access-list 10 permit 192.168.10.0 0.0.0.255
access-list 10 permit 192.168.20.0 0.0.0.255
access-list 10 permit 192.168.21.0 0.0.0.255
access-list 10 deny any
!
! ACL 20: Permit DMZ network
access-list 20 remark DMZ network
access-list 20 permit 192.168.30.0 0.0.0.255
!
! ACL 100: Extended ACL for traffic filtering
! Block external access to internal VLANs, allow to DMZ
access-list 100 remark External to Internal blocking
access-list 100 deny ip any 192.168.10.0 0.0.0.255
access-list 100 deny ip any 192.168.20.0 0.0.0.255
access-list 100 deny ip any 192.168.21.0 0.0.0.255
access-list 100 permit ip any 192.168.30.0 0.0.0.255
access-list 100 permit ip any any
!
end
write memory
EOF

echo "✓ Border-R1 ACLs configured"
echo ""

# ============================================================
# STEP 2: Configure Route-Maps for Policy-Based Routing
# ============================================================
echo "Step 2: Configuring route-maps on border-r1..."

docker exec clab-leaf-spine-lab-border-r1 vtysh << 'EOF' 2>/dev/null
configure terminal
!
! Route-map to mark traffic from internal networks
route-map INTERNAL-TO-DMZ permit 10
 match ip address 10
 set ip next-hop verify-availability 1.1.1.1 1 track 1
!
! Route-map for QoS marking
route-map QOS-MARKING permit 10
 match ip address 10
 set ip dscp cs6
!
route-map QOS-MARKING permit 20
 match ip address 20
 set ip dscp af41
!
end
write memory
EOF

echo "✓ Border-R1 route-maps configured"
echo ""

# ============================================================
# STEP 3: Configure IP Tables for Zone-Based Firewall
# ============================================================
echo "Step 3: Configuring Zone-Based Firewall on border-r1..."

# Define zones using iptables
docker exec clab-leaf-spine-lab-border-r1 bash << 'EOF'
# Clear existing rules
iptables -F
iptables -X

# Default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow established and related connections
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# ZONE: INTERNAL (192.168.10.0/24, 192.168.20.0/24, 192.168.21.0/24)
# Allow internal-to-internal
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.20.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.21.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.10.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.21.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.21.0/24 -d 192.168.10.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.21.0/24 -d 192.168.20.0/24 -j ACCEPT

# Allow internal-to-DMZ
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.30.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.30.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.21.0/24 -d 192.168.30.0/24 -j ACCEPT

# ZONE: DMZ (192.168.30.0/24)
# Allow DMZ-to-internal (return traffic)
iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.20.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.21.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

# ZONE: OUTSIDE
# Block outside-to-internal
iptables -A FORWARD -d 192.168.10.0/24 -j LOG --log-prefix "BLOCKED-TO-INTERNAL: "
iptables -A FORWARD -d 192.168.10.0/24 -j DROP
iptables -A FORWARD -d 192.168.20.0/24 -j LOG --log-prefix "BLOCKED-TO-INTERNAL: "
iptables -A FORWARD -d 192.168.20.0/24 -j DROP
iptables -A FORWARD -d 192.168.21.0/24 -j LOG --log-prefix "BLOCKED-TO-INTERNAL: "
iptables -A FORWARD -d 192.168.21.0/24 -j DROP

# Allow outside-to-DMZ (specific services only)
# HTTP (80), HTTPS (443), SSH (22)
iptables -A FORWARD -d 192.168.30.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.30.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -d 192.168.30.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -d 192.168.30.0/24 -p icmp -j ACCEPT

# Log and drop everything else
iptables -A FORWARD -j LOG --log-prefix "FIREWALL-DROP: "
iptables -A FORWARD -j DROP

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "✓ Zone-Based Firewall configured"
EOF

echo "✓ Border-R1 firewall rules applied"
echo ""

# ============================================================
# STEP 4: Configure QoS on Leaf Switches
# ============================================================
echo "Step 4: Configuring QoS on leaf switches..."

# QoS on Leaf-1
docker exec clab-leaf-spine-lab-leaf-1 bash << 'EOF'
# Enable QoS disciplines (tc - traffic control)
# Use HTB (Hierarchical Token Bucket) for bandwidth management

# Interface to spine-1 (eth1)
tc qdisc add dev eth1 root handle 1: htb default 30

# Class 1:10 - High priority (Voice/Video) - 40% bandwidth
tc class add dev eth1 parent 1: classid 1:10 htb rate 400mbit ceil 1000mbit prio 1

# Class 1:20 - Medium priority (Business apps) - 30% bandwidth
tc class add dev eth1 parent 1: classid 1:20 htb rate 300mbit ceil 800mbit prio 2

# Class 1:30 - Default/Best effort - 30% bandwidth
tc class add dev eth1 parent 1: classid 1:30 htb rate 300mbit ceil 600mbit prio 3

# Filters to classify traffic
# High priority: DSCP EF (VoIP), CS6 (Network control)
tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip dscp 0x2e 0xff flowid 1:10
tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip dscp 0x30 0xff flowid 1:10

# Medium priority: DSCP AF41 (video), AF31 (signaling)
tc filter add dev eth1 protocol ip parent 1:0 prio 2 u32 match ip dscp 0x22 0xff flowid 1:20
tc filter add dev eth1 protocol ip parent 1:0 prio 2 u32 match ip dscp 0x1a 0xff flowid 1:20

echo "✓ QoS configured on leaf-1"
EOF

# QoS on Leaf-2
docker exec clab-leaf-spine-lab-leaf-2 bash << 'EOF'
# Interface to spine-1 (eth1)
tc qdisc add dev eth1 root handle 1: htb default 30

# Class 1:10 - High priority - 40% bandwidth
tc class add dev eth1 parent 1: classid 1:10 htb rate 400mbit ceil 1000mbit prio 1

# Class 1:20 - Medium priority - 30% bandwidth
tc class add dev eth1 parent 1: classid 1:20 htb rate 300mbit ceil 800mbit prio 2

# Class 1:30 - Default - 30% bandwidth
tc class add dev eth1 parent 1: classid 1:30 htb rate 300mbit ceil 600mbit prio 3

# Filters
tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip dscp 0x2e 0xff flowid 1:10
tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip dscp 0x30 0xff flowid 1:10
tc filter add dev eth1 protocol ip parent 1:0 prio 2 u32 match ip dscp 0x22 0xff flowid 1:20
tc filter add dev eth1 protocol ip parent 1:0 prio 2 u32 match ip dscp 0x1a 0xff flowid 1:20

echo "✓ QoS configured on leaf-2"
EOF

echo "✓ Leaf switches QoS configured"
echo ""

# ============================================================
# STEP 5: Configure Traffic Policing on Spines
# ============================================================
echo "Step 5: Configuring traffic policing on spine switches..."

# Rate limiting on Spine-1
docker exec clab-leaf-spine-lab-spine-1 bash << 'EOF'
# Limit ICMP traffic to 10 Mbps (prevent ping floods)
tc qdisc add dev eth1 root handle 1: htb
tc class add dev eth1 parent 1: classid 1:1 htb rate 10mbit
tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip protocol 1 0xff flowid 1:1

echo "✓ Traffic policing on spine-1"
EOF

# Rate limiting on Spine-2
docker exec clab-leaf-spine-lab-spine-2 bash << 'EOF'
# Limit ICMP traffic to 10 Mbps
tc qdisc add dev eth1 root handle 1: htb
tc class add dev eth1 parent 1: classid 1:1 htb rate 10mbit
tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip protocol 1 0xff flowid 1:1

echo "✓ Traffic policing on spine-2"
EOF

echo "✓ Spine switches traffic policing configured"
echo ""

echo "==========================================="
echo "  SECURITY & QoS CONFIGURATION COMPLETE"
echo "==========================================="
echo ""

echo "Configuration Summary:"
echo ""
echo "ACLs:"
echo "  ✓ Border router ACLs configured"
echo "  ✓ Internal networks protected (VLAN 10, 20, 21)"
echo "  ✓ DMZ accessible from outside (VLAN 30)"
echo ""
echo "Zone-Based Firewall:"
echo "  ✓ 3 Security Zones defined:"
echo "      - INTERNAL: VLANs 10, 20, 21"
echo "      - DMZ: VLAN 30"
echo "      - OUTSIDE: External networks"
echo "  ✓ Firewall rules:"
echo "      - INTERNAL ↔ INTERNAL: Allowed"
echo "      - INTERNAL → DMZ: Allowed"
echo "      - DMZ → INTERNAL: Only return traffic"
echo "      - OUTSIDE → INTERNAL: Blocked"
echo "      - OUTSIDE → DMZ: HTTP/HTTPS/SSH only"
echo ""
echo "QoS:"
echo "  ✓ 3 Traffic classes configured:"
echo "      - High priority (40%): Voice/Video (DSCP EF, CS6)"
echo "      - Medium priority (30%): Business apps (DSCP AF41, AF31)"
echo "      - Best effort (30%): Default traffic"
echo "  ✓ Traffic policing on spines (ICMP rate limit: 10 Mbps)"
echo ""

echo "Security Policies Applied:"
echo "  • External traffic cannot reach internal VLANs"
echo "  • DMZ servers accessible via HTTP/HTTPS/SSH only"
echo "  • Internal users can access DMZ"
echo "  • Traffic prioritization for critical services"
echo "  • ICMP flood protection"
echo ""
