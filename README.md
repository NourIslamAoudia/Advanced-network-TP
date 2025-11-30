# Advanced Networks Lab - Leaf-Spine Data Center with SR-MPLS & Security

Complete implementation of a modern data center network using Containerlab with OSPF, BGP, BFD, Segment Routing, ACLs, Zone-Based Firewall, and QoS.

---

## Quick Start

### 1. Deploy the Network
```bash
sudo containerlab deploy --topo main.clab.yml
```

### 2. Apply Post-Deployment Fixes
```bash
./POST-DEPLOY-FIX.sh
```

### 3. Test Connectivity
```bash
./test-connectivity.sh
```

**Expected Result**: 15/15 tests passing ✅

---

## Network Topology

```
                    ┌─────────────┐
                    │  Border-R1  │ 100.100.100.1
                    │   (AS 65000)│
                    └──────┬──────┘
                           │
          ┌────────────────┴───────────────┐
          │                                │
    ┌─────▼─────┐                    ┌────▼──────┐
    │  Spine-1  │ 1.1.1.1            │  Spine-2  │ 2.2.2.2
    │ (RR)      │◄──────BGP──────────┤ (RR)      │
    └─────┬─────┘                    └─────┬─────┘
          │                                │
          │    ┌──────────────────┐        │
          ├────┤                  ├────────┤
          │    │                  │        │
    ┌─────▼────▼──┐         ┌────▼────▼───┐
    │   Leaf-1    │ 10.10   │   Leaf-2    │ 10.10.10.2
    │             │ .10.1   │             │
    └┬───┬───┬───┬┘         └┬───────┬───┬┘
     │   │   │   │           │       │   │
    PC1 PC2 SRV1 SRV1       SRV2    SRV3 SRV4
    .10 .11 .10  .10        .11     .10  .11
    VLAN10  VLAN20         VLAN21  VLAN30
```

---

## Network Features

### Part 1: Base Architecture ✅
- **Leaf-Spine Topology**: 2 Spines, 2 Leafs, 1 Border Router
- **OSPF Underlay**: Area 0, all inter-router links
- **BGP Overlay**: iBGP with Route Reflectors on spines
- **VLAN Segregation**: 4 VLANs (10, 20, 21, 30)
- **Linux Bridges**: For same-subnet multi-port connectivity

### Part 2: High Availability ✅
- **BFD**: Bidirectional Forwarding Detection
- **Fast Convergence**: <1 second failure detection (vs 40s OSPF)
- **Parameters**: 300ms intervals, multiplier 3

### Part 3: Advanced MPLS ✅
- **Segment Routing**: SR-MPLS without LDP
- **Node SIDs**: Unique labels per router (100, 101, 102, 111, 112)
- **MPLS Global Block**: 16000-23999
- **OSPF Integration**: Automatic label distribution

### Part 4: Security & QoS ✅
- **ACLs**: Access Control Lists for traffic filtering
- **Zone-Based Firewall**: 3 security zones (INTERNAL, DMZ, OUTSIDE)
- **Stateful Inspection**: Connection tracking with iptables
- **QoS**: 3-tier traffic prioritization (High/Medium/Default)
- **Traffic Policing**: ICMP rate limiting for DoS protection
- **DSCP Marking**: Traffic classification for priority queuing

---

## IP Addressing Scheme

### Loopback Addresses
| Router | Loopback IP | Node SID | MPLS Label |
|--------|-------------|----------|------------|
| border-r1 | 100.100.100.1/32 | 100 | 16100 |
| spine-1 | 1.1.1.1/32 | 101 | 16101 |
| spine-2 | 2.2.2.2/32 | 102 | 16102 |
| leaf-1 | 10.10.10.1/32 | 111 | 16111 |
| leaf-2 | 10.10.10.2/32 | 112 | 16112 |

### Point-to-Point Links
| Link | Network | Purpose |
|------|---------|---------|
| border-r1 ↔ spine-1 | 10.0.0.0/30 | Border connection |
| border-r1 ↔ spine-2 | 10.0.0.4/30 | Border connection |
| spine-1 ↔ leaf-1 | 10.1.1.0/31 | Spine-Leaf link |
| spine-1 ↔ leaf-2 | 10.1.1.2/31 | Spine-Leaf link |
| spine-2 ↔ leaf-1 | 10.1.1.4/31 | Spine-Leaf link |
| spine-2 ↔ leaf-2 | 10.1.1.6/31 | Spine-Leaf link |
| spine-1 ↔ spine-2 | 10.2.2.0/31 | Spine-Spine link |

