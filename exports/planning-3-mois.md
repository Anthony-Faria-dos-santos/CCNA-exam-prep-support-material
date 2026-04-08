# Planning - Maitrise CCNA en 3 mois

> **Objectif** : Reussir le CCNA 200-301 v1.1 en 12 semaines
> **Charge quotidienne** : 2h30 en semaine + 4-5h le weekend = ~20h/semaine
> **Total estime** : ~240h (incluant revision et exam blanc)
> **Prerequis** : Bases IT, Packet Tracer installe, Anki installe

---

## Vue d'ensemble des 3 mois

| Mois | Semaines | Modules | Focus | Heures |
|------|----------|---------|-------|--------|
| **Mois 1** | S1-S4 | Modules 1-2 | Fondations : reseau, IPv4/IPv6, VLANs, STP | ~80h |
| **Mois 2** | S5-S8 | Modules 3-4 | Coeur technique : routage, OSPF, services IP | ~80h |
| **Mois 3** | S9-S12 | Modules 5-6 + Revision | Securite, automation, exam blanc, revision | ~80h |

---

## MOIS 1 - FONDATIONS (Semaines 1-4)

### Semaine 1 - Network Fundamentals partie 1

**Objectif** : Comprendre les composants reseau, topologies, cablage, TCP/UDP

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topics 1.1-1.2 : Composants reseau, architectures | Jeremy IT Lab Jour 1-2 + Guide Module 1 |
| Mar | 2h30 | Topics 1.3-1.4 : Cablage, interfaces, diagnostic | Jeremy IT Lab Jour 3-4 + Guide |
| Mer | 2h30 | Topic 1.5 : TCP vs UDP + Ports cles | Jeremy IT Lab Jour 5 + Guide |
| Jeu | 2h30 | LAB-1-1 : Cablage et interfaces (Packet Tracer) | Guide LAB-1-1 |
| Ven | 2h30 | TryHackMe : What is Networking + Network Fundamentals | TryHackMe |
| Sam | 4h | Topic 1.6 : IPv4 et subnetting (theorie + exercices) | Jeremy IT Lab Jour 7 + Practical Networking Subnetting Mastery |
| Dim | 4h | Subnetting pratique intensive + revision semaine | SubnettingPractice.com + Anki |

**Rituels quotidiens** (inclus dans les 2h30) :
- 15 min Anki flashcards
- 5 exercices subnetting (des que Topic 1.6 commence)

**Checkpoint** : Capable de calculer un sous-reseau /24 a /28 en moins de 2 minutes

---

### Semaine 2 - Network Fundamentals partie 2

**Objectif** : Maitriser IPv6, wireless, virtualisation, switching concepts

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topics 1.7-1.8 : RFC 1918, IPv6 bases | Jeremy IT Lab Jour 7-9 + Guide |
| Mar | 2h30 | Topics 1.9-1.10 : Types IPv6, verification IP OS | Jeremy IT Lab Jour 10 + Guide |
| Mer | 2h30 | LAB-1-2 : Adressage IPv4/IPv6 dual-stack | Guide LAB-1-2 |
| Jeu | 2h30 | Topics 1.11-1.12 : Wi-Fi, virtualisation | Jeremy IT Lab Jour 55, 53 + Guide |
| Ven | 2h30 | Topics 1.13-1.14 : Switching concepts, IA reseau | Jeremy IT Lab Jour 6 + Guide |
| Sam | 4h | Quiz Module 1 (guide) + revision des erreurs | Guide Quiz M1 + IPCisco Domain 1 quiz |
| Dim | 4h | Subnetting drill niveaux 1-2 (exercices 1-25) + Anki | Guide SUBNETTING-DRILL + SubnettingPractice.com |

**Checkpoint** : Score 70% ou plus au quiz Module 1, subnetting moins de 90s/exercice

---

### Semaine 3 - Network Access partie 1

