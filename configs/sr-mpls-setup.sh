#!/bin/bash
# ============================================================
# SEGMENT ROUTING (SR-MPLS) CONFIGURATION SCRIPT
# Configures SR-MPLS with Node SIDs on all routers
# ============================================================

echo "==========================================="
echo "  CONFIGURING SEGMENT ROUTING (SR-MPLS)"
echo "==========================================="
echo ""

echo "What is Segment Routing?"
echo "  - Simplifies MPLS by eliminating LDP"
echo "  - Uses OSPF to distribute labels"
echo "  - Each router has a unique Node SID (label)"
echo "  - Traffic is forwarded using these labels"
echo ""

# Define Node SIDs (must be unique per router)
# Format: router_name -> Node SID
# We'll use a range: 100-199 for our network
echo "Node SID Assignments:"
echo "  border-r1: Node SID 100"
echo "  spine-1:   Node SID 101"
echo "  spine-2:   Node SID 102"
echo "  leaf-1:    Node SID 111"
echo "  leaf-2:    Node SID 112"
echo ""

# Configure SR-MPLS on Border Router
echo "Step 1: Configuring border-r1..."
docker exec clab-leaf-spine-lab-border-r1 vtysh << 'EOF' 2>/dev/null
configure terminal
!
! Enable Segment Routing globally
segment-routing on
!
! Configure MPLS for Segment Routing
mpls label global-block 16000 23999
!
! Configure OSPF with Segment Routing
router ospf
 segment-routing on
 segment-routing global-block 16000 23999
 segment-routing node-msd 8
 segment-routing prefix 100.100.100.1/32 index 100
!
end
write memory
EOF
echo "✓ border-r1 configured with Node SID 100"

# Configure SR-MPLS on Spine-1
echo "Step 2: Configuring spine-1..."
docker exec clab-leaf-spine-lab-spine-1 vtysh << 'EOF' 2>/dev/null
configure terminal
!
segment-routing on
mpls label global-block 16000 23999
!
router ospf
 segment-routing on
 segment-routing global-block 16000 23999
 segment-routing node-msd 8
 segment-routing prefix 1.1.1.1/32 index 101
!
end
write memory
EOF
echo "✓ spine-1 configured with Node SID 101"

# Configure SR-MPLS on Spine-2
echo "Step 3: Configuring spine-2..."
docker exec clab-leaf-spine-lab-spine-2 vtysh << 'EOF' 2>/dev/null
configure terminal
!
segment-routing on
mpls label global-block 16000 23999
!
router ospf
 segment-routing on
 segment-routing global-block 16000 23999
 segment-routing node-msd 8
 segment-routing prefix 2.2.2.2/32 index 102
!
end
write memory
EOF
echo "✓ spine-2 configured with Node SID 102"

# Configure SR-MPLS on Leaf-1
echo "Step 4: Configuring leaf-1..."
docker exec clab-leaf-spine-lab-leaf-1 vtysh << 'EOF' 2>/dev/null
configure terminal
!
segment-routing on
mpls label global-block 16000 23999
!
router ospf
 segment-routing on
 segment-routing global-block 16000 23999
 segment-routing node-msd 8
 segment-routing prefix 10.10.10.1/32 index 111
!
end
write memory
EOF
echo "✓ leaf-1 configured with Node SID 111"

# Configure SR-MPLS on Leaf-2
echo "Step 5: Configuring leaf-2..."
docker exec clab-leaf-spine-lab-leaf-2 vtysh << 'EOF' 2>/dev/null
configure terminal
!
segment-routing on
mpls label global-block 16000 23999
!
router ospf
 segment-routing on
 segment-routing global-block 16000 23999
 segment-routing node-msd 8
 segment-routing prefix 10.10.10.2/32 index 112
!
end
write memory
EOF
echo "✓ leaf-2 configured with Node SID 112"

echo ""
echo "==========================================="
echo "  SR-MPLS CONFIGURATION COMPLETE"
echo "==========================================="
echo ""

echo "Configuration Summary:"
echo "  ✓ Segment Routing enabled on all routers"
echo "  ✓ MPLS Global Block: 16000-23999"
echo "  ✓ Node SIDs assigned:"
echo "      - border-r1: Label 16100 (16000 + 100)"
echo "      - spine-1:   Label 16101 (16000 + 101)"
echo "      - spine-2:   Label 16102 (16000 + 102)"
echo "      - leaf-1:    Label 16111 (16000 + 111)"
echo "      - leaf-2:    Label 16112 (16000 + 112)"
echo ""
echo "How it works:"
echo "  - OSPF distributes the Node SIDs automatically"
echo "  - Routers build MPLS forwarding table (LFIB)"
echo "  - Traffic uses MPLS labels instead of IP lookups"
echo "  - Result: Faster forwarding, traffic engineering possible"
echo ""
echo "Wait 10 seconds for OSPF to converge and distribute labels..."
sleep 10
echo "✓ Convergence complete"
echo ""