### Client VLANs
| VLAN | Network | Devices | Leaf |
|------|---------|---------|------|
| 10 | 192.168.10.0/24 | pc1, pc2 | leaf-1 |
| 20 | 192.168.20.0/24 | srv1 | leaf-1 |
| 21 | 192.168.21.0/24 | srv2 | leaf-2 |
| 30 | 192.168.30.0/24 | srv3, srv4 | leaf-2 |

---

## Configuration Files

### Router Configurations
- **[configs/border-r1.cfg](configs/border-r1.cfg)** - Border router with OSPF & BGP
- **[configs/spine-1.cfg](configs/spine-1.cfg)** - Spine with RR functionality
- **[configs/spine-2.cfg](configs/spine-2.cfg)** - Spine with RR functionality
- **[configs/leaf-1.cfg](configs/leaf-1.cfg)** - Leaf with bridge configs
- **[configs/leaf-2.cfg](configs/leaf-2.cfg)** - Leaf with bridge configs

### Daemon Configuration
- **[configs/daemons/frr-daemons](configs/daemons/frr-daemons)** - FRR daemon enablement
  - zebra, bgpd, ospfd, bfdd (enabled)

### Setup Scripts
- **[configs/bfd-setup.sh](configs/bfd-setup.sh)** - Configure BFD on all links
- **[configs/sr-mpls-setup.sh](configs/sr-mpls-setup.sh)** - Configure SR-MPLS
- **[configs/security-setup.sh](configs/security-setup.sh)** - Configure ACLs, Firewall, QoS

### Post-Deployment
- **[POST-DEPLOY-FIX.sh](POST-DEPLOY-FIX.sh)** - Fix routes and VLAN 21
  - **MUST RUN** after every deployment!

### Host Configuration
- **[enable-mpls-on-host.sh](enable-mpls-on-host.sh)** - Load MPLS kernel modules

### Testing
- **[test-connectivity.sh](test-connectivity.sh)** - 15 connectivity tests
- **[test-bfd.sh](test-bfd.sh)** - BFD verification
- **[test-sr-mpls.sh](test-sr-mpls.sh)** - SR-MPLS verification
- **[test-security-qos.sh](test-security-qos.sh)** - Security & QoS verification

---

## Complete Deployment Procedure

### First Time Setup

1. **Deploy Network**:
   ```bash
   sudo containerlab deploy --topo main.clab.yml
   ```

2. **Apply Fixes** (REQUIRED):
   ```bash
   ./POST-DEPLOY-FIX.sh
   ```

3. **Verify Connectivity**:
   ```bash
   ./test-connectivity.sh
   ```
   Expected: 15/15 tests passing

### Enable BFD (Part 2)

**Note**: BFD daemon must be enabled BEFORE deployment.

The FRR daemons file already includes `bfdd=yes`, so BFD will start automatically.

After deployment, configure BFD:
```bash
./configs/bfd-setup.sh
```

Verify:
```bash
./test-bfd.sh
```

### Enable SR-MPLS (Part 3)

**IMPORTANT**: Requires MPLS kernel modules on host.

1. **Enable MPLS on Host** (one-time):
   ```bash
   ./enable-mpls-on-host.sh
   ```

2. **Configure SR-MPLS**:
   ```bash
   ./configs/sr-mpls-setup.sh
   ```

3. **Verify**:
   ```bash
   ./test-sr-mpls.sh
   ```

### Enable Security & QoS (Part 4)

1. **Configure ACLs, Firewall, and QoS**:
   ```bash
   ./configs/security-setup.sh
   ```

2. **Verify**:
   ```bash
   ./test-security-qos.sh
   ```

---

## Workflow After Changes

### Modify Configuration
1. Edit config files in `configs/` directory
2. **Destroy** old deployment:
   ```bash
   sudo containerlab destroy --topo main.clab.yml --cleanup
   ```
3. **Redeploy**:
   ```bash
   sudo containerlab deploy --topo main.clab.yml
   ```
4. **Apply post-fixes** (ALWAYS):
   ```bash
   ./POST-DEPLOY-FIX.sh
   ```
