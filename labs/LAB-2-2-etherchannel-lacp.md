# Lab 2.2 — EtherChannel LACP : Agregation de liens

| Champ | Valeur |
|-------|--------|
| **Module** | 2 — Technologies de commutation et VLANs |
| **Topics couverts** | 2.4 (EtherChannel / Agregation de liens) |
| **Difficulte** | Intermediaire |
| **Duree estimee** | 30 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
       ┌─────────────────────────────────────────────┐
       │                                             │
       │    SW1                            SW2       │
       │    ┌──────┐                 ┌──────┐        │
       │    │      │  Fa0/21 ─────── Fa0/21 │        │
       │    │      │  Fa0/22 ─────── Fa0/22 │        │
       │    │      │  Fa0/23 ─────── Fa0/23 │        │
       │    │      │                 │      │        │
       │    │      │  Port-channel 1 │      │        │
       │    │      │  (LACP active)  │      │        │
       │    └──────┘                 └──────┘        │
       │                                             │
       │    VLAN 10 : 10.10.10.1     VLAN 10 : 10.10.10.2
       │    VLAN 20 : (pas d'IP)     VLAN 20 : (pas d'IP)
       │                                             │
       └─────────────────────────────────────────────┘
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | VLAN |
|----------|-----------|-----------|--------|------|
| SW1 | VLAN 10 | 10.10.10.1 | 255.255.255.0 | 10 |
| SW2 | VLAN 10 | 10.10.10.2 | 255.255.255.0 | 10 |
| SW1 | Port-channel 1 | — | — | trunk |
| SW2 | Port-channel 1 | — | — | trunk |

---

## Objectifs

1. Configurer les VLANs 10 et 20 sur les deux switches
2. Creer un EtherChannel LACP en mode active/active avec trois liens physiques
3. Configurer le port-channel comme trunk pour transporter les VLANs 10 et 20
4. Verifier le bon fonctionnement de l'agregation avec les commandes de diagnostic
5. Tester la resilience en desactivant un lien physique et en observant le comportement

---

## Prerequis

- Comprendre le concept d'agregation de liens (combiner plusieurs liens physiques en un lien logique)
- Connaitre la difference entre LACP (standard IEEE 802.3ad) et PAgP (proprietaire Cisco)
- Savoir configurer des VLANs et des trunks (Lab 2.1 recommande)

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

---

## Partie 1 — Configuration des VLANs

Avant de creer l'EtherChannel, on met en place les VLANs qui traverseront le lien agrege.

### Etape 1.1 — Creer les VLANs sur SW1

```
enable
configure terminal
vlan 10
 name Production
vlan 20
 name Backup
exit
```

### Etape 1.2 — Creer les memes VLANs sur SW2

```
enable
configure terminal
vlan 10
 name Production
vlan 20
 name Backup
exit
```

### Etape 1.3 — Configurer les SVI pour le test de connectivite

On attribue une adresse IP dans le VLAN 10 sur chaque switch pour pouvoir tester la connectivite.

**Sur SW1 :**

```
interface vlan 10
 ip address 10.10.10.1 255.255.255.0
 no shutdown
exit
```

**Sur SW2 :**

```
interface vlan 10
 ip address 10.10.10.2 255.255.255.0
 no shutdown
exit
```

### Etape 1.4 — Verification

```
show vlan brief
```

**Output attendu sur SW1 :**

```
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/1, Fa0/2, Fa0/3, Fa0/4
                                                Fa0/5, Fa0/6, Fa0/7, Fa0/8
                                                Fa0/9, Fa0/10, Fa0/11, Fa0/12
                                                Fa0/13, Fa0/14, Fa0/15, Fa0/16
                                                Fa0/17, Fa0/18, Fa0/19, Fa0/20
                                                Fa0/21, Fa0/22, Fa0/23, Fa0/24
                                                Gi0/1, Gi0/2
10   Production                       active
20   Backup                           active
1002 fddi-default                     active
1003 token-ring-default               active
1004 fddinet-default                  active
1005 trnet-default                    active
```

---

## Partie 2 — Configuration LACP (EtherChannel)

EtherChannel combine plusieurs liens physiques en un seul lien logique (port-channel). Cela augmente la bande passante disponible et offre de la redondance : si un lien tombe, le channel continue de fonctionner avec les liens restants.

On va utiliser LACP (Link Aggregation Control Protocol), qui est le standard IEEE 802.3ad. C'est le protocole recommande car il est interoperable entre constructeurs.

### Etape 2.1 — Configurer LACP sur SW1

