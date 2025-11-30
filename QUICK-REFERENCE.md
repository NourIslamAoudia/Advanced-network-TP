# Quick Reference Card - Advanced Networks Lab

## One-Page Cheat Sheet for All Commands

---

## Initial Deployment

```bash
# 1. Deploy network
sudo containerlab deploy --topo main.clab.yml

# 2. Apply fixes (ALWAYS run after deployment!)
./POST-DEPLOY-FIX.sh

# 3. Test base connectivity
./test-connectivity.sh
```

---

## Part 2: Enable BFD

```bash
# Configure BFD on all routers
./configs/bfd-setup.sh

# Test BFD
./test-bfd.sh
```

---

## Part 3: Enable SR-MPLS

```bash
# One-time: Enable MPLS on host
./enable-mpls-on-host.sh

# Configure SR-MPLS
./configs/sr-mpls-setup.sh

# Test SR-MPLS
./test-sr-mpls.sh
```

---

## Part 4: Enable Security & QoS

```bash
# Configure ACLs, Firewall, QoS
./configs/security-setup.sh

# Test Security & QoS
./test-security-qos.sh
```

---

## Complete Setup (All Parts)

```bash
# Full deployment from scratch
sudo containerlab deploy --topo main.clab.yml
./POST-DEPLOY-FIX.sh
./configs/bfd-setup.sh
./enable-mpls-on-host.sh  # One-time only
./configs/sr-mpls-setup.sh
./configs/security-setup.sh

# Run all tests
./test-connectivity.sh
./test-bfd.sh
./test-sr-mpls.sh
./test-security-qos.sh
```

---

## Useful Verification Commands

### Check OSPF
```bash
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show ip ospf neighbor"
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show ip route ospf"
```

### Check BGP
```bash
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show bgp summary"
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show bgp ipv4 unicast"
```

### Check BFD
```bash
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show bfd peers"
docker exec clab-leaf-spine-lab-leaf-1 vtysh -c "show bfd peers brief"
```

### Check SR-MPLS
```bash
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show mpls table"
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show ip ospf database opaque-area"
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show running-config" | grep segment
```

### Check ACLs
```bash
docker exec clab-leaf-spine-lab-border-r1 vtysh -c "show access-lists"
```

### Check Firewall
```bash
docker exec clab-leaf-spine-lab-border-r1 iptables -L -n -v
docker exec clab-leaf-spine-lab-border-r1 dmesg | grep BLOCKED
```

### Check QoS
```bash
docker exec clab-leaf-spine-lab-leaf-1 tc qdisc show dev eth1
docker exec clab-leaf-spine-lab-leaf-1 tc class show dev eth1
docker exec clab-leaf-spine-lab-leaf-1 tc filter show dev eth1
```

---

## Quick Connectivity Tests

```bash
# Same subnet
docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.10.11  # pc1 → pc2

# Cross subnet (same leaf)
docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.20.10  # pc1 → srv1

# Cross leaf
docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.30.10  # pc1 → srv3 (DMZ)
docker exec clab-leaf-spine-lab-pc1 ping -c 2 192.168.21.11  # pc1 → srv2 (VLAN 21)
```

---

## Troubleshooting

### If tests fail after deployment
```bash
# Did you run the post-deployment fix?
./POST-DEPLOY-FIX.sh
./test-connectivity.sh
```

### If MPLS not working
```bash
# Check if MPLS modules loaded on host
lsmod | grep mpls

# If not, enable them
./enable-mpls-on-host.sh
./configs/sr-mpls-setup.sh
```

### If BFD not showing peers
```bash
# Check if bfdd is enabled in daemons file
docker exec clab-leaf-spine-lab-spine-1 cat /etc/frr/daemons | grep bfdd

# Should show: bfdd=yes
```

### View logs
```bash
# Container logs
docker logs clab-leaf-spine-lab-spine-1

# FRR logs
docker exec clab-leaf-spine-lab-spine-1 cat /var/log/frr/frr.log

# Firewall logs
docker exec clab-leaf-spine-lab-border-r1 dmesg | tail -50
```

---

## Network Information

### IP Addresses

