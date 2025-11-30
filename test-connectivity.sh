#!/bin/bash

echo "==========================================="
echo "  CONTAINERLAB CONNECTIVITY TEST SUITE"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_ping() {
    local from=$1
    local to=$2
    local ip=$3
    local desc=$4

    echo -n "Testing: $desc ... "
    if docker exec clab-leaf-spine-lab-$from ping -c 2 -W 2 $ip > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

echo "========================================="
echo "TEST 1: Same Subnet Connectivity"
echo "========================================="
test_ping "pc1" "pc2" "192.168.10.11" "pc1 → pc2 (same subnet)"
test_ping "pc2" "pc1" "192.168.10.10" "pc2 → pc1 (same subnet)"
test_ping "srv3" "srv4" "192.168.30.11" "srv3 → srv4 (same subnet)"
echo ""

echo "========================================="
echo "TEST 2: Gateway Connectivity"
echo "========================================="
test_ping "pc1" "gateway" "192.168.10.1" "pc1 → gateway (leaf-1)"
test_ping "srv1" "gateway" "192.168.20.1" "srv1 → gateway (leaf-1)"
test_ping "srv3" "gateway" "192.168.30.1" "srv3 → gateway (leaf-2)"
echo ""

echo "========================================="
echo "TEST 3: Cross-Subnet (Same Leaf)"
echo "========================================="
test_ping "pc1" "srv1" "192.168.20.10" "pc1 (10.0/24) → srv1 (20.0/24)"
test_ping "srv1" "pc1" "192.168.10.10" "srv1 (20.0/24) → pc1 (10.0/24)"
echo ""

echo "========================================="
echo "TEST 4: Cross-Leaf Connectivity"
echo "========================================="
test_ping "pc1" "srv3" "192.168.30.10" "pc1 (leaf-1) → srv3 (leaf-2)"
test_ping "srv3" "pc1" "192.168.10.10" "srv3 (leaf-2) → pc1 (leaf-1)"
test_ping "srv1" "srv3" "192.168.30.10" "srv1 (leaf-1) → srv3 (leaf-2)"
echo ""

echo "========================================="
echo "TEST 5: All-to-All Matrix"
echo "========================================="
test_ping "pc1" "pc2" "192.168.10.11" "pc1 → pc2"
test_ping "pc1" "srv1" "192.168.20.10" "pc1 → srv1"
test_ping "pc1" "srv2" "192.168.21.11" "pc1 → srv2"
test_ping "pc1" "srv3" "192.168.30.10" "pc1 → srv3"
test_ping "pc1" "srv4" "192.168.30.11" "pc1 → srv4"
echo ""

echo "========================================="
echo "TEST 6: Routing Table Check"
echo "========================================="
echo -e "${YELLOW}pc1 routing table:${NC}"
docker exec clab-leaf-spine-lab-pc1 ip route
echo ""
echo -e "${YELLOW}srv3 routing table:${NC}"
docker exec clab-leaf-spine-lab-srv3 ip route
echo ""

echo "========================================="
echo "TEST 7: BGP Status (Routing Protocol)"
echo "========================================="
echo -e "${YELLOW}Leaf-1 BGP Summary:${NC}"
docker exec clab-leaf-spine-lab-leaf-1 vtysh -c "show ip bgp summary" 2>/dev/null || echo "BGP not running"
echo ""

echo "========================================="
echo "TEST 8: OSPF Neighbors"
echo "========================================="
echo -e "${YELLOW}Spine-1 OSPF Neighbors:${NC}"
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show ip ospf neighbor" 2>/dev/null || echo "OSPF not running"
echo ""

echo "========================================="
echo "TEST 9: Bridge Status"
echo "========================================="
echo -e "${YELLOW}Leaf-1 Bridges:${NC}"
docker exec clab-leaf-spine-lab-leaf-1 ip link show type bridge
echo ""
echo -e "${YELLOW}Leaf-1 Bridge br10 interfaces:${NC}"
docker exec clab-leaf-spine-lab-leaf-1 ip link show master br10
echo ""

echo "========================================="
echo "  TEST COMPLETE"
echo "==========================================="
