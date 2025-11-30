#!/bin/bash

PREFIX="clab-leaf-spine-datacenter"

echo "🔧 Redémarrage de FRR sur tous les nœuds..."
echo ""

# Liste des routeurs
ROUTERS="Spine-1 Spine-2 Leaf-1 Leaf-2 Edge-Router"

for router in $ROUTERS; do
    echo "  ⚙️  $router..."
    
    # Activer bgpd
    docker exec ${PREFIX}-${router} sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
    
    # Redémarrer FRR
    docker exec ${PREFIX}-${router} /etc/init.d/frr restart > /dev/null 2>&1
    
    echo "  ✅ $router redémarré"
    sleep 2
done

echo ""
echo "⏳ Attente de convergence BGP (30 secondes)..."
sleep 30

echo ""
echo "🔍 Vérification BGP sur Spine-1 :"
docker exec ${PREFIX}-Spine-1 vtysh -c "show ip bgp summary"

echo ""
echo "✅ Terminé ! Lancez maintenant : ./test-network.sh"