| Device | VLAN | IP Address | Gateway | Leaf |
|--------|------|------------|---------|------|
| pc1 | 10 | 192.168.10.10/24 | .1 | leaf-1 |
| pc2 | 10 | 192.168.10.11/24 | .1 | leaf-1 |
| srv1 | 20 | 192.168.20.10/24 | .1 | leaf-1 |
| srv2 | 21 | 192.168.21.11/24 | .1 | leaf-2 |
| srv3 | 30 | 192.168.30.10/24 | .1 | leaf-2 |
| srv4 | 30 | 192.168.30.11/24 | .1 | leaf-2 |

### Loopbacks

| Router | Loopback | Node SID | MPLS Label |
|--------|----------|----------|------------|
| border-r1 | 100.100.100.1/32 | 100 | 16100 |
| spine-1 | 1.1.1.1/32 | 101 | 16101 |
| spine-2 | 2.2.2.2/32 | 102 | 16102 |
| leaf-1 | 10.10.10.1/32 | 111 | 16111 |
| leaf-2 | 10.10.10.2/32 | 112 | 16112 |

---

## Cleanup & Redeploy

```bash
# Destroy current deployment
sudo containerlab destroy --topo main.clab.yml --cleanup

# Redeploy from scratch
sudo containerlab deploy --topo main.clab.yml
./POST-DEPLOY-FIX.sh

# Reconfigure everything
./configs/bfd-setup.sh
./configs/sr-mpls-setup.sh
./configs/security-setup.sh
```

---

## File Locations

| Type | File |
|------|------|
| Topology | [main.clab.yml](main.clab.yml) |
| Router Configs | [configs/*.cfg](configs/) |
| FRR Daemons | [configs/daemons/frr-daemons](configs/daemons/frr-daemons) |
| Post-Deploy Fix | [POST-DEPLOY-FIX.sh](POST-DEPLOY-FIX.sh) |
| BFD Setup | [configs/bfd-setup.sh](configs/bfd-setup.sh) |
| SR-MPLS Setup | [configs/sr-mpls-setup.sh](configs/sr-mpls-setup.sh) |
| Security Setup | [configs/security-setup.sh](configs/security-setup.sh) |
| MPLS Enable | [enable-mpls-on-host.sh](enable-mpls-on-host.sh) |
| Tests | [test-*.sh](.) |
| Docs | [*.md](.) |

---

## Key Concepts

### Security Zones
- **INTERNAL**: VLAN 10, 20, 21 - Fully protected
- **DMZ**: VLAN 30 - HTTP/HTTPS/SSH only from outside
- **OUTSIDE**: External networks - Restricted access

### QoS Classes
- **High (1:10)**: 40% bandwidth - Voice/Video (DSCP EF, CS6)
- **Medium (1:20)**: 30% bandwidth - Business apps (DSCP AF41, AF31)
- **Default (1:30)**: 30% bandwidth - Best effort

### Protocols
- **OSPF**: Underlay routing (Area 0)
- **BGP**: Overlay routing (AS 65000, RR on spines)
- **BFD**: Fast failure detection (~900ms)
- **SR-MPLS**: Label-based forwarding without LDP

---

## Documentation

- [README.md](README.md) - Main documentation
- [QUICK_START.md](QUICK_START.md) - Getting started
- [ARCHITECTURE_EXPLAINED.md](ARCHITECTURE_EXPLAINED.md) - Architecture deep-dive
- [PART3-SR-MPLS-GUIDE.md](PART3-SR-MPLS-GUIDE.md) - SR-MPLS guide
- [PART4-SECURITY-QOS-GUIDE.md](PART4-SECURITY-QOS-GUIDE.md) - Security & QoS guide
- [FINAL-SUMMARY.md](FINAL-SUMMARY.md) - Complete summary
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - This document

---

## Status

✅ Part 1: Leaf-Spine Architecture (OSPF, BGP, VLANs)
✅ Part 2: BFD Fast Convergence
✅ Part 3: Segment Routing (SR-MPLS)
✅ Part 4: Security & QoS (ACLs, Firewall, QoS)

**ALL PARTS COMPLETE!** 🎉