> **Regle d'or** : configurez d'abord le channel-group sur les interfaces physiques, AVANT de configurer le trunk. La configuration appliquee au port-channel se propage aux interfaces membres, mais l'inverse peut creer des incoherences.

```
configure terminal
interface range FastEthernet0/21 - 23
 channel-group 1 mode active
 no shutdown
end
```

> **Explication** :
> - `interface range FastEthernet0/21 - 23` : selectionne les trois interfaces en une seule commande.
> - `channel-group 1 mode active` : cree le Port-channel 1 et place ces interfaces en mode LACP actif. Le mode `active` signifie que le switch initie activement la negociation LACP en envoyant des LACPDU (LACP Data Units).
> - Le numero du channel-group (1) correspond au numero du port-channel. `channel-group 1` cree automatiquement l'interface `Port-channel 1`.

### Etape 2.2 — Configurer LACP sur SW2

```
configure terminal
interface range FastEthernet0/21 - 23
 channel-group 1 mode active
 no shutdown
end
```

> **Modes LACP** : Il existe deux modes pour LACP :
> - `active` : le switch envoie des LACPDU pour initier la negociation
> - `passive` : le switch repond aux LACPDU mais n'en envoie pas spontanement
>
> Pour que LACP fonctionne, au moins un cote doit etre en `active`. Les combinaisons valides sont : active/active ou active/passive. La combinaison passive/passive ne fonctionne **pas** (aucun cote n'initie la negociation).
>
> Dans ce lab, on utilise active/active des deux cotes. C'est la configuration la plus fiable.

### Etape 2.3 — Verification rapide de la formation du channel

```
show etherchannel summary
```

**Output attendu sur SW1 :**

```
Flags:  D - down        P - in port-channel
        I - stand-alone s - suspended
        H - Hot-standby (LACP only)
        R - Layer 3      S - Layer 2
        U - in use       f - failed to allocate aggregator

        u - unsuitable for bundling
        w - waiting to be aggregated
        d - default port

Number of channel-groups in use: 1
Number of aggregators:           1

Group  Port-channel  Protocol    Ports
------+-------------+-----------+--------------------------------------------
1      Po1(SU)         LACP      Fa0/21(P)   Fa0/22(P)   Fa0/23(P)
```

> **Comment lire cet output** :
> - `Po1(SU)` : Port-channel 1, S = Layer 2, U = in use. C'est bon.
> - `Fa0/21(P)` : P signifie "in port-channel", donc l'interface participe activement au channel. C'est l'etat souhaite.
> - Si vous voyez `(D)` a la place de `(P)`, l'interface est down. Si vous voyez `(s)`, elle est suspendue (probablement un probleme de configuration incoherente).

---

## Partie 3 — Configuration trunk sur le port-channel

Maintenant que le channel est forme, on le configure comme trunk pour transporter nos VLANs.

### Etape 3.1 — Configurer le trunk sur SW1

```
configure terminal
interface Port-channel 1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
end
```

> **Important** : On configure le trunk sur l'interface logique `Port-channel 1`, pas sur les interfaces physiques individuelles. La configuration du port-channel se propage automatiquement aux interfaces membres. Si vous tentez de configurer le trunk sur les interfaces physiques alors qu'elles sont dans un channel-group, vous risquez des incoherences qui peuvent faire tomber le channel.

### Etape 3.2 — Configurer le trunk sur SW2

```
configure terminal
interface Port-channel 1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
end
```

### Etape 3.3 — Verification du trunk

```
show interfaces trunk
```

**Output attendu sur SW1 :**

```
Port        Mode         Encapsulation  Status        Native vlan
Po1         on           802.1q         trunking      1

Port        Vlans allowed on trunk
Po1         10,20

Port        Vlans allowed and active in management domain
Po1         10,20

Port        Vlans in spanning tree forwarding state and not pruned
Po1         10,20
```

> Le port-channel Po1 apparait comme un trunk unique. Les VLANs 10 et 20 sont autorises. Du point de vue de STP et de la table MAC, le port-channel est traite comme un seul lien logique.

---

## Partie 4 — Verification approfondie

### Etape 4.1 — show etherchannel summary

Cette commande donne une vue d'ensemble rapide :

```
show etherchannel summary
```

Verifiez que :
- Le protocole est bien LACP
- Les trois ports sont en etat (P)
- Le port-channel est en etat (SU)

### Etape 4.2 — show etherchannel port-channel

Cette commande donne des details sur le port-channel lui-meme :

```
show etherchannel port-channel
```

**Output attendu :**

```
                Channel-group listing:
                ----------------------

Group: 1
----------
                Port-channels in the group:
                ---------------------------

Port-channel: Po1
------------

Age of the Port-channel   = 00d:00h:05m:30s
Logical slot/port   = 2/1          Number of ports = 3
GC                  = 0x00000000      HotStandBy port = null
Port state          = Port-channel Ag-Inuse

Ports in the Port-channel:

Index   Load   Port     EC state        No of bits
------+------+------+------------------+-----------
  0     0x00   Fa0/21   Active             0
  0     0x00   Fa0/22   Active             0
  0     0x00   Fa0/23   Active             0

Time since last port bundled:    00d:00h:04m:15s    Fa0/23
```

> L'etat "Active" pour chaque port confirme que LACP fonctionne correctement. Le champ "Number of ports = 3" confirme que les trois liens participent au channel.

### Etape 4.3 — show interfaces port-channel 1

```
show interfaces port-channel 1
```

**Output attendu (extraits pertinents) :**

```
Port-channel1 is up, line protocol is up (connected)
  Hardware is EtherChannel, address is 0001.4200.1500 (bia 0001.4200.1500)
  MTU 1500 bytes, BW 300000 Kbit, DLY 100 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  ...
  Members in this channel: Fa0/21 Fa0/22 Fa0/23
```

> **Points cles** :
> - `BW 300000 Kbit` : la bande passante affichee est 300 Mbps (3 x 100 Mbps), ce qui confirme l'agregation des trois liens FastEthernet.
> - `Members in this channel` : liste les interfaces physiques qui composent le channel.
> - L'adresse MAC du port-channel est generalement celle du port membre ayant le plus petit numero.

### Etape 4.4 — Test de connectivite

Depuis SW1, pinguez SW2 via les SVI du VLAN 10 :

```
ping 10.10.10.2
```

**Output attendu :**

```
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.10.10.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 0/0/1 ms
```

---

## Partie 5 — Test de resilience

L'un des principaux avantages d'EtherChannel est la redondance. Si un lien physique tombe, le channel continue de fonctionner avec les liens restants, sans interruption perceptible.

### Etape 5.1 — Shutdown d'un lien

Sur SW1, desactivez un des liens membres :

```
configure terminal
interface FastEthernet0/21
 shutdown
end
```

### Etape 5.2 — Verifier l'etat du channel

```
show etherchannel summary
```

**Output attendu :**

```
Group  Port-channel  Protocol    Ports
------+-------------+-----------+--------------------------------------------
1      Po1(SU)         LACP      Fa0/21(D)   Fa0/22(P)   Fa0/23(P)
```

> Fa0/21 est maintenant (D) = down, mais le port-channel Po1 reste (SU) = in use. Le channel fonctionne avec deux liens au lieu de trois. La bande passante disponible a diminue (200 Mbps au lieu de 300 Mbps), mais la connectivite est maintenue.

### Etape 5.3 — Verifier la connectivite

```
ping 10.10.10.2
```

Le ping doit toujours reussir. C'est la resilience en action.

### Etape 5.4 — Desactiver un deuxieme lien

```
configure terminal
interface FastEthernet0/22
 shutdown
end
```

```
show etherchannel summary
```

**Output attendu :**

```
Group  Port-channel  Protocol    Ports
------+-------------+-----------+--------------------------------------------
1      Po1(SU)         LACP      Fa0/21(D)   Fa0/22(D)   Fa0/23(P)
```

> Le channel tient toujours avec un seul lien. Le ping continue de fonctionner. Mais si Fa0/23 tombe aussi, le channel passe en etat (SD) = down et toute connectivite est perdue.

### Etape 5.5 — Retablir les liens

```
configure terminal
interface range FastEthernet0/21 - 22
 no shutdown
end
```

Attendez quelques secondes, puis verifiez :

```
show etherchannel summary
```

Les trois ports doivent revenir en etat (P). LACP renegocie automatiquement l'ajout des liens au channel.

---

## Verification finale

- [ ] Les VLANs 10 et 20 existent sur les deux switches
- [ ] Le Port-channel 1 est forme en LACP avec les trois liens (Fa0/21, Fa0/22, Fa0/23)
- [ ] Les trois interfaces membres sont en etat (P) dans `show etherchannel summary`
- [ ] Le port-channel est configure en trunk avec les VLANs 10 et 20 autorises
- [ ] Le ping entre les SVI VLAN 10 (10.10.10.1 <-> 10.10.10.2) fonctionne
- [ ] Apres shutdown d'un lien, le channel reste up et le ping continue
- [ ] Apres retablissement du lien, il rejoint automatiquement le channel

---

## Questions de reflexion

### Question 1 — Quelle est la difference entre LACP et PAgP, et lequel choisir ?

<details>
<summary>Voir la reponse</summary>

**LACP** (Link Aggregation Control Protocol) est le standard IEEE 802.3ad (renomme 802.1AX). Il est supporte par tous les constructeurs reseau (Cisco, Juniper, HP/Aruba, etc.). Ses modes sont `active` et `passive`.

**PAgP** (Port Aggregation Protocol) est un protocole proprietaire Cisco. Il ne fonctionne qu'entre equipements Cisco. Ses modes sont `desirable` et `auto`.

**Lequel choisir ?** Toujours LACP, sauf si vous etes dans un environnement 100% Cisco et que vous avez une raison specifique d'utiliser PAgP. L'interoperabilite de LACP en fait le choix par defaut. Pour le CCNA, il faut connaitre les deux, mais LACP est le protocole recommande.

Il existe aussi le mode `on` (statique, sans protocole de negociation). Ce mode force la creation du channel sans aucune verification. C'est risque car si un cote est en `on` et l'autre n'est pas configure, des boucles STP peuvent se produire. A eviter en production.

</details>

### Question 2 — Pourquoi ne pas configurer le trunk sur les interfaces physiques individuelles avant de creer le channel-group ?

<details>
<summary>Voir la reponse</summary>

Toutes les interfaces membres d'un EtherChannel doivent avoir une configuration identique. Si vous configurez Fa0/21 en trunk mais pas Fa0/22, puis que vous tentez de les regrouper dans un channel-group, le switch refuse ou suspend les ports incoherents.

La bonne methode est :
1. Creer le channel-group d'abord (`channel-group 1 mode active`)
2. Configurer le trunk sur l'interface Port-channel (`interface Port-channel 1` > `switchport mode trunk`)

La configuration du port-channel se propage automatiquement a tous les membres. Cela garantit la coherence.

Les parametres qui doivent etre identiques sur tous les membres incluent : le mode (access/trunk), le VLAN natif, les VLANs autorises, la vitesse, le duplex, et le type de media.

</details>

### Question 3 — On a 3 liens FastEthernet dans le channel. La bande passante est-elle reellement de 300 Mbps ?

<details>
<summary>Voir la reponse</summary>

Oui et non. La bande passante **agregee** est bien de 300 Mbps, mais un **flux individuel** (une conversation entre deux hotes) ne beneficiera que de 100 Mbps.

Voici pourquoi : EtherChannel utilise un algorithme de repartition de charge (load-balancing) base sur des criteres comme l'adresse MAC source, l'adresse MAC destination, l'adresse IP source/destination, ou un hash de ces valeurs. Chaque flux est affecte a un lien physique specifique. Un flux donne ne sera jamais reparti sur plusieurs liens simultanement (sinon les trames arriveraient dans le desordre).

Le gain de bande passante se manifeste quand **plusieurs flux** traversent le channel en meme temps : chaque flux peut emprunter un lien different, ce qui donne une utilisation agregee qui peut atteindre 300 Mbps.

Vous pouvez voir la methode de load-balancing avec `show etherchannel load-balance`.

</details>

### Question 4 — Que se passe-t-il si on configure un cote en LACP active et l'autre en PAgP desirable ?

<details>
<summary>Voir la reponse</summary>

Le channel ne se formera **pas**. LACP et PAgP sont deux protocoles completement differents et incompatibles. Un cote envoie des LACPDU, l'autre des PAgPDU : aucun des deux ne comprend les messages de l'autre.

Les liens resteront individuels (pas d'agregation) et STP les traitera comme des liens separes, bloquant potentiellement certains d'entre eux pour eviter les boucles.

C'est une erreur de configuration classique. Pour le depanner, utilisez `show etherchannel summary` : vous verrez les ports en etat (I) = stand-alone ou (s) = suspended au lieu de (P).

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
 name Backup
!
interface range FastEthernet0/21 - 23
 channel-group 1 mode active
 no shutdown
!
interface Port-channel 1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
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
 name Backup
!
interface range FastEthernet0/21 - 23
 channel-group 1 mode active
 no shutdown
!
interface Port-channel 1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface vlan 10
 ip address 10.10.10.2 255.255.255.0
 no shutdown
!
end
copy running-config startup-config
```

</details>