**Objectif** : Maitriser VLANs, trunks 802.1Q, CDP/LLDP, EtherChannel

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topics 2.1-2.2 : VLANs, trunks 802.1Q | Jeremy IT Lab Jour 16-17 + Guide Module 2 |
| Mar | 2h30 | Topic 2.3 : CDP et LLDP | Jeremy IT Lab Jour 18 + Guide |
| Mer | 2h30 | LAB-2-1 : VLANs, Trunks et Router-on-a-Stick | Guide LAB-2-1 (60 min lab + revision) |
| Jeu | 2h30 | Topic 2.4 : EtherChannel LACP | Jeremy IT Lab Jour 22 + Guide |
| Ven | 2h30 | LAB-2-2 : EtherChannel LACP | Guide LAB-2-2 + labs PacketTracerNetwork |
| Sam | 4h | Topic 2.5 : Spanning Tree RSTP (theorie approfondie) | Jeremy IT Lab Jour 20-21 + Guide |
| Dim | 4h | LAB-2-3 : Spanning Tree + TryHackMe Intro to LAN | Guide LAB-2-3 + TryHackMe |

**Rituels quotidiens** :
- 15 min Anki (ajouter les cartes Module 2)
- 5 exercices subnetting

**Checkpoint** : Configurer VLANs + trunk + router-on-a-stick de memoire

---

### Semaine 4 - Network Access partie 2 + Consolidation Mois 1

**Objectif** : Wireless, management access, consolidation des modules 1-2

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topics 2.6-2.7 : Architectures wireless, WLAN | Jeremy IT Lab Jour 55-56 + Guide |
| Mar | 2h30 | Topics 2.8-2.9 : Management access, WLC GUI | Jeremy IT Lab + Guide |
| Mer | 2h30 | Quiz Module 2 + revision erreurs | Guide Quiz M2 + Crucial Exams Domain 2 |
| Jeu | 2h30 | Refaire LAB-2-1 de memoire (sans guide) | Packet Tracer |
| Ven | 2h30 | Subnetting drill niveaux 2-3 (exercices 11-40) | Guide SUBNETTING-DRILL |
| Sam | 4h | Revision complete Modules 1-2 | Anki + relecture notes + quiz IPCisco |
| Dim | 4h | OverTheWire Bandit niveaux 1-10 + pratique CLI | OverTheWire |

**Checkpoint Mois 1** :
- Quiz Domain 1 (IPCisco) : 70% ou plus
- Quiz Domain 2 (IPCisco) : 70% ou plus
- Subnetting /24-/28 : moins de 90 secondes
- Configurer VLANs+Trunk+ROAS de memoire : OK
- 150+ cartes Anki maitrisees

---

## MOIS 2 - COEUR TECHNIQUE (Semaines 5-8)

### Semaine 5 - IP Connectivity : Routage et OSPF partie 1

**Objectif** : Table de routage, routes statiques, debut OSPF

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topics 3.1-3.2 : Table de routage, decisions forwarding | Jeremy IT Lab Jour 11-12 + Guide Module 3 |
| Mar | 2h30 | Topic 3.3 : Routes statiques IPv4/IPv6 | Jeremy IT Lab Jour 13-14 + Guide |
| Mer | 2h30 | LAB-3-1 : Routes statiques multi-routeurs | Guide LAB-3-1 |
| Jeu | 2h30 | Topic 3.4 partie 1 : OSPF concepts, adjacences | Jeremy IT Lab Jour 26-27 + Guide |
| Ven | 2h30 | Topic 3.4 partie 2 : OSPF DR/BDR, cout, config | Jeremy IT Lab Jour 28-29 + Guide |
| Sam | 5h | **QUIZ TRANSVERSAL 1** (guide) + analyse des erreurs | Guide QUIZ-TRANSVERSAL-1 (40 min) + revision ciblee |
| Dim | 4h | LAB-3-2 : OSPF basique + LAB-3-3 : OSPF DR/BDR | Guide LAB-3-2 + LAB-3-3 |

