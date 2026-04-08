# Lab 2.3 — Spanning Tree Protocol : Rapid PVST+ et optimisation

| Champ | Valeur |
|-------|--------|
| **Module** | 2 — Technologies de commutation et VLANs |
| **Topics couverts** | 2.5 (Spanning Tree Protocol) |
| **Difficulte** | Intermediaire |
| **Duree estimee** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                         SW1
                      ┌────────┐
                Gi0/1 │        │ Gi0/2
                ┌─────┘        └─────┐
                │   VLAN10: 10.10.10.1│
                │                     │
                │                     │
          Gi0/1 │                     │ Gi0/2
          ┌─────┴──┐           ┌──────┴─┐
          │        │           │        │
          │  SW2   │───────────│  SW3   │
          │        │ Gi0/2  Gi0/1      │
          └────────┘           └────────┘
       VLAN10: 10.10.10.2    VLAN10: 10.10.10.3


       Connexions :
       SW1 Gi0/1 ──── SW2 Gi0/1
       SW1 Gi0/2 ──── SW3 Gi0/2
       SW2 Gi0/2 ──── SW3 Gi0/1
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | VLAN |
|----------|-----------|-----------|--------|------|
| SW1 | VLAN 10 | 10.10.10.1 | 255.255.255.0 | 10 |
| SW2 | VLAN 10 | 10.10.10.2 | 255.255.255.0 | 10 |
| SW3 | VLAN 10 | 10.10.10.3 | 255.255.255.0 | 10 |

---

## Objectifs

1. Configurer les VLANs et activer le mode Rapid PVST+ sur les trois switches
2. Identifier le root bridge elu par defaut et comprendre le mecanisme d'election
3. Forcer SW1 comme root bridge pour le VLAN 10 et SW2 pour le VLAN 20
4. Identifier les roles des ports (root, designated, alternate) et comprendre pourquoi
5. Configurer PortFast et BPDU Guard sur les ports access pour accelerer la convergence
6. Observer la convergence rapide de RSTP en simulant une panne de lien

---

## Prerequis

- Connaitre le role de STP : eviter les boucles de couche 2 dans un reseau avec des liens redondants
- Comprendre les concepts de base : BPDU, Bridge ID (priorite + MAC), Root Bridge
- Savoir ce qu'est un port root, designated et alternate (blocked)
- Avoir fait les Labs 2.1 et 2.2 (VLANs, trunks)

---

## Configuration de depart

### SW1 — Configuration initiale

```
enable
configure terminal
hostname SW1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 15
 password cisco
 login
banner motd # Acces non autorise interdit #
end
```

### SW2 — Configuration initiale

```
enable
configure terminal
hostname SW2
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 15
 password cisco
 login
banner motd # Acces non autorise interdit #
end
```

### SW3 — Configuration initiale

```
enable
configure terminal
hostname SW3
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 15
 password cisco
 login
banner motd # Acces non autorise interdit #
end
```

---

## Partie 1 — Configuration de base (VLANs et Rapid PVST+)

### Etape 1.1 — Creer les VLANs sur les trois switches

Sur **chaque switch** (SW1, SW2, SW3), executez :

```
enable
configure terminal
vlan 10
 name Production
vlan 20
 name Serveurs
exit
```

### Etape 1.2 — Configurer les liens inter-switches en trunk

Les liens entre switches doivent etre des trunks pour transporter les VLANs 10 et 20.

**Sur SW1 :**

```
configure terminal
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
end
```

**Sur SW2 :**

```
configure terminal
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
end
```

**Sur SW3 :**

```
configure terminal
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
end
```

### Etape 1.3 — Configurer les SVI

**Sur SW1 :**

```
configure terminal
interface vlan 10
 ip address 10.10.10.1 255.255.255.0
 no shutdown
end
```

**Sur SW2 :**

```
configure terminal
interface vlan 10
 ip address 10.10.10.2 255.255.255.0
 no shutdown
end
```

**Sur SW3 :**

```
configure terminal
interface vlan 10
 ip address 10.10.10.3 255.255.255.0
 no shutdown
end
```

### Etape 1.4 — Activer Rapid PVST+

Par defaut, les switches Cisco utilisent PVST+ (Per-VLAN Spanning Tree Plus). On va passer en Rapid PVST+ pour beneficier d'une convergence plus rapide.

