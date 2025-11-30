# LEAF-SPINE NETWORK ARCHITECTURE EXPLAINED

## 📊 NETWORK TOPOLOGY

```
                    INTERNET (203.0.113.1/30)
                         |
                   BORDER-R1 (100.100.100.1)
                    /           \
            10.0.0.0/30      10.0.0.4/30
              /                   \
         SPINE-1 (1.1.1.1)    SPINE-2 (2.2.2.2)
          /      \              /      \
    10.1.1.0/31  10.1.1.2/31  10.1.1.4/31  10.1.1.6/31
       /            \          /            \
   LEAF-1           LEAF-2   LEAF-1        LEAF-2
(10.10.10.1)     (10.10.10.2)
     |               |
  Bridges:        Bridges:
   br10            br20 (for srv2)
   br20 (for srv1) br30
     |               |
 Clients          Servers
```

## 🔧 WHY BRIDGES ARE NECESSARY

### The Problem:
When **multiple devices** on the **SAME subnet** are connected to **DIFFERENT physical interfaces** on a switch/router, you need a **BRIDGE** to connect them at Layer 2.

### Example from Your Lab:

**Leaf-1:**
- pc1 (192.168.10.10) → eth3
- pc2 (192.168.10.11) → eth4

Both are on `192.168.10.0/24` but on different ports!

**Without Bridge:**
- pc1 sends packet to pc2
- leaf-1 has NO Layer 2 path between eth3 and eth4
- **Result: FAIL ❌**

**With Bridge (br10):**
- eth3 and eth4 are enslaved to br10
- br10 acts like a virtual switch
- Packets can flow between pc1 ↔ pc2
- **Result: SUCCESS ✅**

## 📍 IP ADDRESS ASSIGNMENT

### Loopback IPs (Router IDs):
- border-r1: `100.100.100.1/32`
- spine-1: `1.1.1.1/32`
- spine-2: `2.2.2.2/32`
- leaf-1: `10.10.10.1/32`
- leaf-2: `10.10.10.2/32`

### Point-to-Point Links:
| Link | Side A | Side B | Purpose |
|------|--------|--------|---------|
| Border → Spine-1 | 10.0.0.1/30 | 10.0.0.2/30 | Uplink |
| Border → Spine-2 | 10.0.0.5/30 | 10.0.0.6/30 | Uplink |
| Spine-1 → Leaf-1 | 10.1.1.0/31 | 10.1.1.1/31 | Fabric |
| Spine-1 → Leaf-2 | 10.1.1.2/31 | 10.1.1.3/31 | Fabric |
| Spine-2 → Leaf-1 | 10.1.1.4/31 | 10.1.1.5/31 | Fabric |
| Spine-2 → Leaf-2 | 10.1.1.6/31 | 10.1.1.7/31 | Fabric |
| Spine-1 ↔ Spine-2 | 10.2.2.0/31 | 10.2.2.1/31 | Peering |

### Client Subnets (VLANs):
| VLAN | Subnet | Gateway | Devices | Leaf |
|------|--------|---------|---------|------|
| VLAN 10 | 192.168.10.0/24 | 192.168.10.1 | pc1, pc2 | leaf-1 |
| VLAN 20 | 192.168.20.0/24 | 192.168.20.1 | srv1 | leaf-1 |
| VLAN 20 | 192.168.20.0/24 | 192.168.20.1 | srv2 | leaf-2 |
| VLAN 30 | 192.168.30.0/24 | 192.168.30.1 | srv3, srv4 | leaf-2 |

## 🔄 HOW ROUTING WORKS

### 1. **OSPF (Open Shortest Path First)**
- **Purpose:** Learn network topology and routes
- **Area:** All devices in Area 0 (backbone)
- **What it advertises:**
  - Loopback IPs (for BGP peering)
  - Point-to-point links
  - Client subnets (192.168.x.0/24)

**Example:** When leaf-1 advertises 192.168.10.0/24, spine-1 and spine-2 learn how to reach it.

### 2. **BGP (Border Gateway Protocol)**
- **Purpose:** Exchange routes between leafs (for redundancy)
- **Type:** iBGP (internal) - same AS 65000
- **Route Reflectors:** spine-1 and spine-2
  - Leafs peer with spines via loopback IPs
  - Spines reflect routes between leafs

### 3. **Packet Flow Example: pc1 → srv3**

```
pc1 (192.168.10.10)
  ↓ default route via 192.168.10.1
leaf-1 (br10: 192.168.10.1)
  ↓ OSPF knows 192.168.30.0/24 via spine-1
leaf-1 eth1 (10.1.1.1) → spine-1 eth2 (10.1.1.0)
  ↓ OSPF routing to leaf-2
spine-1 eth3 (10.1.1.2) → leaf-2 eth1 (10.1.1.3)
  ↓ directly connected
leaf-2 (br30: 192.168.30.1)
  ↓ ARP lookup
srv3 (192.168.30.10)
```