**Checkpoint** : Score 70% ou plus au Quiz Transversal 1

---

### Semaine 6 - IP Connectivity : OSPF avance + FHRP + Cloud

**Objectif** : Maitriser OSPF, FHRP, gestion cloud, integration VLAN+OSPF

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Revision OSPF : troubleshooting adjacences | Guide + quiz OSPF supplementaires |
| Mar | 2h30 | Topic 3.5 : FHRP (HSRP/VRRP/GLBP) | Jeremy IT Lab Jour 30 + Guide |
| Mer | 2h30 | Topic 3.6 : Gestion reseau cloud (NOUVEAU v1.1) | Jeremy IT Lab + Guide |
| Jeu | 2h30 | LAB-3-4 : Inter-VLAN + OSPF multi-site (lab integration) | Guide LAB-3-4 (60 min) |
| Ven | 2h30 | Subnetting drill niveaux 3-4 (exercices 26-50) | Guide SUBNETTING-DRILL |
| Sam | 4h | Quiz Module 3 + Crucial Exams Domain 3 | Guide + Crucial Exams |
| Dim | 4h | Wireshark : capturer Hello OSPF + DHCP + refaire labs OSPF | Wireshark + Packet Tracer |

**Checkpoint** : Subnetting moins de 60s/exercice, OSPF config de memoire

---

### Semaine 7 - IP Services

**Objectif** : NAT/PAT, NTP, DHCP/DNS, SNMP, Syslog, QoS, SSH, TFTP/FTP

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topic 4.1 : NAT statique, dynamique, PAT | Jeremy IT Lab Jour 36-37 + Guide Module 4 |
| Mar | 2h30 | LAB-4-1 : NAT/PAT complet | Guide LAB-4-1 |
| Mer | 2h30 | Topics 4.2-4.3 : NTP, DHCP, DNS | Jeremy IT Lab Jour 38 + Guide |
| Jeu | 2h30 | Topics 4.4-4.5 : SNMP, Syslog (niveaux severite!) | Jeremy IT Lab Jour 40 + Guide |
| Ven | 2h30 | Topics 4.6-4.7 : DHCP relay, QoS concepts | Jeremy IT Lab + Guide |
| Sam | 4h | Topics 4.8-4.9 : SSH, TFTP/FTP + LAB-4-2 | Guide LAB-4-2 + labs supplementaires |
| Dim | 4h | Quiz Module 4 + TryHackMe Network Services 1 et 2 | Guide Quiz + TryHackMe |

**Checkpoint** : Configurer NAT/PAT + DHCP relay + SSH de memoire

---

### Semaine 8 - Consolidation Mois 2

**Objectif** : Valider les modules 1-4, preparer la transition vers securite

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Revision Module 3 (OSPF focus) : refaire LAB-3-2 de memoire | Packet Tracer |
| Mar | 2h30 | Revision Module 4 : refaire LAB-4-1 de memoire | Packet Tracer |
| Mer | 2h30 | Subnetting speed run : 50 exercices chronometres | SubnettingPractice.com |
| Jeu | 2h30 | ExamTopics : 50 questions Domains 1-4 | ExamTopics |
| Ven | 2h30 | Revision Anki intensive (toutes les cartes) | Anki |
| Sam | 5h | **QUIZ TRANSVERSAL 2** (guide) + analyse erreurs | Guide QUIZ-TRANSVERSAL-2 (45 min) + revision ciblee |
| Dim | 4h | OverTheWire Bandit niveaux 11-20 | OverTheWire |

**Checkpoint Mois 2** :
- Quiz Transversal 2 : 70% ou plus
- Subnetting : moins de 60 secondes/exercice
- OSPF config + troubleshooting : maitrise
- NAT/PAT + DHCP relay : config de memoire
- 300+ cartes Anki maitrisees

