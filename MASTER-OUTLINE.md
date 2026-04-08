# MASTER OUTLINE — Guide CCNA 200-301 v1.1

> **Version** : 2.0 — Dernière mise à jour : 2026-04-04
> **Auteur** : Guide de préparation complet
> **Durée totale** : 10 semaines (~15h/semaine) — 150 heures
> **Pages estimées** : ~320 pages (hors annexes)

---

## Vue d'ensemble

### Objectif

Ce guide prépare à la certification Cisco CCNA 200-301 v1.1 (valable jusqu'en août 2026 minimum). Il couvre l'intégralité des 6 domaines de l'examen, y compris les ajouts v1.1 (GenAI, Cloud Management, ML). L'approche suit un ratio théorie/pratique de 60/40 avec des labs Packet Tracer et des exercices appliqués à chaque section.

### Public cible

Étudiant(e) Bac+3 en développement ou cybersécurité, avec :
- Des bases IT solides (utilisation courante du terminal, notions client/serveur)
- Une compréhension élémentaire du modèle OSI et de TCP/IP
- Pas d'expérience approfondie en administration réseau ni en configuration Cisco

### Approche pédagogique

Chaque section suit la progression cognitive définie dans `references/pedagogy-rules.md` :
1. Accroche (contexte entreprise) → 2. Concept (théorie + analogies) → 3. Détail technique → 4. CLI avec output → 5. Point exam → 6. Exercice → 7. Cross-references

Les verbes Cisco (Describe, Configure, Compare, Interpret...) dictent le niveau de profondeur selon la taxonomie de Bloom.

### Prérequis techniques

- PC avec 8 Go RAM minimum
- Cisco Packet Tracer 8.2+ installé
- Accès Internet (sandbox Cisco DevNet pour le module 6)
- Éditeur de texte / terminal

---

## Structure des modules

---

## Module 1 — Network Fundamentals

> **Domain 1** | **Poids examen : 20%** | **Durée : 2 semaines** | **Prérequis : Aucun**

### Sections

| # | Section | Topic IDs | Verbe Cisco | Pages estimées |
|---|---------|-----------|-------------|----------------|
| 1.1 | Rôle et fonction des composants réseau | 1.1.a–h | Explain | 5 |
| 1.2 | Topologies réseau (2-tier, 3-tier, spine-leaf, WAN, SOHO, cloud) | 1.2.a–f | Describe | 4 |
| 1.3 | Interfaces physiques et types de câblage | 1.3.a–b | Compare | 3 |
| 1.4 | Problèmes d'interface et de câbles | 1.4 | Identify | 3 |
| 1.5 | TCP vs UDP | 1.5 | Compare | 4 |
| 1.6 | Adressage IPv4 et subnetting | 1.6 | Configure & Verify | 8 |
| 1.7 | Adressage IPv4 privé | 1.7 | Describe | 2 |
| 1.8 | Adressage IPv6 et préfixes | 1.8 | Configure & Verify | 5 |
| 1.9 | Types d'adresses IPv6 (unicast, anycast, multicast, EUI-64) | 1.9.a–d | Describe | 4 |
| 1.10 | Vérification des paramètres IP sur les OS clients | 1.10 | Verify | 3 |
| 1.11 | Principes du wireless (canaux, SSID, RF, chiffrement) | 1.11.a–d | Describe | 4 |
| 1.12 | Fondamentaux de la virtualisation (VMs, containers, VRFs) | 1.12 | Explain | 3 |
| 1.13 | Concepts de commutation (MAC learning, flooding, MAC table) | 1.13.a–d | Describe | 4 |
| 1.14 | Utilisation de la GenAI pour le networking *(NOUVEAU v1.1)* | 1.14 | Describe | 3 |
| | **Total Module 1** | | | **~55 pages** |

### Exercices prévus (14)

| Exercice | Topic | Description |
|----------|-------|-------------|
| Ex 1.1 | 1.1 | Identifier les composants dans un schéma réseau d'entreprise |
| Ex 1.2 | 1.2 | Choisir la topologie adaptée à 3 scénarios (PME, datacenter, campus) |
| Ex 1.3 | 1.3 | Associer câbles et interfaces à partir d'un cahier des charges |
| Ex 1.4 | 1.4 | Diagnostiquer des erreurs d'interface à partir d'outputs `show interface` |
| Ex 1.5 | 1.5 | Déterminer TCP ou UDP pour 10 protocoles applicatifs |
| Ex 1.6a | 1.6 | Calculer sous-réseaux : 5 exercices progressifs (VLSM) |
| Ex 1.6b | 1.6 | Configurer l'adressage IPv4 sur une topologie 3 réseaux |
| Ex 1.7 | 1.7 | Identifier les plages RFC 1918 et justifier l'usage du NAT |
| Ex 1.8 | 1.8 | Configurer IPv6 sur 2 routeurs et vérifier la connectivité |
| Ex 1.9 | 1.9 | Classifier 10 adresses IPv6 par type (GUA, LLA, ULA, multicast) |
| Ex 1.10 | 1.10 | Vérifier et comparer les paramètres IP sur Windows, Linux, macOS |
| Ex 1.11 | 1.11 | Concevoir un plan de canaux Wi-Fi pour un open-space 3 AP |
| Ex 1.12 | 1.12 | Comparer VM, container et VRF dans un tableau + cas d'usage |
| Ex 1.13 | 1.13 | Tracer le parcours d'une trame à travers 2 switches (MAC table) |

### Labs prévus (2)

| Lab | Titre | Topics | Durée |
|-----|-------|--------|-------|
| Lab 1.1 | Câblage et identification des interfaces | 1.3, 1.4, 1.6, 1.10 | 45 min |
| Lab 1.2 | Adressage IPv4/IPv6 et sous-réseaux | 1.6, 1.7, 1.8, 1.9 | 60 min |

### Quiz Module 1

- **15 questions** — MCQ format examen
- Couvre tous les topics 1.1 à 1.14
- Durée suggérée : 25 minutes
- Score minimum pour passer au module 2 : 70%

---

## Module 2 — Network Access

> **Domain 2** | **Poids examen : 20%** | **Durée : 2 semaines** | **Prérequis : Module 1**

### Sections

| # | Section | Topic IDs | Verbe Cisco | Pages estimées |
|---|---------|-----------|-------------|----------------|
| 2.1 | VLANs sur plusieurs switches (access, voice, default, inter-VLAN) | 2.1.a–c | Configure & Verify | 6 |
| 2.2 | Connectivité inter-switches (trunks, 802.1Q, native VLAN) | 2.2.a–c | Configure & Verify | 5 |
| 2.3 | Protocoles de découverte L2 (CDP et LLDP) | 2.3 | Configure & Verify | 3 |
| 2.4 | EtherChannel LACP (L2/L3) | 2.4 | Configure & Verify | 5 |
| 2.5 | Rapid PVST+ Spanning Tree (root, ports, PortFast) | 2.5.a–c | Interpret | 6 |
| 2.6 | Architectures wireless Cisco et modes AP | 2.6 | Describe | 4 |
| 2.7 | Connexions physiques WLAN (AP, WLC, trunks, LAG) | 2.7 | Describe | 3 |
| 2.8 | Accès d'administration (Telnet, SSH, HTTPS, console, TACACS+/RADIUS, cloud) | 2.8 | Describe | 4 |
| 2.9 | Configuration GUI WLC pour la connectivité client | 2.9 | Interpret | 4 |
| | **Total Module 2** | | | **~40 pages** |

### Exercices prévus (9)

| Exercice | Topic | Description |
|----------|-------|-------------|
| Ex 2.1a | 2.1 | Concevoir un plan VLAN pour une entreprise de 4 départements |
| Ex 2.1b | 2.1 | Configurer inter-VLAN routing (router-on-a-stick) |
| Ex 2.2 | 2.2 | Configurer un trunk 802.1Q et identifier les erreurs de native VLAN |
| Ex 2.3 | 2.3 | Interpréter des outputs `show cdp neighbors` et `show lldp neighbors` |
| Ex 2.4 | 2.4 | Configurer un EtherChannel LACP et vérifier le load balancing |
| Ex 2.5 | 2.5 | Prédire l'élection du root bridge et les états des ports sur 3 switches |
| Ex 2.6 | 2.6 | Comparer les modes AP (local, FlexConnect, monitor, sniffer) |
| Ex 2.8 | 2.8 | Choisir le protocole d'accès approprié pour 5 scénarios |
| Ex 2.9 | 2.9 | Interpréter des captures d'écran de configuration WLC |

### Labs prévus (3)

| Lab | Titre | Topics | Durée |
|-----|-------|--------|-------|
| Lab 2.1 | VLANs et Trunks + Router-on-a-Stick | 2.1, 2.2, 2.3 | 60 min |
| Lab 2.2 | EtherChannel LACP | 2.4 | 45 min |
| Lab 2.3 | Spanning Tree (RSTP) | 2.5 | 45 min |

### Quiz Module 2

- **12 questions** — MCQ format examen
- Couvre tous les topics 2.1 à 2.9
- Durée suggérée : 20 minutes
- Score minimum : 70%

---

## Module 3 — IP Connectivity

> **Domain 3** | **Poids examen : 25% (le plus lourd)** | **Durée : 2 semaines** | **Prérequis : Modules 1-2**

### Sections

| # | Section | Topic IDs | Verbe Cisco | Pages estimées |
|---|---------|-----------|-------------|----------------|
| 3.1 | Composants de la table de routage | 3.1.a–g | Interpret | 6 |
| 3.2 | Décision de forwarding d'un routeur | 3.2.a–c | Determine | 5 |
| 3.3 | Routage statique IPv4 et IPv6 (default, network, host, floating) | 3.3.a–d | Configure & Verify | 7 |
| 3.4 | OSPF single-area v2 (adjacences, P2P, broadcast, DR/BDR, router-id) | 3.4.a–d | Configure & Verify | 10 |
| 3.5 | FHRP (HSRP, VRRP, GLBP) — concepts | 3.5 | Describe | 4 |
| 3.6 | Cloud network management *(NOUVEAU v1.1)* | 3.6 | Describe | 3 |
| | **Total Module 3** | | | **~35 pages** |

> **Note** : Le topic 3.4 (OSPF) est le sujet le plus testé à l'examen. Il bénéficie d'un traitement étendu (10 pages) avec 2 labs dédiés, conformément aux règles pédagogiques.

### Exercices prévus (8)

| Exercice | Topic | Description |
|----------|-------|-------------|
| Ex 3.1a | 3.1 | Interpréter une table de routage complète (identifier codes, AD, métrique) |
| Ex 3.1b | 3.1 | Déterminer le next-hop pour 5 destinations à partir d'une table de routage |
| Ex 3.2 | 3.2 | Résoudre 5 scénarios de longest prefix match |
| Ex 3.3a | 3.3 | Configurer des routes statiques IPv4/IPv6 sur une topologie 4 routeurs |
| Ex 3.3b | 3.3 | Implémenter une floating static route avec basculement |
| Ex 3.4a | 3.4 | Prédire l'élection DR/BDR à partir des priorités et router-id |
| Ex 3.4b | 3.4 | Troubleshooter une adjacence OSPF qui ne s'établit pas |
| Ex 3.5 | 3.5 | Comparer HSRP, VRRP et GLBP dans un tableau + recommandation |

### Labs prévus (4)

| Lab | Titre | Topics | Durée |
|-----|-------|--------|-------|
| Lab 3.1 | Routes statiques IPv4/IPv6 | 3.1, 3.2, 3.3 | 60 min |
| Lab 3.2 | OSPF Single-Area — Configuration de base | 3.4 | 60 min |
| Lab 3.3 | OSPF — DR/BDR et types de réseau | 3.4 | 60 min |
| Lab 3.4 | Inter-VLAN Routing + OSPF combiné | 3.2, 3.4, 2.1, 2.2 | 75 min |

### Quiz Module 3

- **15 questions** — MCQ format examen (dont 5 sur OSPF)
- Couvre tous les topics 3.1 à 3.6
- Durée suggérée : 25 minutes
- Score minimum : 70%

---

## Module 4 — IP Services

> **Domain 4** | **Poids examen : 10%** | **Durée : 1 semaine** | **Prérequis : Modules 1-3**

### Sections

| # | Section | Topic IDs | Verbe Cisco | Pages estimées |
|---|---------|-----------|-------------|----------------|
| 4.1 | NAT statique et pools (inside source) | 4.1 | Configure & Verify | 5 |
| 4.2 | NTP client/serveur | 4.2 | Configure & Verify | 3 |
| 4.3 | DHCP et DNS — rôle dans le réseau | 4.3 | Explain | 4 |
| 4.4 | SNMP dans les opérations réseau | 4.4 | Explain | 3 |
| 4.5 | Syslog (facilities et levels) | 4.5 | Describe | 3 |
| 4.6 | DHCP client et relay | 4.6 | Configure & Verify | 4 |
| 4.7 | QoS — PHB (classification, marking, queuing, policing, shaping) | 4.7 | Explain | 4 |
| 4.8 | Accès distant SSH | 4.8 | Configure | 3 |
| 4.9 | TFTP/FTP dans le réseau | 4.9 | Describe | 2 |
| | **Total Module 4** | | | **~31 pages** |

### Exercices prévus (9)

| Exercice | Topic | Description |
|----------|-------|-------------|
| Ex 4.1a | 4.1 | Configurer du NAT statique pour 3 serveurs internes |
| Ex 4.1b | 4.1 | Configurer PAT et vérifier avec `show ip nat translations` |
| Ex 4.2 | 4.2 | Configurer une hiérarchie NTP (serveur → client → downstream) |
| Ex 4.3 | 4.3 | Schématiser le flux DHCP DORA et la résolution DNS |
| Ex 4.4 | 4.4 | Interpréter des traps SNMP et identifier un problème réseau |
| Ex 4.5 | 4.5 | Associer 8 messages syslog à leur severity level (0-7) |
| Ex 4.6 | 4.6 | Configurer un DHCP relay entre 2 sous-réseaux |
| Ex 4.7 | 4.7 | Classifier du trafic et déterminer le traitement QoS approprié |
| Ex 4.8 | 4.8 | Sécuriser l'accès à un routeur (SSH v2, timeout, ACL vty) |

### Labs prévus (2)

| Lab | Titre | Topics | Durée |
|-----|-------|--------|-------|
| Lab 4.1 | NAT/PAT complet | 4.1 | 45 min |
| Lab 4.2 | DHCP, NTP et Syslog | 4.2, 4.3, 4.5, 4.6 | 60 min |

### Quiz Module 4

- **10 questions** — MCQ format examen
- Couvre tous les topics 4.1 à 4.9
- Durée suggérée : 15 minutes
- Score minimum : 70%

---

## Module 5 — Security Fundamentals

> **Domain 5** | **Poids examen : 15%** | **Durée : 2 semaines** | **Prérequis : Modules 1-4**

### Sections

| # | Section | Topic IDs | Verbe Cisco | Pages estimées |
|---|---------|-----------|-------------|----------------|
| 5.1 | Concepts clés de sécurité (menaces, vulnérabilités, exploits, mitigations) | 5.1 | Define | 4 |
| 5.2 | Programme de sécurité (sensibilisation, formation, contrôle physique) | 5.2 | Describe | 3 |
| 5.3 | Contrôle d'accès par mots de passe locaux | 5.3 | Configure & Verify | 4 |
| 5.4 | Politiques de mots de passe (MFA, certificats, biométrie) | 5.4 | Describe | 3 |
| 5.5 | VPN IPsec (remote access et site-to-site) | 5.5 | Describe | 5 |
| 5.6 | Access Control Lists (standard et extended) | 5.6 | Configure & Verify | 7 |
| 5.7 | Sécurité Layer 2 (DHCP snooping, DAI, port security) | 5.7 | Configure & Verify | 6 |
| 5.8 | AAA — Authentication, Authorization, Accounting | 5.8 | Compare | 3 |
| 5.9 | Protocoles wireless (WPA, WPA2, WPA3) | 5.9 | Describe | 4 |
| 5.10 | Configuration WLAN GUI avec WPA2 PSK | 5.10 | Configure & Verify | 3 |
| 5.11 | Machine Learning pour la sécurité réseau *(NOUVEAU v1.1)* | 5.11 | Describe | 3 |
| | **Total Module 5** | | | **~45 pages** |

### Exercices prévus (11)

| Exercice | Topic | Description |
|----------|-------|-------------|
| Ex 5.1 | 5.1 | Classifier 10 scénarios en menace, vulnérabilité ou exploit |
| Ex 5.2 | 5.2 | Concevoir un programme de sensibilisation sécurité pour une PME |
| Ex 5.3 | 5.3 | Sécuriser un routeur (enable secret, line password, service password-encryption) |
| Ex 5.4 | 5.4 | Comparer 5 méthodes d'authentification (complexité vs sécurité) |
| Ex 5.5 | 5.5 | Schématiser un tunnel IPsec site-to-site et identifier les phases IKE |
| Ex 5.6a | 5.6 | Écrire 5 ACLs standard à partir de spécifications de filtrage |
| Ex 5.6b | 5.6 | Écrire 5 ACLs extended avec wildcard masks |
| Ex 5.7 | 5.7 | Configurer port security + DHCP snooping et simuler une attaque |
| Ex 5.8 | 5.8 | Associer des scénarios à Authentication, Authorization ou Accounting |
| Ex 5.9 | 5.9 | Comparer WPA/WPA2/WPA3 dans un tableau (chiffrement, failles, usage) |
| Ex 5.10 | 5.10 | Créer un WLAN avec WPA2 PSK via captures d'écran WLC |

### Labs prévus (3)

| Lab | Titre | Topics | Durée |
|-----|-------|--------|-------|
| Lab 5.1 | ACL Standard et Extended | 5.6 | 60 min |
| Lab 5.2 | Port Security et DHCP Snooping | 5.7 | 45 min |
| Lab 5.3 | SSH et sécurisation d'accès | 5.3, 4.8 | 45 min |

### Quiz Module 5

- **12 questions** — MCQ format examen
- Couvre tous les topics 5.1 à 5.11
- Durée suggérée : 20 minutes
- Score minimum : 70%

---

## Module 6 — Automation and Programmability

> **Domain 6** | **Poids examen : 10%** | **Durée : 1 semaine** | **Prérequis : Modules 1-5**

### Sections

| # | Section | Topic IDs | Verbe Cisco | Pages estimées |
|---|---------|-----------|-------------|----------------|
| 6.1 | Impact de l'automatisation sur la gestion réseau | 6.1 | Explain | 4 |
| 6.2 | Réseaux traditionnels vs controller-based | 6.2 | Compare | 4 |
| 6.3 | Architecture SDN (overlay, underlay, fabric, plans, APIs) | 6.3.a–b | Describe | 5 |
| 6.4 | Gestion traditionnelle vs Cisco DNA Center | 6.4 | Compare | 4 |
| 6.5 | APIs REST (CRUD, verbes HTTP, encodage) | 6.5 | Describe | 5 |
| 6.6 | Configuration management (Puppet, Chef, Ansible) | 6.6 | Recognize | 3 |
| 6.7 | JSON — composants et structure | 6.7 | Recognize | 3 |
| | **Total Module 6** | | | **~28 pages** |

### Exercices prévus (7)

| Exercice | Topic | Description |
|----------|-------|-------------|
| Ex 6.1 | 6.1 | Identifier les tâches réseau automatisables dans un scénario |
| Ex 6.2 | 6.2 | Comparer la gestion CLI traditionnelle vs SDN sur 5 critères |
| Ex 6.3 | 6.3 | Schématiser une architecture SDN (plans, APIs, overlay/underlay) |
| Ex 6.4 | 6.4 | Lister les avantages de DNA Center vs CLI pour 5 opérations courantes |
| Ex 6.5 | 6.5 | Associer verbes HTTP à opérations CRUD + écrire 3 requêtes REST |
| Ex 6.6 | 6.6 | Comparer Puppet, Chef et Ansible (push/pull, agent, langage) |
| Ex 6.7 | 6.7 | Interpréter et corriger 3 documents JSON contenant des erreurs |

### Labs prévus (2)

| Lab | Titre | Topics | Durée |
|-----|-------|--------|-------|
| Lab 6.1 | REST API et JSON (Postman/curl) | 6.5, 6.7 | 45 min |
| Lab 6.2 | Cisco DNA Center — exploration GUI (DevNet Sandbox) | 6.4 | 45 min |

### Quiz Module 6

- **10 questions** — MCQ format examen
- Couvre tous les topics 6.1 à 6.7
- Durée suggérée : 15 minutes
- Score minimum : 70%

---

## Récapitulatif global

| Module | Domain | Poids | Pages | Sections | Exercices | Labs | Quiz |
|--------|--------|-------|-------|----------|-----------|------|------|
| 1 | Network Fundamentals | 20% | ~55 | 14 | 14 | 2 | 15 Q |
| 2 | Network Access | 20% | ~40 | 9 | 9 | 3 | 12 Q |
| 3 | IP Connectivity | 25% | ~35 | 6 | 8 | 4 | 15 Q |
| 4 | IP Services | 10% | ~31 | 9 | 9 | 2 | 10 Q |
| 5 | Security Fundamentals | 15% | ~45 | 11 | 11 | 3 | 12 Q |
| 6 | Automation & Programmability | 10% | ~28 | 7 | 7 | 2 | 10 Q |
| **Total** | | **100%** | **~234** | **56** | **58** | **16** | **74 Q** |

> Les annexes ajoutent ~80 pages supplémentaires (voir ci-dessous).

---

## Planning semaine par semaine

### Semaine 1 — Module 1, partie 1

| Jour | Contenu | Durée |
|------|---------|-------|
| L-M | Sections 1.1 à 1.4 : Composants, topologies, câblage, diagnostic | 4h |
| M-J | Section 1.5 : TCP vs UDP | 2h |
| V | Section 1.6 : Adressage IPv4 et subnetting (partie théorie + méthode) | 3h |
| S | Section 1.6 : Subnetting — exercices pratiques | 3h |
| **Livrable** | Exercices 1.1 à 1.6a complétés | |

### Semaine 2 — Module 1, partie 2

| Jour | Contenu | Durée |
|------|---------|-------|
| L-M | Sections 1.7 à 1.9 : IPv4 privé, IPv6, types d'adresses IPv6 | 4h |
| M | Section 1.10 : Vérification IP sur OS clients | 2h |
| J | Sections 1.11 à 1.14 : Wireless, virtualisation, switching, GenAI | 4h |
| V | **Lab 1.1** : Câblage et interfaces | 1h |
| S | **Lab 1.2** : Adressage IPv4/IPv6 + **Quiz Module 1** | 2h |
| **Livrable** | Module 1 complet — Quiz >= 70% | |

### Semaine 3 — Module 2, partie 1

| Jour | Contenu | Durée |
|------|---------|-------|
| L-M | Sections 2.1 à 2.2 : VLANs, trunks, 802.1Q, inter-VLAN | 5h |
| M-J | Sections 2.3 à 2.4 : CDP/LLDP, EtherChannel LACP | 4h |
| V | Section 2.5 : Rapid PVST+ Spanning Tree | 3h |
| S | **Lab 2.1** : VLANs et Trunks | 1h |
| **Livrable** | Exercices 2.1a à 2.5 complétés | |

### Semaine 4 — Module 2, partie 2

| Jour | Contenu | Durée |
|------|---------|-------|
| L-M | Sections 2.6 à 2.9 : Wireless (architectures, GUI WLC, accès admin) | 5h |
| M | **Lab 2.2** : EtherChannel LACP | 1h |
| J | **Lab 2.3** : Spanning Tree | 1h |
| V | Exercices 2.6 à 2.9 + révision | 3h |
| S | **Quiz Module 2** + remédiation | 2h |
| **Livrable** | Module 2 complet — Quiz >= 70% | |

### Semaine 5 — Module 3, partie 1

| Jour | Contenu | Durée |
|------|---------|-------|
| L | Section 3.1 : Table de routage — composants et interprétation | 3h |
| M | Section 3.2 : Décision de forwarding (longest prefix, AD, métrique) | 3h |
| M-J | Section 3.3 : Routage statique IPv4/IPv6 (default, network, host, floating) | 4h |
| V | **Lab 3.1** : Routes statiques | 1h |
| S | Exercices 3.1 à 3.3 — drill longest prefix match | 3h |
| **Livrable** | Sections 3.1-3.3 + Lab 3.1 complétés | |

### Semaine 6 — Module 3, partie 2 (OSPF)

| Jour | Contenu | Durée |
|------|---------|-------|
| L-M | Section 3.4 : OSPF — théorie (Hello, DBD, LSR/LSU/LSAck, états) | 4h |
| M | Section 3.4 : OSPF — configuration + DR/BDR | 3h |
| J | **Lab 3.2** : OSPF de base + **Lab 3.3** : DR/BDR | 2h |
| V | Section 3.5 + 3.6 : FHRP et Cloud Management | 3h |
| S | **Lab 3.4** : Inter-VLAN + OSPF combiné + **Quiz Module 3** | 2.5h |
| **Livrable** | Module 3 complet — Quiz >= 70% | |

### Semaine 7 — Module 4 (complet)

| Jour | Contenu | Durée |
|------|---------|-------|
| L | Section 4.1 : NAT/PAT | 3h |
| M | Sections 4.2 à 4.3 : NTP + DHCP/DNS | 3h |
| M | Sections 4.4 à 4.5 : SNMP + Syslog | 2h |
| J | Sections 4.6 à 4.9 : DHCP relay, QoS, SSH, TFTP/FTP | 4h |
| V | **Lab 4.1** : NAT/PAT + **Lab 4.2** : DHCP/NTP/Syslog | 2h |
| S | Exercices complets + **Quiz Module 4** | 2h |
| **Livrable** | Module 4 complet — Quiz >= 70% | |

### Semaine 8 — Module 5, partie 1

| Jour | Contenu | Durée |
|------|---------|-------|
| L | Sections 5.1 à 5.2 : Concepts sécurité, programme de sécurité | 3h |
| M | Sections 5.3 à 5.4 : Mots de passe, politiques, MFA | 3h |
| M | Section 5.5 : VPN IPsec | 3h |
| J-V | Section 5.6 : ACLs standard et extended (avec wildcard masks) | 4h |
| S | **Lab 5.1** : ACLs + exercices 5.1 à 5.6 | 2h |
| **Livrable** | Sections 5.1-5.6 + Lab 5.1 complétés | |

### Semaine 9 — Module 5, partie 2 + Module 6

| Jour | Contenu | Durée |
|------|---------|-------|
| L | Section 5.7 : Sécurité L2 (port security, DHCP snooping, DAI) | 3h |
| M | Sections 5.8 à 5.11 : AAA, wireless security, WLC, ML | 4h |
| M | **Lab 5.2** + **Lab 5.3** + **Quiz Module 5** | 2.5h |
| J | Module 6 — Sections 6.1 à 6.4 : Automation, SDN, DNA Center | 4h |
| V | Module 6 — Sections 6.5 à 6.7 : REST APIs, config management, JSON | 3h |
| S | **Lab 6.1** + **Lab 6.2** + **Quiz Module 6** | 2h |
| **Livrable** | Modules 5 et 6 complets — Quiz >= 70% | |

### Semaine 10 — Révisions et examen blanc

| Jour | Contenu | Durée |
|------|---------|-------|
| L | Subnetting Drill : 50 exercices progressifs (Annexe A) | 3h |
| M | Révision OSPF + ACLs (topics les plus testés) | 3h |
| M | Révision wireless + NAT + DHCP | 3h |
| J | **Examen blanc n.1** (120 questions, 120 min) + correction détaillée | 4h |
| V | Remédiation ciblée sur les domaines faibles | 3h |
| S | **Examen blanc n.2** (120 questions, 120 min) + score final | 4h |
| **Objectif** | Score >= 80% à l'examen blanc n.2 | |

---

## Annexes prévues

### Annexe A — Subnetting Drill (SUBNETTING-DRILL.md)

- **50 exercices progressifs** répartis en 5 niveaux :
  - Niveau 1 (10 ex.) : Calculs de base — masque, réseau, broadcast, plage d'hôtes
  - Niveau 2 (10 ex.) : Découpage en sous-réseaux (nombre de sous-réseaux demandé)
  - Niveau 3 (10 ex.) : VLSM — allocation optimale pour plusieurs réseaux
  - Niveau 4 (10 ex.) : Subnetting IPv6 — préfixes /48, /64, /128
  - Niveau 5 (10 ex.) : Scénarios mixtes (subnetting + routage + ACL wildcard)
- Chaque exercice avec solution détaillée pas-à-pas
- **Pages estimées : ~30**

### Annexe B — Examens blancs (EXAM-PRACTICE.md)

- **2 examens blancs de 120 questions** chacun
- Format identique à l'examen réel :
  - MCQ (4 options, 1 ou 2 bonnes réponses)
  - Répartition par domain respectant les poids officiels
  - Durée : 120 minutes par examen
- Explication détaillée de chaque réponse (correcte ET incorrectes)
- Grille de score avec diagnostic par domain
- **Pages estimées : ~40**

### Annexe C — Glossaire (GLOSSARY.md)

- **~150 termes** classés alphabétiquement
- Format : terme → définition concise → topic ID de référence → commande CLI associée (si applicable)
- Inclut les acronymes Cisco (AD, BDR, BPDU, CAPWAP, DHCP, DR, FHRP, LACP, LLDP, LSA, OSPF, PAT, PVST, STP, VRF, WLC...)
- **Pages estimées : ~10**

### Annexe D — Aide-mémoire commandes (CHEAT-SHEET.md)

- Commandes essentielles organisées par thème :
  - Configuration de base (hostname, passwords, SSH)
  - VLANs et Trunks
  - Routage statique et OSPF
  - NAT/DHCP/NTP
  - ACLs
  - Sécurité L2
  - Commandes `show` et vérification
- Format : commande → syntaxe → description courte → mode requis
- **Pages estimées : ~8**

---

## Conventions du guide

### Encadrés

| Encadré | Usage |
|---------|-------|
| **Point exam** | Piège fréquent ou subtilité à connaître pour l'examen |
| **Analogie** | Comparaison avec le monde réel pour clarifier un concept |
| **CLI** | Bloc de commandes avec output attendu |
| **Attention** | Erreur courante de configuration à éviter |
| **Cross-ref** | Lien vers un topic connexe dans un autre module |

### Nommage des fichiers

```
modules/
  module-1-network-fundamentals.md
  module-2-network-access.md
  module-3-ip-connectivity.md
  module-4-ip-services.md
  module-5-security-fundamentals.md
  module-6-automation-programmability.md
labs/
  lab-1.1-cablage-interfaces.md
  lab-1.2-adressage-ipv4-ipv6.md
  lab-2.1-vlans-trunks.md
  ...
quizzes/
  quiz-module-1.md
  quiz-module-2.md
  ...
annexes/
  subnetting-drill.md
  exam-practice.md
  glossary.md
  cheat-sheet.md
```

---

## Métriques de couverture

| Critère pédagogique | Objectif | Prévu |
|---------------------|----------|-------|
| Topics couverts | 56/56 | 56/56 (100%) |
| Commandes CLI avec output | >= 1 par section | 56 minimum |
| Points exam | >= 1 par section | 56 minimum |
| Exercices | >= 1 par topic ID | 58 |
| Labs Packet Tracer | >= 2 par module (4 pour M3) | 16 total |
| Quiz | 10-15 Q par module | 74 Q total |
| Analogies | >= 1 par concept abstrait | A valider par module |
| Ratio théorie/pratique | 60/40 | Contrôlé section par section |
| Sujets v1.1 (GenAI, Cloud, ML) | 3 topics | Topics 1.14, 3.6, 5.11 |
