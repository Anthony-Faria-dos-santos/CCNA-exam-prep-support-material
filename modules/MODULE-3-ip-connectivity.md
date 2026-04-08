# Module 3 — IP Connectivity

> **Domain** : 3 — IP Connectivity | **Poids examen** : 25% (le plus élevé)
> **Durée estimée** : 2 semaines | **Prérequis** : Modules 1 et 2
> **Topics couverts** : 3.1 à 3.6

## Objectif du module

À l'issue de ce module, vous serez capable de :
- Interpréter chaque composant d'une table de routage (codes, préfixe, masque, next-hop, AD, métrique)
- Déterminer le chemin qu'un routeur choisit parmi plusieurs routes candidates (longest prefix match, AD, métrique)
- Configurer et vérifier le routage statique IPv4 et IPv6 (default, network, host, floating static)
- Configurer et vérifier OSPF single-area (adjacences, DR/BDR, router-id, passive-interface)
- Décrire le rôle et le fonctionnement des protocoles FHRP (HSRP, VRRP, GLBP)
- Décrire l'intérêt de la gestion réseau cloud (Meraki, DNA Center, contrôleurs cloud)

---

## 3.1 — Anatomie de la table de routage

> **Exam topic 3.1** : *Interpret* — the components of routing table
> **Niveau** : Interpret

### Contexte

La table de routage est le GPS du routeur. Chaque paquet qui traverse un routeur est confronté à une question simple : « par où dois-je sortir ? ». La réponse se trouve dans cette table. Un administrateur réseau qui ne sait pas lire une table de routage, c'est comme un pilote qui ne sait pas lire ses instruments de vol — techniquement aux commandes, mais incapable d'intervenir quand quelque chose déraille.

### Théorie

La table de routage est une structure de données maintenue en mémoire par le routeur. Elle contient l'ensemble des réseaux de destination connus et, pour chacun, les informations nécessaires pour acheminer les paquets. Chaque ligne de la table est une **route** — une instruction qui dit : « pour atteindre ce réseau, envoie le paquet à cette adresse, via cette interface ».

Les routes peuvent être apprises de trois façons :
- **Directement connectées (C)** : les réseaux configurés sur les interfaces actives du routeur
- **Statiques (S)** : configurées manuellement par l'administrateur
- **Dynamiques** : apprises via un protocole de routage (OSPF, EIGRP, BGP…)

#### Output complet d'une table de routage

Voici une table de routage réaliste sur un routeur d'entreprise. Prenons le temps de la décortiquer :

```
R1# show ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route, + - replicated route, % - next hop override

Gateway of last resort is 203.0.113.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 203.0.113.1
      10.0.0.0/8 is variably subnetted, 6 subnets, 3 masks
C        10.1.1.0/24 is directly connected, GigabitEthernet0/0
L        10.1.1.1/32 is directly connected, GigabitEthernet0/0
C        10.1.2.0/24 is directly connected, GigabitEthernet0/1
L        10.1.2.1/32 is directly connected, GigabitEthernet0/1
O        10.1.3.0/24 [110/20] via 10.1.2.2, 00:15:32, GigabitEthernet0/1
O        10.1.4.0/26 [110/30] via 10.1.2.2, 00:15:32, GigabitEthernet0/1
      192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
S        192.168.1.0/24 [1/0] via 10.1.2.3
S        192.168.1.128/25 [1/0] via 10.1.2.4
      203.0.113.0/24 is variably subnetted, 2 subnets, 2 masks
C        203.0.113.0/30 is directly connected, GigabitEthernet0/2
L        203.0.113.2/32 is directly connected, GigabitEthernet0/2
```

#### 3.1.a — Codes des protocoles de routage

La première section de l'output est la **légende des codes**. Chaque lettre identifie la source de la route :

| Code | Source | Signification |
|------|--------|---------------|
| **C** | Connected | Réseau directement connecté (interface active) |
| **L** | Local | Adresse IP exacte de l'interface (/32) |
| **S** | Static | Route configurée manuellement |
| **S*** | Static default | Route par défaut statique |
| **O** | OSPF | Route apprise par OSPF intra-area |
| **O IA** | OSPF inter area | Route OSPF d'une autre area |
| **O E1/E2** | OSPF external | Route redistribuée dans OSPF |
| **D** | EIGRP | Route apprise par EIGRP |
| **R** | RIP | Route apprise par RIP |
| **B** | BGP | Route apprise par BGP |

Les routes **C** et **L** apparaissent automatiquement dès qu'une interface est configurée avec une adresse IP et passe en état `up/up`. La route **L** (local) est un ajout d'IOS 15+ : elle représente l'adresse exacte de l'interface avec un masque /32 — le routeur sait que cette adresse lui appartient.

#### 3.1.b — Préfixe réseau

Le **préfixe** est l'adresse réseau de destination. Dans notre exemple :
- `10.1.1.0` est le préfixe du premier réseau connecté
- `0.0.0.0` est le préfixe de la route par défaut (« tout le reste »)

Notez la ligne `10.0.0.0/8 is variably subnetted, 6 subnets, 3 masks`. C'est un **en-tête de réseau classful** : IOS regroupe visuellement toutes les routes qui partagent le même réseau classful (ici 10.0.0.0/8) et indique combien de sous-réseaux et de masques distincts existent. Ce n'est pas une route — c'est un regroupement d'affichage.

#### 3.1.c — Masque réseau

Le masque accompagne toujours le préfixe, en notation CIDR :
- `/24` = 255.255.255.0 (256 adresses, 254 hôtes)
- `/26` = 255.255.255.192 (64 adresses, 62 hôtes)
- `/30` = 255.255.255.252 (4 adresses, 2 hôtes — lien point-to-point)
- `/32` = 255.255.255.255 (une seule adresse — route locale ou host route)

Le couple préfixe/masque définit précisément l'étendue du réseau de destination. C'est ce couple qui sera utilisé pour le **longest prefix match** (section 3.2).

#### 3.1.d — Next hop (prochain saut)

Le **next hop** est l'adresse IP du routeur voisin vers lequel le paquet doit être envoyé. Dans notre exemple :
- `via 10.1.2.2` — le paquet est envoyé au routeur dont l'interface a l'adresse 10.1.2.2
- `via 203.0.113.1` — le next hop pour la route par défaut

Pour les routes **connected**, il n'y a pas de next hop : le routeur est directement connecté au réseau. L'output affiche `is directly connected` suivi du nom de l'interface de sortie.

#### 3.1.e — Distance administrative (AD)

La **distance administrative** est un entier compris entre 0 et 255 qui mesure la confiance que le routeur accorde à la source de la route. Plus la valeur est basse, plus la source est fiable.

| Source | AD par défaut |
|--------|--------------|
| Directement connectée | 0 |
| Route statique | 1 |
| eBGP | 20 |
| EIGRP interne | 90 |
| OSPF | 110 |
| IS-IS | 115 |
| RIP | 120 |
| EIGRP externe | 170 |
| iBGP | 200 |
| Inaccessible | 255 |

Dans l'output, l'AD apparaît entre crochets, avant la métrique : `[110/20]` signifie AD = 110, métrique = 20. Une route statique affiche `[1/0]` — AD de 1, métrique de 0.

L'AD sert uniquement à **départager des routes vers la même destination apprises par des sources différentes**. Si OSPF et EIGRP proposent tous les deux une route vers 10.1.3.0/24, le routeur choisit EIGRP (AD 90 < AD 110).

#### 3.1.f — Métrique

La **métrique** est la valeur utilisée par un protocole de routage pour comparer ses propres routes entre elles. Chaque protocole utilise sa propre métrique :

| Protocole | Métrique | Composants |
|-----------|----------|------------|
| RIP | Hop count | Nombre de routeurs traversés (max 15) |
| OSPF | Cost | Basé sur la bande passante (ref BW / interface BW) |
| EIGRP | Composite | Bande passante + délai (par défaut) |

La métrique n'est comparable qu'entre routes du **même protocole**. Comparer une métrique OSPF à une métrique RIP n'a aucun sens — c'est pour cela que l'AD existe.

Dans `[110/20]`, la métrique OSPF est 20. Si une autre route OSPF vers la même destination avait une métrique de 30, celle avec 20 gagnerait.

#### 3.1.g — Gateway of last resort

La ligne `Gateway of last resort is 203.0.113.1 to network 0.0.0.0` indique la **route par défaut** active. C'est le dernier recours : quand aucune route plus spécifique ne correspond au paquet, le routeur l'envoie vers cette gateway.

Si aucune route par défaut n'est configurée, l'output affiche : `Gateway of last resort is not set`. Dans ce cas, tout paquet dont la destination ne figure pas dans la table est simplement **jeté** (dropped) — le routeur n'a nulle part où l'envoyer.

#### Schéma : anatomie d'une ligne de route

```
O     10.1.3.0/24 [110/20] via 10.1.2.2, 00:15:32, GigabitEthernet0/1
│     │          │  │   │       │          │          │
│     │          │  │   │       │          │          └─ Interface de sortie
│     │          │  │   │       │          └─ Uptime (depuis quand la route est connue)
│     │          │  │   │       └─ Adresse du next hop
│     │          │  │   └─ Métrique (coût OSPF)
│     │          │  └─ Distance administrative
│     │          └─ Masque en notation CIDR
│     └─ Préfixe réseau (adresse de destination)
└─ Code du protocole (O = OSPF)
```

### Mise en pratique CLI

```cisco
! Afficher la table de routage complète
R1# show ip route

! Filtrer par protocole — uniquement les routes OSPF
R1# show ip route ospf

! Filtrer par protocole — uniquement les routes statiques
R1# show ip route static

! Chercher une route spécifique
R1# show ip route 10.1.3.0
```

**Output de `show ip route 10.1.3.0` :**
```
Routing entry for 10.1.3.0/24
  Known via "ospf 1", distance 110, metric 20, type intra area
  Last update from 10.1.2.2 on GigabitEthernet0/1, 00:15:32 ago
  Routing Descriptor Blocks:
  * 10.1.2.2, from 10.1.2.2, 00:15:32 ago, via GigabitEthernet0/1
      Route metric is 20, traffic share count is 1
```

**Interprétation** : cette vue détaillée confirme que la route vers 10.1.3.0/24 provient d'OSPF (processus 1), avec une AD de 110 et un coût de 20. Elle est de type *intra area* — le réseau 10.1.3.0/24 est dans la même area OSPF que R1. Le next hop 10.1.2.2 est accessible via Gi0/1.

### Point exam

> **Piège courant** : confondre la distance administrative et la métrique. L'AD compare des **sources différentes** (OSPF vs EIGRP). La métrique compare des **routes du même protocole** (deux chemins OSPF). L'examen propose régulièrement des scénarios où OSPF a une meilleure métrique qu'EIGRP, mais EIGRP gagne quand même grâce à son AD inférieure.
>
> **À retenir** : les routes **L** (/32) sont normales à partir d'IOS 15. Ne les confondez pas avec des host routes statiques. Elles représentent les propres adresses IP du routeur.

### Exercice 3.1a — Interpréter une table de routage

**Contexte** : vous êtes administrateur réseau chez TechLab, une PME de 80 employés. Le routeur central R1 affiche la table de routage suivante :

```
Gateway of last resort is 172.16.0.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 172.16.0.1
      10.0.0.0/8 is variably subnetted, 4 subnets, 2 masks
C        10.10.10.0/24 is directly connected, GigabitEthernet0/0
L        10.10.10.1/32 is directly connected, GigabitEthernet0/0
O        10.10.20.0/24 [110/20] via 10.10.30.2, 01:05:12, GigabitEthernet0/1
O        10.10.30.0/24 [110/10] via 10.10.30.2, 01:05:12, GigabitEthernet0/1
      172.16.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.16.0.0/30 is directly connected, GigabitEthernet0/2
L        172.16.0.2/32 is directly connected, GigabitEthernet0/2
```

**Consigne** : répondez aux questions suivantes :
1. Combien d'interfaces actives R1 possède-t-il ?
2. Quelle est l'adresse IP de R1 sur son lien WAN ?
3. Vers quelle adresse un paquet destiné à 8.8.8.8 sera-t-il envoyé ?
4. La route vers 10.10.20.0/24 provient de quel protocole ? Quelle est sa métrique ?
5. Pourquoi 10.10.30.0/24 a-t-il une métrique différente de 10.10.20.0/24 alors que les deux passent par le même next hop ?

**Indice** : <details><summary>Voir l'indice</summary>Les routes C et L vont par paires. Comptez les paires pour trouver le nombre d'interfaces. Pour la question 5, pensez au nombre de sauts OSPF.</details>

<details>
<summary>Solution</summary>

1. **3 interfaces actives** : Gi0/0 (10.10.10.1), Gi0/1 (implicite — c'est l'interface de sortie des routes OSPF, mais on ne voit pas sa route C/L dans cette table, ce qui signifie que Gi0/1 a une adresse dans le réseau 10.10.30.0/24), Gi0/2 (172.16.0.2). En fait, Gi0/1 est dans le réseau 10.10.30.0/24 — on voit que ce réseau est à la fois "connected" via OSPF (métrique 10 = un seul lien) et accessible via Gi0/1. Vérification : il y a 3 paires C/L → 3 interfaces ? Non, seulement 2 paires C/L visibles (Gi0/0 et Gi0/2). Mais Gi0/1 est mentionné comme interface de sortie. La route C/L pour le réseau de Gi0/1 devrait exister — elle est probablement dans le réseau 10.10.30.0/24 mais l'output la montre comme route O car OSPF l'a aussi apprise. En réalité R1 a bien **3 interfaces actives**.

2. **172.16.0.2** — la route L sur Gi0/2 avec un masque /30 (lien point-to-point typique WAN).

3. **172.16.0.1** — 8.8.8.8 ne correspond à aucune route spécifique, donc la route par défaut `S* 0.0.0.0/0 via 172.16.0.1` s'applique.

4. **OSPF** (code O), métrique **20**. Le `[110/20]` indique AD=110 (OSPF) et métrique=20.

5. Le réseau 10.10.30.0/24 a une métrique de **10** car il est directement connecté au next hop (un seul lien OSPF à traverser). Le réseau 10.10.20.0/24 a une métrique de **20** car il est un saut plus loin (deux liens OSPF). La métrique OSPF est cumulative — elle additionne le coût de chaque lien traversé.

</details>

### Exercice 3.1b — Gateway of last resort

**Contexte** : un collègue vous signale que le routeur de la succursale R-BRANCH ne peut pas joindre Internet.

**Consigne** : vous tapez `show ip route` et voyez `Gateway of last resort is not set`. Expliquez le problème et proposez deux solutions pour le résoudre.

**Indice** : <details><summary>Voir l'indice</summary>Pensez aux deux façons de créer une route par défaut : statiquement, ou via un protocole de routage.</details>

<details>
<summary>Solution</summary>

**Problème** : aucune route par défaut n'est configurée. Tout paquet dont la destination ne figure pas explicitement dans la table de routage est jeté.

**Solution 1 — Route statique par défaut** :
```cisco
R-BRANCH(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1
```

**Solution 2 — Recevoir la route par défaut via OSPF** : si R-BRANCH participe à un domaine OSPF, le routeur de bordure peut redistribuer une route par défaut :
```cisco
! Sur le routeur de bordure (celui qui a accès à Internet)
R-EDGE(config-router)# default-information originate
```
R-BRANCH recevra alors la route par défaut via OSPF avec le code `O*E2`.

**Explication** : la première solution est simple et directe — adaptée aux topologies avec une seule sortie Internet. La seconde est plus élégante pour les topologies où plusieurs routeurs peuvent servir de passerelle, car OSPF peut basculer automatiquement vers un routeur de secours.