---

## MOIS 3 - SECURITE, AUTOMATION ET EXAM (Semaines 9-12)

### Semaine 9 - Security Fundamentals

**Objectif** : Concepts securite, mots de passe, VPN, ACLs, securite L2

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topics 5.1-5.3 : Concepts securite, controle acces | Jeremy IT Lab Jour 43 + Guide Module 5 |
| Mar | 2h30 | Topics 5.4-5.5 : MFA, VPN IPsec | Jeremy IT Lab Jour 53 + Guide |
| Mer | 2h30 | Topic 5.6 : ACLs standard et extended | Jeremy IT Lab Jour 44-45 + Guide |
| Jeu | 2h30 | LAB-5-1 : ACLs + LAB-5-3 : SSH securisation | Guide LAB-5-1 + LAB-5-3 |
| Ven | 2h30 | Topic 5.7 : Port Security, DHCP Snooping, DAI | Jeremy IT Lab Jour 49 + Guide |
| Sam | 4h | LAB-5-2 : Port Security/DHCP Snooping + Topics 5.8-5.9 : AAA, WiFi security | Guide LAB-5-2 + Guide Module 5 |
| Dim | 4h | Topics 5.10-5.11 : WLC config, ML securite (v1.1) + TryHackMe Wireshark 101 | Guide + TryHackMe |

**Checkpoint** : ACLs (standard + extended) de memoire, Port Security de memoire

---

### Semaine 10 - Automation et Programmability + Debut revision

**Objectif** : SDN, DNA Center, REST API, JSON, Ansible + debut revision globale

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Topics 6.1-6.3 : Automation, SDN, controller-based | Jeremy IT Lab Jour 51-52 + Guide Module 6 |
| Mar | 2h30 | Topic 6.4 : DNA Center + LAB-6-2 (DevNet Sandbox) | Guide LAB-6-2 + sandboxdnac.cisco.com |
| Mer | 2h30 | Topics 6.5-6.7 : REST API, Ansible, JSON | Jeremy IT Lab Jour 58-60 + Guide |
| Jeu | 2h30 | LAB-6-1 : REST API et JSON (Postman) | Guide LAB-6-1 |
| Ven | 2h30 | Quiz Modules 5+6 + Crucial Exams Domains 5+6 | Guide + Crucial Exams |
| Sam | 4h | Revision globale : Anki full deck + ExamTopics 50 questions | Anki + ExamTopics |
| Dim | 4h | PicoCTF challenges networking + revision notes | PicoCTF |

**Checkpoint** : Tous les 6 modules couverts, REST API/JSON compris

---

### Semaine 11 - EXAM BLANC + Revision ciblee

**Objectif** : Passer exam blanc, identifier et combler les lacunes

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | Revision pre-exam : topics les moins maitrises (Anki stats) | Anki + Guide |
| Mar | 2h30 | Revision OSPF + Subnetting speed (les 2 plus testes) | Labs OSPF + SubnettingPractice |
| Mer | 3h | **EXAM BLANC** (102 questions, 120 min) | Guide EXAM-BLANC |
| Jeu | 2h30 | Analyse detaillee des erreurs exam blanc par domaine | Guide corrections |
| Ven | 2h30 | Revision ciblee domaine le plus faible | Jeremy IT Lab videos ciblees |
| Sam | 5h | Refaire les labs des domaines faibles | Packet Tracer |
| Dim | 4h | ExamTopics : 100 questions full review | ExamTopics |

**Checkpoint** : Score exam blanc 80% ou plus. Si moins de 80%, reporter examen de 1 semaine.

---

### Semaine 12 - Revision finale et examen

**Objectif** : Atteindre 85%+ en practice exam, passer examen reel

