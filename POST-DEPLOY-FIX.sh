#!/bin/bash
# ============================================================
# POST-DEPLOYMENT FIX SCRIPT
# Run this ONCE after: sudo containerlab deploy --topo main.clab.yml
# ============================================================

echo "==========================================="
echo "  POST-DEPLOYMENT FIX"
echo "==========================================="
echo ""

# Step 1: Fix client default routes
echo "Step 1: Fixing client default routes..."
for node in pc1 pc2 srv1 srv2 srv3 srv4; do
    docker exec clab-leaf-spine-lab-$node ip route del default via 172.20.20.1 2>/dev/null || true
done

docker exec clab-leaf-spine-lab-pc1 ip route add default via 192.168.10.1 dev eth1 2>/dev/null || true
docker exec clab-leaf-spine-lab-pc2 ip route add default via 192.168.10.1 dev eth1 2>/dev/null || true
docker exec clab-leaf-spine-lab-srv1 ip route add default via 192.168.20.1 dev eth1 2>/dev/null || true
docker exec clab-leaf-spine-lab-srv2 ip route add default via 192.168.20.1 dev eth1 2>/dev/null || true
docker exec clab-leaf-spine-lab-srv3 ip route add default via 192.168.30.1 dev eth1 2>/dev/null || true
docker exec clab-leaf-spine-lab-srv4 ip route add default via 192.168.30.1 dev eth1 2>/dev/null || true
echo "✓ Default routes fixed"
echo ""

# Step 2: Fix VLAN 21 (srv2)
echo "Step 2: Changing srv2 to VLAN 21..."
docker exec clab-leaf-spine-lab-srv2 ip addr del 192.168.20.11/24 dev eth1 2>/dev/null || true
docker exec clab-leaf-spine-lab-srv2 ip addr add 192.168.21.11/24 dev eth1 2>/dev/null || true
docker exec clab-leaf-spine-lab-srv2 ip route del default 2>/dev/null || true
docker exec clab-leaf-spine-lab-srv2 ip route add default via 192.168.21.1 dev eth1 2>/dev/null || true
echo "✓ srv2 IP changed to 192.168.21.11"
echo ""

# Step 3: Fix leaf-2 bridge
echo "Step 3: Updating leaf-2 bridge to VLAN 21..."
docker exec clab-leaf-spine-lab-leaf-2 ip addr del 192.168.20.1/24 dev br20 2>/dev/null || true
docker exec clab-leaf-spine-lab-leaf-2 ip addr add 192.168.21.1/24 dev br20 2>/dev/null || true
echo "✓ leaf-2 gateway changed to 192.168.21.1"
echo ""

# Step 4: Update OSPF on leaf-2
echo "Step 4: Updating OSPF on leaf-2..."
docker exec clab-leaf-spine-lab-leaf-2 vtysh -c "conf t" \
  -c "router ospf" \
  -c "no network 192.168.20.0/24 area 0" \
  -c "network 192.168.21.0/24 area 0" \
  -c "end" 2>/dev/null
echo "✓ OSPF updated"
echo ""

# Step 5: Update BGP on leaf-2
echo "Step 5: Updating BGP on leaf-2..."
docker exec clab-leaf-spine-lab-leaf-2 vtysh -c "conf t" \
  -c "router bgp 65000" \
  -c "address-family ipv4 unicast" \
  -c "no network 192.168.20.0/24" \
  -c "network 192.168.21.0/24" \
  -c "end" 2>/dev/null
echo "✓ BGP updated"
echo ""

# Wait for routing to converge
echo "Waiting 10 seconds for routing to converge..."
sleep 10
echo ""

echo "==========================================="
echo "  TESTING CONNECTIVITY"
echo "==========================================="
echo ""

# Test same subnet
echo -n "Test 1: pc1 → pc2 (same subnet): "
if docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.10.11 > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test cross-subnet same leaf
echo -n "Test 2: pc1 → srv1 (cross-subnet): "
if docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.20.10 > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test cross-leaf
echo -n "Test 3: pc1 → srv3 (cross-leaf): "
if docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.30.10 > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# Test VLAN 21
echo -n "Test 4: pc1 → srv2 (VLAN 21): "
if docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.21.11 > /dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo ""
echo "==========================================="
echo "  SETUP COMPLETE!"
echo "==========================================="
echo ""
echo "VLAN Configuration:"
echo "  VLAN 10: 192.168.10.0/24 - pc1, pc2 (leaf-1)"
echo "  VLAN 20: 192.168.20.0/24 - srv1 (leaf-1)"
echo "  VLAN 21: 192.168.21.0/24 - srv2 (leaf-2)"
echo "  VLAN 30: 192.168.30.0/24 - srv3, srv4 (leaf-2)"
echo ""
echo "Run: ./test-connectivity.sh for full test suite"
echo ""