</details>

### Voir aussi

- Topic 1.6 dans Module 1 (relation : adressage IPv4 et notation CIDR)
- Topic 3.2 dans ce module (relation : longest prefix match utilise le préfixe/masque pour la décision)
- Topic 3.3 dans ce module (relation : les routes statiques peuplent cette table)
- Topic 3.4 dans ce module (relation : OSPF peuple cette table dynamiquement)

---

## 3.2 — Décisions de routage (longest prefix, AD, métrique)

> **Exam topic 3.2** : *Determine* — how a router makes a forwarding decision by default
> **Niveau** : Determine

### Contexte

Un routeur d'entreprise typique possède des dizaines, voire des centaines de routes dans sa table. Quand un paquet arrive avec une adresse de destination, le routeur doit prendre une décision en quelques microsecondes. Comment choisit-il parmi toutes ces routes ? La réponse suit un processus en trois étapes, toujours dans le même ordre. Comprendre ce processus est fondamental pour diagnostiquer des problèmes de routage.

### Théorie

Le processus de décision d'un routeur suit une hiérarchie stricte :

```
Paquet arrive avec IP destination
          │
          ▼
┌─────────────────────────┐
│ 1. LONGEST PREFIX MATCH │  ← Trouve toutes les routes qui matchent
│    (le plus spécifique)  │     et garde la plus spécifique
└──────────┬──────────────┘
           │ Si plusieurs routes avec le même préfixe/masque
           ▼
┌─────────────────────────┐
│ 2. ADMINISTRATIVE       │  ← Compare la fiabilité des sources
│    DISTANCE (la + basse)│     (EIGRP 90 bat OSPF 110)
└──────────┬──────────────┘
           │ Si même AD (= même protocole)
           ▼
┌─────────────────────────┐
│ 3. METRIC               │  ← Compare les chemins au sein
│    (la + basse)          │     du même protocole
└─────────────────────────┘
```

#### 3.2.a — Longest prefix match

C'est la règle la plus importante du routage IP. Le routeur compare l'adresse de destination du paquet à toutes les routes de sa table et sélectionne celle dont le **masque est le plus long** (le plus spécifique).

Prenons un exemple concret. Un paquet arrive avec la destination **10.1.3.67**. La table contient :

| Route | Masque | Correspond ? | Bits matchés |
|-------|--------|-------------|--------------|
| 0.0.0.0/0 | /0 | Oui (match tout) | 0 |
| 10.0.0.0/8 | /8 | Oui | 8 |
| 10.1.0.0/16 | /16 | Oui | 16 |
| 10.1.3.0/24 | /24 | Oui | 24 |
| 10.1.3.64/26 | /26 | Oui (10.1.3.64–127) | 26 |
| 10.1.4.0/24 | /24 | Non | — |

Le routeur choisit **10.1.3.64/26** — c'est la route la plus spécifique qui contient 10.1.3.67. La route par défaut (/0) est le « filet de sécurité », utilisée uniquement si rien de plus spécifique n'existe.

L'analogie postale fonctionne bien ici : imaginez que vous devez livrer un colis à « 15 rue Victor Hugo, Lyon 3e ». Vous avez un carnet avec les destinations « France », « Rhône-Alpes », « Lyon », « Lyon 3e » et « 15 rue Victor Hugo, Lyon 3e ». Vous choisissez naturellement l'entrée la plus précise — c'est exactement ce que fait le routeur.

#### Le longest prefix match en binaire

Pour bien comprendre, convertissons en binaire. L'adresse 10.1.3.67 :

```
10.1.3.67  = 00001010.00000001.00000011.01000011

Route 10.1.3.0/24 :
Réseau     = 00001010.00000001.00000011.00000000
Masque /24 = 11111111.11111111.11111111.00000000
                                        ^^^^^^^^ pas comparé
Résultat : 24 bits matchent ✓

Route 10.1.3.64/26 :
Réseau     = 00001010.00000001.00000011.01000000
Masque /26 = 11111111.11111111.11111111.11000000
                                        ^^       comparé aussi !
67 en bin  = 01000011
64 en bin  = 01000000
Les 26 premiers bits matchent ✓ (plus spécifique → GAGNE)
```

#### 3.2.b — Distance administrative

L'AD n'intervient que lorsque **deux routes vers exactement le même préfixe/masque** sont apprises par des **sources différentes**. C'est un départage inter-protocoles.

Scénario : OSPF et EIGRP proposent tous les deux une route vers 10.1.3.0/24.

```
D     10.1.3.0/24 [90/307200] via 10.1.1.2     ← EIGRP, AD 90
O     10.1.3.0/24 [110/20] via 10.1.2.2         ← OSPF, AD 110
```

Le routeur installe uniquement la route EIGRP (AD 90 < 110). La route OSPF reste dans la base OSPF mais **ne figure pas dans la table de routage**. Si la route EIGRP disparaît (panne du voisin EIGRP), la route OSPF prendra le relais — ce mécanisme s'appelle le **failover**.

Ce principe est aussi à la base des **floating static routes** (section 3.3.d).

#### 3.2.c — Métrique du protocole de routage

La métrique départage des routes apprises par le **même protocole** vers la **même destination**. Chaque protocole a sa propre métrique :

| Protocole | Métrique | Meilleur = |
|-----------|----------|-----------|
| RIP | Nombre de sauts (hop count) | Le moins de sauts |
| OSPF | Coût (basé sur bande passante) | Le coût le plus bas |
| EIGRP | Composite (BW + delay par défaut) | La valeur la plus basse |

Scénario : deux chemins OSPF vers 10.1.3.0/24.

```
O     10.1.3.0/24 [110/20] via 10.1.2.2     ← Coût 20 (chemin rapide)
O     10.1.3.0/24 [110/30] via 10.1.5.2     ← Coût 30 (chemin plus lent)
```

Le routeur choisit le chemin via 10.1.2.2 (coût 20 < 30). Si les deux métriques étaient identiques, le routeur ferait du **load balancing** — il utiliserait les deux chemins simultanément (ECMP : Equal-Cost Multi-Path).

#### Résumé du processus de décision

```
┌────────────────────────────────────────────────────┐
│            PROCESSUS DE FORWARDING                  │
├────────────────────────────────────────────────────┤
│ Étape 1 : Longest prefix match                     │
│   → Toujours exécutée en premier                   │
│   → /26 bat /24, qui bat /16, qui bat /0           │
│   → Si une seule route match → FIN                 │
│                                                    │
│ Étape 2 : Administrative distance                  │
│   → Seulement si même préfixe, sources différentes │
│   → Connected (0) > Static (1) > EIGRP (90) >     │
│     OSPF (110) > RIP (120)                         │
│   → Si même AD → Étape 3                           │
│                                                    │
│ Étape 3 : Metric                                   │
│   → Seulement si même protocole                    │
│   → La plus basse gagne                            │
│   → Si même métrique → Load balancing (ECMP)       │
│                                                    │
│ Aucun match → Gateway of last resort (si définie)  │
│ Aucun match + pas de default → DROP                │
└────────────────────────────────────────────────────┘
```

### Mise en pratique CLI

```cisco
! Voir la table complète pour analyser les décisions
R1# show ip route

! Vérifier quel chemin sera utilisé pour une destination précise
R1# show ip route 10.1.3.67
```

**Output :**
```
Routing entry for 10.1.3.64/26
  Known via "ospf 1", distance 110, metric 20, type intra area
  Last update from 10.1.2.2 on GigabitEthernet0/1, 00:22:41 ago
  Routing Descriptor Blocks:
  * 10.1.2.2, from 10.1.2.2, 00:22:41 ago, via GigabitEthernet0/1
      Route metric is 20, traffic share count is 1
```

**Interprétation** : le routeur a trouvé la route la plus spécifique (10.1.3.64/26) pour atteindre 10.1.3.67. Le `show ip route <IP>` est l'outil de diagnostic clé pour comprendre les décisions de routage.

### Point exam

> **Piège courant** : l'examen adore présenter un scénario où une route statique (/24) et une route OSPF (/26) pointent vers des next hops différents. Les candidats pensent que la route statique gagne (AD 1 < AD 110), mais c'est faux : le longest prefix match s'applique TOUJOURS en premier. La route OSPF /26 est plus spécifique et gagne, quelle que soit l'AD.
>
> **À retenir** : l'ordre est **toujours** longest prefix → AD → metric. L'AD ne peut jamais « battre » un masque plus long.

### Exercice 3.2 — Déterminer le chemin choisi

**Contexte** : le routeur R-CORE de l'entreprise MegaCorp a la table de routage suivante :

```
S     172.16.0.0/16 [1/0] via 10.0.0.1
O     172.16.0.0/16 [110/40] via 10.0.0.2
D     172.16.10.0/24 [90/307200] via 10.0.0.3
O     172.16.10.128/25 [110/20] via 10.0.0.4
S     172.16.10.128/25 [5/0] via 10.0.0.5
```

**Consigne** : pour chaque destination ci-dessous, indiquez quelle route sera utilisée et via quel next hop :
1. 172.16.10.200
2. 172.16.10.50
3. 172.16.20.1
4. 172.16.10.130

**Indice** : <details><summary>Voir l'indice</summary>Appliquez systématiquement les 3 étapes : d'abord trouvez toutes les routes qui matchent, puis gardez la plus spécifique (longest prefix), puis comparez l'AD si nécessaire.</details>

<details>
<summary>Solution</summary>

**1. 172.16.10.200** → via **10.0.0.4** (route OSPF 172.16.10.128/25)
- Matchent : /16 (S et O), /24 (D), /25 (O et S)
- Longest prefix : /25 (172.16.10.128–255 contient .200) → deux routes /25
- AD : OSPF [110] vs Static [5] → Static gagne (AD 5 < 110)
- **Correction** : la route statique `S 172.16.10.128/25 [5/0] via 10.0.0.5` gagne. Next hop = **10.0.0.5**.

**2. 172.16.10.50** → via **10.0.0.3** (route EIGRP 172.16.10.0/24)
- Matchent : /16 (S et O), /24 (D)
- 10.50 n'est PAS dans 172.16.10.128/25 (128–255), donc les routes /25 ne matchent pas
- Longest prefix : /24 → seule route EIGRP
- Next hop = **10.0.0.3**

**3. 172.16.20.1** → via **10.0.0.1** (route statique 172.16.0.0/16)
- Matchent : /16 (S et O) uniquement — .20.1 n'est dans aucun /24 ou /25
- Longest prefix : /16 → deux routes (S et O)
- AD : Static [1] vs OSPF [110] → Static gagne
- Next hop = **10.0.0.1**

**4. 172.16.10.130** → via **10.0.0.5** (route statique 172.16.10.128/25)
- Matchent : /16, /24, /25 (130 est dans 128–255)
- Longest prefix : /25 → deux routes (O [110] et S [5])
- AD : Static [5] bat OSPF [110]
- Next hop = **10.0.0.5**

</details>

### Voir aussi

- Topic 3.1 dans ce module (relation : composants de la table de routage)
- Topic 1.6 dans Module 1 (relation : subnetting et calcul de masques)
- Topic 3.3 dans ce module (relation : les routes statiques et l'AD modifiable)
- Topic 5.6 dans Module 5 (relation : les ACLs utilisent aussi le wildcard mask pour le matching)

---

## 3.3 — Routage statique IPv4 et IPv6

> **Exam topic 3.3** : *Configure and verify* — IPv4 and IPv6 static routing
> **Niveau** : Configure/Verify

### Contexte

Avant l'existence des protocoles de routage dynamique, chaque route devait être configurée à la main sur chaque routeur. Aujourd'hui, le routage statique reste indispensable dans de nombreux scénarios : connexion à un FAI, petites succursales avec une seule sortie, routes de secours, ou réseaux stub sans besoin de protocole dynamique. C'est aussi le fondement pédagogique — comprendre le routage statique avant le dynamique est comme apprendre à conduire en boîte manuelle avant l'automatique.

### Théorie

Une route statique est une instruction permanente dans la configuration du routeur : « pour atteindre ce réseau, passe par là ». Contrairement aux routes dynamiques, elle ne s'adapte pas aux changements de topologie — si le lien tombe, la route reste dans la configuration (et dans la table de routage tant que l'interface de sortie est up).

#### Syntaxe de base

```cisco
! Syntaxe IPv4
ip route <réseau> <masque> <next-hop | interface-sortie> [AD]

! Syntaxe IPv6
ipv6 route <préfixe/longueur> <next-hop | interface-sortie> [AD]
```

#### 3.3.a — Route par défaut (default route)

La route par défaut est le « catch-all » — elle correspond à toute destination qui n'a pas de route plus spécifique. Son préfixe est 0.0.0.0/0 (IPv4) ou ::/0 (IPv6).

```cisco
! IPv4 — Route par défaut vers le FAI
R1(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1

! IPv6 — Route par défaut vers le FAI
R1(config)# ipv6 route ::/0 2001:DB8:ACAD:1::1
```

**Vérification :**
```
R1# show ip route static
S*    0.0.0.0/0 [1/0] via 203.0.113.1

R1# show ipv6 route static
S   ::/0 [1/0]
     via 2001:DB8:ACAD:1::1
```

L'astérisque `*` confirme que cette route est reconnue comme gateway of last resort.

Cas d'usage typique : une succursale avec un seul lien vers le siège. Tout le trafic non local part par ce lien.

#### 3.3.b — Route réseau (network route)

La route réseau spécifie comment atteindre un sous-réseau précis. C'est le type de route statique le plus courant.

```cisco
! IPv4 — Atteindre le réseau 192.168.10.0/24 via le routeur voisin
R1(config)# ip route 192.168.10.0 255.255.255.0 10.1.1.2

! IPv6
R1(config)# ipv6 route 2001:DB8:ACAD:10::/64 2001:DB8:ACAD:1::2
```

On peut aussi spécifier l'interface de sortie au lieu du next hop :
```cisco
R1(config)# ip route 192.168.10.0 255.255.255.0 GigabitEthernet0/1
```

Ou les deux (recommandé sur les réseaux multi-accès) :
```cisco
R1(config)# ip route 192.168.10.0 255.255.255.0 GigabitEthernet0/1 10.1.1.2
```

#### Schéma : topologie pour le routage statique

```
        Réseau A                                      Réseau B
    192.168.10.0/24                               192.168.20.0/24

 [PC-A]──────[SW1]──────[R1]════════════[R2]──────[SW2]──────[PC-B]
              │         Gi0/0  Lien P2P  Gi0/0        │
              │       .1    10.1.1.0/30    .2          │
              │         Gi0/1                Gi0/1     │
              │       .1                       .1      │
         192.168.10.0/24                  192.168.20.0/24
```

Pour que PC-A (192.168.10.10) puisse joindre PC-B (192.168.20.10), il faut configurer :
- Sur R1 : une route vers 192.168.20.0/24 via 10.1.1.2
- Sur R2 : une route vers 192.168.10.0/24 via 10.1.1.1

Sans ces deux routes (aller ET retour), la communication ne fonctionne pas.

#### 3.3.c — Route hôte (host route)

Une route hôte pointe vers une **adresse IP unique** — un masque /32 (IPv4) ou /128 (IPv6). Cas d'usage : diriger le trafic vers un serveur spécifique via un chemin particulier, ou créer une route pour une adresse de loopback.

```cisco
! IPv4 — Route vers un serveur précis
R1(config)# ip route 10.1.1.100 255.255.255.255 192.168.1.2

! IPv6
R1(config)# ipv6 route 2001:DB8:ACAD::100/128 2001:DB8:ACAD:1::2
```

