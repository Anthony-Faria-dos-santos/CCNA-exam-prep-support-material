# Règles Pédagogiques — Guide CCNA

## Taxonomie de Bloom adaptée aux verbes Cisco

| Verbe exam | Niveau Bloom | Traitement dans le guide |
|------------|-------------|-------------------------|
| Identify | 1 — Connaître | Définition + liste + schéma |
| Describe | 2 — Comprendre | Explication + analogie + tableau |
| Explain | 2 — Comprendre | Paragraphe détaillé + exemple réseau réel |
| Compare | 3 — Analyser | Tableau comparatif + cas d'usage |
| Configure | 3 — Appliquer | Commandes CLI + topologie + lab pas-à-pas |
| Verify | 3 — Appliquer | Commandes show + output attendu + interprétation |
| Interpret | 4 — Analyser | Output réel + questions "que signifie..." |
| Determine | 5 — Évaluer | Scénario + arbre de décision |
| Troubleshoot | 5 — Évaluer | Symptôme → diagnostic → commandes → fix |

## Structure cognitive par section

Chaque section suit cette progression :

1. **Accroche** (2-3 lignes) — Pourquoi ce sujet compte en entreprise
2. **Concept** — Théorie avec analogies du monde réel
3. **Détail technique** — Fonctionnement précis, formats, algorithmes
4. **Mise en pratique** — Commandes CLI avec output complet
5. **Point exam** — Pièges et subtilités de l'examen
6. **Exercice** — Application immédiate
7. **Cross-reference** — Liens vers topics connexes

## Densité de contenu

| Élément | Fréquence minimum |
|---------|-------------------|
| Commande CLI avec output | 1 par section |
| Tableau/schéma | 1 par sous-section majeure (>2 pages) |
| Exercice | 1 par topic ID |
| Lab Packet Tracer | 2 par module (4 pour module 3) |
| Point exam | 1 par section |
| Analogie monde réel | 1 par concept abstrait |
| Quiz | 10-15 questions par module |

## Format des exercices

### Exercice standard
- Contexte réseau réaliste (entreprise fictive)
- Consigne claire avec objectif mesurable
- Indice optionnel (spoiler caché)
- Solution complète avec explications

### Lab Packet Tracer
- Topologie décrite (composants + connexions + adressage)
- Configuration initiale fournie
- Étapes numérotées avec commandes exactes
- Commandes de vérification
- Questions de compréhension post-lab

### Quiz
- Format examen (MCQ 4 options, une ou deux bonnes réponses)
- Topic ID référencé par question
- Explication détaillée de la bonne réponse ET des mauvaises

## Subnetting — Traitement spécial

Le subnetting traverse les domains 1, 3 et 5. Traitement :
- Module 1 : Théorie complète + méthode de calcul pas-à-pas
- Module 3 : Application au routage (longest prefix match)
- Module 5 : Application aux ACLs (wildcard masks)
- Annexe : 50 exercices progressifs (SUBNETTING-DRILL.md)

## OSPF — Traitement spécial

Topic 3.4 = sujet le plus testé. Minimum 6 pages :
- Fonctionnement (Hello, DBD, LSR, LSU, LSAck)
- États d'adjacence (Down → Full)
- Élection DR/BDR (priorité, router-id)
- Configuration single-area (network, router-id, passive-interface)
- Vérification (show ip ospf neighbor, show ip route ospf)
- Lab dédié + quiz dédié

## Wireless — Traitement spécial

Cisco a considérablement augmenté les questions wireless récemment.
Couvrir en détail :
- Architecture split-MAC (CAPWAP tunnel, FlexConnect)
- Modes AP
- Configuration WLC GUI
- Sécurité (WPA2/WPA3, PSK, 802.1X)
- DHCP/DNS dans le contexte wireless