5. **Test**:
   ```bash
   ./test-connectivity.sh
   ```

### Quick Tests Without Redeployment

Modify running configuration:
```bash
docker exec clab-leaf-spine-lab-spine-1 vtysh
```

Then test:
```bash
./test-connectivity.sh
```

**Note**: Changes made in vtysh are NOT persistent! Use config files for permanent changes.

---

## Architecture Explained

### Why Bridges?

**Problem**: Multiple devices on the same subnet connected to different ports of the same router.

**Example**: pc1 (eth3) and pc2 (eth4) both on 192.168.10.0/24 connected to leaf-1

**Solution**: Linux bridge (br10)
```bash
ip link add br10 type bridge
ip link set eth3 master br10
ip link set eth4 master br10
ip addr add 192.168.10.1/24 dev br10
```

**Result**: Layer 2 switching within the subnet, router acts as gateway.

### Why OSPF + BGP?

**OSPF (Underlay)**:
- Distributes reachability between routers
- Fast convergence with BFD
- Simple configuration in single area

**BGP (Overlay)**:
- Scalable for large networks
- Route Reflectors on spines avoid full mesh
- Prepares for EVPN/VXLAN expansion

### Why VLAN 21 Instead of VLAN 20?

**Problem**: srv1 (leaf-1) and srv2 (leaf-2) both on 192.168.20.0/24

**Issue**: Each leaf thinks it "owns" the subnet as directly connected

**Solution**: Changed srv2 to VLAN 21 (192.168.21.0/24)

**Reason**: Avoid same-subnet-different-leaf without VXLAN/EVPN

---

## Protocol Stack

```
┌───────────────────────────────────────────────┐
│          Application Layer                    │
│  (PC1 → PC2, Server Communication)            │
└───────────────────────────────────────────────┘
                    ▼
┌───────────────────────────────────────────────┐
│          SR-MPLS (Part 3)                     │
│  Label Switching, Traffic Engineering         │
└───────────────────────────────────────────────┘
                    ▼
┌───────────────────────────────────────────────┐
│       BGP Overlay (Route Reflectors)          │
│  Scalable routing, prepares for EVPN          │
└───────────────────────────────────────────────┘
                    ▼
┌───────────────────────────────────────────────┐
│       OSPF Underlay (+ SR Distribution)       │
│  Reachability, fast convergence               │
└───────────────────────────────────────────────┘
                    ▼
┌───────────────────────────────────────────────┐
│       BFD (Part 2)                            │
│  Sub-second failure detection                 │
└───────────────────────────────────────────────┘
                    ▼
┌───────────────────────────────────────────────┐
│       Physical Layer                          │
│  Containerlab virtual links                   │
└───────────────────────────────────────────────┘
```

---

## Troubleshooting

### All Tests Failing

**Likely Cause**: Forgot to run POST-DEPLOY-FIX.sh

**Solution**:
```bash
./POST-DEPLOY-FIX.sh
./test-connectivity.sh
```

### Same-Subnet Tests Failing (pc1 ↔ pc2)

**Likely Cause**: Bridges not configured properly

**Check**:
```bash
docker exec clab-leaf-spine-lab-leaf-1 ip link show br10
```

**Fix**: Redeploy (bridges are created during deployment)

### Cross-Leaf Tests Failing

**Likely Cause**: OSPF or BGP not running

**Check**:
```bash
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show ip ospf neighbor"
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show bgp summary"
```

**Fix**: Check daemon file, ensure bgpd and ospfd are enabled

### SR-MPLS Not Working

**Likely Cause**: MPLS kernel modules not loaded

**Solution**:
```bash
./enable-mpls-on-host.sh
./configs/sr-mpls-setup.sh
```

### BFD Not Showing Peers

**Likely Cause**: bfdd not enabled in daemons file

**Check**:
```bash
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show bfd peers"
```

**Fix**: Ensure configs/daemons/frr-daemons has `bfdd=yes`, then redeploy

---

## Documentation

### Comprehensive Guides
- **[ARCHITECTURE_EXPLAINED.md](ARCHITECTURE_EXPLAINED.md)** - Network design and rationale
- **[QUICK_START.md](QUICK_START.md)** - Getting started guide
- **[PART3-SR-MPLS-GUIDE.md](PART3-SR-MPLS-GUIDE.md)** - Complete SR-MPLS guide
- **[SR-MPLS-STATUS.md](SR-MPLS-STATUS.md)** - SR-MPLS implementation status
- **[PART4-SECURITY-QOS-GUIDE.md](PART4-SECURITY-QOS-GUIDE.md)** - Complete Security & QoS guide