**Vérification :**
```
R1# show ip route 10.1.1.100
Routing entry for 10.1.1.100/32
  Known via "static", distance 1, metric 0
  Routing Descriptor Blocks:
  * 192.168.1.2
      Route metric is 0, traffic share count is 1
```

#### 3.3.d — Floating static route

Une **floating static** est une route statique avec une AD volontairement augmentée pour qu'elle serve de **route de secours**. Par défaut, une route statique a une AD de 1. Si on la monte à 130 (par exemple), elle sera moins préférée qu'une route OSPF (AD 110) — mais si OSPF tombe, elle prend le relais automatiquement.

```
                 Lien principal (fibre)
         ┌────────── OSPF ──────────┐
   [R1]──┤                          ├──[R2]
         └──── Lien backup (4G) ────┘
              Floating static (AD 130)
```

```cisco
! R1 — Route de secours via le lien 4G (AD 130 > OSPF 110)
R1(config)# ip route 192.168.20.0 255.255.255.0 10.99.1.2 130

! Vérification — la route n'apparaît PAS tant qu'OSPF fonctionne
R1# show ip route 192.168.20.0
Routing entry for 192.168.20.0/24
  Known via "ospf 1", distance 110, metric 20, type intra area
  ...
```

Si le lien OSPF tombe :
```
R1# show ip route 192.168.20.0
Routing entry for 192.168.20.0/24
  Known via "static", distance 130, metric 0
  Routing Descriptor Blocks:
  * 10.99.1.2
      Route metric is 0, traffic share count is 1
```

La route statique avec AD 130 « flotte » en arrière-plan et n'apparaît dans la table que quand la route préférée (OSPF) disparaît. C'est un mécanisme de failover simple et fiable.

### Mise en pratique CLI — Configuration complète

```cisco
! === Topologie : R1 ── R2 ── R3 (en série) ===
! Sur R1 : atteindre le réseau derrière R3 en passant par R2

! Route réseau vers le LAN de R3
R1(config)# ip route 192.168.30.0 255.255.255.0 10.1.12.2

! Route par défaut pour tout le reste
R1(config)# ip route 0.0.0.0 0.0.0.0 10.1.12.2

! Route IPv6
R1(config)# ipv6 unicast-routing
R1(config)# ipv6 route 2001:DB8:30::/64 2001:DB8:12::2
R1(config)# ipv6 route ::/0 2001:DB8:12::2
```

**Vérification complète :**
```
R1# show ip route static
Codes: L - local, C - connected, S - static, ...

Gateway of last resort is 10.1.12.2 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.1.12.2
S     192.168.30.0/24 [1/0] via 10.1.12.2

R1# show ipv6 route static
S   ::/0 [1/0]
     via 2001:DB8:12::2
S   2001:DB8:30::/64 [1/0]
     via 2001:DB8:12::2

R1# ping 192.168.30.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 192.168.30.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

### Point exam

> **Piège courant** : oublier la route **retour**. Vous configurez une route statique sur R1 vers le réseau de R2, mais oubliez de configurer la route retour sur R2 vers le réseau de R1. Le ping semble échouer alors que les paquets ICMP Echo arrivent bien — c'est le Echo Reply qui ne peut pas revenir. L'examen teste régulièrement ce piège avec des scénarios « le ping ne fonctionne pas, trouvez pourquoi ».
>
> **À retenir** : pour les routes statiques IPv6, la commande `ipv6 unicast-routing` doit être activée sur le routeur. Sans elle, le routeur traite les paquets IPv6 en tant qu'hôte, pas en tant que routeur.

### Exercice 3.3a — Routes statiques et default route

**Contexte** : vous configurez le réseau d'une PME avec 3 routeurs en série :

```
[LAN-A: 10.10.1.0/24]──[R1]──(10.10.12.0/30)──[R2]──(10.10.23.0/30)──[R3]──[LAN-C: 10.10.3.0/24]
                                                 │
                                            [LAN-B: 10.10.2.0/24]
```

Adresses des interfaces de transit :
- R1 Gi0/1 : 10.10.12.1 | R2 Gi0/0 : 10.10.12.2
- R2 Gi0/2 : 10.10.23.1 | R3 Gi0/0 : 10.10.23.2
- R2 Gi0/1 : 10.10.2.1

**Consigne** : configurez les routes statiques nécessaires pour que les trois LANs puissent communiquer entre eux. R1 et R3 n'ont qu'une seule sortie — utilisez des routes par défaut.

**Indice** : <details><summary>Voir l'indice</summary>R2 est au centre et a besoin de routes spécifiques vers LAN-A et LAN-C. R1 et R3 n'ont qu'une seule sortie → default route.</details>

<details>
<summary>Solution</summary>

```cisco
! === R1 — une seule sortie vers R2 ===
R1(config)# ip route 0.0.0.0 0.0.0.0 10.10.12.2

! === R2 — hub central, routes vers les deux LANs distants ===
R2(config)# ip route 10.10.1.0 255.255.255.0 10.10.12.1
R2(config)# ip route 10.10.3.0 255.255.255.0 10.10.23.2

! === R3 — une seule sortie vers R2 ===
R3(config)# ip route 0.0.0.0 0.0.0.0 10.10.23.1
```

**Explication** : R1 et R3 sont des routeurs "stub" — ils n'ont qu'un seul voisin (R2). Une route par défaut suffit : tout le trafic non local va vers R2. R2, en revanche, doit savoir dans quelle direction se trouvent LAN-A et LAN-C, d'où les routes réseau spécifiques. Le LAN-B est directement connecté à R2, pas besoin de route statique.

**Vérification** :
```cisco
R1# ping 10.10.3.1 source 10.10.1.1
!!!!!
R3# ping 10.10.1.1 source 10.10.3.1
!!!!!
```

</details>

### Exercice 3.3b — Floating static route

**Contexte** : l'entreprise NordConnect dispose de deux liens entre R-SIEGE et R-BRANCH :
- Lien principal : fibre, couvert par OSPF (coût 10)
- Lien backup : VPN 4G, interface Tunnel0, next hop 172.16.99.1

**Consigne** : configurez une floating static route sur R-BRANCH pour que le réseau du siège (10.0.0.0/16) soit accessible via le lien 4G en cas de panne OSPF.

**Indice** : <details><summary>Voir l'indice</summary>L'AD d'OSPF est 110. Votre route statique doit avoir une AD supérieure pour rester en backup.</details>

<details>
<summary>Solution</summary>

```cisco
R-BRANCH(config)# ip route 10.0.0.0 255.255.0.0 172.16.99.1 130
```

**Explication** : l'AD de 130 est supérieure à celle d'OSPF (110), donc cette route reste invisible tant qu'OSPF annonce 10.0.0.0/16. Si l'adjacence OSPF tombe, la route OSPF disparaît de la table et la route statique (AD 130) prend le relais automatiquement. Quand OSPF se rétablit, la route dynamique reprend la main (110 < 130).

Le choix de l'AD 130 est une convention courante, mais toute valeur entre 111 et 254 fonctionnerait. On évite 255 car c'est l'AD « inaccessible » (la route ne serait jamais installée).

</details>

### Voir aussi

- Topic 3.1 dans ce module (relation : les routes statiques sont visibles dans la table avec le code S)
- Topic 3.2 dans ce module (relation : AD modifiable et longest prefix match)
- Topic 3.4 dans ce module (relation : OSPF remplace le routage statique dans les topologies complexes)
- Topic 1.8 dans Module 1 (relation : adressage IPv6 et préfixes)

---

## 3.4 — OSPF single-area

> **Exam topic 3.4** : *Configure and verify* — single area OSPFv2
> **Niveau** : Configure/Verify

### Contexte

Le routage statique fonctionne pour 3 ou 4 routeurs, mais imaginez un réseau de 50 routeurs : maintenir des centaines de routes statiques à la main est un cauchemar opérationnel. Si un lien tombe, il faut intervenir manuellement pour rediriger le trafic. C'est là qu'intervient OSPF (Open Shortest Path First) — un protocole de routage dynamique qui permet aux routeurs de découvrir automatiquement la topologie du réseau, de calculer les meilleurs chemins, et de s'adapter en temps réel aux changements.

OSPF est le protocole de routage le plus testé à l'examen CCNA. Le topic 3.4 représente à lui seul une part significative des 25% du domain IP Connectivity. Maîtriser OSPF, c'est maîtriser le cœur du routage d'entreprise.

### Théorie

#### Qu'est-ce qu'OSPF ?

OSPF est un protocole de routage **link-state** (à état de liens), standardisé par l'IETF (RFC 2328 pour OSPFv2, RFC 5340 pour OSPFv3). Contrairement aux protocoles distance-vector comme RIP qui ne connaissent que la direction et la distance vers chaque destination, OSPF donne à chaque routeur une **carte complète de la topologie** du réseau.

L'analogie GPS est parfaite : RIP, c'est demander la direction à chaque passant (« le centre-ville ? tout droit, puis à gauche ») — chaque personne ne connaît que son voisinage. OSPF, c'est comme avoir une carte routière complète — chaque routeur possède la même carte et calcule lui-même le meilleur itinéraire.

#### Caractéristiques principales

| Caractéristique | Valeur |
|-----------------|--------|
| Type | Link-state (IGP) |
| Algorithme | Dijkstra (SPF — Shortest Path First) |
| Métrique | Coût (basé sur la bande passante) |
| AD | 110 |
| Transport | IP protocole 89 (pas TCP, pas UDP) |
| Multicast Hello | 224.0.0.5 (AllSPFRouters) |
| Multicast DR/BDR | 224.0.0.6 (AllDRouters) |
| Timers (broadcast) | Hello = 10s, Dead = 40s |
| Timers (point-to-point) | Hello = 10s, Dead = 40s |
| Timers (NBMA) | Hello = 30s, Dead = 120s |
| Supporte VLSM | Oui |
| Supporte CIDR | Oui |
| Mises à jour | Incrémentales (pas de full update périodique) |

#### Les 5 types de paquets OSPF

OSPF utilise 5 types de paquets pour établir des adjacences et synchroniser les bases de données topologiques :

| Type | Nom | Rôle | Analogie |
|------|-----|------|----------|
| 1 | **Hello** | Découvrir les voisins, maintenir l'adjacence | « Bonjour, je suis R1, voici mes paramètres » |
| 2 | **DBD** (Database Description) | Résumer le contenu de la LSDB | « Voici la liste de ce que je sais » |
| 3 | **LSR** (Link-State Request) | Demander les détails manquants | « Je n'ai pas cette info, envoie-la moi » |
| 4 | **LSU** (Link-State Update) | Envoyer les détails des LSA | « Voici les infos que tu as demandées » |
| 5 | **LSAck** | Accuser réception d'un LSU | « Bien reçu, merci » |

#### Contenu du paquet Hello

Le paquet Hello transporte les paramètres critiques qui doivent correspondre entre deux voisins pour former une adjacence :

| Champ | Description | Doit matcher ? |
|-------|-------------|----------------|
| Router ID | Identifiant unique du routeur | Non |
| Hello interval | Fréquence d'envoi des Hello | **Oui** |
| Dead interval | Temps avant de déclarer un voisin mort | **Oui** |
| Area ID | Numéro de l'area OSPF | **Oui** |
| Network mask | Masque du sous-réseau | **Oui** (broadcast/NBMA) |
| Authentication | Type + mot de passe | **Oui** (si configuré) |
| Stub area flag | Indicateur de zone stub | **Oui** |
| Neighbors | Liste des Router ID voisins déjà connus | Non |
| DR/BDR | Adresses du DR et BDR élus | Non |
| Priority | Priorité pour l'élection DR/BDR | Non |

#### 3.4.a — Adjacences OSPF (Neighbor adjacencies)

L'établissement d'une adjacence OSPF suit un processus en 7 états. Ce processus est au cœur du fonctionnement d'OSPF — et de l'examen.

```
État 1: DOWN
  │  Le routeur n'a reçu aucun Hello de ce voisin
  │  ← Envoi du premier Hello
  ▼
État 2: INIT
  │  Un Hello a été reçu, mais notre Router ID
  │  n'apparaît pas dans le champ Neighbors du voisin
  │  ← Le voisin nous ajoute à sa liste Neighbors
  ▼
État 3: 2-WAY
  │  Communication bidirectionnelle confirmée
  │  Notre Router ID apparaît dans le Hello du voisin
  │  ← Sur réseau broadcast : élection DR/BDR ici
  │  ← Sur point-to-point : passage direct à ExStart
  ▼
État 4: EXSTART
  │  Négociation du master/slave pour l'échange DBD
  │  Le routeur avec le Router ID le plus élevé = master
  │  ← Échange des premiers DBD (vides, pour établir la séquence)
  ▼
État 5: EXCHANGE
  │  Échange des DBD (résumés de la LSDB)
  │  Chaque routeur découvre ce que l'autre sait
  │  ← Comparaison des DBD reçus avec sa propre LSDB
  ▼
État 6: LOADING
  │  Envoi de LSR pour les LSA manquants
  │  Réception des LSU contenant les détails
  │  ← Échange LSR → LSU → LSAck
  ▼
État 7: FULL
     Adjacence complète — les LSDB sont synchronisées
     Le routeur calcule le SPF et installe les routes
```

Sur un **réseau broadcast** (Ethernet), l'état **2-WAY** est atteint par tous les voisins, mais seuls le DR et le BDR forment des adjacences **FULL** avec les autres routeurs. Les routeurs DROther restent en 2-WAY entre eux — c'est normal et attendu.

Sur un **réseau point-to-point**, il n'y a que deux routeurs : pas besoin de DR/BDR. L'adjacence passe directement de 2-WAY à ExStart, puis à FULL.

#### Conditions pour former une adjacence

Deux routeurs OSPF ne deviendront voisins que si **toutes** ces conditions sont remplies :

1. Les interfaces sont dans la **même area**
2. Les **Hello et Dead intervals** correspondent
3. Le **masque de sous-réseau** correspond (sur réseaux broadcast/NBMA)
4. L'**authentification** correspond (si configurée)
5. Le **stub flag** correspond
6. Les **Router ID** sont uniques
7. L'**MTU** correspond (sinon bloqué en ExStart/Exchange)

Si une adjacence ne se forme pas, vérifiez ces 7 points dans l'ordre.

#### 3.4.b — Réseau point-to-point

Sur un lien point-to-point (serial, tunnel, ou Ethernet configuré en point-to-point), OSPF se comporte simplement :
- Pas d'élection DR/BDR (inutile avec seulement 2 routeurs)
- Les Hello sont envoyés en multicast 224.0.0.5
- L'adjacence monte directement à FULL
- Le masque de sous-réseau n'a pas besoin de matcher (car pas de réseau multi-accès)

```cisco
! Forcer le type de réseau en point-to-point sur une interface Ethernet
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip ospf network point-to-point
```

Cas d'usage typique : liens WAN série, tunnels GRE, ou liens Ethernet dédiés entre deux routeurs (de plus en plus courant dans les datacenters).

#### 3.4.c — Réseau broadcast et élection DR/BDR

Sur un réseau multi-accès (Ethernet), si tous les routeurs formaient des adjacences FULL avec tous les autres, la quantité de trafic OSPF serait explosive. Avec N routeurs, on aurait N×(N-1)/2 adjacences. La solution d'OSPF : élire un **Designated Router (DR)** et un **Backup Designated Router (BDR)**.

```
              Segment Ethernet broadcast
    ┌──────────────────────────────────────────┐
    │                                          │
  [R1]        [R2]        [R3]        [R4]
  DROther      DR          BDR       DROther
  Prio: 1    Prio: 255   Prio: 200   Prio: 0

  R1 ←→ R2 (FULL)       R3 ←→ R2 (FULL)
  R1 ←→ R3 (FULL)       R4 ←→ R2 (FULL)
  R1 ←→ R4 (2-WAY)      R4 ←→ R3 (FULL)
