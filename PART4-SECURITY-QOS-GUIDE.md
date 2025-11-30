# Part 4: Security & QoS - Complete Implementation Guide

## Overview

This guide covers the implementation of **Access Control Lists (ACLs)**, **Zone-Based Firewall**, and **Quality of Service (QoS)** on the Leaf-Spine network topology.

---

## Table of Contents

1. [Security Architecture](#security-architecture)
2. [ACLs (Access Control Lists)](#acls-access-control-lists)
3. [Zone-Based Firewall](#zone-based-firewall)
4. [QoS (Quality of Service)](#qos-quality-of-service)
5. [Configuration](#configuration)
6. [Verification & Testing](#verification--testing)
7. [Troubleshooting](#troubleshooting)

---

## Security Architecture

### Security Zones

The network is divided into three security zones:

```
┌─────────────────────────────────────────────────────────┐
│                    OUTSIDE ZONE                         │
│              (External Networks)                        │
│                  via border-r1                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Firewall Rules
                     │ • Block → INTERNAL
                     │ • Allow → DMZ (HTTP/HTTPS/SSH)
                     │
          ┌──────────▼──────────────────────┐
          │      Border Router (R1)         │
          │     Zone-Based Firewall         │
          └──────────┬──────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   ┌────▼─────┐             ┌────▼─────┐
   │ Spine-1  │             │ Spine-2  │
   └────┬─────┘             └────┬─────┘
        │                         │
   ┌────┴──────────┬──────────────┴────┐
   │               │                   │
┌──▼───┐       ┌──▼───┐           ┌───▼──┐
│Leaf-1│       │Leaf-2│           │Leaf-2│
└──┬───┘       └──┬───┘           └───┬──┘
   │              │                   │
   ▼              ▼                   ▼
┌─────────────────────┐    ┌──────────────────────┐
│   INTERNAL ZONE     │    │      DMZ ZONE        │
│                     │    │                      │
│ • VLAN 10 (PC1,PC2) │    │ • VLAN 30 (SRV3,SRV4)│
│ • VLAN 20 (SRV1)    │    │                      │
│ • VLAN 21 (SRV2)    │    │ Public-facing servers│
│                     │    │ HTTP/HTTPS/SSH only  │
│ Fully Protected     │    │                      │
└─────────────────────┘    └──────────────────────┘
```

### Zone Definitions

| Zone | Networks | Purpose | Access |
|------|----------|---------|--------|
| **INTERNAL** | VLAN 10, 20, 21<br>192.168.10.0/24<br>192.168.20.0/24<br>192.168.21.0/24 | Client PCs and internal servers | Fully protected from outside |
| **DMZ** | VLAN 30<br>192.168.30.0/24 | Public-facing servers | HTTP/HTTPS/SSH from outside |
| **OUTSIDE** | External networks<br>via border-r1 | Internet/External | Restricted access |

---

## ACLs (Access Control Lists)

### What are ACLs?

Access Control Lists filter traffic based on:
- Source/Destination IP addresses
- Protocols (TCP, UDP, ICMP)
- Port numbers
- Traffic direction

### Configured ACLs

#### Standard ACL 10: Internal Networks
```
access-list 10 remark Internal networks
access-list 10 permit 192.168.10.0 0.0.0.255
access-list 10 permit 192.168.20.0 0.0.0.255
access-list 10 permit 192.168.21.0 0.0.0.255
access-list 10 deny any
```

**Purpose**: Identify internal network traffic for QoS and policy routing

#### Standard ACL 20: DMZ Network
```
access-list 20 remark DMZ network
access-list 20 permit 192.168.30.0 0.0.0.255
```

**Purpose**: Identify DMZ traffic for differentiated treatment

#### Extended ACL 100: External Traffic Filtering
```
access-list 100 remark External to Internal blocking
access-list 100 deny ip any 192.168.10.0 0.0.0.255
access-list 100 deny ip any 192.168.20.0 0.0.0.255
access-list 100 deny ip any 192.168.21.0 0.0.0.255
access-list 100 permit ip any 192.168.30.0 0.0.0.255
access-list 100 permit ip any any
```

**Purpose**: Block external access to internal VLANs, allow to DMZ

### ACL Logic

```
External Traffic:
    ├─ Destination: 192.168.10.0/24 → DENY (Internal)
    ├─ Destination: 192.168.20.0/24 → DENY (Internal)
    ├─ Destination: 192.168.21.0/24 → DENY (Internal)
    ├─ Destination: 192.168.30.0/24 → PERMIT (DMZ)
    └─ All other → PERMIT
```

---

## Zone-Based Firewall

### What is Zone-Based Firewall?

Unlike traditional ACLs which filter traffic on interfaces, Zone-Based Firewall:
- Groups interfaces into security zones
- Defines policies between zones
- Provides stateful inspection (tracks connections)
- Logs security events

### Implemented Using iptables

#### Firewall Rules Structure

```bash
# Default Policies
iptables -P INPUT ACCEPT
iptables -P FORWARD DROP      # Drop by default, explicit allow
iptables -P OUTPUT ACCEPT

# Stateful Inspection
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
```

#### Zone-to-Zone Rules

**1. INTERNAL → INTERNAL (Allow All)**
```bash
# VLAN 10 ↔ VLAN 20
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.20.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.10.0/24 -j ACCEPT

# VLAN 10 ↔ VLAN 21
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.21.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.21.0/24 -d 192.168.10.0/24 -j ACCEPT

# VLAN 20 ↔ VLAN 21
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.21.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.21.0/24 -d 192.168.20.0/24 -j ACCEPT
```

**2. INTERNAL → DMZ (Allow All)**
```bash
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.30.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.30.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.21.0/24 -d 192.168.30.0/24 -j ACCEPT
```

**3. DMZ → INTERNAL (Only Return Traffic)**
```bash
# Only established connections allowed back
iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.10.0/24 \
  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.20.0/24 \
  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.21.0/24 \
  -m state --state ESTABLISHED,RELATED -j ACCEPT
```

**4. OUTSIDE → INTERNAL (Block All)**
```bash
# Log and drop
iptables -A FORWARD -d 192.168.10.0/24 \
  -j LOG --log-prefix "BLOCKED-TO-INTERNAL: "
iptables -A FORWARD -d 192.168.10.0/24 -j DROP

iptables -A FORWARD -d 192.168.20.0/24 \
  -j LOG --log-prefix "BLOCKED-TO-INTERNAL: "
iptables -A FORWARD -d 192.168.20.0/24 -j DROP

iptables -A FORWARD -d 192.168.21.0/24 \
  -j LOG --log-prefix "BLOCKED-TO-INTERNAL: "
iptables -A FORWARD -d 192.168.21.0/24 -j DROP
```

**5. OUTSIDE → DMZ (Specific Services Only)**
```bash
# Allow HTTP, HTTPS, SSH
iptables -A FORWARD -d 192.168.30.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.30.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -d 192.168.30.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -d 192.168.30.0/24 -p icmp -j ACCEPT
```

### Traffic Flow Matrix

| Source Zone | Destination Zone | Action | Services |
|-------------|------------------|--------|----------|
| INTERNAL | INTERNAL | ✅ ALLOW | All |
| INTERNAL | DMZ | ✅ ALLOW | All |
| INTERNAL | OUTSIDE | ✅ ALLOW | All |
| DMZ | INTERNAL | ⚠️ STATEFUL | Return traffic only |
| DMZ | DMZ | ✅ ALLOW | All |
| DMZ | OUTSIDE | ✅ ALLOW | All |
| OUTSIDE | INTERNAL | ❌ DENY | Logged |
| OUTSIDE | DMZ | ✅ ALLOW | HTTP/HTTPS/SSH/ICMP |
| OUTSIDE | OUTSIDE | ✅ ALLOW | All |

---

## QoS (Quality of Service)

### What is QoS?

Quality of Service ensures critical traffic gets priority and guaranteed bandwidth:
- **Traffic Classification**: Identify traffic types (DSCP markings)
- **Queuing**: Separate queues for different priorities
- **Scheduling**: Determine which queue to service
- **Policing**: Rate limiting to prevent abuse

### QoS Architecture

```
┌──────────────────────────────────────────────────┐
│           Traffic Classification                 │
│  (Based on DSCP markings in IP header)           │
└────────────┬─────────────────────────────────────┘
             │
    ┌────────┴─────────┬──────────────┐
    │                  │              │
┌───▼────────┐  ┌─────▼─────┐  ┌────▼────────┐
│ High Queue │  │ Med Queue │  │ Default Queue│
│  Priority 1│  │Priority 2 │  │  Priority 3  │
│  40% BW    │  │  30% BW   │  │   30% BW     │
│  DSCP EF   │  │ DSCP AF41 │  │   Default    │
│  DSCP CS6  │  │ DSCP AF31 │  │              │
└────────────┘  └───────────┘  └──────────────┘
        │              │               │
        └──────────────┴───────────────┘
                       │
                       ▼
            ┌──────────────────┐
            │  HTB Scheduler   │
            │ (Fair Queuing)   │
            └──────────────────┘
                       │
                       ▼
                  Interface
```

### QoS Classes Configured

#### Class 1:10 - High Priority (40%)
- **Rate**: 400 Mbps (guaranteed)
- **Ceiling**: 1000 Mbps (burst capability)
- **Priority**: 1 (highest)
- **Traffic**: VoIP, Network Control
- **DSCP Markings**:
  - EF (0x2e / 46) - Voice
  - CS6 (0x30 / 48) - Network Control

#### Class 1:20 - Medium Priority (30%)
- **Rate**: 300 Mbps (guaranteed)
- **Ceiling**: 800 Mbps (burst capability)
- **Priority**: 2
- **Traffic**: Video, Business Applications
- **DSCP Markings**:
  - AF41 (0x22 / 34) - Video
  - AF31 (0x1a / 26) - Multimedia

#### Class 1:30 - Default/Best Effort (30%)
- **Rate**: 300 Mbps (guaranteed)
- **Ceiling**: 600 Mbps (burst capability)
- **Priority**: 3 (lowest)
- **Traffic**: Everything else
- **DSCP Markings**: Default (0x00 / 0)

### HTB (Hierarchical Token Bucket)

HTB allows:
- **Guaranteed bandwidth** (rate)
- **Burst capability** (ceiling)
- **Hierarchical classes** (parent-child relationships)
- **Fair queuing** within same priority

```bash
# Root qdisc
tc qdisc add dev eth1 root handle 1: htb default 30

# High Priority Class
tc class add dev eth1 parent 1: classid 1:10 \
  htb rate 400mbit ceil 1000mbit prio 1

# Medium Priority Class
tc class add dev eth1 parent 1: classid 1:20 \
  htb rate 300mbit ceil 800mbit prio 2

# Default Class
tc class add dev eth1 parent 1: classid 1:30 \
  htb rate 300mbit ceil 600mbit prio 3
```

### Traffic Classification Filters

```bash
# High priority: DSCP EF (VoIP)
tc filter add dev eth1 protocol ip parent 1:0 prio 1 \
  u32 match ip dscp 0x2e 0xff flowid 1:10

# High priority: DSCP CS6 (Network Control)
tc filter add dev eth1 protocol ip parent 1:0 prio 1 \
  u32 match ip dscp 0x30 0xff flowid 1:10

# Medium priority: DSCP AF41 (Video)
tc filter add dev eth1 protocol ip parent 1:0 prio 2 \
  u32 match ip dscp 0x22 0xff flowid 1:20

# Medium priority: DSCP AF31 (Signaling)
tc filter add dev eth1 protocol ip parent 1:0 prio 2 \
  u32 match ip dscp 0x1a 0xff flowid 1:20
```

### DSCP Values Reference

| DSCP Name | Hex | Decimal | Binary | Traffic Type | QoS Class |
|-----------|-----|---------|--------|--------------|-----------|
| EF | 0x2e | 46 | 101110 | VoIP/Voice | High (1:10) |
| CS6 | 0x30 | 48 | 110000 | Network Control | High (1:10) |
| AF41 | 0x22 | 34 | 100010 | Video Streaming | Medium (1:20) |
| AF31 | 0x1a | 26 | 011010 | Multimedia Signaling | Medium (1:20) |
| Default | 0x00 | 0 | 000000 | Best Effort | Default (1:30) |

### Traffic Policing (ICMP Rate Limiting)

To prevent ping floods and DoS attacks:

```bash
# Limit ICMP to 10 Mbps on spine routers
tc qdisc add dev eth1 root handle 1: htb
tc class add dev eth1 parent 1: classid 1:1 htb rate 10mbit
tc filter add dev eth1 protocol ip parent 1:0 prio 1 \
  u32 match ip protocol 1 0xff flowid 1:1
```

**Benefits**:
- Prevents ICMP flood attacks
- Limits ping bandwidth to 10 Mbps
- Network control traffic still prioritized

---

## Configuration

### Prerequisites

Ensure the network is deployed and basic connectivity is working:

```bash
sudo containerlab deploy --topo main.clab.yml
./POST-DEPLOY-FIX.sh
./test-connectivity.sh  # Should show 15/15 passing
```

### Step 1: Apply Security & QoS Configuration

```bash
./configs/security-setup.sh
```

This script will:
1. Configure ACLs on border router
2. Set up Zone-Based Firewall rules
3. Configure QoS on leaf switches
4. Set up traffic policing on spine switches

**Expected output**:
```
===========================================
  CONFIGURING SECURITY & QoS (PART 4)
===========================================

✓ Border-R1 ACLs configured
✓ Border-R1 route-maps configured
✓ Border-R1 firewall rules applied
✓ Leaf switches QoS configured
✓ Spine switches traffic policing configured

===========================================
  SECURITY & QoS CONFIGURATION COMPLETE
===========================================
```

### Step 2: Verify Configuration

```bash
./test-security-qos.sh
```

---

## Verification & Testing

### Manual Verification Commands

#### Check ACLs
```bash
docker exec clab-leaf-spine-lab-border-r1 vtysh -c "show access-lists"
```

#### Check Firewall Rules
```bash
docker exec clab-leaf-spine-lab-border-r1 iptables -L -n -v
```

#### Check QoS Configuration
```bash
# On Leaf-1
docker exec clab-leaf-spine-lab-leaf-1 tc qdisc show dev eth1
docker exec clab-leaf-spine-lab-leaf-1 tc class show dev eth1
docker exec clab-leaf-spine-lab-leaf-1 tc filter show dev eth1
```

#### Check Traffic Policing
```bash
docker exec clab-leaf-spine-lab-spine-1 tc qdisc show dev eth1
```

#### View Firewall Logs
```bash
docker exec clab-leaf-spine-lab-border-r1 dmesg | grep -E "BLOCKED|FIREWALL"
```

### Test Scenarios

#### Test 1: Internal Communication (Should Work)
```bash
# pc1 → srv1 (both internal)
docker exec clab-leaf-spine-lab-pc1 ping -c 3 192.168.20.10
# Expected: SUCCESS
```

#### Test 2: Internal to DMZ (Should Work)
```bash
# pc1 → srv3 (DMZ)
docker exec clab-leaf-spine-lab-pc1 ping -c 3 192.168.30.10
# Expected: SUCCESS
```

#### Test 3: Firewall Blocking (Simulated)
External → Internal traffic would be blocked by firewall.
In our lab, we don't have a true "external" source, but the firewall rules are configured.

#### Test 4: QoS Traffic Marking
```bash
# Send traffic with DSCP marking
docker exec clab-leaf-spine-lab-pc1 ping -Q 0x2e -c 3 192.168.30.10
# Traffic will be classified as high priority (DSCP EF)
```

---

## How It All Works Together

### Example: Web Request from PC1 to DMZ Server

```
1. PC1 sends HTTP request to srv3 (192.168.30.10)
   ├─ Source: 192.168.10.10 (VLAN 10 - INTERNAL)
   └─ Destination: 192.168.30.10 (VLAN 30 - DMZ)

2. Packet reaches Leaf-1
   ├─ QoS: Traffic classified based on DSCP
   ├─ If DSCP = AF41 (video): Medium priority queue
   └─ HTB scheduler allocates bandwidth

3. Packet forwarded to Spine-1
   ├─ OSPF routing determines path
   ├─ Traffic policing checks ICMP rate
   └─ Forwards to Leaf-2

4. Packet reaches Border Router (conceptually)
   ├─ ACL Check: Source = INTERNAL, Dest = DMZ
   ├─ Firewall: INTERNAL → DMZ = ALLOW
   ├─ State tracking: New connection recorded
   └─ Packet forwarded

5. Packet reaches srv3 in DMZ
   └─ Server processes request

6. Return traffic (srv3 → pc1)
   ├─ Firewall: DMZ → INTERNAL
   ├─ State check: Part of ESTABLISHED connection
   ├─ ALLOW (stateful inspection)
   └─ Packet delivered to pc1
```

### Example: External Attack Attempt

```
1. External host tries to access pc1 (192.168.10.10)
   ├─ Source: 203.0.113.50 (OUTSIDE)
   └─ Destination: 192.168.10.10 (INTERNAL)

2. Packet reaches Border Router
   ├─ ACL 100 Check: Destination = 192.168.10.0/24
   ├─ Rule: deny ip any 192.168.10.0/24
   └─ DENY

3. Firewall Rule
   ├─ OUTSIDE → INTERNAL
   ├─ LOG: "BLOCKED-TO-INTERNAL: SRC=203.0.113.50 DST=192.168.10.10"
   └─ DROP

4. Result: Attack blocked, event logged
```

---

## Integration with Previous Parts

Part 4 builds on the foundation of Parts 1-3:

```
┌─────────────────────────────────────────────────────┐
│              Part 4: Security & QoS                 │
│  • ACLs filter traffic based on zones               │
│  • Firewall enforces security policies             │
│  • QoS prioritizes critical traffic                │
└────────────────────┬────────────────────────────────┘
                     │
┌─────────────────────────────────────────────────────┐
│           Part 3: Segment Routing (SR-MPLS)         │
│  • Fast label-based forwarding                      │
│  • Traffic engineering capabilities                │
└────────────────────┬────────────────────────────────┘
                     │
┌─────────────────────────────────────────────────────┐
│              Part 2: BFD Fast Convergence           │
│  • Sub-second failure detection                     │
│  • Triggers QoS and firewall path changes           │
└────────────────────┬────────────────────────────────┘
                     │
┌─────────────────────────────────────────────────────┐
│         Part 1: Leaf-Spine Base Architecture        │
│  • OSPF underlay routing                            │
│  • BGP overlay with route reflectors               │
│  • VLAN segregation                                │
└─────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Issue 1: Firewall Blocking Legitimate Traffic

**Symptom**: Internal users cannot communicate

**Check**:
```bash
docker exec clab-leaf-spine-lab-border-r1 iptables -L -n -v
```

**Solution**: Verify INTERNAL → INTERNAL rules are before DROP rules

### Issue 2: QoS Not Classifying Traffic

**Symptom**: All traffic in default queue

**Check**:
```bash
docker exec clab-leaf-spine-lab-leaf-1 tc filter show dev eth1
```

**Solution**: Ensure traffic has DSCP markings, or filters match correctly

### Issue 3: ACLs Not Filtering

**Symptom**: ACL shows configured but not filtering

**Check**:
```bash
docker exec clab-leaf-spine-lab-border-r1 vtysh -c "show access-lists"
```

**Solution**: ACLs must be applied to interface or route-map

### Issue 4: QoS Configuration Lost After Restart

**Symptom**: tc rules disappear after container restart

**Solution**: Traffic control (tc) rules are runtime. Re-run:
```bash
./configs/security-setup.sh
```

---

## Summary

### What Was Accomplished

✅ **ACLs (Access Control Lists)**
- Standard ACL 10: Internal networks identification
- Standard ACL 20: DMZ network identification
- Extended ACL 100: External traffic filtering

✅ **Zone-Based Firewall**
- 3 security zones: INTERNAL, DMZ, OUTSIDE
- Stateful firewall with connection tracking
- Traffic logging for security events
- Service-specific filtering (HTTP/HTTPS/SSH to DMZ)

✅ **QoS (Quality of Service)**
- HTB queuing on leaf switches
- 3-tier priority system (High/Medium/Default)
- DSCP-based traffic classification
- Bandwidth guarantees and ceilings
- ICMP rate limiting (flood protection)

### Security Benefits

- **Defense in Depth**: Multiple layers of security
- **Zone Segmentation**: Internal networks isolated from external
- **DMZ Protection**: Public servers in separate zone
- **Stateful Inspection**: Tracks connection state
- **Logging**: Security events recorded for audit

### QoS Benefits

- **Traffic Prioritization**: Critical services get bandwidth
- **Guaranteed Performance**: Minimum bandwidth per class
- **Burst Capability**: Can use more when available
- **DoS Protection**: ICMP rate limiting
- **Fair Queuing**: Within priority classes

---

## Files Created for Part 4

1. ✅ [configs/security-setup.sh](configs/security-setup.sh) - Complete security & QoS configuration
2. ✅ [test-security-qos.sh](test-security-qos.sh) - Comprehensive testing script
3. ✅ [PART4-SECURITY-QOS-GUIDE.md](PART4-SECURITY-QOS-GUIDE.md) - This guide

---

## Next Steps

Your network now has:
- ✅ **Part 1**: Leaf-Spine Architecture (OSPF, BGP, VLANs)
- ✅ **Part 2**: BFD Fast Convergence
- ✅ **Part 3**: Segment Routing (SR-MPLS)
- ✅ **Part 4**: Security & QoS (ACLs, Firewall, QoS)

**The lab is complete!** All requirements have been implemented.

For production deployment, consider:
- Backup and disaster recovery
- Monitoring and alerting (SNMP, syslog)
- Configuration management (Ansible, Salt)
- Network automation
- Documentation and runbooks

---

## References

- **iptables Documentation**: https://netfilter.org/documentation/
- **Linux Traffic Control (tc)**: https://tldp.org/HOWTO/Traffic-Control-HOWTO/
- **DSCP Standards**: RFC 2474, RFC 2475
- **QoS Best Practices**: Cisco QoS Design Guide
- **Zone-Based Firewall**: Cisco Zone-Based Policy Firewall

---

**Congratulations! You've built a production-grade data center network with enterprise security and QoS!** 🎉
