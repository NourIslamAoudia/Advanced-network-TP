#!/bin/bash
# ============================================================
# BFD CONFIGURATION SCRIPT
# Enables BFD for fast failure detection on OSPF links
# ============================================================

echo "==========================================="
echo "  CONFIGURING BFD ON ALL ROUTERS"
echo "==========================================="
echo ""

# Configure BFD on Border Router
echo "Configuring BFD on border-r1..."
docker exec clab-leaf-spine-lab-border-r1 vtysh -c "conf t" \
  -c "bfd" \
  -c "  peer 10.0.0.2" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.0.0.6" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "exit" \
  -c "router ospf" \
  -c "  bfd all-interfaces" \
  -c "end" 2>/dev/null
echo "✓ border-r1 configured"

# Configure BFD on Spine-1
echo "Configuring BFD on spine-1..."
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "conf t" \
  -c "bfd" \
  -c "  peer 10.0.0.1" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.1.1.1" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.1.1.3" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.2.2.1" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "exit" \
  -c "router ospf" \
  -c "  bfd all-interfaces" \
  -c "end" 2>/dev/null
echo "✓ spine-1 configured"

# Configure BFD on Spine-2
echo "Configuring BFD on spine-2..."
docker exec clab-leaf-spine-lab-spine-2 vtysh -c "conf t" \
  -c "bfd" \
  -c "  peer 10.0.0.5" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.1.1.5" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.1.1.7" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.2.2.0" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "exit" \
  -c "router ospf" \
  -c "  bfd all-interfaces" \
  -c "end" 2>/dev/null
echo "✓ spine-2 configured"

# Configure BFD on Leaf-1
echo "Configuring BFD on leaf-1..."
docker exec clab-leaf-spine-lab-leaf-1 vtysh -c "conf t" \
  -c "bfd" \
  -c "  peer 10.1.1.0" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.1.1.4" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "exit" \
  -c "router ospf" \
  -c "  bfd all-interfaces" \
  -c "end" 2>/dev/null
echo "✓ leaf-1 configured"

# Configure BFD on Leaf-2
echo "Configuring BFD on leaf-2..."
docker exec clab-leaf-spine-lab-leaf-2 vtysh -c "conf t" \
  -c "bfd" \
  -c "  peer 10.1.1.2" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "  peer 10.1.1.6" \
  -c "    detect-multiplier 3" \
  -c "    receive-interval 300" \
  -c "    transmit-interval 300" \
  -c "  exit" \
  -c "exit" \
  -c "router ospf" \
  -c "  bfd all-interfaces" \
  -c "end" 2>/dev/null
echo "✓ leaf-2 configured"

echo ""
echo "==========================================="
echo "  BFD CONFIGURATION COMPLETE"
echo "==========================================="
echo ""
echo "BFD Parameters:"
echo "  - Transmit Interval: 300ms"
echo "  - Receive Interval: 300ms"
echo "  - Detect Multiplier: 3"
echo "  - Detection Time: ~900ms (3 x 300ms)"
echo ""
echo "This means link failures will be detected in under 1 second!"
echo ""