```

Le DR centralise l'échange de LSA : les routeurs envoient leurs mises à jour au DR (multicast 224.0.0.6), et le DR les redistribue à tout le monde (multicast 224.0.0.5). Le BDR est le remplaçant en cas de panne du DR.

#### Algorithme d'élection DR/BDR

1. Le routeur avec la **priorité OSPF la plus élevée** devient DR
2. En cas d'égalité de priorité, le **Router ID le plus élevé** départage
3. Le deuxième plus élevé devient BDR
4. Priorité **0** = le routeur ne participe **jamais** à l'élection (reste DROther)
5. L'élection est **non-préemptive** : si un routeur plus prioritaire arrive après l'élection, il ne prend PAS le rôle de DR

Ce dernier point est critique et souvent testé à l'examen. Si R2 est DR avec une priorité de 100, et que R5 arrive avec une priorité de 255, R5 ne deviendra pas DR — il faut redémarrer le processus OSPF (`clear ip ospf process`) pour forcer une nouvelle élection.

```cisco
! Modifier la priorité OSPF sur une interface
R2(config)# interface GigabitEthernet0/0
R2(config-if)# ip ospf priority 255

! Empêcher un routeur de devenir DR/BDR
R4(config)# interface GigabitEthernet0/0
R4(config-if)# ip ospf priority 0
```

#### 3.4.d — Router ID

Le **Router ID** (RID) est un identifiant unique de 32 bits au format d'une adresse IPv4 (mais ce n'est pas forcément une adresse IP routable). Chaque routeur OSPF doit avoir un RID unique dans le domaine OSPF.

Le routeur choisit son RID selon cette hiérarchie :

1. **Commande `router-id`** explicite (priorité maximale)
2. **Adresse IP la plus élevée** parmi les interfaces loopback actives
3. **Adresse IP la plus élevée** parmi les interfaces physiques actives

```cisco
! Méthode recommandée : configuration explicite
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
```

Si le Router ID change (modification de la commande ou changement d'interface), le changement ne prend effet qu'après un **redémarrage du processus OSPF** :

```cisco
R1# clear ip ospf process
Reset ALL OSPF processes? [no]: yes
```

#### Calcul du coût OSPF

La métrique OSPF est le **coût**, calculé par la formule :

```
Coût = Reference Bandwidth / Interface Bandwidth
```

La reference bandwidth par défaut est **100 Mbps** (10^8 bps).

| Interface | Bande passante | Coût par défaut |
|-----------|---------------|-----------------|
| Serial (T1) | 1.544 Mbps | 64 |
| FastEthernet | 100 Mbps | 1 |
| GigabitEthernet | 1 Gbps | 1 |
| 10 GigabitEthernet | 10 Gbps | 1 |

Le problème saute aux yeux : FastEthernet, GigabitEthernet et 10G ont tous un coût de 1 ! OSPF ne peut pas distinguer les liens rapides. La solution :

```cisco
! Modifier la reference bandwidth (recommandé : 10000 pour supporter 10G)
R1(config-router)# auto-cost reference-bandwidth 10000

! Résultat :
! 10G     → coût 1
! 1G      → coût 10
! 100 Mbps→ coût 100
! 10 Mbps → coût 1000
```

Cette commande doit être configurée de manière **identique sur tous les routeurs** du domaine OSPF pour que les calculs de chemin soient cohérents.

#### Configuration OSPF complète

Voici une configuration OSPF single-area typique :

```cisco
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# auto-cost reference-bandwidth 10000
R1(config-router)# network 10.1.1.0 0.0.0.255 area 0
R1(config-router)# network 10.1.12.0 0.0.0.3 area 0
R1(config-router)# passive-interface GigabitEthernet0/0
R1(config-router)# default-information originate
```

Décortiquons chaque commande :

| Commande | Rôle |
|----------|------|
| `router ospf 1` | Active OSPF, processus 1 (local au routeur, pas transmis aux voisins) |
| `router-id 1.1.1.1` | Identifiant unique — utiliser une convention comme X.X.X.X pour RX |
| `auto-cost reference-bandwidth 10000` | Adapte les coûts aux liens modernes |
| `network 10.1.1.0 0.0.0.255 area 0` | Active OSPF sur les interfaces dont l'IP matche, dans l'area 0 |
| `passive-interface Gi0/0` | Empêche l'envoi de Hello sur cette interface (LAN, pas de voisin OSPF) |
| `default-information originate` | Annonce la route par défaut aux voisins OSPF |

La commande `network` utilise un **wildcard mask** (inverse du masque de sous-réseau) :
- 0.0.0.255 = /24 (les 24 premiers bits doivent matcher exactement)
- 0.0.0.3 = /30
- 0.0.0.0 = /32 (une seule adresse)

Alternative plus explicite (IOS 15+) — activer OSPF directement sur l'interface :
```cisco
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip ospf 1 area 0
```

#### passive-interface

Une interface **passive** participe à OSPF (son réseau est annoncé aux voisins) mais n'envoie pas de Hello et ne forme pas d'adjacence. C'est essentiel pour :
- Les interfaces LAN connectées uniquement à des PCs/serveurs (pas de voisin OSPF)
- Les interfaces loopback
- Réduire le trafic OSPF inutile et la surface d'attaque

```cisco
! Rendre toutes les interfaces passives par défaut, puis activer les exceptions
R1(config-router)# passive-interface default
R1(config-router)# no passive-interface GigabitEthernet0/1
R1(config-router)# no passive-interface GigabitEthernet0/2
```

Cette approche « deny all, permit specific » est une bonne pratique de sécurité OSPF.

### Mise en pratique CLI — Vérification OSPF

Les commandes de vérification OSPF sont tout aussi importantes que la configuration. L'examen teste intensivement l'interprétation de ces outputs.

```cisco
! Voir les voisins OSPF
R1# show ip ospf neighbor
```

**Output :**
```
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/DR         00:00:36    10.1.12.2       GigabitEthernet0/1
3.3.3.3           1   FULL/BDR        00:00:33    10.1.13.2       GigabitEthernet0/2
4.4.4.4           1   2WAY/DROTHER    00:00:38    10.1.14.2       GigabitEthernet0/3
```

**Interprétation** :
- **Neighbor ID** : Router ID du voisin (pas son adresse IP !)
- **Pri** : priorité OSPF du voisin
- **State** : état de l'adjacence / rôle du voisin
  - `FULL/DR` = adjacence complète, le voisin est DR
  - `FULL/BDR` = adjacence complète, le voisin est BDR
  - `2WAY/DROTHER` = normal sur broadcast entre DROthers (pas FULL entre eux)
- **Dead Time** : temps restant avant de déclarer le voisin mort (décompte)
- **Address** : adresse IP de l'interface du voisin
- **Interface** : interface locale vers ce voisin

```cisco
! Voir les détails OSPF par interface
R1# show ip ospf interface GigabitEthernet0/1
```

**Output :**
```
GigabitEthernet0/1 is up, line protocol is up
  Internet Address 10.1.12.1/30, Area 0, Attached via Network Statement
  Process ID 1, Router ID 1.1.1.1, Network Type BROADCAST, Cost: 10
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           10        no          no            Base
  Transmit Delay is 1 sec, State DR, Priority 1
  Designated Router (ID) 1.1.1.1, Interface address 10.1.12.1
  Backup Designated Router (ID) 2.2.2.2, Interface address 10.1.12.2
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:04
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/2/2, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2  (Backup Designated Router)
  Suppress hello for 0 neighbor(s)
```

**Champs clés** :
- **Network Type BROADCAST** : le type de réseau OSPF
- **Cost: 10** : le coût de cette interface
- **State DR** : ce routeur est DR sur ce segment
- **Hello 10, Dead 40** : les timers (doivent matcher avec le voisin)

```cisco
! Voir les routes OSPF dans la table de routage
R1# show ip route ospf
```

**Output :**
```
Codes: L - local, C - connected, S - static, O - OSPF, ...

      10.0.0.0/8 is variably subnetted, 8 subnets, 3 masks
O        10.1.2.0/24 [110/20] via 10.1.12.2, 00:45:12, GigabitEthernet0/1
O        10.1.3.0/24 [110/30] via 10.1.12.2, 00:45:12, GigabitEthernet0/1
O        10.1.23.0/30 [110/20] via 10.1.12.2, 00:45:12, GigabitEthernet0/1
```

```cisco
! Voir le protocole OSPF global
R1# show ip protocols
```

**Output :**
```
*** IP Routing is NSF aware ***

Routing Protocol is "ospf 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Router ID 1.1.1.1
  Number of areas in this router is 1. 1 normal 0 stub 0 nssa
  Maximum path: 4
  Routing for Networks:
    10.1.1.0 0.0.0.255 area 0
    10.1.12.0 0.0.0.3 area 0
  Passive Interface(s):
    GigabitEthernet0/0
  Routing Information Sources:
    Gateway         Distance      Last Update
    2.2.2.2              110      00:45:12
    3.3.3.3              110      00:44:58
  Distance: (default is 110)
```

**Champs clés** :
- **Router ID** : confirme le RID actif
- **Routing for Networks** : quelles commandes network sont configurées
- **Passive Interface(s)** : interfaces qui n'envoient pas de Hello
- **Routing Information Sources** : voisins qui nous envoient des routes

### Point exam

> **Piège courant #1** : l'élection DR/BDR est **non-préemptive**. Un routeur avec une priorité plus élevée qui rejoint le réseau après l'élection ne deviendra PAS DR automatiquement. C'est le piège le plus fréquent sur OSPF à l'examen.
>
> **Piège courant #2** : le numéro de processus OSPF (`router ospf 1`) est **local** au routeur. R1 peut utiliser le processus 1 et R2 le processus 10 — ils formeront quand même une adjacence. En revanche, l'**area ID** DOIT correspondre.
>
> **Piège courant #3** : la commande `network` utilise un **wildcard mask**, pas un masque de sous-réseau. `network 10.1.1.0 0.0.0.255 area 0` est correct. `network 10.1.1.0 255.255.255.0 area 0` activerait OSPF sur des interfaces inattendues.
>
> **À retenir** : si `show ip ospf neighbor` montre un voisin bloqué en **EXSTART** ou **EXCHANGE**, c'est presque toujours un problème de **MTU mismatch**. Si bloqué en **INIT**, vérifiez que le Hello/Dead interval et l'area correspondent.

### Exercice 3.4a — Configuration OSPF de base

**Contexte** : vous déployez OSPF sur un réseau de 3 routeurs pour l'entreprise DataFlow :

```
     LAN-R1                                LAN-R3
  10.10.1.0/24     10.10.12.0/30      10.10.3.0/24
        │               │                    │
      [R1]──────Gi0/1──[lien]──Gi0/0──────[R2]──────Gi0/1──[lien]──Gi0/0──[R3]
     Gi0/0        .1          .2       Gi0/2        .1            .2      Gi0/1
   10.10.1.1                        10.10.23.0/30              10.10.3.1
                                         │
                                    LAN-R2: 10.10.2.0/24
                                    (Gi0/1 : 10.10.2.1)
```

**Consigne** : configurez OSPF (processus 1, area 0) sur les 3 routeurs avec :
- Router ID explicite (1.1.1.1, 2.2.2.2, 3.3.3.3)
- Toutes les interfaces participent à OSPF
- Les interfaces LAN sont passives
- Reference bandwidth à 10000

**Indice** : <details><summary>Voir l'indice</summary>Utilisez `passive-interface default` puis `no passive-interface` sur les interfaces inter-routeurs.</details>

<details>
<summary>Solution</summary>

```cisco
! === R1 ===
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# auto-cost reference-bandwidth 10000
R1(config-router)# network 10.10.1.0 0.0.0.255 area 0
R1(config-router)# network 10.10.12.0 0.0.0.3 area 0
R1(config-router)# passive-interface default
R1(config-router)# no passive-interface GigabitEthernet0/1

! === R2 ===
R2(config)# router ospf 1
R2(config-router)# router-id 2.2.2.2
R2(config-router)# auto-cost reference-bandwidth 10000
R2(config-router)# network 10.10.2.0 0.0.0.255 area 0
R2(config-router)# network 10.10.12.0 0.0.0.3 area 0
R2(config-router)# network 10.10.23.0 0.0.0.3 area 0
R2(config-router)# passive-interface default
R2(config-router)# no passive-interface GigabitEthernet0/0
R2(config-router)# no passive-interface GigabitEthernet0/2

! === R3 ===
R3(config)# router ospf 1
R3(config-router)# router-id 3.3.3.3
R3(config-router)# auto-cost reference-bandwidth 10000
R3(config-router)# network 10.10.3.0 0.0.0.255 area 0
R3(config-router)# network 10.10.23.0 0.0.0.3 area 0
R3(config-router)# passive-interface default
R3(config-router)# no passive-interface GigabitEthernet0/0
```

**Vérification :**
```cisco
R2# show ip ospf neighbor
Neighbor ID     Pri   State           Dead Time   Address         Interface
1.1.1.1           1   FULL/ -         00:00:36    10.10.12.1      GigabitEthernet0/0
3.3.3.3           1   FULL/ -         00:00:33    10.10.23.2      GigabitEthernet0/2

R2# show ip route ospf
O     10.10.1.0/24 [110/10] via 10.10.12.1, 00:02:15, GigabitEthernet0/0
O     10.10.3.0/24 [110/10] via 10.10.23.2, 00:02:10, GigabitEthernet0/2
```

**Explication** : le `FULL/ -` (sans DR/BDR) indique que les liens sont de type point-to-point (/30 avec 2 routeurs). Si c'étaient des segments broadcast avec plusieurs routeurs, on verrait `FULL/DR`, `FULL/BDR` ou `2WAY/DROTHER`. Les routes OSPF vers les LANs distants ont un coût de 10 (avec reference-bandwidth 10000 et interfaces GigabitEthernet).

</details>

### Exercice 3.4b — Manipulation DR/BDR

**Contexte** : quatre routeurs (R1 à R4) partagent un segment Ethernet (10.10.100.0/24). Les Router ID sont 1.1.1.1, 2.2.2.2, 3.3.3.3, 4.4.4.4. Tous ont la priorité par défaut (1).

**Consigne** :
1. Sans modifier la priorité, quel routeur sera élu DR ? BDR ?
2. Que devez-vous configurer pour que R2 devienne DR et R3 devienne BDR ?
3. Que devez-vous configurer pour que R4 ne puisse jamais devenir DR ou BDR ?
4. Si R2 est DR et que R5 (RID 5.5.5.5, priorité 255) rejoint le réseau, que se passe-t-il ?

**Indice** : <details><summary>Voir l'indice</summary>Priorité la plus haute → DR. En cas d'égalité → Router ID le plus haut. L'élection est non-préemptive.</details>

<details>
<summary>Solution</summary>

1. **DR = R4** (RID 4.4.4.4, le plus élevé), **BDR = R3** (RID 3.3.3.3). Avec des priorités identiques (1), c'est le Router ID le plus élevé qui l'emporte.

2. Configuration :
```cisco
R2(config-if)# ip ospf priority 255
R3(config-if)# ip ospf priority 200
! Puis redémarrer le processus OSPF sur tous les routeurs
R1# clear ip ospf process
```

3. Configuration :
```cisco
R4(config-if)# ip ospf priority 0
```
Un routeur avec une priorité de 0 ne participe jamais à l'élection DR/BDR.

4. **Rien ne change**. L'élection DR/BDR est non-préemptive. R2 reste DR, R3 reste BDR. R5 devient DROther malgré sa priorité supérieure. Pour que R5 devienne DR, il faudrait forcer une nouvelle élection (`clear ip ospf process` sur tous les routeurs), ce qui causerait une interruption temporaire du routage.

</details>

### Exercice 3.4c — Troubleshooting adjacence OSPF

**Contexte** : R1 et R2 sont connectés via un lien Ethernet. OSPF est configuré sur les deux, mais `show ip ospf neighbor` sur R1 ne montre aucun voisin.

Voici les configurations :

```
! R1
interface GigabitEthernet0/0
 ip address 10.1.1.1 255.255.255.0
 ip ospf 1 area 0
 ip ospf hello-interval 5

