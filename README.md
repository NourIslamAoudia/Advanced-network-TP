# 🎓 Atelier Réseaux Avancés - Containerlab

## 📋 Vue d'ensemble

Ce projet implémente un **réseau d'entreprise moderne** basé sur une architecture **Leaf-Spine** avec Containerlab. Il couvre les technologies essentielles pour les réseaux de datacenter : VLANs, BGP, QoS, Sécurité et concepts avancés comme le Segment Routing.

### 🎯 Objectifs Pédagogiques

L'atelier est divisé en **4 parties progressives** :

1. **🟦 Fondations Layer 2 & 3** - VLANs, Trunking, Routage Inter-VLAN
2. **🟩 Architecture Underlay** - Leaf-Spine, BGP, ECMP, Haute Disponibilité
3. **🟨 Segment Routing & Overlay** - MPLS, SR-MPLS, EVPN (niveau avancé)
4. **🟥 Sécurité & Services** - ACLs, Firewall, QoS

📖 **[Guide Complet de l'Atelier →](./ATELIER-GUIDE.md)**

---

## 🏗️ Architecture Réseau

```
                    Internet (203.0.113.2/30)
                         |
                    Edge-Router (Firewall/QoS)
                    /            \
              Spine-1          Spine-2
             (AS 65000)       (AS 65000)
                \    X    /
                 \  / \  /
                  \/   \/
                  /\   /\
                 /  \ /  \
              Leaf-1    Leaf-2
            (AS 65001)  (AS 65002)
              /    \        |
         Server-1  Server-2  Client-1
        (VLAN 10) (VLAN 20) (VLAN 30)
```

### Composants

- **2 Spines** : Routeurs cœur (FRRouting)
- **2 Leafs** : Routeurs accès avec VLANs (FRRouting)
- **1 Edge Router** : Routeur de bordure avec firewall
- **3 Serveurs/Clients** : Machines Alpine Linux

---

## 🚀 Démarrage Rapide

### 1️⃣ Prérequis

```bash
# Installer Containerlab
sudo bash -c "$(curl -sL https://get.containerlab.dev)"

# Vérifier Docker
docker --version
```

### 2️⃣ Déployer le Lab

```bash
# Cloner le projet
git clone https://github.com/NourIslamAoudia/Advanced-network-TP
cd Advanced-network-TP

# Déployer la topologie
sudo containerlab deploy -t leaf-spine-datacenter.clab.yml

# Attendre que les conteneurs soient prêts (10-15 secondes)
sleep 15

# Configurer automatiquement le réseau
sudo chmod +x setup-all.sh
sudo ./setup-all.sh
```

### 3️⃣ Vérifier le Fonctionnement

```bash
# Lancer les tests automatiques
sudo chmod +x test-network.sh
sudo ./test-network.sh

# Accéder à un routeur
docker exec -it clab-leaf-spine-datacenter-Spine-1 vtysh

# Vérifier les sessions BGP
vtysh -c "show ip bgp summary"
```

---

## 🧪 Tests et Validation

### Tests de Connectivité

```bash
# Server-1 → Gateway Leaf-1
docker exec clab-leaf-spine-datacenter-Server-1 ping -c 3 192.168.10.1

# Server-1 → Client-1 (Inter-VLAN via BGP)
docker exec clab-leaf-spine-datacenter-Server-1 ping -c 3 192.168.30.10

# Server-1 → Internet
docker exec clab-leaf-spine-datacenter-Server-1 ping -c 3 203.0.113.2
```

### Vérification BGP

```bash
# Sessions BGP sur Spine-1
docker exec clab-leaf-spine-datacenter-Spine-1 vtysh -c "show ip bgp summary"

# Routes BGP apprises
docker exec clab-leaf-spine-datacenter-Spine-1 vtysh -c "show ip bgp"
```

### Test de Résilience (ECMP)

```bash
# Couper un lien Spine-1 ↔ Leaf-1
docker exec clab-leaf-spine-datacenter-Spine-1 ip link set eth1 down

# Vérifier que le trafic passe toujours (via Spine-2)
docker exec clab-leaf-spine-datacenter-Server-1 ping -c 3 192.168.30.10

# Réactiver le lien
docker exec clab-leaf-spine-datacenter-Spine-1 ip link set eth1 up
```

---

## 📚 Documentation

### Plan d'Adressage

**Loopbacks (Router-ID BGP)** :
| Routeur | Loopback | AS BGP |
|---------|----------|--------|
| Spine-1 | 10.255.0.1/32 | 65000 |
| Spine-2 | 10.255.0.2/32 | 65000 |
| Leaf-1 | 10.255.1.1/32 | 65001 |
| Leaf-2 | 10.255.1.2/32 | 65002 |
| Edge-Router | 10.255.255.1/32 | 65100 |

**Liens Point-to-Point (/31)** :
| Lien | Adressage |
|------|-----------|
| Spine-1 ↔ Leaf-1 | 10.0.1.0/31 |
| Spine-1 ↔ Leaf-2 | 10.0.1.2/31 |
| Spine-2 ↔ Leaf-1 | 10.0.1.4/31 |
| Spine-2 ↔ Leaf-2 | 10.0.1.6/31 |
| Spine-1 ↔ Edge | 10.0.2.0/31 |
| Spine-2 ↔ Edge | 10.0.2.2/31 |

**VLANs & Serveurs** :
| VLAN | Réseau | Serveur | Leaf |
|------|--------|---------|------|
| 10 | 192.168.10.0/24 | Server-1 (.10) | Leaf-1 |
| 20 | 192.168.20.0/24 | Server-2 (.10) | Leaf-1 |
| 30 | 192.168.30.0/24 | Client-1 (.10) | Leaf-2 |

---

## 🛠️ Commandes Utiles

### Gestion du Lab

```bash
# Lister les conteneurs du lab
docker ps

# Accéder à un routeur
docker exec -it clab-leaf-spine-datacenter-<NOM> sh
docker exec -it clab-leaf-spine-datacenter-<NOM> vtysh  # Mode FRR

# Voir les logs d'un conteneur
docker logs clab-leaf-spine-datacenter-Spine-1

# Détruire le lab
sudo containerlab destroy -t leaf-spine-datacenter.clab.yml
```

### Diagnostic Réseau

```bash
# Table de routage
ip route show

# Interfaces réseau
ip addr show
ip link show

# Statistiques d'interfaces
ip -s link show eth1

# Test de connectivité
ping -c 3 <IP>
traceroute <IP>
```

### Diagnostic BGP (FRRouting)

```bash
# Se connecter au CLI FRR
vtysh

# Résumé des voisins BGP
show ip bgp summary

# Table BGP complète
show ip bgp

# Détails d'un voisin
show ip bgp neighbors <IP>

# Routes vers un réseau spécifique
show ip bgp 192.168.10.0/24
```

### Sécurité & Firewall

```bash
# Règles iptables
iptables -L -n -v
iptables -t nat -L -n -v

# Ajouter une règle
iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.10.0/24 -j DROP

# QoS (Traffic Control)
tc qdisc show
tc class show
```

---

## 🔧 Troubleshooting

### Problème : "Cannot find device eth1"

**Cause** : Les conteneurs ne sont pas complètement démarrés.

**Solution** :

```bash
# Détruire et recréer
sudo containerlab destroy -t leaf-spine-datacenter.clab.yml
sudo containerlab deploy -t leaf-spine-datacenter.clab.yml

# Attendre 15 secondes avant de lancer setup-all.sh
sleep 15
sudo ./setup-all.sh
```

### Problème : Sessions BGP en état "Active" ou "Idle"

**Cause** : Mauvaise configuration IP ou problème de routabilité.

**Solution** :

```bash
# Vérifier les IPs des interfaces
docker exec clab-leaf-spine-datacenter-Spine-1 ip addr show

# Vérifier la connectivité vers le voisin
docker exec clab-leaf-spine-datacenter-Spine-1 ping -c 3 10.0.1.1

# Relancer FRR
docker exec clab-leaf-spine-datacenter-Spine-1 /etc/init.d/frr restart
```

### Problème : Pas de connectivité Inter-VLAN

**Cause** : BGP n'a pas convergé ou routes non annoncées.

**Solution** :

```bash
# Vérifier que BGP annonce les réseaux
docker exec clab-leaf-spine-datacenter-Leaf-1 vtysh -c "show ip bgp"

# Vérifier les routes dans la table de routage
docker exec clab-leaf-spine-datacenter-Leaf-1 ip route show

# Relancer le script de configuration
sudo ./setup-all.sh
```

---

## 📖 Ressources Complémentaires

### Documentation

- **[Guide Complet de l'Atelier](./ATELIER-GUIDE.md)** - Cours théorique et exercices pratiques
- [Containerlab Documentation](https://containerlab.dev/)
- [FRRouting Documentation](https://docs.frrouting.org/)
- [RFC 4271 - BGP-4](https://datatracker.ietf.org/doc/html/rfc4271)

### Concepts Avancés

- **Segment Routing** : [RFC 8660](https://datatracker.ietf.org/doc/html/rfc8660)
- **EVPN** : [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432)
- **BGP in Data Center** : [RFC 7938](https://datatracker.ietf.org/doc/html/rfc7938)

---

## 🤝 Contribution et Collaboration

### Récupérer les Dernières Modifications

```bash
git pull origin main
```

### Partager Vos Modifications

```bash
# Ajouter vos changements
git add leaf-spine-datacenter.clab.yml setup-all.sh

# Commit avec un message descriptif
git commit -m "feat: ajout configuration QoS sur Edge-Router"

# Pousser sur GitHub
git push origin main
```

### Bonnes Pratiques

✅ **À PUSH** :

- Fichiers de configuration (`.clab.yml`, `.conf`, `.sh`)
- Documentation (`.md`)
- Scripts utiles

❌ **NE PAS PUSH** :

- Dossier `clab-*/` (généré automatiquement)
- Fichiers logs (`*.log`)
- Fichiers temporaires

---

## 📝 Structure du Projet

```
Advanced-network-TP/
├── leaf-spine-datacenter.clab.yml  # Topologie Containerlab
├── setup-all.sh                     # Script de configuration automatique
├── test-network.sh                  # Script de tests
├── restart-frr.sh                   # Redémarrage FRR
├── README.md                        # Ce fichier
├── ATELIER-GUIDE.md                 # Guide pédagogique complet
├── spine1-frr.conf                  # Config FRR Spine-1
├── spine2-frr.conf                  # Config FRR Spine-2
├── leaf1-frr.conf                   # Config FRR Leaf-1
├── leaf2-frr.conf                   # Config FRR Leaf-2
├── edge-frr.conf                    # Config FRR Edge-Router
└── .gitignore                       # Fichiers à ignorer
```

---

## 🎓 Niveau et Prérequis

**Niveau** : Intermédiaire à Avancé

**Prérequis recommandés** :

- Connaissance de base de TCP/IP
- Notions de routage (statique, OSPF ou BGP)
- Familiarité avec Linux et ligne de commande
- Concepts VLANs et switching

**Durée estimée** : 4-6 heures (toutes parties)

---

## 📜 Licence

Ce projet est à **but éducatif** uniquement.

---

## 🌟 Auteurs

- **Nour Islam Aoudia** - [GitHub](https://github.com/NourIslamAoudia)

---

**Bon apprentissage ! 🚀 N'hésitez pas à ouvrir une issue pour toute question.**