### Lab Document
- **todo.pdf** - Original lab requirements (Activity 4)

---

## Test Results

### Connectivity Tests (test-connectivity.sh)
```
✓ pc1 → pc2 (same subnet, same leaf)
✓ pc1 → srv1 (cross-subnet, same leaf)
✓ pc1 → srv2 (cross-leaf, VLAN 21)
✓ pc1 → srv3 (cross-leaf, VLAN 30)
... (15 total tests)

Result: 15/15 PASSING ✅
```

### BFD Tests (test-bfd.sh)
```
✓ BFD peers established on all links
✓ OSPF using BFD for all neighbors
✓ Detection time: ~900ms (vs 40s without BFD)
✓ 40x faster convergence
```

### SR-MPLS Tests (test-sr-mpls.sh)
```
✓ MPLS Global Block: 16000-23999
✓ Node SIDs assigned to all routers
✓ OSPF distributing SR information
✓ MPLS forwarding tables populated
✓ Connectivity maintained
```

### Security & QoS Tests (test-security-qos.sh)
```
✓ ACLs configured on border router
✓ Zone-Based Firewall: 3 zones (INTERNAL, DMZ, OUTSIDE)
✓ Stateful firewall rules active
✓ QoS: 3-tier priority queuing
✓ Traffic policing: ICMP rate limiting
✓ Internal-to-internal traffic: Allowed
✓ Internal-to-DMZ traffic: Allowed
✓ External-to-internal traffic: Blocked
```

---

## Key Achievements

1. ✅ **Fully functional Leaf-Spine data center network**
2. ✅ **OSPF underlay with BFD fast convergence**
3. ✅ **BGP overlay with Route Reflectors**
4. ✅ **VLAN segmentation across leafs**
5. ✅ **Segment Routing (SR-MPLS) without LDP**
6. ✅ **Enterprise-grade Security (ACLs, Zone-Based Firewall)**
7. ✅ **Quality of Service (QoS) with traffic prioritization**
8. ✅ **Production-grade configuration**
9. ✅ **Comprehensive testing and documentation**

---

## Technologies Used

- **Containerlab**: Network topology orchestration
- **FRR (Free Range Routing)**: Open-source routing stack
  - OSPF (Open Shortest Path First)
  - BGP (Border Gateway Protocol)
  - BFD (Bidirectional Forwarding Detection)
  - Segment Routing (SR-MPLS)
  - ACLs (Access Control Lists)
- **Linux Networking**:
  - Bridges (for Layer 2 switching)
  - MPLS kernel modules
  - Network namespaces
  - iptables (Zone-Based Firewall)
  - tc (Traffic Control for QoS)
- **Docker**: Container runtime

---

## Lab Completion Status

✅ **Part 1**: Leaf-Spine Architecture (OSPF, BGP, VLANs) - **COMPLETE**
✅ **Part 2**: BFD Fast Convergence - **COMPLETE**
✅ **Part 3**: Segment Routing (SR-MPLS) - **COMPLETE**
✅ **Part 4**: Security & QoS (ACLs, Firewall, QoS) - **COMPLETE**

**All lab requirements have been successfully implemented!** 🎉

---

## References

- [Containerlab Documentation](https://containerlab.dev/)
- [FRR Documentation](https://docs.frrouting.org/)
- [RFC 8665 - OSPF Extensions for Segment Routing](https://datatracker.ietf.org/doc/html/rfc8665)
- [RFC 8402 - Segment Routing Architecture](https://datatracker.ietf.org/doc/html/rfc8402)
- [Linux MPLS Documentation](https://www.kernel.org/doc/html/latest/networking/mpls-sysctl.html)

---

## Authors

- **Course**: Advanced Networks - 4th Year, S1
- **Institution**: USTHB
- **Lab**: Activity 4 - Leaf-Spine Data Center with SR-MPLS

---

## License

Educational use only - USTHB Advanced Networks Course

---

## Support

For issues or questions:
1. Check documentation in this repository
2. Review test outputs
3. Verify all prerequisites are met
4. Check troubleshooting section above

---

**Happy Networking! 🚀**