! R2
interface GigabitEthernet0/0
 ip address 10.1.1.2 255.255.255.0
 ip ospf 1 area 1
```

**Consigne** : identifiez toutes les raisons pour lesquelles l'adjacence ne se forme pas et proposez les corrections.

**Indice** : <details><summary>Voir l'indice</summary>Revoyez les 7 conditions d'adjacence. Comparez les paramètres des deux routeurs.</details>

<details>
<summary>Solution</summary>

**Problème 1 — Area mismatch** : R1 est dans l'area 0, R2 dans l'area 1. Les deux interfaces du même lien doivent être dans la même area.

**Problème 2 — Hello interval mismatch** : R1 a un hello-interval de 5 secondes (dead = 20 par défaut, soit 4× hello). R2 utilise les valeurs par défaut (hello = 10, dead = 40). Les timers doivent correspondre.

**Corrections :**
```cisco
! Sur R2 — corriger l'area
R2(config)# interface GigabitEthernet0/0
R2(config-if)# no ip ospf 1 area 1
R2(config-if)# ip ospf 1 area 0

! Option A : aligner les timers sur R2
R2(config-if)# ip ospf hello-interval 5

! Option B : remettre les timers par défaut sur R1
R1(config)# interface GigabitEthernet0/0
R1(config-if)# no ip ospf hello-interval 5
```

**Commande de diagnostic clé :**
```cisco
R1# show ip ospf interface GigabitEthernet0/0
! Vérifie : area, timers, network type, état
```

</details>

### Exercice 3.4d — Calcul de coût OSPF

**Contexte** : la topologie suivante avec reference-bandwidth par défaut (100 Mbps) :

```
[R1]──── FastEthernet ────[R2]──── GigabitEthernet ────[R3]
         100 Mbps                    1 Gbps

[R1]──── Serial (T1) ────[R4]──── FastEthernet ────[R3]
         1.544 Mbps                  100 Mbps
```

**Consigne** : calculez le coût total de chaque chemin R1 → R3 et déterminez lequel OSPF choisira. Puis recalculez avec `auto-cost reference-bandwidth 10000`.

<details>
<summary>Solution</summary>

**Avec reference-bandwidth par défaut (100 Mbps)** :
- Chemin via R2 : coût FastEth (100/100 = 1) + coût GigE (100/1000 = 0.1 → arrondi à **1**) = **2**
- Chemin via R4 : coût Serial (100/1.544 = **64**) + coût FastEth (100/100 = **1**) = **65**
- OSPF choisit **via R2** (coût 2 < 65)

Le problème : FastEthernet et GigabitEthernet ont le même coût (1). OSPF ne voit pas la différence.

**Avec reference-bandwidth 10000 (10 Gbps)** :
- Chemin via R2 : coût FastEth (10000/100 = **100**) + coût GigE (10000/1000 = **10**) = **110**
- Chemin via R4 : coût Serial (10000/1.544 = **6476**) + coût FastEth (10000/100 = **100**) = **6576**
- OSPF choisit toujours **via R2** (coût 110 < 6576), mais maintenant il peut distinguer FastEth de GigE

</details>

### Voir aussi

- Topic 3.1 dans ce module (relation : les routes OSPF apparaissent avec le code O dans la table)
- Topic 3.2 dans ce module (relation : AD 110 pour OSPF, métrique = coût)
- Topic 2.1 dans Module 2 (relation : inter-VLAN routing combiné avec OSPF dans le Lab 3.4)
- Topic 1.6 dans Module 1 (relation : wildcard masks pour la commande network)

---

## 3.5 — Protocoles de redondance du premier saut (FHRP)

> **Exam topic 3.5** : *Describe* — the purpose, functions, and concepts of first hop redundancy protocols
> **Niveau** : Describe

### Contexte

Imaginez un bureau de 200 employés. Tous leurs PCs ont comme passerelle par défaut l'adresse 192.168.1.1, configurée sur le routeur R1. Un mardi matin, R1 tombe en panne. Résultat : plus personne ne peut accéder à Internet ni aux autres sous-réseaux, même si un second routeur R2 (192.168.1.2) est parfaitement fonctionnel sur le même segment. Pourquoi ? Parce que les PCs ne connaissent qu'une seule gateway — celle qui est configurée en dur dans leurs paramètres réseau.

Les protocoles FHRP (First Hop Redundancy Protocol) résolvent ce problème en créant une **adresse IP virtuelle** partagée entre plusieurs routeurs. Les PCs pointent vers cette adresse virtuelle, et les routeurs se coordonnent pour décider lequel répond.

### Théorie

Le principe est commun aux trois protocoles FHRP : deux routeurs (ou plus) partagent une **adresse IP virtuelle** et une **adresse MAC virtuelle**. Les hôtes du LAN configurent cette adresse virtuelle comme passerelle par défaut. Si le routeur actif tombe, un routeur de secours prend le relais — de manière transparente pour les clients.

```
                         IP virtuelle : 192.168.1.254
                         MAC virtuelle : 0000.0c07.ac01
                                │
                 ┌──────────────┼──────────────┐
                 │              │              │
              [R1]           [SW1]          [R2]
           192.168.1.1                  192.168.1.2
             ACTIF                       STANDBY
                 │                          │
                 └──── vers le réseau ──────┘

   [PC1]  [PC2]  [PC3]  ... tous configurés avec gateway 192.168.1.254
```

Si R1 tombe, R2 détecte l'absence de Hello de R1, prend le rôle actif et commence à répondre aux requêtes ARP pour l'IP virtuelle. Les PCs continuent d'envoyer leurs paquets à 192.168.1.254 — sans aucune reconfiguration.

#### Tableau comparatif des protocoles FHRP

| Caractéristique | HSRP (v2) | VRRP (v3) | GLBP |
|-----------------|-----------|-----------|------|
| **Standard** | Propriétaire Cisco | IETF (RFC 5798) | Propriétaire Cisco |
| **Rôles** | Active / Standby / Listen | Master / Backup | AVG / AVF |
| **IP virtuelle** | Différente des IPs réelles | Peut être l'IP d'un routeur | Différente des IPs réelles |
| **MAC virtuelle** | 0000.0c9f.fXXX (v2) | 0000.5e00.01XX | 0007.b400.XXYY |
| **Multicast** | 224.0.0.102 (v2) | 224.0.0.18 | 224.0.0.102 |
| **Load balancing** | Non (1 actif) | Non (1 master) | **Oui** (natif) |
| **Préemption** | Désactivée par défaut | Activée par défaut | Activée par défaut |
| **Timers par défaut** | Hello 3s, Hold 10s | Hello 1s, Dead 3s | Hello 3s, Hold 10s |
| **Scope examen CCNA** | Concepts seulement | Concepts seulement | Concepts seulement |

#### HSRP (Hot Standby Router Protocol)

HSRP est le protocole FHRP le plus courant dans les environnements Cisco. Le routeur avec la **priorité la plus élevée** (par défaut 100) devient **Active**. Le deuxième devient **Standby**. Les autres sont en état **Listen** (ils attendent en cas de double panne).

La **préemption** est désactivée par défaut en HSRP : si le routeur Active tombe puis revient, il ne reprend pas automatiquement le rôle Active. Il faut explicitement activer `standby preempt` pour ce comportement.

#### VRRP (Virtual Router Redundancy Protocol)

VRRP est le standard ouvert (IETF). Son fonctionnement est très similaire à HSRP, avec une particularité : le routeur **Master** peut utiliser sa propre adresse IP réelle comme IP virtuelle. La préemption est activée par défaut.

#### GLBP (Gateway Load Balancing Protocol)

GLBP se distingue par sa capacité de **load balancing natif**. Au lieu d'avoir un seul routeur actif, GLBP distribue le trafic entre plusieurs routeurs en assignant des MAC virtuelles différentes à chaque routeur. L'AVG (Active Virtual Gateway) répond aux requêtes ARP en alternant les MAC virtuelles, répartissant ainsi la charge.

### Mise en pratique CLI

Bien que l'examen CCNA ne teste pas la configuration FHRP, comprendre l'output aide à visualiser les concepts :

```cisco
R1# show standby brief
                     P indicates configured to preempt.
                     |
Interface   Grp  Pri P State   Active          Standby         Virtual IP
Gi0/0       1    110 P Active  local           192.168.1.2     192.168.1.254
```

**Interprétation** :
- **Grp 1** : groupe HSRP 1
- **Pri 110** : priorité configurée
- **P** : préemption activée
- **State Active** : ce routeur est le routeur actif
- **Virtual IP 192.168.1.254** : l'adresse que les hôtes utilisent comme gateway

### Point exam

> **Piège courant** : confondre les rôles entre HSRP et VRRP. HSRP utilise Active/Standby, VRRP utilise Master/Backup. L'examen peut mélanger les termes dans les réponses pour piéger les candidats inattentifs.
>
> **À retenir** : seul GLBP fait du load balancing natif. Si une question demande « quel FHRP permet de répartir la charge entre plusieurs routeurs sans configuration supplémentaire ? », la réponse est GLBP. HSRP et VRRP ne supportent qu'un seul routeur actif/master à la fois par groupe.

### Exercice 3.5 — Identifier les rôles FHRP

**Contexte** : l'entreprise LogiNet utilise HSRP entre R1 et R2 pour le LAN 10.10.50.0/24. Configuration :
- R1 : priorité 110, preempt activé, IP 10.10.50.1
- R2 : priorité 100, preempt désactivé, IP 10.10.50.2
- IP virtuelle : 10.10.50.254

**Consigne** :
1. Quel routeur est Active ? Pourquoi ?
2. R1 redémarre (panne puis retour). Quel routeur est Active après le redémarrage de R1 ?
3. Si on désactive preempt sur R1, que change la réponse à la question 2 ?
4. Comment les 50 PCs du LAN doivent-ils être configurés (gateway) ?

<details>
<summary>Solution</summary>

1. **R1 est Active** car sa priorité (110) est supérieure à celle de R2 (100).

2. **R1 redevient Active**. Pendant la panne de R1, R2 prend le rôle Active. Quand R1 revient, sa préemption est activée et sa priorité (110) est supérieure à celle de R2 (100), donc R1 reprend le rôle Active.

3. **R2 reste Active**. Sans préemption sur R1, même si R1 a une priorité plus élevée, il ne peut pas « reprendre » le rôle Active à R2 qui l'a obtenu pendant la panne. R1 passe en Standby.

4. Tous les PCs doivent avoir comme gateway **10.10.50.254** (l'adresse IP virtuelle). Pas 10.10.50.1 ni 10.10.50.2 — sinon on perd le bénéfice de la redondance.

</details>

### Voir aussi

- Topic 1.1.a dans Module 1 (relation : rôle des routeurs, incluant la redondance)
- Topic 3.4 dans ce module (relation : OSPF gère le routage entre réseaux, FHRP gère la redondance de la gateway locale)
- Topic 2.5 dans Module 2 (relation : STP gère la redondance L2, FHRP gère la redondance L3)

---

## 3.6 — Gestion réseau cloud

> **Exam topic 3.6** : *Describe* — the purpose of cloud network management *(NOUVEAU v1.1)*
> **Niveau** : Describe

### Contexte

Traditionnellement, chaque équipement réseau est configuré individuellement en CLI — connexion SSH, commandes ligne par ligne, fichier de configuration sauvegardé localement. Pour 10 switches, c'est gérable. Pour 500 équipements répartis sur 20 sites, c'est un cauchemar opérationnel. La gestion réseau cloud propose un changement radical : un tableau de bord centralisé, accessible depuis n'importe où, qui gère l'ensemble du parc réseau.

### Théorie

La gestion réseau cloud (cloud network management) consiste à déporter le plan de gestion des équipements vers une plateforme hébergée dans le cloud. Les équipements réseau se connectent à cette plateforme via Internet (tunnel sécurisé), et l'administrateur gère tout depuis un navigateur web.

#### Modèle traditionnel vs cloud-managed

| Aspect | Gestion traditionnelle (CLI) | Gestion cloud |
|--------|------------------------------|---------------|
| **Interface** | CLI (SSH/console) par équipement | Dashboard web centralisé |
| **Déploiement** | Configuration manuelle, un par un | Zero-touch provisioning (ZTP) |
| **Mises à jour firmware** | Téléchargement manuel, reboot planifié | Push automatique depuis le cloud |
| **Monitoring** | SNMP + Syslog + outils tiers | Dashboard intégré, alertes temps réel |
| **Accès** | VPN ou accès réseau direct requis | Navigateur + identifiants, de n'importe où |
| **Scalabilité** | Linéaire (1 admin → N équipements) | Exponentielle (1 admin → N×10 équipements) |
| **Coût** | CAPEX (licence IOS) | OPEX (abonnement annuel/par device) |
| **Dépendance** | Autonome (fonctionne hors-ligne) | Nécessite une connexion Internet |

#### Plateformes Cisco de gestion cloud

**Cisco Meraki** est l'exemple phare de gestion 100% cloud. Les équipements Meraki (switches, AP, routeurs, firewalls, caméras) se connectent au cloud Meraki et sont entièrement configurés depuis le dashboard web. Aucune CLI n'est nécessaire — ni même disponible sur la plupart des modèles.

**Cisco DNA Center** (rebaptisé Catalyst Center) est une plateforme on-premises ou cloud qui gère les équipements Catalyst traditionnels. Elle offre une approche hybride : les équipements conservent leur CLI IOS, mais DNA Center fournit un plan de gestion centralisé avec automatisation, assurance réseau et analytique.

**Cisco SD-WAN (Viptela)** gère les routeurs WAN depuis vManage, un contrôleur cloud. Les politiques de routage et de sécurité sont définies centralement et poussées vers les routeurs des succursales.

#### Avantages de la gestion cloud

1. **Déploiement simplifié** : un nouvel équipement se connecte à Internet, contacte le cloud, télécharge sa configuration → opérationnel sans intervention sur site (Zero-Touch Provisioning)
2. **Visibilité centralisée** : topologie, santé des liens, utilisation des clients, le tout dans un seul dashboard
3. **Mises à jour automatisées** : le cloud pousse les patches de sécurité et les nouvelles fonctionnalités
4. **Conformité et reporting** : le cloud maintient un historique de configuration et détecte les dérives
5. **Intelligence réseau** : analyse du trafic par ML/AI pour détecter les anomalies (voir topic 5.11)

#### Limites et considérations

- **Dépendance Internet** : si le lien Internet tombe, les équipements continuent de fonctionner avec leur dernière configuration, mais l'administrateur perd la visibilité et le contrôle à distance
- **Confidentialité des données** : les données de télémétrie transitent par le cloud — certaines organisations (défense, santé) peuvent avoir des contraintes réglementaires
- **Coût récurrent** : modèle d'abonnement vs achat de licence perpétuelle
- **Vendor lock-in** : les plateformes cloud sont généralement propriétaires

### Mise en pratique CLI

La gestion cloud n'implique pas de commandes CLI traditionnelles, mais un routeur peut être vérifié pour sa connexion au contrôleur :

```cisco
! Vérifier la connexion au DNA Center (Catalyst Center)
R1# show platform software dnac
DNAC Connection Status: Connected
DNAC IP: 10.100.1.50
Connection Established: 2025-12-10 08:32:15