**TTL decreases:**
- pc1: TTL=64
- After leaf-1: TTL=63
- After spine-1: TTL=62
- After leaf-2: TTL=61
- Arrives at srv3: TTL=61 ✓

## ⚠️ CURRENT ARCHITECTURE LIMITATION

### The VLAN 20 Problem:
- **srv1** is on VLAN 20 connected to **leaf-1**
- **srv2** is on VLAN 20 connected to **leaf-2**

Both leafs think they "own" 192.168.20.0/24 as a directly connected network.

**Current Status:**
- ✅ pc1 ↔ srv1 (same leaf)
- ✅ pc1 ↔ srv3 (different leafs, different subnets)
- ❌ srv1 ↔ srv2 (same subnet, different leafs) **DOESN'T WORK**

### Why srv1 ↔ srv2 Fails:
1. srv1 sends to srv2 (192.168.20.11)
2. leaf-1 sees 192.168.20.0/24 as "directly connected"
3. leaf-1 does ARP lookup for 192.168.20.11 on br20
4. srv2 is NOT on leaf-1's br20 (it's on leaf-2!)
5. **ARP fails → ping fails**

### Solutions:
1. **Simple Fix:** Use separate subnets per leaf
   - VLAN 20 on leaf-1: 192.168.20.0/24 (srv1 only)
   - VLAN 21 on leaf-2: 192.168.21.0/24 (srv2 only)

2. **Advanced Fix:** Implement VXLAN/EVPN (out of scope for basic lab)

## ✅ WHAT WORKS PERFECTLY

| Test | Status | Explanation |
|------|--------|-------------|
| pc1 → pc2 | ✅ PASS | Same subnet, same leaf, via br10 |
| pc1 → srv1 | ✅ PASS | Different subnets, same leaf, routed via leaf-1 |
| pc1 → srv3 | ✅ PASS | Different subnets, different leafs, routed via spine |
| srv3 → srv4 | ✅ PASS | Same subnet, same leaf, via br30 |
| pc1 → gateway | ✅ PASS | Direct ARP to br10 |
| srv1 → srv2 | ❌ FAIL | Same subnet, different leafs - needs VXLAN |

## 🎯 KEY CONCEPTS

### 1. **Leaf-Spine Architecture**
- **Leafs:** Access layer (connect end devices)
- **Spines:** Aggregation layer (connect leafs together)
- **Benefits:**
  - Predictable latency (max 2 hops between any leafs)
  - Easy to scale (add more leafs/spines)
  - High bandwidth (ECMP across spines)

### 2. **Underlay vs Overlay**
- **Underlay:** Physical IP connectivity (10.x.x.x networks)
  - Uses OSPF for reachability
- **Overlay:** Logical connectivity (192.168.x.x networks)
  - Uses BGP for route exchange
  - Can use VXLAN for L2 extension

### 3. **Route Reflectors**
- Instead of full mesh iBGP (every leaf peers with every leaf)
- Leafs peer only with spines (route reflectors)
- Spines reflect routes between leafs
- **Benefit:** Scales better (N+2 peers instead of N²)

## 📝 FILES BREAKDOWN

### Config Files:
- `configs/spine-1.cfg` - OSPF + BGP for spine-1
- `configs/spine-2.cfg` - OSPF + BGP for spine-2
- `configs/leaf-1.cfg` - OSPF + BGP for leaf-1
- `configs/leaf-2.cfg` - OSPF + BGP for leaf-2
- `configs/border-r1.cfg` - OSPF + BGP for border router
- `configs/daemons/frr-daemons` - Enables FRR routing daemons

### Lab Files:
- `main.clab.yml` - Containerlab topology definition
- `test-connectivity.sh` - Automated testing script

## 🚀 HOW TO USE

### Deploy Lab:
```bash
sudo containerlab deploy --topo main.clab.yml
```

### Test Connectivity:
```bash
./test-connectivity.sh
```

### Check Routing:
```bash
# OSPF neighbors
docker exec clab-leaf-spine-lab-spine-1 vtysh -c "show ip ospf neighbor"

# BGP status
docker exec clab-leaf-spine-lab-leaf-1 vtysh -c "show ip bgp summary"

# Routes
docker exec clab-leaf-spine-lab-leaf-1 vtysh -c "show ip route"
```


### Destroy Lab:
```bash
sudo containerlab destroy --topo main.clab.yml --cleanup
```
