# CCNA 200-301 v1.1 — Résumé du Guide Complet

> **Date de génération** : 2026-04-04
> **Alignement** : Cisco CCNA 200-301 v1.1 (incluant topics GenAI, Cloud, ML)
> **Couverture exam topics** : 53/53 (100%)

---

## Statistiques globales

| Métrique | Valeur |
|----------|--------|
| **Mots total** | 206 016 |
| **Lignes** | 33 812 |
| **Pages estimées** | ~588 (350 mots/page) |
| **Modules** | 6 |
| **Labs pratiques** | 16 |
| **Exercices dans les modules** | 64 |
| **Points exam** | 56 |
| **Questions quiz (transversaux)** | 50 |
| **Questions exam blanc** | 102 |
| **Exercices subnetting** | 50 |
| **Termes au glossaire** | 220 |
| **Blocs CLI (code/output)** | 1 219 |

---

## Détail par module

| Module | Titre | Mots | Exercices | Points exam | Domain (poids) |
|--------|-------|------|-----------|-------------|----------------|
| 1 | Network Fundamentals | 18 631 | 15 | 14 | Domain 1 (20%) |
| 2 | Network Access | 14 186 | 9 | 9 | Domain 2 (20%) |
| 3 | IP Connectivity | 16 724 | 11 | 6 | Domain 3 (25%) |
| 4 | IP Services | 14 823 | 9 | 9 | Domain 4 (10%) |
| 5 | Security Fundamentals | 17 706 | 13 | 11 | Domain 5 (15%) |
| 6 | Automation & Programmability | 12 527 | 7 | 7 | Domain 6 (10%) |

---

## Labs pratiques (16)

| Lab | Titre | Mots | Module | Topics couverts |
|-----|-------|------|--------|-----------------|
| LAB-1-1 | Câblage et interfaces | 2 747 | 1 | 1.3, 1.4, 1.6, 1.10 |
| LAB-1-2 | Adressage IPv4/IPv6 | 4 592 | 1 | 1.6–1.9 |
| LAB-2-1 | VLANs et Trunks | 3 942 | 2 | 2.1–2.3 |
| LAB-2-2 | EtherChannel LACP | 2 803 | 2 | 2.4 |
| LAB-2-3 | Spanning Tree RSTP | 4 802 | 2 | 2.5 |
| LAB-3-1 | Routes statiques | 3 303 | 3 | 3.1–3.3 |
| LAB-3-2 | OSPF base | 3 459 | 3 | 3.4 |
| LAB-3-3 | OSPF DR/BDR | 3 558 | 3 | 3.4 |
| LAB-3-4 | Inter-VLAN + OSPF combiné | 4 350 | 3 | 2.1–2.2, 3.2, 3.4 |
| LAB-4-1 | NAT/PAT | 3 318 | 4 | 4.1 |
| LAB-4-2 | DHCP, NTP, Syslog | 4 668 | 4 | 4.2–4.6 |
| LAB-5-1 | ACL Standard/Extended | 3 995 | 5 | 5.6 |
| LAB-5-2 | Port Security, DHCP Snooping | 4 242 | 5 | 5.7 |
| LAB-5-3 | SSH et sécurisation | 3 700 | 5 | 5.3, 4.8 |
| LAB-6-1 | REST API et JSON | 3 840 | 6 | 6.5, 6.7 |
| LAB-6-2 | DNA Center exploration | 3 784 | 6 | 6.4 |

**Total labs** : 61 103 mots

---

## Évaluations

| Ressource | Questions/Exercices | Mots |
|-----------|---------------------|------|
| Quiz Transversal 1 (mi-parcours) | 25 questions | 5 217 |
| Quiz Transversal 2 (fin parcours) | 25 questions | 7 060 |
| Exam Blanc complet | 102 questions | 19 428 |
| Subnetting Drill | 50 exercices progressifs | 13 425 |

**Total évaluations** : 202 questions/exercices — 45 130 mots

---

## Sommaire du guide assemblé

1. **Module 1** — Network Fundamentals (Domain 1, 20%)
   - Composants réseau, topologies, câblage, TCP/UDP
   - Adressage IPv4/IPv6, subnetting, wireless, virtualisation
   - Switching L2, outils GenAI (topic 1.14 — nouveau v1.1)

2. **Module 2** — Network Access (Domain 2, 20%)
   - VLANs, trunks 802.1Q, CDP/LLDP
   - EtherChannel LACP, Rapid PVST+ STP
   - Architectures wireless, WLC, accès management

3. **Module 3** — IP Connectivity (Domain 3, 25%)
   - Table de routage, forwarding (longest prefix match)
   - Routes statiques IPv4/IPv6 (default, floating)
   - OSPFv2 single-area (adjacences, DR/BDR, router-id)
   - FHRP, gestion réseau cloud (topic 3.6 — nouveau v1.1)

4. **Module 4** — IP Services (Domain 4, 10%)
   - NAT/PAT, NTP, DHCP/DNS, SNMP, Syslog
   - QoS (PHB), SSH, TFTP/FTP

5. **Module 5** — Security Fundamentals (Domain 5, 15%)
   - Concepts sécurité, AAA, mots de passe, VPN IPsec
   - ACLs, sécurité L2 (DHCP snooping, DAI, port security)
   - Wireless security (WPA2/WPA3)
   - ML pour la sécurité réseau (topic 5.11 — nouveau v1.1)

6. **Module 6** — Automation & Programmability (Domain 6, 10%)
   - SDN, controller-based networking, DNA Center
   - REST API, CRUD, JSON
   - Puppet, Chef, Ansible

7. **Annexe A** — Labs Complémentaires (16 labs Packet Tracer)
8. **Annexe B** — Évaluations Transversales (quizzes + exam blanc + subnetting drill)
9. **Glossaire** — 220 termes avec références croisées

---

## Fichier de sortie

- **Guide complet** : `exports/CCNA-GUIDE-COMPLET.md`
- **Ce résumé** : `exports/RESUME-GUIDE.md`