! Vérifier le mode de gestion sur un switch Catalyst
SW1# show run | include transport
transport https
```

Sur un équipement Meraki, il n'y a pas de CLI — tout passe par le dashboard. L'étudiant peut explorer l'interface Meraki via le **Meraki Dashboard Demo** accessible gratuitement en ligne.

### Point exam

> **Piège courant** : penser que la gestion cloud remplace complètement la CLI. En réalité, DNA Center et les outils cloud **coexistent** avec la CLI sur les équipements Catalyst. Seul Meraki est 100% cloud-managed sans CLI. L'examen peut demander de distinguer ces deux approches.
>
> **À retenir** : le Zero-Touch Provisioning (ZTP) est l'un des avantages clés de la gestion cloud. L'équipement neuf se connecte à Internet, contacte le cloud, reçoit sa configuration automatiquement. C'est le scénario de déploiement en succursale que l'examen teste.

### Exercice 3.6 — Gestion traditionnelle vs cloud

**Contexte** : l'entreprise GlobeTech possède 30 sites avec chacun 2 switches, 3 AP et 1 routeur WAN. L'équipe réseau de 3 personnes est basée au siège.

**Consigne** : pour chaque scénario, indiquez si la gestion traditionnelle ou cloud est plus adaptée et justifiez :
1. Déployer 5 nouveaux sites en 2 semaines, sans envoyer de technicien réseau sur place
2. Débugger un problème OSPF complexe avec des timers personnalisés
3. Vérifier à 22h depuis chez vous que tous les AP des 30 sites sont opérationnels
4. Appliquer une mise à jour de sécurité critique sur les 60 switches en une nuit

<details>
<summary>Solution</summary>

1. **Cloud** — le Zero-Touch Provisioning permet de pré-configurer les équipements dans le dashboard, les expédier sur site, et laisser un employé non technique les brancher. La configuration se télécharge automatiquement.

2. **CLI traditionnelle** — un debug OSPF nécessite des commandes de diagnostic avancées (`debug ip ospf adj`, `show ip ospf interface`, modification de timers). La CLI offre un contrôle granulaire que les dashboards cloud ne fournissent pas toujours.

3. **Cloud** — un dashboard accessible via navigateur, de n'importe où, montre l'état de tous les AP en temps réel avec alertes. En CLI traditionnel, il faudrait un VPN vers chaque site puis vérifier chaque AP individuellement.

4. **Cloud** — la mise à jour centralisée via le dashboard permet de planifier le déploiement sur les 60 switches en une seule opération, avec rollback automatique en cas d'échec. En CLI, il faudrait se connecter à chaque switch et copier manuellement le firmware.

</details>

### Voir aussi

- Topic 1.2.f dans Module 1 (relation : architectures on-premises vs cloud)
- Topic 1.1.e dans Module 1 (relation : rôle des contrôleurs — DNA Center et WLC)
- Topic 2.6 dans Module 2 (relation : architecture wireless cloud-managed — Meraki)
- Topic 6.2 dans Module 6 (relation : comparaison réseau traditionnel vs controller-based)
- Topic 6.4 dans Module 6 (relation : DNA Center en détail)

---

## Labs Module 3

### Lab 3.1 — Routes statiques IPv4/IPv6

**Topologie :**
```
                    10.10.12.0/30         10.10.23.0/30         10.10.34.0/30
  LAN-A ────[R1]════════════════[R2]════════════════[R3]════════════════[R4]──── LAN-D
10.10.1.0/24  Gi0/0  Gi0/1  Gi0/0  Gi0/1  Gi0/0  Gi0/1  Gi0/0  Gi0/1
               .1     .1     .2     .1     .2     .1     .2     .1
                              │                                  │
                         LAN-B: 10.10.2.0/24               LAN-D: 10.10.4.0/24
                         (Gi0/2 : 10.10.2.1)

  IPv6 :
  LAN-A : 2001:DB8:A:1::/64     Lien R1-R2 : 2001:DB8:A:12::/64
  LAN-B : 2001:DB8:A:2::/64     Lien R2-R3 : 2001:DB8:A:23::/64
  LAN-D : 2001:DB8:A:4::/64     Lien R3-R4 : 2001:DB8:A:34::/64
```

**Tableau d'adressage :**

| Équipement | Interface | IPv4 | Masque | IPv6 | Gateway |
|------------|-----------|------|--------|------|---------|
| R1 | Gi0/0 | 10.10.1.1 | /24 | 2001:DB8:A:1::1/64 | — |
| R1 | Gi0/1 | 10.10.12.1 | /30 | 2001:DB8:A:12::1/64 | — |
| R2 | Gi0/0 | 10.10.12.2 | /30 | 2001:DB8:A:12::2/64 | — |
| R2 | Gi0/1 | 10.10.23.1 | /30 | 2001:DB8:A:23::1/64 | — |
| R2 | Gi0/2 | 10.10.2.1 | /24 | 2001:DB8:A:2::1/64 | — |
| R3 | Gi0/0 | 10.10.23.2 | /30 | 2001:DB8:A:23::2/64 | — |
| R3 | Gi0/1 | 10.10.34.1 | /30 | 2001:DB8:A:34::1/64 | — |
| R4 | Gi0/0 | 10.10.34.2 | /30 | 2001:DB8:A:34::2/64 | — |
| R4 | Gi0/1 | 10.10.4.1 | /24 | 2001:DB8:A:4::1/64 | — |
| PC-A | NIC | 10.10.1.10 | /24 | Auto (SLAAC) | 10.10.1.1 |
| PC-D | NIC | 10.10.4.10 | /24 | Auto (SLAAC) | 10.10.4.1 |

**Objectifs :**
1. Configurer les interfaces et l'adressage IP sur les 4 routeurs
2. Configurer des routes statiques réseau pour la connectivité complète
3. Configurer une route par défaut sur R1 et R4 (stub routers)
4. Configurer les routes IPv6 équivalentes
5. Vérifier la connectivité de bout en bout

**Configuration de départ :**
```cisco
! === Sur chaque routeur — interfaces et adressage ===
! (Exemple pour R1)
R1(config)# hostname R1
R1(config)# no ip domain-lookup
R1(config)# ipv6 unicast-routing
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip address 10.10.1.1 255.255.255.0
R1(config-if)# ipv6 address 2001:DB8:A:1::1/64
R1(config-if)# no shutdown
R1(config-if)# exit
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip address 10.10.12.1 255.255.255.252
R1(config-if)# ipv6 address 2001:DB8:A:12::1/64
R1(config-if)# no shutdown
```

**Étapes :**

1. **Configurer l'adressage sur R2, R3, R4** (reprendre le même modèle que R1)

2. **Configurer les routes statiques IPv4**
   ```cisco
   ! R1 — stub router, default route suffit
   R1(config)# ip route 0.0.0.0 0.0.0.0 10.10.12.2

   ! R2 — routes vers LAN-A et LAN-D
   R2(config)# ip route 10.10.1.0 255.255.255.0 10.10.12.1
   R2(config)# ip route 10.10.4.0 255.255.255.0 10.10.23.2
   R2(config)# ip route 10.10.34.0 255.255.255.252 10.10.23.2

   ! R3 — routes vers LAN-A, LAN-B et LAN-D
   R3(config)# ip route 10.10.1.0 255.255.255.0 10.10.23.1
   R3(config)# ip route 10.10.2.0 255.255.255.0 10.10.23.1
   R3(config)# ip route 10.10.4.0 255.255.255.0 10.10.34.2
   R3(config)# ip route 10.10.12.0 255.255.255.252 10.10.23.1

   ! R4 — stub router, default route suffit
   R4(config)# ip route 0.0.0.0 0.0.0.0 10.10.34.1
   ```

3. **Configurer les routes statiques IPv6**
   ```cisco
   ! R1
   R1(config)# ipv6 route ::/0 2001:DB8:A:12::2

   ! R2
   R2(config)# ipv6 route 2001:DB8:A:1::/64 2001:DB8:A:12::1
   R2(config)# ipv6 route 2001:DB8:A:4::/64 2001:DB8:A:23::2
   R2(config)# ipv6 route 2001:DB8:A:34::/64 2001:DB8:A:23::2

   ! R3
   R3(config)# ipv6 route 2001:DB8:A:1::/64 2001:DB8:A:23::1
   R3(config)# ipv6 route 2001:DB8:A:2::/64 2001:DB8:A:23::1
   R3(config)# ipv6 route 2001:DB8:A:4::/64 2001:DB8:A:34::2
   R3(config)# ipv6 route 2001:DB8:A:12::/64 2001:DB8:A:23::1

   ! R4
   R4(config)# ipv6 route ::/0 2001:DB8:A:34::1
   ```

4. **Vérification**
   ```cisco
   R1# ping 10.10.4.10 source 10.10.1.1
   !!!!!

   R1# ping 2001:DB8:A:4::1 source 2001:DB8:A:1::1
   !!!!!

   R1# traceroute 10.10.4.10 source 10.10.1.1
   1  10.10.12.2    1 msec
   2  10.10.23.2    2 msec
   3  10.10.34.2    3 msec
   4  10.10.4.10    4 msec
   ```

**Vérification finale :**
```cisco
R2# show ip route static
S     10.10.1.0/24 [1/0] via 10.10.12.1
S     10.10.4.0/24 [1/0] via 10.10.23.2
S     10.10.34.0/30 [1/0] via 10.10.23.2

R2# show ipv6 route static
S   2001:DB8:A:1::/64 [1/0]
     via 2001:DB8:A:12::1
S   2001:DB8:A:4::/64 [1/0]
     via 2001:DB8:A:23::2
S   2001:DB8:A:34::/64 [1/0]
     via 2001:DB8:A:23::2
```

**Questions de validation :**
1. Pourquoi R1 et R4 utilisent-ils une route par défaut plutôt que des routes spécifiques ?
2. Que se passe-t-il si vous oubliez la route `10.10.12.0/30` sur R3 et que R4 fait un ping vers R1 avec l'adresse source de LAN-D ?
3. Combien de routes statiques faudrait-il au total si on ajoutait un 5e routeur ? Et avec OSPF ?

---

### Lab 3.2 — OSPF Single-Area : configuration de base

**Topologie :**
```
                         Area 0

  LAN-R1              10.10.12.0/30             LAN-R2
10.10.1.0/24    [R1]════════════════[R2]     10.10.2.0/24
  Gi0/0 (.1)    Gi0/1 (.1)    (.2) Gi0/0    Gi0/1 (.1)
                  │                   │
                  │   10.10.13.0/30   │   10.10.23.0/30
                  │       (.1)        │       (.1)
                  └────────[R3]───────┘
                       Gi0/0  Gi0/1
                        (.2)   (.2)
                         │
                    LAN-R3: 10.10.3.0/24
                    Gi0/2 (.1)
```

**Tableau d'adressage :**

| Équipement | Interface | Adresse IP | Masque |
|------------|-----------|-----------|--------|
| R1 | Gi0/0 | 10.10.1.1 | /24 |
| R1 | Gi0/1 | 10.10.12.1 | /30 |
| R1 | Gi0/2 | 10.10.13.1 | /30 |
| R2 | Gi0/0 | 10.10.12.2 | /30 |
| R2 | Gi0/1 | 10.10.2.1 | /24 |
| R2 | Gi0/2 | 10.10.23.1 | /30 |
| R3 | Gi0/0 | 10.10.13.2 | /30 |
| R3 | Gi0/1 | 10.10.23.2 | /30 |
| R3 | Gi0/2 | 10.10.3.1 | /24 |
| PC1 | NIC | 10.10.1.10 | /24 |
| PC2 | NIC | 10.10.2.10 | /24 |
| PC3 | NIC | 10.10.3.10 | /24 |

**Objectifs :**
1. Configurer OSPF single-area (area 0) sur les 3 routeurs
2. Définir les router-id explicitement
3. Configurer les passive-interfaces sur les LANs
4. Vérifier les adjacences et les routes apprises
5. Tester la convergence en désactivant un lien

**Étapes :**

1. **Configurer OSPF sur R1**
   ```cisco
   R1(config)# router ospf 1
   R1(config-router)# router-id 1.1.1.1
   R1(config-router)# auto-cost reference-bandwidth 10000
   R1(config-router)# network 10.10.1.0 0.0.0.255 area 0
   R1(config-router)# network 10.10.12.0 0.0.0.3 area 0
   R1(config-router)# network 10.10.13.0 0.0.0.3 area 0
   R1(config-router)# passive-interface GigabitEthernet0/0
   ```

2. **Configurer OSPF sur R2 et R3** (même logique, adapter les réseaux et RID)
   ```cisco
   ! R2
   R2(config)# router ospf 1
   R2(config-router)# router-id 2.2.2.2
   R2(config-router)# auto-cost reference-bandwidth 10000
   R2(config-router)# network 10.10.2.0 0.0.0.255 area 0
   R2(config-router)# network 10.10.12.0 0.0.0.3 area 0
   R2(config-router)# network 10.10.23.0 0.0.0.3 area 0
   R2(config-router)# passive-interface GigabitEthernet0/1

   ! R3
   R3(config)# router ospf 1
   R3(config-router)# router-id 3.3.3.3
   R3(config-router)# auto-cost reference-bandwidth 10000
   R3(config-router)# network 10.10.3.0 0.0.0.255 area 0
   R3(config-router)# network 10.10.13.0 0.0.0.3 area 0
   R3(config-router)# network 10.10.23.0 0.0.0.3 area 0
   R3(config-router)# passive-interface GigabitEthernet0/2
   ```

3. **Vérifier les adjacences**
   ```cisco
   R1# show ip ospf neighbor
   Neighbor ID     Pri   State           Dead Time   Address         Interface
   2.2.2.2           1   FULL/ -         00:00:36    10.10.12.2      GigabitEthernet0/1
   3.3.3.3           1   FULL/ -         00:00:33    10.10.13.2      GigabitEthernet0/2
   ```

4. **Vérifier les routes OSPF**
   ```cisco
   R1# show ip route ospf
   O     10.10.2.0/24 [110/10] via 10.10.12.2, 00:05:32, GigabitEthernet0/1
   O     10.10.3.0/24 [110/10] via 10.10.13.2, 00:05:28, GigabitEthernet0/2
   O     10.10.23.0/30 [110/20] via 10.10.12.2, 00:05:32, GigabitEthernet0/1
                        [110/20] via 10.10.13.2, 00:05:28, GigabitEthernet0/2
   ```
   Notez le **load balancing ECMP** vers 10.10.23.0/30 : deux chemins de coût égal (20).

5. **Tester la convergence** — Coupez le lien R1–R2 :
   ```cisco
   R1(config)# interface GigabitEthernet0/1
   R1(config-if)# shutdown
   ```
   Après ~40 secondes (Dead interval), vérifiez :
   ```cisco
   R1# show ip route ospf
   O     10.10.2.0/24 [110/20] via 10.10.13.2, 00:00:15, GigabitEthernet0/2
   O     10.10.3.0/24 [110/10] via 10.10.13.2, 00:05:28, GigabitEthernet0/2
   O     10.10.23.0/30 [110/20] via 10.10.13.2, 00:05:28, GigabitEthernet0/2
   ```
   OSPF a automatiquement recalculé le chemin vers LAN-R2 via R3. Le coût est passé de 10 à 20.

**Vérification finale :**
```cisco
R1# ping 10.10.2.10 source 10.10.1.1
!!!!!

R1# show ip protocols | section ospf
Routing Protocol is "ospf 1"
  Router ID 1.1.1.1
  ...
