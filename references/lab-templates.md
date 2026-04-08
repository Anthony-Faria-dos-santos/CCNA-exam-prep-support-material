# Lab Templates Reference — Topologies et scénarios par module

## Module 1 — Network Fundamentals

### Lab 1.1 : Câblage et identification des interfaces
- Topologie : 2 PCs + 1 switch + 1 routeur
- Focus : Identifier interfaces, types de câbles, configurer IP, vérifier connectivité
- Topics : 1.3, 1.4, 1.6, 1.10

### Lab 1.2 : Adressage IPv4/IPv6 et sous-réseaux
- Topologie : 3 réseaux interconnectés par 2 routeurs
- Focus : Calculer sous-réseaux, configurer IPv4+IPv6, vérifier avec ping/traceroute
- Topics : 1.6, 1.7, 1.8, 1.9

## Module 2 — Network Access

### Lab 2.1 : VLANs et Trunks
- Topologie : 4 PCs + 2 switches + 1 routeur (router-on-a-stick)
- Focus : Créer VLANs, configurer trunks 802.1Q, inter-VLAN routing
- Topics : 2.1, 2.2, 2.3

### Lab 2.2 : EtherChannel LACP
- Topologie : 2 switches avec liens redondants
- Focus : Configurer LACP, vérifier channel-group, load balancing
- Topics : 2.4

### Lab 2.3 : Spanning Tree (RSTP)
- Topologie : 3 switches en triangle avec redondance
- Focus : Identifier root bridge, ports, observer convergence, configurer PortFast
- Topics : 2.5

## Module 3 — IP Connectivity

### Lab 3.1 : Routes statiques IPv4/IPv6
- Topologie : 4 routeurs en série + réseaux stub
- Focus : Routes statiques, default route, floating static, vérification
- Topics : 3.1, 3.2, 3.3

### Lab 3.2 : OSPF Single-Area — Configuration de base
- Topologie : 3 routeurs + 2 switches + 4 PCs (area 0)
- Focus : Activer OSPF, router-id, passive-interface, adjacences
- Topics : 3.4

### Lab 3.3 : OSPF — DR/BDR et types de réseau
- Topologie : 4 routeurs sur segment broadcast + point-to-point
- Focus : Élection DR/BDR, priorité, réseau point-to-point, vérification
- Topics : 3.4

### Lab 3.4 : Inter-VLAN Routing + OSPF combiné
- Topologie : 2 routeurs + 2 switches + 6 PCs multi-VLAN
- Focus : Router-on-a-stick + OSPF pour connectivité inter-sites
- Topics : 3.2, 3.4, 2.1, 2.2

## Module 4 — IP Services

### Lab 4.1 : NAT/PAT
- Topologie : 1 routeur (NAT gateway) + réseau interne + "Internet" simulé
- Focus : NAT statique, NAT pool, PAT, vérification avec show ip nat translations
- Topics : 4.1

### Lab 4.2 : DHCP, NTP, Syslog
- Topologie : 1 routeur DHCP server + 1 switch + 3 PCs + 1 serveur NTP/Syslog
- Focus : Configurer DHCP pool, relay, NTP client/server, syslog
- Topics : 4.2, 4.3, 4.5, 4.6

## Module 5 — Security Fundamentals

### Lab 5.1 : ACL Standard et Extended
- Topologie : 2 routeurs + 2 réseaux + serveurs (web, DNS)
- Focus : Créer ACLs, appliquer in/out, vérifier filtrage, named ACLs
- Topics : 5.6

### Lab 5.2 : Port Security et DHCP Snooping
- Topologie : 1 switch + 4 PCs (dont 1 attaquant simulé)
- Focus : Port security (sticky MAC), DHCP snooping, DAI
- Topics : 5.7

### Lab 5.3 : SSH et sécurisation d'accès
- Topologie : 1 routeur + 1 switch + 1 PC d'administration
- Focus : Désactiver telnet, configurer SSH, local users, enable secret
- Topics : 5.3, 4.8

## Module 6 — Automation & Programmability

### Lab 6.1 : REST API et JSON
- Topologie : Conceptuel (pas Packet Tracer — utiliser Postman ou curl)
- Focus : Requêtes GET/POST sur API réseau simulée, interpréter JSON
- Topics : 6.5, 6.7

### Lab 6.2 : Cisco DNA Center (exploration GUI)
- Topologie : Simulation sandbox Cisco DevNet
- Focus : Explorer l'interface DNA Center, comparer avec CLI traditionnel
- Topics : 6.4
