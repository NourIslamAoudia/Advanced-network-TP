#!/bin/bash

# ========================================
# Script de Validation - Atelier Réseaux Avancés
# ========================================

LAB_NAME="leaf-spine-datacenter"
PREFIX="clab-${LAB_NAME}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🧪 VALIDATION AUTOMATIQUE - ATELIER RÉSEAUX AVANCÉS      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Fonction de test
test_cmd() {
    local test_name="$1"
    local cmd="$2"
    local expected="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  [TEST $TOTAL_TESTS] $test_name ... "
    
    result=$(eval "$cmd" 2>&1)
    
    if echo "$result" | grep -q "$expected"; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "    Attendu: $expected"
        echo "    Obtenu: $result"
        return 1
    fi
}

# Fonction de ping test
ping_test() {
    local test_name="$1"
    local container="$2"
    local target="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  [TEST $TOTAL_TESTS] $test_name ... "
    
    result=$(docker exec ${PREFIX}-${container} ping -c 3 -W 2 $target 2>&1 | grep "packet loss" | awk '{print $6}')
    
    if [ "$result" = "0%" ]; then
        echo -e "${GREEN}✓ PASS${NC} (0% loss)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} ($result loss)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  PARTIE 1 : LAYER 2 & 3 - VLANS ET SVI"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 1.1 : VLANs sur Leaf-1
test_cmd "VLAN 10 sur Leaf-1" \
    "docker exec ${PREFIX}-Leaf-1 ip addr show eth3.10" \
    "192.168.10.1"

test_cmd "VLAN 20 sur Leaf-1" \
    "docker exec ${PREFIX}-Leaf-1 ip addr show eth3.20" \
    "192.168.20.1"

# Test 1.2 : VLAN sur Leaf-2
test_cmd "VLAN 30 sur Leaf-2" \
    "docker exec ${PREFIX}-Leaf-2 ip addr show eth3.30" \
    "192.168.30.1"

# Test 1.3 : Connectivité vers Gateway
ping_test "Server-1 → Gateway (192.168.10.1)" "Server-1" "192.168.10.1"
ping_test "Server-2 → Gateway (192.168.20.1)" "Server-2" "192.168.20.1"
ping_test "Client-1 → Gateway (192.168.30.1)" "Client-1" "192.168.30.1"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  PARTIE 2 : UNDERLAY BGP & HAUTE DISPONIBILITÉ"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 2.1 : BGP Neighbors sur Spine-1
test_cmd "BGP Neighbor Leaf-1 (Spine-1)" \
    "docker exec ${PREFIX}-Spine-1 vtysh -c 'show ip bgp summary' 2>/dev/null" \
    "Established"

test_cmd "BGP Neighbor Leaf-2 (Spine-1)" \
    "docker exec ${PREFIX}-Spine-1 vtysh -c 'show ip bgp summary' 2>/dev/null" \
    "Established"

# Test 2.2 : BGP Routes sur Leaf-1
test_cmd "Route BGP vers VLAN 30 (Leaf-1)" \
    "docker exec ${PREFIX}-Leaf-1 vtysh -c 'show ip route 192.168.30.0/24' 2>/dev/null" \
    "192.168.30.0/24"

# Test 2.3 : ECMP - Vérifier plusieurs next-hops
test_cmd "ECMP actif (Leaf-1 → VLAN 30)" \
    "docker exec ${PREFIX}-Leaf-1 ip route show 192.168.30.0/24" \
    "nexthop"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  PARTIE 3 : OVERLAY & ROUTAGE INTER-VLAN"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 3.1 : Loopbacks configurés
test_cmd "Loopback Spine-1 (10.255.0.1)" \
    "docker exec ${PREFIX}-Spine-1 ip addr show lo" \
    "10.255.0.1"

test_cmd "Loopback Leaf-1 (10.255.1.1)" \
    "docker exec ${PREFIX}-Leaf-1 ip addr show lo" \
    "10.255.1.1"

test_cmd "Loopback Edge-Router (10.255.255.1)" \
    "docker exec ${PREFIX}-Edge-Router ip addr show lo" \
    "10.255.255.1"

# Test 3.2 : Routage Inter-VLAN
ping_test "Server-1 (VLAN 10) → Server-2 (VLAN 20)" "Server-1" "192.168.20.10"
ping_test "Server-1 (VLAN 10) → Client-1 (VLAN 30)" "Server-1" "192.168.30.10"
ping_test "Server-2 (VLAN 20) → Client-1 (VLAN 30)" "Server-2" "192.168.30.10"
ping_test "Client-1 (VLAN 30) → Server-1 (VLAN 10)" "Client-1" "192.168.10.10"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  PARTIE 4 : SÉCURITÉ & SERVICES"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 4.1 : Firewall Rules
test_cmd "Règle Firewall ESTABLISHED" \
    "docker exec ${PREFIX}-Edge-Router iptables -L FORWARD -n" \
    "RELATED,ESTABLISHED"

test_cmd "Règle Firewall 192.168.0.0/16" \
    "docker exec ${PREFIX}-Edge-Router iptables -L FORWARD -n" \
    "192.168.0.0/16"

# Test 4.2 : Connectivité Internet
ping_test "Server-1 → Internet (203.0.113.2)" "Server-1" "203.0.113.2"
ping_test "Client-1 → Internet (203.0.113.2)" "Client-1" "203.0.113.2"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  TESTS DE PERFORMANCE"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 5.1 : Latence
echo -n "  [PERF] Latence Server-1 → Client-1 ... "
latency=$(docker exec ${PREFIX}-Server-1 ping -c 10 -q 192.168.30.10 2>/dev/null | grep "avg" | awk -F'/' '{print $5}')
if [ ! -z "$latency" ]; then
    echo -e "${GREEN}${latency} ms${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 5.2 : Packet Loss sur longue durée
echo -n "  [PERF] Stabilité (100 pings) ... "
loss=$(docker exec ${PREFIX}-Server-1 ping -c 100 -q 192.168.20.10 2>/dev/null | grep "packet loss" | awk '{print $6}')
if [ "$loss" = "0%" ]; then
    echo -e "${GREEN}0% loss${NC}"
else
    echo -e "${YELLOW}${loss} loss${NC}"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    RÉSUMÉ DES TESTS                        ║"
echo "╠════════════════════════════════════════════════════════════╣"
printf "║  Total      : %-42d   ║\n" $TOTAL_TESTS
printf "║  ${GREEN}Réussis${NC}   : %-42d   ║\n" $PASSED_TESTS
printf "║  ${RED}Échoués${NC}   : %-42d   ║\n" $FAILED_TESTS
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Calcul du pourcentage
if [ $TOTAL_TESTS -gt 0 ]; then
    percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -n "Taux de réussite : "
    
    if [ $percentage -eq 100 ]; then
        echo -e "${GREEN}${percentage}% 🎉 EXCELLENT !${NC}"
    elif [ $percentage -ge 80 ]; then
        echo -e "${GREEN}${percentage}% ✓ Très bien${NC}"
    elif [ $percentage -ge 60 ]; then
        echo -e "${YELLOW}${percentage}% ⚠ Acceptable${NC}"
    else
        echo -e "${RED}${percentage}% ✗ À revoir${NC}"
    fi
fi

echo ""

# Code de sortie
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les tests sont passés avec succès !${NC}"
    exit 0
else
    echo -e "${RED}✗ Certains tests ont échoué. Vérifiez la configuration.${NC}"
    exit 1
fi