```

**Questions de validation :**
1. Pourquoi la route vers 10.10.23.0/30 a-t-elle deux next hops dans l'état initial ?
2. Combien de temps faut-il pour que R1 détecte la panne du lien R1–R2 ? Pourquoi ?
3. Si vous ajoutiez un 4e routeur, combien de routes statiques faudrait-il par rapport à OSPF ?

---

### Lab 3.3 — OSPF : DR/BDR et types de réseau

**Topologie :**
```
              Segment broadcast : 10.10.100.0/24

      [R1]─────────────[SW1]─────────────[R2]
    Gi0/0 (.1)           │              Gi0/0 (.2)
    Prio: 200            │              Prio: 100
                         │
      [R3]───────────────┘──────────────[R4]
    Gi0/0 (.3)                        Gi0/0 (.4)
    Prio: 50                          Prio: 0

              Lien point-to-point : 10.10.50.0/30

      [R1]════════════════════════════[R2]
    Gi0/1 (.1)                      Gi0/1 (.2)
```

**Tableau d'adressage :**

| Équipement | Interface | Adresse IP | Réseau |
|------------|-----------|-----------|--------|
| R1 | Gi0/0 | 10.10.100.1 | /24 (broadcast) |
| R1 | Gi0/1 | 10.10.50.1 | /30 (point-to-point) |
| R2 | Gi0/0 | 10.10.100.2 | /24 (broadcast) |
| R2 | Gi0/1 | 10.10.50.2 | /30 (point-to-point) |
| R3 | Gi0/0 | 10.10.100.3 | /24 (broadcast) |
| R4 | Gi0/0 | 10.10.100.4 | /24 (broadcast) |

**Objectifs :**
1. Observer l'élection DR/BDR sur un segment broadcast
2. Manipuler les priorités OSPF
3. Vérifier que l'élection est non-préemptive
4. Configurer un lien point-to-point et observer l'absence de DR/BDR
5. Comparer les états d'adjacence (FULL vs 2-WAY)

**Étapes :**

1. **Configurer OSPF avec priorités différentes**
   ```cisco
   ! R1
   R1(config)# router ospf 1
   R1(config-router)# router-id 1.1.1.1
   R1(config-router)# network 10.10.100.0 0.0.0.255 area 0
   R1(config-router)# network 10.10.50.0 0.0.0.3 area 0
   R1(config)# interface GigabitEthernet0/0
   R1(config-if)# ip ospf priority 200
   R1(config)# interface GigabitEthernet0/1
   R1(config-if)# ip ospf network point-to-point

   ! R2
   R2(config)# router ospf 1
   R2(config-router)# router-id 2.2.2.2
   R2(config-router)# network 10.10.100.0 0.0.0.255 area 0
   R2(config-router)# network 10.10.50.0 0.0.0.3 area 0
   R2(config)# interface GigabitEthernet0/0
   R2(config-if)# ip ospf priority 100
   R2(config)# interface GigabitEthernet0/1
   R2(config-if)# ip ospf network point-to-point

   ! R3
   R3(config)# router ospf 1
   R3(config-router)# router-id 3.3.3.3
   R3(config-router)# network 10.10.100.0 0.0.0.255 area 0
   R3(config)# interface GigabitEthernet0/0
   R3(config-if)# ip ospf priority 50

   ! R4
   R4(config)# router ospf 1
   R4(config-router)# router-id 4.4.4.4
   R4(config-router)# network 10.10.100.0 0.0.0.255 area 0
   R4(config)# interface GigabitEthernet0/0
   R4(config-if)# ip ospf priority 0
   ```

2. **Forcer une nouvelle élection** (pour que les priorités prennent effet)
   ```cisco
   ! Sur chaque routeur
   R1# clear ip ospf process
   ```

3. **Vérifier l'élection DR/BDR** depuis R3 :
   ```cisco
   R3# show ip ospf neighbor
   Neighbor ID     Pri   State           Dead Time   Address         Interface
   1.1.1.1         200   FULL/DR         00:00:36    10.10.100.1     GigabitEthernet0/0
   2.2.2.2         100   FULL/BDR        00:00:33    10.10.100.2     GigabitEthernet0/0
   4.4.4.4           0   2WAY/DROTHER    00:00:38    10.10.100.4     GigabitEthernet0/0
   ```
   - R1 est DR (priorité 200, la plus haute)
   - R2 est BDR (priorité 100, la deuxième plus haute)
   - R4 est DROther avec priorité 0 (ne peut pas devenir DR/BDR)
   - R3 est aussi DROther (priorité 50)
   - R3 est FULL avec DR et BDR, mais 2-WAY avec R4 (entre DROthers)

4. **Observer le lien point-to-point** :
   ```cisco
   R1# show ip ospf interface GigabitEthernet0/1
   ...
   Process ID 1, Router ID 1.1.1.1, Network Type POINT_TO_POINT, Cost: 10
   ...
   No designated router on this network
   No backup designated router on this network
   ...
   ```
   Pas de DR/BDR sur le lien point-to-point.

5. **Tester la non-préemption** — redémarrer R1 pour voir si R2 garde le rôle DR :
   ```cisco
   ! Simuler une panne de R1
   R1(config)# interface GigabitEthernet0/0
   R1(config-if)# shutdown
   ! Attendre 40 secondes...
   R1(config-if)# no shutdown
   ```
   Après le retour de R1 :
   ```cisco
   R3# show ip ospf neighbor
   Neighbor ID     Pri   State           Dead Time   Address         Interface
   2.2.2.2         100   FULL/DR         00:00:36    10.10.100.2     GigabitEthernet0/0
   1.1.1.1         200   FULL/BDR        00:00:31    10.10.100.1     GigabitEthernet0/0
   ...
   ```
   R2 est devenu DR pendant la panne de R1 et le reste — l'élection est non-préemptive. R1, malgré sa priorité supérieure, est maintenant BDR.

**Questions de validation :**
1. Pourquoi R3 et R4 sont-ils en 2-WAY et non en FULL entre eux ?
2. Que se passerait-il si on faisait `clear ip ospf process` sur tous les routeurs maintenant ?
3. Quel est l'avantage du type réseau point-to-point par rapport au broadcast sur un lien entre 2 routeurs ?

---

### Lab 3.4 — Inter-VLAN Routing + OSPF combiné

**Topologie :**
```
                    Site A                          Site B
                                 OSPF Area 0
  VLAN 10 ─┐                                      ┌─ VLAN 10
  VLAN 20 ─┤── [SW1] ═══ trunk ═══ [R1] ════════ [R2] ═══ trunk ═══ [SW2] ──┤── VLAN 10
  VLAN 30 ─┘   Fa0/1          Gi0/0  Gi0/1  Gi0/0  Gi0/1           Fa0/1    └── VLAN 20
                               RoaS        10.10.0.0/30       RoaS

  Site A VLANs :                        Site B VLANs :
  VLAN 10 : 192.168.10.0/24            VLAN 10 : 192.168.110.0/24
  VLAN 20 : 192.168.20.0/24            VLAN 20 : 192.168.120.0/24
  VLAN 30 : 192.168.30.0/24

  Lien inter-site : 10.10.0.0/30
  R1 Gi0/1 : 10.10.0.1   |   R2 Gi0/0 : 10.10.0.2