Sur **chaque switch** :

```
configure terminal
spanning-tree mode rapid-pvst
end
```

> **Explication** : Rapid PVST+ combine deux choses :
> - **RSTP** (Rapid Spanning Tree Protocol, IEEE 802.1w) : convergence en quelques secondes au lieu de 30-50 secondes avec le STP classique
> - **Per-VLAN** : une instance STP separee par VLAN, ce qui permet d'optimiser les chemins differemment selon les VLANs
>
> C'est le mode recommande dans la plupart des environnements Cisco.

### Etape 1.5 — Verification

```
show spanning-tree
```

Vous devriez voir une section pour chaque VLAN (VLAN0010 et VLAN0020). Attendez que tous les ports atteignent l'etat "forwarding" ou "alternate" avant de continuer.

---

## Partie 2 — Identifier le Root Bridge

Le root bridge est le switch central de l'arbre STP. C'est lui qui sert de reference pour calculer les chemins les plus courts. Par defaut, c'est le switch avec le Bridge ID le plus bas qui est elu.

### Etape 2.1 — Examiner le STP pour le VLAN 10

Sur **chaque switch**, executez :

```
show spanning-tree vlan 10
```

**Output attendu sur le switch qui est root bridge (exemple si c'est SW1) :**

```
VLAN0010
  Spanning tree enabled protocol rstp
  Root ID    Priority    32778
             Address     0001.4200.1111
             This bridge is the root
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32778  (priority 32768 sys-id-ext 10)
             Address     0001.4200.1111
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  20

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- --------------------------------
Gi0/1            Desg FWD 4         128.25   P2p
Gi0/2            Desg FWD 4         128.26   P2p
```

> **Comment lire cet output** :
> - **Root ID** : identifie le root bridge du reseau pour ce VLAN. Le champ "This bridge is the root" confirme que ce switch est le root bridge.
> - **Bridge ID** : identifie le switch local. La priorite est composee de la priorite de base (32768 par defaut) + le sys-id-ext (le numero du VLAN, ici 10), soit 32778.
> - **Priority 32778** : c'est 32768 + 10. Tous les switches ont la meme priorite par defaut (32768), donc le departage se fait sur l'adresse MAC la plus basse.
> - **Role Desg** : tous les ports du root bridge sont toujours "Designated" (ils envoient les BPDUs vers les segments).
> - **Sts FWD** : le port est en etat "Forwarding" (il transmet les trames).

**Output attendu sur un switch non-root (exemple SW2) :**

```
VLAN0010
  Spanning tree enabled protocol rstp
  Root ID    Priority    32778
             Address     0001.4200.1111
             Cost        4
             Port        25(GigabitEthernet0/1)
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32778  (priority 32768 sys-id-ext 10)
             Address     0002.4200.2222
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  20

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- --------------------------------
Gi0/1            Root FWD 4         128.25   P2p
Gi0/2            Desg FWD 4         128.26   P2p
```

> - **Root port (Gi0/1)** : c'est le port qui offre le chemin le plus court vers le root bridge. Chaque switch non-root a exactement un root port.
> - **Cost 4** : le cout pour atteindre le root bridge via ce port. Pour un lien GigabitEthernet, le cout STP par defaut est 4.

### Etape 2.2 — Identifier le switch elu comme root

Notez l'adresse MAC du Root ID sur chaque switch. Le root bridge est celui dont l'adresse MAC du Bridge ID correspond a celle du Root ID.

> **En pratique** : Dans Packet Tracer, les adresses MAC sont attribuees dans l'ordre de creation des equipements. Le switch cree en premier aura generalement la MAC la plus basse et sera elu root bridge. Mais on ne veut pas laisser le hasard decider ! C'est pourquoi on va forcer le root bridge dans la partie suivante.

### Etape 2.3 — Documenter l'etat actuel

Avant de modifier quoi que ce soit, notez sur papier :

| Switch | Role pour VLAN 10 | Role pour VLAN 20 | Priorite | MAC |
|--------|-------------------|-------------------|----------|-----|
| SW1 | ? | ? | 32778/32788 | ? |
| SW2 | ? | ? | 32778/32788 | ? |
| SW3 | ? | ? | 32778/32788 | ? |

> La priorite pour le VLAN 10 est 32768+10 = 32778. Pour le VLAN 20, c'est 32768+20 = 32788.

---

## Partie 3 — Forcer le Root Bridge

Laisser STP elire le root bridge au hasard (basee sur la MAC la plus basse) est une mauvaise pratique. Le root bridge devrait etre le switch le plus central et le plus performant du reseau. On va forcer SW1 comme root pour le VLAN 10 et SW2 pour le VLAN 20.

### Etape 3.1 — Faire de SW1 le root bridge pour le VLAN 10

Sur SW1 :

```
configure terminal
spanning-tree vlan 10 root primary
end
```

> **Explication** : La commande `spanning-tree vlan 10 root primary` modifie la priorite du switch pour qu'il devienne root bridge. Concretement, elle met la priorite a 24576 (ou 4096 de moins que le root bridge actuel si celui-ci a deja une priorite inferieure a 24576). Avec une priorite de 24576 + 10 (sys-id-ext) = 24586, SW1 aura la priorite la plus basse et sera elu root.
>
> Alternativement, on peut definir la priorite manuellement :
> ```
> spanning-tree vlan 10 priority 24576
> ```
> Le resultat est le meme, mais la commande `root primary` est plus pratique car elle s'adapte automatiquement.

### Etape 3.2 — Faire de SW2 le root bridge pour le VLAN 20

Sur SW2 :

```
configure terminal
spanning-tree vlan 20 root primary
end
```

### Etape 3.3 — Configurer les root bridges secondaires

Un root bridge secondaire prendra le relais si le primaire tombe. Sa priorite est mise a 28672.

Sur SW2 (backup root pour VLAN 10) :

```
configure terminal
spanning-tree vlan 10 root secondary
end
```

Sur SW1 (backup root pour VLAN 20) :

```
configure terminal
spanning-tree vlan 20 root secondary
end
```

### Etape 3.4 — Verification

Sur chaque switch :

```
show spanning-tree vlan 10
show spanning-tree vlan 20
```

**Output attendu sur SW1 pour VLAN 10 :**

```
VLAN0010
  Spanning tree enabled protocol rstp
  Root ID    Priority    24586
             Address     0001.4200.1111
             This bridge is the root
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    24586  (priority 24576 sys-id-ext 10)
             Address     0001.4200.1111
             ...
```

> La priorite est maintenant 24586 (24576 + 10) au lieu de 32778. Le message "This bridge is the root" confirme que SW1 est bien le root bridge pour le VLAN 10.

**Output attendu sur SW2 pour VLAN 20 :**

```
VLAN0020
  Spanning tree enabled protocol rstp
  Root ID    Priority    24596
             Address     0002.4200.2222
             This bridge is the root
             ...
```

> SW2 est root bridge pour le VLAN 20 avec une priorite de 24596 (24576 + 20).

> **Concept cle — Per-VLAN Spanning Tree** : Chaque VLAN a sa propre instance STP avec potentiellement un root bridge different. Cela permet de faire du load-balancing : le trafic du VLAN 10 emprunte un chemin optimal vers SW1, tandis que le trafic du VLAN 20 emprunte un chemin optimal vers SW2. Les ports bloques ne sont pas les memes selon le VLAN.

---

## Partie 4 — Identifier les roles des ports

Maintenant que les root bridges sont fixes, analysons les roles de chaque port dans l'arbre STP.

### Etape 4.1 — Rappel des roles

| Role | Signification |
|------|---------------|
| **Root** | Port qui offre le meilleur chemin vers le root bridge. Un par switch non-root. |
| **Designated** | Port qui envoie les BPDUs sur un segment. Tous les ports du root bridge sont designated. |
| **Alternate** | Port bloque qui fournit un chemin alternatif vers le root bridge. Pret a prendre le relais. |

### Etape 4.2 — Analyser les ports pour le VLAN 10 (root = SW1)

Executez `show spanning-tree vlan 10` sur les trois switches et remplissez le tableau :

| Switch | Interface | Role attendu | Etat | Explication |
|--------|-----------|-------------|------|-------------|
| SW1 | Gi0/1 | Designated | FWD | Tous les ports du root bridge sont designated |
| SW1 | Gi0/2 | Designated | FWD | Idem |
| SW2 | Gi0/1 | Root | FWD | Chemin direct vers SW1 (root), cout = 4 |
| SW2 | Gi0/2 | Designated | FWD | Meilleur BID que SW3 sur ce segment |
| SW3 | Gi0/1 | Alternate | BLK | Chemin alternatif vers root via SW2 (cout 8 > 4) |
| SW3 | Gi0/2 | Root | FWD | Chemin direct vers SW1 (root), cout = 4 |

> **Explication du port Alternate sur SW3 Gi0/1** : SW3 a deux chemins vers le root bridge SW1 :
> - Via Gi0/2 (direct vers SW1) : cout = 4
> - Via Gi0/1 (vers SW2, puis SW2 vers SW1) : cout = 4 + 4 = 8
>
> Le chemin via Gi0/2 est meilleur (cout 4 < 8), donc Gi0/2 est le root port. Gi0/1 devient alternate (bloque) car le segment SW2-SW3 a deja un designated port (Gi0/2 de SW2, car SW2 a un meilleur BID que SW3 ou un cout root plus faible).

> **Note** : Les roles exacts peuvent varier selon les adresses MAC de vos switches dans Packet Tracer. L'important est de comprendre la logique de selection. Si votre resultat differe, refaites le raisonnement en comparant les couts et les BID.

### Etape 4.3 — Analyser les ports pour le VLAN 20 (root = SW2)

Executez `show spanning-tree vlan 20` et notez que les roles changent car le root bridge est maintenant SW2 :

| Switch | Interface | Role attendu | Etat |
|--------|-----------|-------------|------|
| SW2 | Gi0/1 | Designated | FWD |
| SW2 | Gi0/2 | Designated | FWD |
| SW1 | Gi0/1 | Root | FWD |
| SW1 | Gi0/2 | Designated | FWD |
| SW3 | Gi0/1 | Root | FWD |
| SW3 | Gi0/2 | Alternate | BLK |

> Le port bloque a change de place par rapport au VLAN 10. C'est l'essence du Per-VLAN Spanning Tree : on peut equilibrer la charge entre les liens en choisissant des root bridges differents par VLAN.

---

## Partie 5 — PortFast et BPDU Guard

Les ports qui connectent des stations de travail (PCs, imprimantes) n'ont aucune raison de participer au calcul STP. Par defaut, un port passe par les etats Listening (15s) et Learning (15s) avant d'atteindre Forwarding. Avec RSTP, c'est plus rapide, mais PortFast elimine completement ce delai.

### Etape 5.1 — Comprendre PortFast

PortFast fait passer un port directement en etat Forwarding des qu'il detecte un lien. C'est indispensable pour les postes clients qui ont besoin d'une connectivite reseau immediate (notamment pour DHCP).

> **Attention** : PortFast ne doit **jamais** etre active sur un port connecte a un autre switch. Si un switch est branche sur un port PortFast, cela cree un risque de boucle temporaire car STP ne passera pas par les etapes normales de convergence.

### Etape 5.2 — Configurer PortFast sur les ports access

On va configurer PortFast sur quelques ports access (Fa0/1 a Fa0/10) de chaque switch, en supposant qu'ils seront connectes a des postes clients.

Sur **chaque switch** :

```
configure terminal
interface range FastEthernet0/1 - 10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 no shutdown
end
```

> **Explication** : `spanning-tree portfast` active PortFast sur ces ports. Vous verrez le message :
> ```
> %Warning: portfast should only be enabled on ports connected to a single
>  host. Connecting hubs, concentrators, switches, bridges, etc... to this
>  interface when portfast is enabled, can cause temporary bridging loops.
>  Use with CAUTION
> ```
> C'est un avertissement, pas une erreur. Il rappelle simplement de ne pas connecter de switch sur ce port.

**Alternative — PortFast global** : Au lieu de configurer PortFast port par port, on peut l'activer globalement pour tous les ports access :

```
configure terminal
spanning-tree portfast default
end
```

Cette commande active PortFast sur tous les ports en mode access. Les ports trunk ne sont pas affectes. C'est la methode preferee en production.

### Etape 5.3 — Configurer BPDU Guard

BPDU Guard est le complement securitaire de PortFast. Si un port avec BPDU Guard recoit une BPDU (ce qui signifie qu'un switch a ete branche), le port est immediatement desactive (err-disabled).

Sur **chaque switch** :

```
configure terminal
interface range FastEthernet0/1 - 10
 spanning-tree bpduguard enable
end
```

**Alternative — BPDU Guard global** (s'applique a tous les ports PortFast) :

```
configure terminal
spanning-tree portfast bpduguard default
end
```

### Etape 5.4 — Verification

```
show spanning-tree interface FastEthernet0/1 detail
```

**Output attendu (extrait) :**

```
Port 1 (FastEthernet0/1) of VLAN0010 is designated forwarding
   Port path cost 19, Port priority 128, Port Identifier 128.1.
   ...
   Number of transitions to forwarding state: 1
   The port is in the portfast mode
   Link type is point-to-point by default
   Bpdu guard is enabled
```

> Les mentions "portfast mode" et "Bpdu guard is enabled" confirment la configuration.

### Etape 5.5 — Tester BPDU Guard (optionnel)

Pour voir BPDU Guard en action, connectez temporairement un switch additionnel sur Fa0/1 d'un des switches. Le port devrait passer en `err-disabled` :

```
show interfaces FastEthernet0/1 status
```

```
Port      Name               Status       Vlan       Duplex  Speed Type
Fa0/1                        err-disabled 10         auto    auto  10/100BaseTX
```

Pour retablir le port :

```
configure terminal
interface FastEthernet0/1
 shutdown
 no shutdown
end
```

---

## Partie 6 — Observer la convergence RSTP

RSTP offre une convergence beaucoup plus rapide que le STP classique (802.1D). On va provoquer une panne et observer comment RSTP reconfigure l'arbre en quelques secondes.

### Etape 6.1 — Etat initial

Verifiez l'etat STP pour le VLAN 10 avant la manipulation :

```
show spanning-tree vlan 10
```

Notez quels ports sont root, designated et alternate. Identifiez le port actuellement bloque (alternate).

### Etape 6.2 — Provoquer une panne

On va desactiver le lien entre SW1 (root bridge) et SW3. Sur SW1 :

```
configure terminal
interface GigabitEthernet0/2
 shutdown
end
```

### Etape 6.3 — Observer les changements

Immediatement apres le shutdown, verifiez l'etat STP sur SW3 :

```
show spanning-tree vlan 10
```

**Ce qui devrait se passer :**

Avant la panne, SW3 avait :
- Gi0/2 = Root port (chemin direct vers SW1, cout 4)
- Gi0/1 = Alternate port (bloque, chemin via SW2, cout 8)

Apres la panne (Gi0/2 down) :
- Gi0/1 = **Root port** (maintenant le seul chemin vers SW1, via SW2, cout 8)

> **Convergence RSTP** : Le port alternate (Gi0/1) passe directement en Forwarding sans attendre les timers. C'est la force de RSTP : le port alternate est "pre-calcule" comme chemin de secours. La transition est quasi-instantanee (moins d'une seconde).
>
> Avec le STP classique (802.1D), le port bloque aurait du passer par Listening (15s) puis Learning (15s) avant Forwarding, soit un total de 30 secondes d'indisponibilite.

### Etape 6.4 — Verifier la connectivite

Depuis SW3 :

```
ping 10.10.10.1
```

Le ping doit reussir. Le trafic passe maintenant par SW2 pour atteindre SW1.

### Etape 6.5 — Retablir le lien

Sur SW1 :

```
configure terminal
interface GigabitEthernet0/2
 no shutdown
end
```

Verifiez que l'arbre STP revient a son etat optimal :

```
show spanning-tree vlan 10
```

SW3 Gi0/2 devrait redevenir root port (chemin direct, cout 4), et Gi0/1 redevenir alternate (bloque).

---

## Verification finale

- [ ] Les trois switches sont en mode `rapid-pvst` (`show spanning-tree | include mode`)
- [ ] Les VLANs 10 et 20 existent sur les trois switches
- [ ] SW1 est root bridge pour le VLAN 10 (priorite 24586)
- [ ] SW2 est root bridge pour le VLAN 20 (priorite 24596)
- [ ] SW2 est root bridge secondaire pour le VLAN 10 (priorite 28682)
- [ ] SW1 est root bridge secondaire pour le VLAN 20 (priorite 28692)
- [ ] Les roles des ports (root, designated, alternate) sont coherents avec l'analyse
- [ ] Les ports access ont PortFast active
- [ ] Les ports access ont BPDU Guard active
- [ ] Apres shutdown d'un lien, le port alternate prend le relais en moins d'une seconde
- [ ] Apres retablissement du lien, l'arbre STP revient a l'etat optimal
- [ ] Ping reussi entre les trois SVI VLAN 10 dans tous les cas

---

## Questions de reflexion

### Question 1 — Pourquoi STP est-il necessaire ? Que se passe-t-il sans STP dans une topologie en triangle ?

<details>
<summary>Voir la reponse</summary>

Sans STP, une topologie avec des liens redondants cree des **boucles de couche 2**. Les consequences sont catastrophiques :

1. **Broadcast storm** : une trame broadcast envoyee par un hote est retransmise sur tous les ports de chaque switch (sauf le port d'entree). Dans une boucle, cette trame circule indefiniment, se multiplie a chaque tour, et sature rapidement toute la bande passante.

2. **Instabilite de la table MAC** : la table CAM (Content Addressable Memory) du switch associe une adresse MAC a un port. Si la meme MAC est vue sur deux ports differents (a cause de la boucle), la table oscille en permanence (MAC flapping), ce qui cause des pertes de trames.

3. **Duplication de trames** : les trames unicast peuvent etre recues en double par le destinataire.

STP resout ce probleme en bloquant logiquement certains ports pour eliminer les boucles, tout en gardant les liens physiques disponibles en secours. C'est un protocole fondamental de tout reseau commute avec redondance.

</details>

### Question 2 — Quelle est la difference entre STP (802.1D), RSTP (802.1w) et MSTP (802.1s) ?

<details>
<summary>Voir la reponse</summary>

| Protocole | Standard | Convergence | Instances STP | Remarques |
|-----------|----------|-------------|---------------|-----------|
| **STP** | 802.1D | 30-50 secondes | 1 (CST) | Original, tres lent. Les ports passent par Blocking > Listening > Learning > Forwarding. |
| **RSTP** | 802.1w | < 1 seconde | 1 (CST) | Amelioration majeure de STP. Introduit les roles Alternate et Backup. Le port alternate bascule instantanement en Forwarding si le root port tombe. |
| **PVST+** | Cisco | 30-50 secondes | 1 par VLAN | Version Cisco de STP avec une instance par VLAN. Permet un root bridge different par VLAN. |
| **Rapid PVST+** | Cisco | < 1 seconde | 1 par VLAN | Combine RSTP et Per-VLAN. C'est le mode par defaut recommande sur les switches Cisco. |
| **MSTP** | 802.1s | < 1 seconde | Configurable (instances mappees a des groupes de VLANs) | Plus scalable que Rapid PVST+ car on peut grouper plusieurs VLANs dans une meme instance STP, reduisant la charge CPU. |

Pour le CCNA, il faut surtout maitriser PVST+ et Rapid PVST+. MSTP est un bonus.

</details>

### Question 3 — On a configure SW1 comme root primary avec `spanning-tree vlan 10 root primary`. Que se passe-t-il si on ajoute un nouveau switch avec une priorite de 4096 ?

<details>
<summary>Voir la reponse</summary>

La commande `root primary` fixe la priorite de SW1 a 24576 (ou 4096 de moins que le root actuel). Si un nouveau switch est ajoute avec une priorite de 4096, sa priorite totale pour le VLAN 10 sera 4096 + 10 = 4106, ce qui est inferieur a 24576 + 10 = 24586.

Le nouveau switch sera elu root bridge pour le VLAN 10, ce qui reconfigure tout l'arbre STP. C'est un scenario potentiellement dangereux :
- Les chemins optimaux changent
- Des ports precedemment actifs sont bloques et inversement
- La connectivite peut etre temporairement interrompue

**Comment se proteger ?** Avec **Root Guard**. Cette fonctionnalite, configuree sur les ports du switch actuel, empeche un switch connecte sur ce port de devenir root bridge. Si un BPDU superieur (priorite plus basse) est recu sur un port avec Root Guard, le port est mis en etat "root-inconsistent" (bloque).

```
interface GigabitEthernet0/1
 spanning-tree guard root
```

C'est une bonne pratique de securite STP complementaire a BPDU Guard.

</details>

### Question 4 — Pourquoi ne pas activer PortFast sur les ports trunk (inter-switches) ?

<details>
<summary>Voir la reponse</summary>

PortFast fait passer un port directement en Forwarding, sans attendre la convergence STP. Si on active PortFast sur un port trunk connectant deux switches :

1. Des qu'un switch est branche ou redemarré, le port passe immediatement en Forwarding
2. Le switch commence a transmettre des trames **avant** que STP ait calcule l'arbre sans boucle
3. Pendant ces quelques secondes, il peut y avoir une **boucle temporaire** qui declenche un broadcast storm

Avec RSTP, le risque est moindre car la convergence est rapide, mais le principe reste : PortFast est concu uniquement pour les ports edge (stations de travail, imprimantes, serveurs) qui ne generent pas de BPDUs et ne creent pas de boucles.

BPDU Guard est le filet de securite : si quelqu'un branche un switch par erreur sur un port PortFast, le port se desactive immediatement au lieu de creer une boucle.

</details>

### Question 5 — Comment STP choisit-il quel port bloquer quand deux switches ont le meme cout vers le root ?

<details>
<summary>Voir la reponse</summary>

Le processus de selection du root port suit un ordre de criteres de departage :

1. **Plus faible cout root** (Root Path Cost) : le cout cumule pour atteindre le root bridge
2. **Plus faible Bridge ID de l'emetteur** : si deux chemins ont le meme cout, on prefere celui qui passe par le switch avec le BID le plus bas
3. **Plus faible Port Priority de l'emetteur** : si c'est le meme switch voisin avec deux liens, on compare la priorite des ports (128 par defaut, configurable par increments de 16)
4. **Plus faible Port ID de l'emetteur** : en dernier recours, le port avec le numero le plus bas gagne

Ce mecanisme garantit qu'il n'y a jamais d'ambiguite. Un et un seul port sera elu root port sur chaque switch non-root.

On peut influencer ce choix avec la commande :
```
interface GigabitEthernet0/1
 spanning-tree vlan 10 port-priority 64
```

En reduisant la priorite (64 < 128), on rend ce port plus "attractif" pour devenir root port du cote du voisin.

</details>

---

## Solution complete

<details>
<summary>Voir la solution complete</summary>

### SW1 — Configuration complete

```
enable
configure terminal
hostname SW1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 15
 password cisco
 login
banner motd # Acces non autorise interdit #
!
vlan 10
 name Production
vlan 20
 name Serveurs
!
spanning-tree mode rapid-pvst
spanning-tree vlan 10 root primary
spanning-tree vlan 20 root secondary
spanning-tree portfast default
spanning-tree portfast bpduguard default
!
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface range FastEthernet0/1 - 10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
!
interface vlan 10
 ip address 10.10.10.1 255.255.255.0
 no shutdown
!
end
copy running-config startup-config
```

### SW2 — Configuration complete

```
enable
configure terminal
hostname SW2
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 15
 password cisco
 login
banner motd # Acces non autorise interdit #
!
vlan 10
 name Production
vlan 20
 name Serveurs
!
spanning-tree mode rapid-pvst
spanning-tree vlan 20 root primary
spanning-tree vlan 10 root secondary
spanning-tree portfast default
spanning-tree portfast bpduguard default
!
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface range FastEthernet0/1 - 10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
!
interface vlan 10
 ip address 10.10.10.2 255.255.255.0
 no shutdown
!
end
copy running-config startup-config
```

### SW3 — Configuration complete

```
enable
configure terminal
hostname SW3
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 15
 password cisco
 login
banner motd # Acces non autorise interdit #
!
vlan 10
 name Production
vlan 20
 name Serveurs
!
spanning-tree mode rapid-pvst
spanning-tree portfast default
spanning-tree portfast bpduguard default
!
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface range FastEthernet0/1 - 10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
!
interface vlan 10
 ip address 10.10.10.3 255.255.255.0
 no shutdown
!
end
copy running-config startup-config
```

</details>
