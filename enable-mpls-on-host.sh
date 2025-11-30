#!/bin/bash
# ============================================================
# ENABLE MPLS ON HOST SYSTEM
# This script loads MPLS kernel modules on the HOST
# Run this ONCE before using SR-MPLS features
# ============================================================

echo "==========================================="
echo "  ENABLING MPLS ON HOST SYSTEM"
echo "==========================================="
echo ""

echo "Checking if MPLS modules are available..."
if [ ! -d "/lib/modules/$(uname -r)/kernel/net/mpls/" ]; then
    echo "❌ ERROR: MPLS modules not found in your kernel!"
    echo "Your kernel was not compiled with MPLS support."
    echo "You would need to use a different kernel or use VMs instead of containers."
    exit 1
fi

echo "✓ MPLS modules found"
echo ""

echo "Loading MPLS kernel modules..."
sudo modprobe mpls_router
if [ $? -ne 0 ]; then
    echo "❌ Failed to load mpls_router module"
    exit 1
fi

sudo modprobe mpls_iptunnel
if [ $? -ne 0 ]; then
    echo "❌ Failed to load mpls_iptunnel module"
    exit 1
fi

echo "✓ MPLS modules loaded"
echo ""

echo "Configuring MPLS parameters..."
sudo sysctl -w net.mpls.platform_labels=100000 > /dev/null
sudo sysctl -w net.mpls.conf.all.input=1 > /dev/null
echo "✓ MPLS parameters configured"
echo ""

echo "Verifying MPLS is enabled..."
if sysctl net.mpls.platform_labels > /dev/null 2>&1; then
    echo "✓ MPLS is now enabled on the host!"
else
    echo "❌ MPLS verification failed"
    exit 1
fi
echo ""

echo "==========================================="
echo "  MPLS ENABLED SUCCESSFULLY"
echo "==========================================="
echo ""
echo "MPLS Configuration:"
echo "  • Platform Labels: 100000"
echo "  • Input Enabled: Yes"
echo "  • Modules Loaded: mpls_router, mpls_iptunnel"
echo ""
echo "Next steps:"
echo "  1. The MPLS modules are now loaded (this session only)"
echo "  2. Run: ./configs/sr-mpls-setup.sh to configure SR on routers"
echo "  3. Run: ./test-sr-mpls.sh to verify SR-MPLS is working"
echo ""
echo "To make MPLS persistent across reboots (optional):"
echo "  sudo bash -c 'echo mpls_router >> /etc/modules-load.d/mpls.conf'"
echo "  sudo bash -c 'echo mpls_iptunnel >> /etc/modules-load.d/mpls.conf'"
echo "  sudo bash -c 'echo net.mpls.platform_labels=100000 >> /etc/sysctl.d/90-mpls.conf'"
echo "  sudo bash -c 'echo net.mpls.conf.all.input=1 >> /etc/sysctl.d/90-mpls.conf'"
echo ""