| Jour | Duree | Activite | Ressource |
|------|-------|----------|-----------|
| Lun | 2h30 | 2eme passage exam blanc (ou Crucial Exams full) | Guide ou Crucial Exams |
| Mar | 2h30 | Revision des erreurs + Anki full review | Anki + notes |
| Mer | 2h30 | Subnetting speed final (50 exercices moins de 60s chaque) | SubnettingPractice |
| Jeu | 2h30 | Revision legere : relire les cheat sheets + Points exam | Guide cheat sheets |
| Ven | 2h | Revision tres legere : Anki seulement + repos mental | Anki |
| **Sam** | **3h** | **EXAMEN CCNA 200-301** | Centre Pearson VUE |
| Dim | - | Celebration ! | - |

---

## Charge de travail realiste

### En semaine (Lun-Ven)

| Plage | Activite | Duree |
|-------|----------|-------|
| Matin/Midi | Anki flashcards | 15 min |
| Soir session 1 | Video + theorie | 45-60 min |
| Soir session 2 | Lab / exercices / quiz | 45-60 min |
| Avant dormir | 5 exercices subnetting | 10 min |
| **Total** | | **~2h30** |

### Weekend (Sam-Dim)

| Plage | Activite | Duree |
|-------|----------|-------|
| Matin | Labs pratiques intensifs | 2h |
| Apres-midi | Quiz + revision + wargames | 2h |
| **Total par jour** | | **~4h** |

### Total hebdomadaire

- Semaine : 5 x 2h30 = **12h30**
- Weekend : 2 x 4h = **8h**
- **Total : ~20h/semaine**
- **Total 12 semaines : ~240h**

---

## Adaptations selon votre situation

### Si vous avez plus de temps (etudiant a plein temps)

- Passez a 4h/jour en semaine + 6h/jour le weekend (~32h/semaine)
- Visez 8-10 semaines au lieu de 12
- Ajoutez des labs supplementaires et des wargames

### Si vous avez moins de temps (salarie)

- Reduisez a 1h30/jour en semaine + 3h/jour le weekend (~12h/semaine)
- Etendez a 16-18 semaines
- Priorisez : videos + labs > quiz > wargames

### Si vous bloquez sur un module

- Ne restez pas bloque plus de 2 jours sur un concept
- Regardez une 2eme source (David Bombal, NetworkChuck, PowerCert)
- Posez la question sur r/ccna ou Discord Cisco Study Group
- Continuez et revenez-y apres 1-2 jours de repos

---

## Jalons et decisions

| Jalon | Semaine | Condition de passage |
|-------|---------|---------------------|
| Fin Module 1 | S2 | Quiz M1 70% ou plus |
| Fin Module 2 | S4 | Quiz M2 70% ou plus + VLANs config de memoire |
| Quiz Transversal 1 | S5 | 70% ou plus (18/25) |
| Subnetting speed | S6 | moins de 60 secondes/exercice |
| Fin Modules 3-4 | S7 | Quiz M3+M4 70% ou plus + OSPF de memoire |
| Quiz Transversal 2 | S8 | 70% ou plus (18/25) |
| Fin Modules 5-6 | S10 | Quiz M5+M6 70% ou plus |
| Exam blanc | S11 | 80% ou plus = planifier examen |
| 2eme exam blanc | S12 | 85% ou plus = passer examen |

**Regle absolue** : Ne planifiez votre examen que quand vous scorez 85%+ de facon repetee. Mieux vaut attendre 1-2 semaines de plus que de rater (330 USD).

---

## Inscription a examen

- **Site** : https://home.pearsonvue.com/cisco
- **Examen** : 200-301 CCNA
- **Prix** : ~330 USD
- **Duree** : 120 minutes
- **Questions** : 100-120
- **Score requis** : ~825/1000
- **Validite** : 3 ans
- **Format** : Centre Pearson VUE ou en ligne (OnVUE)

Planifiez examen au moins 2 semaines a avance pour choisir votre creneau ideal. Preferez un creneau le matin quand votre concentration est maximale.