```

**Tableau d'adressage :**

| Équipement | Interface | VLAN | Adresse IP | Masque |
|------------|-----------|------|-----------|--------|
| R1 | Gi0/0.10 | 10 | 192.168.10.1 | /24 |
| R1 | Gi0/0.20 | 20 | 192.168.20.1 | /24 |
| R1 | Gi0/0.30 | 30 | 192.168.30.1 | /24 |
| R1 | Gi0/1 | — | 10.10.0.1 | /30 |
| R2 | Gi0/0 | — | 10.10.0.2 | /30 |
| R2 | Gi0/1.10 | 10 | 192.168.110.1 | /24 |
| R2 | Gi0/1.20 | 20 | 192.168.120.1 | /24 |
| SW1 | VLAN 10 | 10 | 192.168.10.2 | /24 |
| SW2 | VLAN 10 | 10 | 192.168.110.2 | /24 |
| PC-A1 | NIC | 10 | 192.168.10.10 | /24 |
| PC-A2 | NIC | 20 | 192.168.20.10 | /24 |
| PC-B1 | NIC | 10 | 192.168.110.10 | /24 |

**Objectifs :**
1. Configurer le router-on-a-stick sur R1 et R2 (reprise du Module 2)
2. Configurer les VLANs et trunks sur SW1 et SW2
3. Configurer OSPF pour annoncer tous les réseaux entre les deux sites
4. Vérifier la connectivité inter-VLAN et inter-site
5. Comprendre la combinaison routage L2 (VLANs) et L3 (OSPF)

**Étapes :**

1. **Configurer les VLANs et trunks sur SW1**
   ```cisco
   SW1(config)# vlan 10
   SW1(config-vlan)# name DATA-A
   SW1(config)# vlan 20
   SW1(config-vlan)# name DEV-A
   SW1(config)# vlan 30
   SW1(config-vlan)# name MGMT-A
   SW1(config)# interface FastEthernet0/1
   SW1(config-if)# switchport trunk encapsulation dot1q
   SW1(config-if)# switchport mode trunk
   SW1(config-if)# switchport trunk allowed vlan 10,20,30
   SW1(config)# interface FastEthernet0/10
   SW1(config-if)# switchport mode access
   SW1(config-if)# switchport access vlan 10
   SW1(config)# interface FastEthernet0/11
   SW1(config-if)# switchport mode access
   SW1(config-if)# switchport access vlan 20
   ```

2. **Configurer le router-on-a-stick sur R1**
   ```cisco
   R1(config)# interface GigabitEthernet0/0
   R1(config-if)# no shutdown
   R1(config)# interface GigabitEthernet0/0.10
   R1(config-subif)# encapsulation dot1Q 10
   R1(config-subif)# ip address 192.168.10.1 255.255.255.0
   R1(config)# interface GigabitEthernet0/0.20
   R1(config-subif)# encapsulation dot1Q 20
   R1(config-subif)# ip address 192.168.20.1 255.255.255.0
   R1(config)# interface GigabitEthernet0/0.30
   R1(config-subif)# encapsulation dot1Q 30
   R1(config-subif)# ip address 192.168.30.1 255.255.255.0
   R1(config)# interface GigabitEthernet0/1
   R1(config-if)# ip address 10.10.0.1 255.255.255.252
   R1(config-if)# no shutdown
   ```

3. **Configurer OSPF sur R1**
   ```cisco
   R1(config)# router ospf 1
   R1(config-router)# router-id 1.1.1.1
   R1(config-router)# network 192.168.10.0 0.0.0.255 area 0
   R1(config-router)# network 192.168.20.0 0.0.0.255 area 0
   R1(config-router)# network 192.168.30.0 0.0.0.255 area 0
   R1(config-router)# network 10.10.0.0 0.0.0.3 area 0
   R1(config-router)# passive-interface GigabitEthernet0/0.10
   R1(config-router)# passive-interface GigabitEthernet0/0.20
   R1(config-router)# passive-interface GigabitEthernet0/0.30
   ```

4. **Configurer R2 et SW2** (même logique, adapter les adresses et VLANs)

5. **Vérification complète**
   ```cisco
   R1# show ip ospf neighbor
   Neighbor ID     Pri   State           Dead Time   Address         Interface
   2.2.2.2           1   FULL/ -         00:00:36    10.10.0.2       GigabitEthernet0/1

   R1# show ip route ospf
   O     192.168.110.0/24 [110/2] via 10.10.0.2, 00:03:45, GigabitEthernet0/1
   O     192.168.120.0/24 [110/2] via 10.10.0.2, 00:03:45, GigabitEthernet0/1

   ! Test inter-site : PC du VLAN 10 Site A → PC du VLAN 10 Site B
   PC-A1> ping 192.168.110.10
   !!!!!

   ! Test inter-VLAN et inter-site : PC VLAN 20 Site A → PC VLAN 10 Site B
   PC-A2> ping 192.168.110.10
   !!!!!
   ```

**Questions de validation :**
1. Pourquoi les sous-interfaces (Gi0/0.10, Gi0/0.20, Gi0/0.30) sont-elles en passive-interface ?
2. Combien de routes OSPF R1 annonce-t-il à R2 ?
3. Un PC du VLAN 20 du Site A veut joindre un PC du VLAN 10 du Site B. Décrivez le chemin complet du paquet (L2 et L3).

---

## Quiz OSPF — 8 questions

> Quiz dédié au topic 3.4 — le sujet le plus testé du module

**Q1.** Quel protocole de transport utilise OSPF ? _(Topic 3.4)_

- A) TCP port 89
- B) UDP port 520
- C) IP protocole 89
- D) TCP port 179

<details>
<summary>Réponse</summary>

**C** — OSPF utilise le protocole IP numéro 89 directement, sans couche TCP ni UDP. Le port TCP 179 est utilisé par BGP, et UDP 520 par RIP.

</details>

---

**Q2.** Deux routeurs OSPF sur le même segment ont les configurations suivantes :
- R1 : hello-interval 10, dead-interval 40, area 0
- R2 : hello-interval 10, dead-interval 30, area 0

Quel sera l'état de l'adjacence ? _(Topic 3.4.a)_

- A) FULL
- B) 2-WAY
- C) INIT
- D) L'adjacence ne se formera pas (stuck in INIT ou DOWN)

<details>
<summary>Réponse</summary>

**D** — Les dead intervals ne correspondent pas (40 vs 30). Le dead interval doit être identique sur les deux côtés pour former une adjacence. Les Hello seront reçus mais ignorés à cause du mismatch de paramètres. Même si les hello-intervals sont identiques, le dead interval est vérifié indépendamment.

</details>

---

**Q3.** Sur un segment Ethernet broadcast avec 4 routeurs OSPF, combien d'adjacences FULL seront établies ? _(Topic 3.4.c)_

- A) 6 (full mesh : N×(N-1)/2)
- B) 4
- C) 3
- D) 5

<details>
<summary>Réponse</summary>

**D** — Sur un segment broadcast, le DR forme une adjacence FULL avec chaque autre routeur (3 adjacences), et le BDR fait de même (3 adjacences). Mais l'adjacence DR↔BDR est comptée une seule fois. Donc : DR↔R3, DR↔R4, BDR↔R3, BDR↔R4, DR↔BDR = **5 adjacences FULL**. Les DROthers entre eux restent en 2-WAY.

Note : avec 4 routeurs = 1 DR, 1 BDR, 2 DROther. Chaque DROther est FULL avec DR et BDR (2×2=4) + DR↔BDR (1) = **5**.

</details>

---

**Q4.** Un routeur OSPF a le router-id 1.1.1.1 configuré explicitement, une loopback avec l'adresse 10.10.10.10, et une interface physique avec 192.168.1.1. Quel sera son Router ID ? _(Topic 3.4.d)_

- A) 192.168.1.1
- B) 10.10.10.10
- C) 1.1.1.1
- D) 0.0.0.1

<details>
<summary>Réponse</summary>

**C** — La hiérarchie de sélection du Router ID est : 1) commande `router-id` explicite, 2) IP la plus haute sur une loopback, 3) IP la plus haute sur une interface physique. Ici, `router-id 1.1.1.1` a la priorité maximale, quelle que soit l'IP des interfaces.

</details>

---

**Q5.** Le routeur R1 est DR sur un segment avec une priorité de 100. R5 rejoint le segment avec une priorité de 255. Que se passe-t-il ? _(Topic 3.4.c)_

- A) R5 devient immédiatement DR
- B) R5 devient BDR, puis DR au prochain cycle
- C) R5 devient DROther — l'élection DR/BDR est non-préemptive
- D) R5 déclenche une nouvelle élection et gagne

<details>
<summary>Réponse</summary>

**C** — L'élection DR/BDR dans OSPF est **non-préemptive**. Un routeur avec une priorité plus élevée qui rejoint le réseau après l'élection ne prend pas le rôle de DR. R5 deviendra BDR uniquement si le BDR actuel tombe, puis DR si l'actuel DR tombe aussi. Pour forcer une nouvelle élection, il faut `clear ip ospf process` sur tous les routeurs.

</details>

---

**Q6.** Quelle commande configure correctement OSPF pour inclure l'interface 10.1.1.1/24 dans l'area 0 ? _(Topic 3.4)_

- A) `network 10.1.1.0 255.255.255.0 area 0`
- B) `network 10.1.1.0 0.0.0.255 area 0`
- C) `network 10.1.1.1 0.0.0.0 area 0`
- D) B et C sont toutes les deux correctes

<details>
<summary>Réponse</summary>

**D** — La commande `network` utilise un **wildcard mask**. `10.1.1.0 0.0.0.255` inclut toutes les interfaces dont l'IP est dans 10.1.1.0/24. `10.1.1.1 0.0.0.0` inclut uniquement l'interface exacte 10.1.1.1 — c'est plus précis mais tout aussi correct. L'option A utilise un masque de sous-réseau au lieu d'un wildcard mask — c'est une erreur courante mais qui activerait OSPF sur des interfaces imprévues.

</details>

---

**Q7.** `show ip ospf neighbor` affiche un voisin bloqué en état EXSTART. Quelle est la cause la plus probable ? _(Topic 3.4.a)_

- A) Mismatch de hello/dead interval
- B) Mismatch de MTU
- C) Mismatch d'area ID
- D) Le voisin a une priorité de 0

<details>
<summary>Réponse</summary>

**B** — Un voisin bloqué en EXSTART ou EXCHANGE indique presque toujours un **mismatch de MTU**. Les paquets DBD sont trop gros pour passer sur l'un des deux côtés. Les mismatches de hello/dead interval et d'area ID empêchent l'adjacence de dépasser l'état INIT. La priorité 0 n'empêche pas la formation d'adjacence — elle empêche seulement le routeur de devenir DR/BDR.

</details>

---

**Q8.** Quel est le coût OSPF d'une interface GigabitEthernet si la reference bandwidth est de 10000 Mbps ? _(Topic 3.4)_

- A) 1
- B) 10
- C) 100
- D) 1000

<details>
<summary>Réponse</summary>

**B** — Coût = reference bandwidth / interface bandwidth = 10000 / 1000 = **10**. Avec la reference bandwidth par défaut (100 Mbps), le coût serait 100/1000 = 0.1 → arrondi à 1, ce qui ne distingue pas GigE de FastEth. C'est pour cela qu'on recommande d'augmenter la reference bandwidth.

</details>

---

## Quiz Module 3 — 15 questions

**Q1.** Quelle ligne d'une table de routage indique la route par défaut ? _(Topic 3.1.g)_

- A) `C 0.0.0.0/0 is directly connected`
- B) `S* 0.0.0.0/0 [1/0] via 10.1.1.1`
- C) `L 0.0.0.0/32 is directly connected`
- D) `O 0.0.0.0/0 [110/1] via 10.1.1.1`

<details>
<summary>Réponse</summary>

**B** — L'astérisque `*` dans `S*` identifie la route comme candidate par défaut (gateway of last resort). Le préfixe 0.0.0.0/0 matche tout. L'option D serait aussi valide si OSPF redistribuait une route par défaut (code `O*E2`), mais le format exact montré est une route statique. L'option A est impossible car 0.0.0.0/0 ne peut pas être directement connecté. L'option C n'existe pas — /32 est une host route, pas une default route.

</details>

---

**Q2.** Un routeur a ces routes dans sa table :
```
S 10.0.0.0/8 [1/0] via 192.168.1.1
O 10.10.0.0/16 [110/20] via 192.168.1.2
D 10.10.10.0/24 [90/307200] via 192.168.1.3
```
Vers quel next hop sera envoyé un paquet destiné à 10.10.10.50 ? _(Topic 3.2.a)_

- A) 192.168.1.1 (route statique, AD la plus basse)
- B) 192.168.1.2 (route OSPF)
- C) 192.168.1.3 (route EIGRP, longest prefix match)
- D) Le paquet est dropped

<details>
<summary>Réponse</summary>

**C** — Le longest prefix match s'applique toujours en premier. 10.10.10.50 correspond aux trois routes (/8, /16, /24), mais /24 est la plus spécifique. Peu importe que la route statique ait une AD inférieure (1 vs 90) — le longest prefix match prévaut toujours sur l'AD.

</details>

---

**Q3.** Quelle commande crée une route statique flottante avec une AD de 150 ? _(Topic 3.3.d)_

- A) `ip route 10.1.1.0 255.255.255.0 192.168.1.1 150`
- B) `ip route 10.1.1.0 255.255.255.0 192.168.1.1 metric 150`
- C) `ip route 10.1.1.0 255.255.255.0 192.168.1.1 distance 150`
- D) `ip route 10.1.1.0 0.0.0.255 192.168.1.1 150`

<details>
<summary>Réponse</summary>

**A** — La syntaxe correcte est `ip route <réseau> <masque> <next-hop> [AD]`. Le dernier paramètre optionnel est l'AD. L'option B utilise un mot-clé `metric` qui n'existe pas dans cette commande. L'option C utilise `distance` qui n'est pas non plus la bonne syntaxe. L'option D utilise un wildcard mask au lieu d'un masque de sous-réseau — la commande `ip route` utilise le masque de sous-réseau, pas le wildcard.

</details>

---

**Q4.** Quelle distance administrative a une route OSPF par défaut ? _(Topic 3.1.e)_

- A) 90
- B) 100
- C) 110
- D) 120

<details>
<summary>Réponse</summary>

**C** — OSPF a une AD de **110**. 90 est l'AD d'EIGRP interne, 100 ne correspond à aucun protocole standard, et 120 est l'AD de RIP. Mémo : **O**SPF = **O**ne hundred **ten** = 110.

</details>

---

**Q5.** Quel type de paquet OSPF est utilisé pour maintenir les adjacences ? _(Topic 3.4.a)_

- A) DBD (Database Description)
- B) LSU (Link-State Update)
- C) Hello
- D) LSAck

<details>
<summary>Réponse</summary>

**C** — Le paquet **Hello** sert à découvrir les voisins ET à maintenir les adjacences. Il est envoyé périodiquement (toutes les 10 secondes sur broadcast/point-to-point). Si aucun Hello n'est reçu pendant le Dead interval (40 secondes par défaut), le voisin est déclaré mort. Les DBD, LSR, LSU et LSAck servent à l'échange et la synchronisation de la LSDB.

</details>

---

**Q6.** Sur un réseau broadcast, quel est l'état normal entre deux routeurs DROther ? _(Topic 3.4.c)_

- A) FULL
- B) DOWN
- C) 2-WAY
- D) EXCHANGE

<details>
<summary>Réponse</summary>

**C** — Sur un réseau broadcast, les DROthers forment des adjacences FULL uniquement avec le DR et le BDR. Entre DROthers, l'état **2-WAY** est normal et attendu — ce n'est PAS un problème. Si l'examen affiche un `show ip ospf neighbor` avec des états 2-WAY/DROTHER, ne cherchez pas un problème : c'est le comportement par défaut.

</details>

---

**Q7.** Quel protocole FHRP permet le load balancing natif entre plusieurs routeurs ? _(Topic 3.5)_

- A) HSRP
- B) VRRP
- C) GLBP
- D) HSRP et VRRP avec des groupes multiples

<details>
<summary>Réponse</summary>

**C** — **GLBP** (Gateway Load Balancing Protocol) est le seul protocole FHRP qui fait du load balancing natif en distribuant différentes MAC virtuelles via l'AVG. HSRP et VRRP ne supportent qu'un routeur actif/master par groupe. L'option D est techniquement possible mais nécessite une configuration manuelle de groupes multiples sur les hôtes — ce n'est pas du load balancing "natif".

</details>

---

**Q8.** Vous tapez `show ip route` et voyez `Gateway of last resort is not set`. Un utilisateur ne peut pas accéder à Internet. Quelle est la cause ? _(Topic 3.1.g)_

- A) Les interfaces du routeur sont down
- B) OSPF n'est pas configuré
- C) Aucune route par défaut n'est configurée
- D) Le DNS ne fonctionne pas

<details>
<summary>Réponse</summary>

**C** — `Gateway of last resort is not set` signifie qu'aucune route par défaut (0.0.0.0/0) n'existe dans la table de routage. Sans route par défaut, tout paquet vers une destination non explicitement connue est jeté. La solution est de configurer une route par défaut statique ou de recevoir une via un protocole de routage.

</details>

---

**Q9.** Un routeur a ces deux routes vers 10.1.1.0/24 :
```
O 10.1.1.0/24 [110/20] via 192.168.1.1
O 10.1.1.0/24 [110/20] via 192.168.1.2
```
Que fait le routeur ? _(Topic 3.2.c)_

- A) Il choisit la première route installée
- B) Il choisit celle avec l'adresse next hop la plus basse
- C) Il fait du load balancing (ECMP) entre les deux
- D) Il supprime la deuxième route

<details>
<summary>Réponse</summary>

**C** — Les deux routes ont la même AD (110) et la même métrique (20). Le routeur utilise les deux chemins simultanément — c'est le **Equal-Cost Multi-Path (ECMP)**. Les paquets sont distribués entre les deux next hops, ce qui augmente la bande passante effective et la résilience.

</details>

---

**Q10.** Quelle affirmation est vraie concernant `ipv6 unicast-routing` ? _(Topic 3.3)_

- A) Elle active le routage OSPF pour IPv6
- B) Elle est nécessaire pour que le routeur transfère des paquets IPv6
- C) Elle active automatiquement OSPFv3
- D) Elle n'est nécessaire que pour les routes statiques IPv6

<details>
<summary>Réponse</summary>

**B** — La commande `ipv6 unicast-routing` active le forwarding IPv6 sur le routeur. Sans cette commande, le routeur traite les paquets IPv6 comme un hôte (il ne les route pas). Elle est nécessaire pour TOUTE forme de routage IPv6 : statique, OSPF, EIGRP, etc. Elle n'active pas de protocole de routage en elle-même.

</details>

---

**Q11.** Quel est le wildcard mask correct pour le réseau 192.168.1.0/26 dans la commande `network` OSPF ? _(Topic 3.4)_

- A) 0.0.0.63
- B) 0.0.0.192
- C) 255.255.255.192
- D) 0.0.0.255

<details>
<summary>Réponse</summary>

**A** — Le masque /26 est 255.255.255.192. Le wildcard mask est l'inverse : 255-192 = **63**, donc 0.0.0.63. L'option B (0.0.0.192) est le dernier octet du masque de sous-réseau, pas du wildcard. L'option C est le masque de sous-réseau lui-même. L'option D (0.0.0.255) correspond à /24, pas /26.

</details>

---

**Q12.** Un routeur OSPF montre cet output :
```
show ip ospf interface Gi0/0
  Network Type BROADCAST, Cost: 1
```
Quelle reference bandwidth est probablement configurée ? _(Topic 3.4)_

- A) 100 (par défaut)
- B) 1000
- C) 10000
- D) Impossible à déterminer sans connaître la bande passante de l'interface

<details>
<summary>Réponse</summary>

**D** — Le coût de 1 pourrait résulter de plusieurs combinaisons : reference 100 / interface 100 Mbps (FastEth) = 1, reference 1000 / interface 1000 Mbps (GigE) = 1, reference 10000 / interface 10000 Mbps (10G) = 1. Sans connaître la bande passante de l'interface Gi0/0, on ne peut pas déterminer la reference bandwidth. C'est un piège classique.

</details>

---

**Q13.** Quel avantage principal la gestion réseau cloud offre-t-elle pour le déploiement en succursale ? _(Topic 3.6)_

- A) Les équipements n'ont pas besoin d'adresse IP
- B) Le Zero-Touch Provisioning (pas besoin de technicien réseau sur site)
- C) Les équipements fonctionnent sans connexion Internet
- D) Le coût des équipements est réduit

<details>
<summary>Réponse</summary>

**B** — Le **Zero-Touch Provisioning** est l'avantage majeur : l'équipement est pré-configuré dans le dashboard cloud, expédié sur site, branché par n'importe qui, et il télécharge automatiquement sa configuration. L'option A est fausse (ils ont besoin d'IP). L'option C est fausse (ils ont besoin d'Internet pour contacter le cloud). L'option D n'est pas nécessairement vraie (modèle d'abonnement).

</details>

---

**Q14.** HSRP utilise les termes Active/Standby. Quels termes utilise VRRP ? _(Topic 3.5)_

- A) Primary / Secondary
- B) Master / Backup
- C) Active / Passive
- D) Leader / Follower

<details>
<summary>Réponse</summary>

**B** — VRRP utilise **Master** (équivalent d'Active en HSRP) et **Backup** (équivalent de Standby). C'est un piège classique de l'examen : mélanger les terminologies HSRP et VRRP. GLBP utilise AVG (Active Virtual Gateway) et AVF (Active Virtual Forwarder).

</details>

---

**Q15.** Quelle commande permet de vérifier si OSPF a correctement appris des routes sur un routeur ? _(Topic 3.4)_

- A) `show ip ospf database`
- B) `show ip route ospf`
- C) `show ip ospf neighbor`
- D) `show ip protocols`

<details>
<summary>Réponse</summary>

**B** — `show ip route ospf` affiche uniquement les routes installées dans la table de routage par OSPF. C'est la commande la plus directe pour vérifier les routes apprises. L'option A montre la LSDB (base de données topologique), pas les routes installées. L'option C montre les voisins et leurs états, pas les routes. L'option D montre la configuration du protocole, pas les routes.

</details>

---

## Récapitulatif Module 3

| Topic | Concept clé | Commande(s) essentielles |
|-------|------------|--------------------------|
| 3.1 | Table de routage : codes, préfixe, masque, next-hop, AD, métrique, gateway of last resort | `show ip route`, `show ip route <IP>` |
| 3.2 | Longest prefix match → AD → Metric — dans cet ordre strict | `show ip route <destination>` |
| 3.3 | Routes statiques : default, network, host, floating static | `ip route`, `ipv6 route`, `show ip route static` |
| 3.4 | OSPF : adjacences, DR/BDR, router-id, coût, passive-interface | `show ip ospf neighbor`, `show ip ospf interface`, `show ip route ospf` |
| 3.5 | FHRP : IP virtuelle partagée, HSRP (Active/Standby), VRRP (Master/Backup), GLBP (load balancing) | `show standby brief` |
| 3.6 | Gestion cloud : dashboard centralisé, ZTP, Meraki, DNA Center | — |

**Check-list avant de passer au Module 4 :**
- [ ] Je sais lire et interpréter chaque composant d'une table de routage
- [ ] Je sais appliquer le longest prefix match pour déterminer le chemin choisi
- [ ] Je sais configurer des routes statiques IPv4/IPv6 (default, network, host, floating)
- [ ] Je sais configurer OSPF single-area et vérifier les adjacences
- [ ] Je comprends l'élection DR/BDR et sa nature non-préemptive
- [ ] Je sais calculer le coût OSPF et ajuster la reference bandwidth
- [ ] Je comprends le rôle des FHRP et les différences HSRP/VRRP/GLBP
- [ ] Je sais décrire les avantages de la gestion réseau cloud
- [ ] J'ai complété les 12 exercices
- [ ] J'ai réalisé les 4 labs
- [ ] J'ai obtenu >70% aux deux quiz (OSPF + module complet)