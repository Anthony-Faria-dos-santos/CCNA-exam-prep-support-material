# Conventions Visuelles — Diagrammes & Schémas Réseau

## Inventaire minimum de diagrammes par module

| Module | Diagrammes Mermaid minimum | Types principaux |
|--------|---------------------------|------------------|
| M1 — Network Fundamentals | 10 | topologie, comparatif, sequenceDiagram |
| M2 — Network Access | 8 | topologie VLAN, stateDiagram STP, sequence LACP |
| M3 — IP Connectivity | 10 | topologie routage, stateDiagram OSPF, flowchart |
| M4 — IP Services | 8 | sequenceDiagram DHCP/DNS, topologie NAT, flowchart QoS |
| M5 — Security Fundamentals | 9 | flowchart ACL, sequenceDiagram attaques, comparatif |
| M6 — Automation | 7 | graph SDN, flowchart REST, comparatif outils |
| **Total minimum** | **52** | |

## Types de diagrammes et usage

### 1. Topologies réseau — `graph LR` ou `graph TD`

**Quand** : Illustrer une architecture physique ou logique avec des équipements interconnectés.

**Conventions** :
- Routeurs : rectangles arrondis avec hostname + IPs par interface
- Switches : rectangles avec hostname + VLANs
- PCs/Serveurs : rectangles simples avec hostname + IP/masque
- Liens : étiquetés avec type d'interface + adresse IP du segment
- Sous-réseaux : regroupés dans des subgraph étiquetés

```mermaid
graph LR
    subgraph "Réseau 192.168.1.0/24"
        PC1["PC1<br/>192.168.1.10/24"]
        PC2["PC2<br/>192.168.1.20/24"]
    end
    PC1 --- SW1["SW1<br/>Fa0/1-24"]
    PC2 --- SW1
    SW1 -->|"Gi0/0<br/>192.168.1.1"| R1(("R1"))
    R1 -->|"Gi0/1<br/>10.0.0.1/30"| R2(("R2"))
    subgraph "Réseau 172.16.0.0/16"
        SRV["Serveur<br/>172.16.1.100/24"]
    end
    R2 -->|"Gi0/0<br/>172.16.1.1"| SRV
```

### 2. Échanges de protocoles — `sequenceDiagram`

**Quand** : Illustrer un échange temporel de messages entre entités.

**Conventions** :
- Participants nommés avec rôle (Client, Serveur, Routeur R1)
- Messages avec nom du paquet/trame + champs clés
- Notes pour les timers, états, décisions
- Boucles (loop) pour les processus répétés

```mermaid
sequenceDiagram
    participant R1 as Routeur R1
    participant R2 as Routeur R2
    
    Note over R1,R2: État initial : Down
    R1->>R2: Hello (RID: 1.1.1.1, Neighbors: vide)
    Note over R2: État → Init
    R2->>R1: Hello (RID: 2.2.2.2, Neighbors: 1.1.1.1)
    Note over R1: État → 2-Way
    Note over R1,R2: Élection DR/BDR sur segment broadcast
    R1->>R2: DBD (séquence, résumés LSA)
    R2->>R1: DBD (séquence, résumés LSA)
    Note over R1,R2: État → ExStart → Exchange
    R1->>R2: LSR (demande LSAs manquants)
    R2->>R1: LSU (LSAs complets)
    R1->>R2: LSAck
    Note over R1,R2: État → Full (adjacence complète)
```

### 3. États et transitions — `stateDiagram-v2`

**Quand** : Illustrer les états d'un protocole ou d'un mécanisme avec conditions de transition.

```mermaid
stateDiagram-v2
    [*] --> Blocking : Port activé
    Blocking --> Listening : Port désigné ou root
    Listening --> Learning : Forward delay (15s)
    Learning --> Forwarding : Forward delay (15s)
    Blocking --> Blocking : Port non-désigné
    Forwarding --> Blocking : Topology change
    
    note right of Blocking : Ne transmet NI données NI MACs
    note right of Learning : Apprend MACs, ne transmet pas
    note right of Forwarding : Transmet données + apprend MACs
```

### 4. Arbres de décision / Processus — `flowchart TD`

**Quand** : Illustrer un algorithme, un processus de décision, ou un troubleshooting.

```mermaid
flowchart TD
    A[Paquet arrive sur le routeur] --> B{Route existe<br/>dans la table ?}
    B -->|Non| C[Vérifier route par défaut]
    B -->|Oui, multiple matches| D{Longest Prefix Match}
    D --> E[Sélectionner le masque<br/>le plus spécifique]
    C -->|Pas de default route| F[Drop + ICMP Unreachable]
    C -->|Default route existe| G[Transmettre via gateway of last resort]
    E --> H{Même préfixe,<br/>protocoles différents ?}
    H -->|Oui| I[Plus faible AD gagne]
    H -->|Non| J[Transmettre via next-hop]
```

### 5. Comparaisons — `flowchart LR` avec branches

**Quand** : Comparer deux concepts, protocoles, ou technologies côte à côte.

```mermaid
flowchart LR
    subgraph TCP["TCP (Fiable)"]
        direction TB
        T1[Connection-oriented]
        T2[3-way handshake]
        T3[Acknowledgements]
        T4[Contrôle de flux]
        T5["Port 80 (HTTP), 443 (HTTPS)<br/>22 (SSH), 25 (SMTP)"]
    end
    subgraph UDP["UDP (Rapide)"]
        direction TB
        U1[Connectionless]
        U2[Pas de handshake]
        U3[Pas d'ACK]
        U4[Best-effort]
        U5["Port 53 (DNS), 67/68 (DHCP)<br/>69 (TFTP), 161 (SNMP)"]
    end
```

## Règles globales

### Taille
- Maximum 25 lignes de code Mermaid par diagramme
- Si plus complexe → découper en 2 diagrammes avec cross-reference
- Les labels doivent tenir sur une ligne (max ~40 caractères)

### Lisibilité
- Toujours un titre avant le bloc mermaid (### ou ####)
- Toujours une légende/explication après le diagramme (1-3 lignes)
- Pas de diagramme sans contexte textuel autour

### Labels
- En français sauf pour les termes techniques Cisco (show, interface, etc.)
- Adresses IP complètes avec masque CIDR (/24, /30)
- Noms d'équipements cohérents dans tout le module (R1, SW1, PC1)

### Couleurs et styles Mermaid
- Utiliser les styles par défaut de Mermaid (thème neutral dans Quarto)
- Pas de classDef custom sauf pour distinguer des groupes dans une topologie
- Les subgraph pour regrouper par sous-réseau, VLAN, ou zone de sécurité

### Nomenclature pour fichiers externalisés (.mmd)
Format : `m[module]-[topic]-[description].mmd`
Exemples :
- `m1-tcp-handshake.mmd`
- `m3-ospf-adjacency-states.mmd`
- `m5-acl-processing-flowchart.mmd`

Seuil d'externalisation : >20 lignes de code Mermaid → fichier .mmd séparé
