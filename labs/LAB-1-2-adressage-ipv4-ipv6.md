# LAB 1.2 — Adressage IPv4 et IPv6 dual-stack avec routage statique

| Info | Detail |
|------|--------|
| **Module** | 1 — Fondamentaux reseau |
| **Topics couverts** | 1.6 (Adressage IPv4), 1.7 (Adresses privees IPv4), 1.8 (Adressage IPv6), 1.9 (Sous-reseaux IPv4) |
| **Difficulte** | Intermediaire |
| **Duree estimee** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
    LAN1 (10.1.1.0/24)                                          LAN2 (10.1.2.0/24)
   2001:db8:1:1::/64                                           2001:db8:1:2::/64

  ┌─────┐  ┌─────┐                                           ┌─────┐  ┌─────┐
  │ PC1 │  │ PC2 │                                           │ PC3 │  │ PC4 │
  │ .10 │  │ .11 │                                           │ .10 │  │ .11 │
  └──┬──┘  └──┬──┘                                           └──┬──┘  └──┬──┘
     │        │                                                  │        │
     │  Fa0/1 │  Fa0/2                                    Fa0/1 │  Fa0/2 │
  ┌──┴────────┴──┐                                        ┌──┴────────┴──┐
  │     SW1      │                                        │     SW2      │
  │    2960      │                                        │    2960      │
  └──────┬───────┘                                        └──────┬───────┘
         │ Gi0/1                                                 │ Gi0/1
         │                                                       │
         │ Gi0/0                   Lien serie              Gi0/0 │
    ┌────┴────┐              10.1.100.0/30             ┌────┴────┐
    │         │  Se0/0/0   2001:db8:1:100::/64  Se0/0/0│         │
    │   R1    ├────────────────────────────────────────┤   R2    │
    │  2911   │    .1                           .2     │  2911   │
    │         │                                        │         ├──── Gi0/1
    └─────────┘                                        └─────────┘      │
                                                                        │
                                                                   ┌────┴────┐
                                                                   │   SW3   │
                                                                   │  2960   │
                                                                   └────┬────┘
                                                                        │ Fa0/1
                                                                   ┌────┴────┐
                                                                   │  PC5    │
                                                                   │  .10    │
                                                                   └─────────┘
                                                              LAN3 (10.1.3.0/24)
                                                             2001:db8:1:3::/64
```

---

## Tableau d'adressage

### IPv4

| Equipement | Interface | Adresse IPv4 | Masque | Passerelle par defaut |
|------------|-----------|-------------|--------|----------------------|
| R1 | Gi0/0 | 10.1.1.1 | 255.255.255.0 | — |
| R1 | Se0/0/0 | 10.1.100.1 | 255.255.255.252 | — |
| R2 | Se0/0/0 | 10.1.100.2 | 255.255.255.252 | — |
| R2 | Gi0/0 | 10.1.2.1 | 255.255.255.0 | — |
| R2 | Gi0/1 | 10.1.3.1 | 255.255.255.0 | — |
| PC1 | FastEthernet0 | 10.1.1.10 | 255.255.255.0 | 10.1.1.1 |
| PC2 | FastEthernet0 | 10.1.1.11 | 255.255.255.0 | 10.1.1.1 |
| PC3 | FastEthernet0 | 10.1.2.10 | 255.255.255.0 | 10.1.2.1 |
| PC4 | FastEthernet0 | 10.1.2.11 | 255.255.255.0 | 10.1.2.1 |
| PC5 | FastEthernet0 | 10.1.3.10 | 255.255.255.0 | 10.1.3.1 |

### IPv6

| Equipement | Interface | Adresse IPv6 GUA | Link-local |
|------------|-----------|-----------------|------------|
| R1 | Gi0/0 | 2001:db8:1:1::1/64 | FE80::1 |
| R1 | Se0/0/0 | 2001:db8:1:100::1/64 | FE80::1 |
| R2 | Se0/0/0 | 2001:db8:1:100::2/64 | FE80::2 |
| R2 | Gi0/0 | 2001:db8:1:2::1/64 | FE80::2 |
| R2 | Gi0/1 | 2001:db8:1:3::1/64 | FE80::2 |
| PC1 | FastEthernet0 | 2001:db8:1:1::10/64 | Auto |
| PC2 | FastEthernet0 | 2001:db8:1:1::11/64 | Auto |
| PC3 | FastEthernet0 | 2001:db8:1:2::10/64 | Auto |
| PC4 | FastEthernet0 | 2001:db8:1:2::11/64 | Auto |
| PC5 | FastEthernet0 | 2001:db8:1:3::10/64 | Auto |

---

## Objectifs

1. Analyser un plan d'adressage IPv4 avec subnetting (comprendre le /30 pour les liens point-a-point)
2. Configurer l'adressage IPv4 sur tous les equipements
3. Configurer l'adressage IPv6 en dual-stack (GUA + link-local) sur les routeurs et les PCs
4. Mettre en place des routes statiques IPv4 et IPv6 pour assurer la connectivite inter-LAN
5. Verifier la connectivite de bout en bout en IPv4 et IPv6

---

## Prerequis

- Avoir realise le LAB 1.1 (cablage et configuration IP de base)
- Comprendre la notation CIDR (/24, /30, /64)
- Connaitre la difference entre adresse reseau, adresse hote et adresse de broadcast
- Notion de base sur l'hexadecimal (pour IPv6)

---

## Configuration de depart

Placez les equipements suivants dans Packet Tracer :

- 2x Routeur Cisco 2911 (R1, R2)
- 3x Switch Cisco 2960 (SW1, SW2, SW3)
- 5x PC generiques (PC1 a PC5)

**Important pour le lien serie :** Les routeurs 2911 n'ont pas de port serie par defaut. Vous devez ajouter un module :

1. Cliquez sur le routeur, allez dans l'onglet **Physical**
2. **Eteignez le routeur** (cliquez sur le bouton power)
3. Faites glisser le module **HWIC-2T** dans un emplacement libre
4. **Rallumez le routeur**
5. Repetez pour le second routeur

Cablez ensuite la topologie avec des **cables droits** partout, sauf le lien serie R1-R2 qui utilise un **cable serie DCE** (cliquer sur R1 Se0/0/0 puis R2 Se0/0/0).

> Le cable serie DCE fournit le signal d'horloge. Le cote DCE doit configurer le `clock rate`. Packet Tracer indique quel cote est DCE quand vous cliquez sur l'interface.

---

## Partie 1 — Planification de l'adressage (exercice de subnetting)

Avant de configurer, prenez un moment pour comprendre le plan d'adressage.

### Etape 1.1 : Analyser les sous-reseaux IPv4

Le reseau global utilise 10.1.0.0/16 decoupe en sous-reseaux :

| Sous-reseau | Adresse reseau | Plage d'hotes utilisables | Broadcast | Masque |
|-------------|---------------|--------------------------|-----------|--------|
| LAN1 | 10.1.1.0 | 10.1.1.1 - 10.1.1.254 | 10.1.1.255 | /24 (255.255.255.0) |
| LAN2 | 10.1.2.0 | 10.1.2.1 - 10.1.2.254 | 10.1.2.255 | /24 (255.255.255.0) |
| LAN3 | 10.1.3.0 | 10.1.3.1 - 10.1.3.254 | 10.1.3.255 | /24 (255.255.255.0) |
| Lien serie | 10.1.100.0 | 10.1.100.1 - 10.1.100.2 | 10.1.100.3 | /30 (255.255.255.252) |

### Etape 1.2 : Comprendre le masque /30

**Pourquoi /30 pour un lien point-a-point ?**

Un masque /30 donne 4 adresses au total : 1 adresse reseau + 2 adresses hotes + 1 broadcast. C'est le minimum necessaire pour connecter exactement deux equipements. Utiliser un /24 (254 adresses hotes) pour un lien entre deux routeurs serait un gaspillage enorme d'adresses.

Calcul :
- /30 = 32 - 30 = 2 bits hote = 2^2 = 4 adresses totales
- Adresses utilisables : 4 - 2 = **2 hotes** (parfait pour un lien point-a-point)

> **Point exam CCNA :** Le subnetting est un sujet majeur de l'examen. Vous devez savoir calculer rapidement le nombre d'hotes, l'adresse reseau et le broadcast pour n'importe quel masque. Le /30 est le classique des liens inter-routeurs. En IPv6, on utilise souvent un /127 (equivalent) ou un /64 meme sur les liens point-a-point (l'espace d'adressage IPv6 est immense).

### Etape 1.3 : Comprendre le plan IPv6

Chaque sous-reseau IPv6 utilise un prefixe /64 issu de 2001:db8:1::/48 :

| Sous-reseau | Prefixe IPv6 | 4e quartet (subnet ID) |
|-------------|-------------|----------------------|
| LAN1 | 2001:db8:1:**1**::/64 | 0001 |
| LAN2 | 2001:db8:1:**2**::/64 | 0002 |
| LAN3 | 2001:db8:1:**3**::/64 | 0003 |
| Lien serie | 2001:db8:1:**100**::/64 | 0100 |

Le 4e quartet (16 bits) sert de "subnet ID", ce qui permet 65 536 sous-reseaux. Chaque /64 offre 2^64 adresses hotes (un nombre astronomique).

> **Point exam CCNA :** Les adresses commencant par `2001:db8::/32` sont reservees a la **documentation** (RFC 3849). On les utilise dans les labs et exemples. En production, vous utiliserez des prefixes GUA attribues par votre fournisseur d'acces.

---

## Partie 2 — Configuration IPv4 sur routeurs et PCs

### Etape 2.1 : Configurer R1

Cliquez sur R1, allez dans l'onglet CLI :

```
Router> enable
Router# configure terminal
Router(config)# hostname R1

! --- Interface LAN vers SW1 ---
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip address 10.1.1.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit

! --- Interface serie vers R2 ---
R1(config)# interface Serial0/0/0
R1(config-if)# ip address 10.1.100.1 255.255.255.252
R1(config-if)# clock rate 128000
R1(config-if)# no shutdown
R1(config-if)# exit
R1(config)# exit
R1#
```

**Pourquoi `clock rate` ?** Sur un lien serie, un cote fournit le signal d'horloge (cote DCE) et l'autre le recoit (cote DTE). Le `clock rate` se configure uniquement sur le cote DCE. Si R1 est le cote DTE, omettez cette commande et configurez-la sur R2 a la place. Packet Tracer vous indiquera le cote DCE quand vous ferez `show controllers serial 0/0/0`.

Pour verifier quel cote est DCE :

```
R1# show controllers serial 0/0/0
```

Cherchez la ligne `DCE V.35` ou `DTE V.35` dans l'output.

### Etape 2.2 : Configurer R2

```
Router> enable
Router# configure terminal
Router(config)# hostname R2

! --- Interface serie vers R1 ---
R2(config)# interface Serial0/0/0
R2(config-if)# ip address 10.1.100.2 255.255.255.252
R2(config-if)# no shutdown
R2(config-if)# exit

! --- Interface LAN2 vers SW2 ---
R2(config)# interface GigabitEthernet0/0
R2(config-if)# ip address 10.1.2.1 255.255.255.0
R2(config-if)# no shutdown
R2(config-if)# exit

! --- Interface LAN3 vers SW3 ---
R2(config)# interface GigabitEthernet0/1
R2(config-if)# ip address 10.1.3.1 255.255.255.0
R2(config-if)# no shutdown
R2(config-if)# exit
R2(config)# exit
R2#
```

> **Note :** Si R2 est le cote DCE du lien serie, ajoutez `clock rate 128000` sous l'interface Serial0/0/0 de R2 au lieu de R1.

### Etape 2.3 : Configurer les PCs

Accedez a **Desktop > IP Configuration** sur chaque PC :

**PC1 :**

| Parametre | Valeur |
|-----------|--------|
| IPv4 Address | 10.1.1.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 10.1.1.1 |

**PC2 :**

| Parametre | Valeur |
|-----------|--------|
| IPv4 Address | 10.1.1.11 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 10.1.1.1 |

**PC3 :**

| Parametre | Valeur |
|-----------|--------|
| IPv4 Address | 10.1.2.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 10.1.2.1 |

**PC4 :**

| Parametre | Valeur |
|-----------|--------|
| IPv4 Address | 10.1.2.11 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 10.1.2.1 |

**PC5 :**

| Parametre | Valeur |
|-----------|--------|
| IPv4 Address | 10.1.3.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 10.1.3.1 |

### Etape 2.4 : Verification rapide IPv4 (locale)

A ce stade, testez la connectivite locale (au sein de chaque LAN) :

Depuis PC1 :
```
C:\> ping 10.1.1.1
```

**Output attendu :**

```
Pinging 10.1.1.1 with 32 bytes of data:

Reply from 10.1.1.1: bytes=32 time<1ms TTL=255
Reply from 10.1.1.1: bytes=32 time<1ms TTL=255
Reply from 10.1.1.1: bytes=32 time<1ms TTL=255
Reply from 10.1.1.1: bytes=32 time<1ms TTL=255

Ping statistics for 10.1.1.1:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

Depuis R1, testez le lien serie :
```
R1# ping 10.1.100.2
```

**Output attendu :**

```
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.100.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

> **Important :** A ce stade, un ping de PC1 vers PC3 (10.1.2.10) echouera. C'est normal : les routeurs ne savent pas encore comment atteindre les reseaux distants. Il faut configurer le routage (Partie 4).

---

## Partie 3 — Configuration IPv6 dual-stack

### Etape 3.1 : Activer le routage IPv6

Par defaut, les routeurs Cisco ne routent pas le trafic IPv6. Il faut activer cette fonctionnalite globalement.

Sur R1 :

```
R1# configure terminal
R1(config)# ipv6 unicast-routing
```

Sur R2 :

```
R2# configure terminal
R2(config)# ipv6 unicast-routing
```

**Pourquoi cette commande est-elle necessaire ?** IPv4 est route par defaut sur les routeurs Cisco, mais IPv6 ne l'est pas. Sans `ipv6 unicast-routing`, le routeur accepte des adresses IPv6 sur ses interfaces mais ne transfere pas les paquets IPv6 entre elles. C'est un piege classique.

### Etape 3.2 : Configurer IPv6 sur R1

```
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ipv6 address 2001:db8:1:1::1/64
R1(config-if)# ipv6 address FE80::1 link-local
R1(config-if)# exit

R1(config)# interface Serial0/0/0
R1(config-if)# ipv6 address 2001:db8:1:100::1/64
R1(config-if)# ipv6 address FE80::1 link-local
R1(config-if)# exit
R1(config)# exit
R1#
```

**Deux adresses par interface — pourquoi ?**

- **GUA (Global Unicast Address)** : `2001:db8:1:1::1/64` — c'est l'equivalent de l'adresse IPv4 publique. Routable sur Internet.
- **Link-local** : `FE80::1` — utilisee uniquement pour la communication sur le lien direct (meme segment). Les protocoles de routage (OSPF, EIGRP) utilisent les adresses link-local pour echanger entre voisins.

On configure manuellement l'adresse link-local a `FE80::1` pour la simplicite. Sans cette commande, le routeur genererait automatiquement une adresse link-local basee sur l'adresse MAC (format EUI-64), qui serait plus longue et moins lisible.

### Etape 3.3 : Configurer IPv6 sur R2

```
R2# configure terminal

R2(config)# interface Serial0/0/0
R2(config-if)# ipv6 address 2001:db8:1:100::2/64
R2(config-if)# ipv6 address FE80::2 link-local
R2(config-if)# exit

R2(config)# interface GigabitEthernet0/0
R2(config-if)# ipv6 address 2001:db8:1:2::1/64
R2(config-if)# ipv6 address FE80::2 link-local
R2(config-if)# exit

R2(config)# interface GigabitEthernet0/1
R2(config-if)# ipv6 address 2001:db8:1:3::1/64
R2(config-if)# ipv6 address FE80::2 link-local
R2(config-if)# exit
R2(config)# exit
R2#
```

### Etape 3.4 : Configurer IPv6 sur les PCs

Dans Packet Tracer, allez dans **Desktop > IP Configuration** de chaque PC, puis l'onglet IPv6 (ou la section IPv6 selon la version) :

- Selectionnez **Static** pour la configuration IPv6
- Desactivez l'auto-configuration (SLAAC/DHCPv6) si necessaire

**PC1 :**

| Parametre | Valeur |
|-----------|--------|
| IPv6 Address | 2001:db8:1:1::10/64 |
| Default Gateway | FE80::1 |

**PC2 :**

| Parametre | Valeur |
|-----------|--------|
| IPv6 Address | 2001:db8:1:1::11/64 |
| Default Gateway | FE80::1 |

**PC3 :**

| Parametre | Valeur |
|-----------|--------|
| IPv6 Address | 2001:db8:1:2::10/64 |
| Default Gateway | FE80::2 |

**PC4 :**

| Parametre | Valeur |
|-----------|--------|
| IPv6 Address | 2001:db8:1:2::11/64 |
| Default Gateway | FE80::2 |

**PC5 :**

| Parametre | Valeur |
|-----------|--------|
| IPv6 Address | 2001:db8:1:3::10/64 |
| Default Gateway | FE80::2 |

> **Attention :** La passerelle par defaut IPv6 sur les PCs est l'adresse **link-local** du routeur (FE80::1 ou FE80::2), pas l'adresse GUA. C'est une difference importante avec IPv4 ou on utilise l'adresse "normale" du routeur.

### Etape 3.5 : Verifier la configuration IPv6 sur les routeurs

Sur R1 :

```
R1# show ipv6 interface brief
```

**Output attendu :**

```
GigabitEthernet0/0         [up/up]
    FE80::1
    2001:DB8:1:1::1
GigabitEthernet0/1         [administratively down/down]
    unassigned
GigabitEthernet0/2         [administratively down/down]
    unassigned
Serial0/0/0                [up/up]
    FE80::1
    2001:DB8:1:100::1
Vlan1                      [administratively down/down]
    unassigned
```

Chaque interface active doit afficher **deux adresses** : la link-local (FE80::1) et la GUA.

---

## Partie 4 — Routes statiques IPv4 et IPv6

Sans routes statiques, les routeurs ne connaissent que les reseaux directement connectes. R1 ne sait pas comment atteindre 10.1.2.0/24 ni 10.1.3.0/24, et R2 ne sait pas comment atteindre 10.1.1.0/24.

### Etape 4.1 : Routes statiques IPv4 sur R1

R1 doit pouvoir atteindre LAN2 et LAN3, qui sont derriere R2. Le prochain saut est 10.1.100.2 (l'adresse serie de R2).

```
R1# configure terminal
R1(config)# ip route 10.1.2.0 255.255.255.0 10.1.100.2
R1(config)# ip route 10.1.3.0 255.255.255.0 10.1.100.2
R1(config)# exit
R1#
```

**Lecture de la commande :** `ip route [reseau destination] [masque] [prochain saut]`

- "Pour atteindre le reseau 10.1.2.0/24, envoie le paquet a 10.1.100.2"
- "Pour atteindre le reseau 10.1.3.0/24, envoie le paquet a 10.1.100.2"

### Etape 4.2 : Routes statiques IPv4 sur R2

R2 doit pouvoir atteindre LAN1, qui est derriere R1. Le prochain saut est 10.1.100.1.

```
R2# configure terminal
R2(config)# ip route 10.1.1.0 255.255.255.0 10.1.100.1
R2(config)# exit
R2#
```

R2 n'a besoin que d'une seule route statique car LAN2 et LAN3 sont directement connectes a ses interfaces.

### Etape 4.3 : Verifier la table de routage IPv4

Sur R1 :

```
R1# show ip route
```

**Output attendu (extraits pertinents) :**

```
Gateway of last resort is not set

     10.0.0.0/8 is variably subnetted, 4 subnets, 2 masks
C       10.1.1.0/24 is directly connected, GigabitEthernet0/0
L       10.1.1.1/32 is directly connected, GigabitEthernet0/0
C       10.1.100.0/30 is directly connected, Serial0/0/0
L       10.1.100.1/32 is directly connected, Serial0/0/0
S       10.1.2.0/24 [1/0] via 10.1.100.2
S       10.1.3.0/24 [1/0] via 10.1.100.2
```

Les codes importants :
- **C** = Connected (directement connecte)
- **L** = Local (l'adresse IP propre de l'interface)
- **S** = Static (route statique configuree manuellement)

### Etape 4.4 : Routes statiques IPv6 sur R1

En IPv6, le prochain saut est l'adresse **link-local** du voisin (et non l'adresse GUA). Comme les adresses link-local ne sont pas uniques globalement, on doit preciser l'interface de sortie.

```
R1# configure terminal
R1(config)# ipv6 route 2001:db8:1:2::/64 Serial0/0/0 FE80::2
R1(config)# ipv6 route 2001:db8:1:3::/64 Serial0/0/0 FE80::2
R1(config)# exit
R1#
```

**Syntaxe :** `ipv6 route [prefixe destination] [interface de sortie] [link-local du prochain saut]`

### Etape 4.5 : Routes statiques IPv6 sur R2

```
R2# configure terminal
R2(config)# ipv6 route 2001:db8:1:1::/64 Serial0/0/0 FE80::1
R2(config)# exit
R2#
```

### Etape 4.6 : Verifier la table de routage IPv6

Sur R1 :

```
R1# show ipv6 route
```

**Output attendu (extraits pertinents) :**

```
IPv6 Routing Table - 7 entries
C   2001:DB8:1:1::/64 [0/0]
     via GigabitEthernet0/0, directly connected
L   2001:DB8:1:1::1/128 [0/0]
     via GigabitEthernet0/0, receive
S   2001:DB8:1:2::/64 [1/0]
     via FE80::2, Serial0/0/0
S   2001:DB8:1:3::/64 [1/0]
     via FE80::2, Serial0/0/0
C   2001:DB8:1:100::/64 [0/0]
     via Serial0/0/0, directly connected
L   2001:DB8:1:100::1/128 [0/0]
     via Serial0/0/0, receive
L   FF00::/8 [0/0]
     via Null0, receive
```

---

## Partie 5 — Verification complete

### Etape 5.1 : Test de connectivite IPv4 de bout en bout

Depuis **PC1** (Command Prompt) :

```
C:\> ping 10.1.2.10
```

**Output attendu :**

```
Pinging 10.1.2.10 with 32 bytes of data:

Reply from 10.1.2.10: bytes=32 time=5ms TTL=126
Reply from 10.1.2.10: bytes=32 time=4ms TTL=126
Reply from 10.1.2.10: bytes=32 time=3ms TTL=126
Reply from 10.1.2.10: bytes=32 time=4ms TTL=126

Ping statistics for 10.1.2.10:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

Remarquez le **TTL=126** : le paquet a traverse 2 routeurs (TTL initial 128 - 2 sauts = 126).

Effectuez tous les tests suivants depuis PC1 :

| Destination | Adresse | Resultat attendu |
|-------------|---------|-----------------|
| R1 (passerelle) | 10.1.1.1 | Succes |
| R2 (serie) | 10.1.100.2 | Succes |
| PC3 (LAN2) | 10.1.2.10 | Succes |
| PC4 (LAN2) | 10.1.2.11 | Succes |
| PC5 (LAN3) | 10.1.3.10 | Succes |

### Etape 5.2 : Traceroute IPv4

Depuis PC1, tracez le chemin vers PC5 :

```
C:\> tracert 10.1.3.10
```

**Output attendu :**

```
Tracing route to 10.1.3.10 over a maximum of 30 hops:

  1   0 ms    0 ms    0 ms    10.1.1.1
  2   1 ms    1 ms    1 ms    10.1.100.2
  3   1 ms    2 ms    1 ms    10.1.3.10

Trace complete.
```

Le traceroute confirme le chemin : PC1 -> R1 (10.1.1.1) -> R2 (10.1.100.2) -> PC5 (10.1.3.10). Trois sauts, ce qui correspond bien a la topologie.

### Etape 5.3 : Test de connectivite IPv6

Depuis PC1 :

```
C:\> ping 2001:db8:1:2::10
```

**Output attendu :**

```
Pinging 2001:db8:1:2::10 with 32 bytes of data:

Reply from 2001:DB8:1:2::10: bytes=32 time=5ms TTL=126
Reply from 2001:DB8:1:2::10: bytes=32 time=4ms TTL=126
Reply from 2001:DB8:1:2::10: bytes=32 time=3ms TTL=126
Reply from 2001:DB8:1:2::10: bytes=32 time=4ms TTL=126

Ping statistics for 2001:DB8:1:2::10:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

Testez aussi vers PC5 en IPv6 :

```
C:\> ping 2001:db8:1:3::10
```

### Etape 5.4 : Verification depuis les routeurs

Sur R1, verifiez la connectivite IPv6 vers R2 :

```
R1# ping ipv6 2001:db8:1:100::2
```

**Output attendu :**

```
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 2001:DB8:1:100::2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

### Etape 5.5 : Vue d'ensemble des interfaces

Sur R2, verifiez que tout est operationnel :

```
R2# show ip interface brief
```

**Output attendu :**

```
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     10.1.2.1        YES manual up                    up
GigabitEthernet0/1     10.1.3.1        YES manual up                    up
GigabitEthernet0/2     unassigned      YES unset  administratively down down
Serial0/0/0            10.1.100.2      YES manual up                    up
Vlan1                  unassigned      YES unset  administratively down down
```

```
R2# show ipv6 interface brief
```

**Output attendu :**

```
GigabitEthernet0/0         [up/up]
    FE80::2
    2001:DB8:1:2::1
GigabitEthernet0/1         [up/up]
    FE80::2
    2001:DB8:1:3::1
GigabitEthernet0/2         [administratively down/down]
    unassigned
Serial0/0/0                [up/up]
    FE80::2
    2001:DB8:1:100::2
Vlan1                      [administratively down/down]
    unassigned
```

---

## Verification finale

Avant de considerer ce lab comme termine, verifiez chaque critere :

- [ ] Tous les equipements sont cables correctement (cables droits + cable serie DCE)
- [ ] Le module HWIC-2T est installe sur les deux routeurs
- [ ] `ipv6 unicast-routing` est active sur R1 et R2
- [ ] Toutes les interfaces des routeurs sont `up/up` (show ip interface brief)
- [ ] Chaque interface a son adresse IPv4 ET son adresse IPv6 (GUA + link-local)
- [ ] Les 5 PCs ont leurs adresses IPv4 et IPv6 configurees avec les bonnes passerelles
- [ ] Les routes statiques IPv4 sont en place (2 sur R1, 1 sur R2)
- [ ] Les routes statiques IPv6 sont en place (2 sur R1, 1 sur R2)
- [ ] Ping IPv4 de PC1 vers PC3 (10.1.2.10) : succes
- [ ] Ping IPv4 de PC1 vers PC5 (10.1.3.10) : succes
- [ ] Ping IPv6 de PC1 vers PC3 (2001:db8:1:2::10) : succes
- [ ] Ping IPv6 de PC1 vers PC5 (2001:db8:1:3::10) : succes
- [ ] Traceroute de PC1 vers PC5 montre 3 sauts

---

## Questions de reflexion

**Q1 : Quelle est la difference entre une adresse GUA, ULA et link-local en IPv6 ?**

<details>
<summary>Reponse</summary>

- **GUA (Global Unicast Address)** : Commence par `2000::/3` (en pratique `2xxx:` ou `3xxx:`). Routable sur Internet, equivalent d'une adresse IPv4 publique. Attribuee par un RIR (registre regional) ou un FAI.

- **ULA (Unique Local Address)** : Commence par `FC00::/7` (en pratique `FDxx:`). Routable uniquement au sein d'une organisation privee. Equivalent des plages privees IPv4 (10.x, 172.16.x, 192.168.x). Rarement utilise en pratique car chaque interface peut avoir une GUA.

- **Link-local** : Commence par `FE80::/10`. Non routable, limitee au segment local (un seul lien physique ou VLAN). Automatiquement generee sur toute interface IPv6 active. Indispensable pour le fonctionnement d'IPv6 (decouverte de voisins, protocoles de routage).

Pour l'examen, retenez que **toute interface IPv6 a au minimum une adresse link-local**, et que les routeurs utilisent les adresses link-local pour communiquer entre voisins directs.

</details>

**Q2 : Pourquoi utilise-t-on l'adresse link-local comme passerelle par defaut sur les PCs en IPv6, et pas l'adresse GUA ?**

<details>
<summary>Reponse</summary>

L'adresse link-local du routeur est **toujours stable** : elle ne change pas meme si le prefixe GUA est modifie (par exemple, si le FAI change le prefixe attribue). En utilisant la link-local comme passerelle, les PCs n'ont pas besoin d'etre reconfigures quand le prefixe change.

De plus, c'est le comportement standard d'IPv6 : les messages Router Advertisement (RA) annoncent la link-local du routeur comme passerelle, et c'est cette adresse que les hotes utilisent automatiquement avec SLAAC.

</details>

**Q3 : Que se passe-t-il si on oublie `ipv6 unicast-routing` sur R1 ?**

<details>
<summary>Reponse</summary>

Les interfaces de R1 auront bien leurs adresses IPv6, et les PCs du LAN1 pourront pinger R1 en IPv6. En revanche, R1 ne **transferera pas** les paquets IPv6 entre ses interfaces. Concretement :

- PC1 pourra pinger 2001:db8:1:1::1 (interface locale de R1) : succes
- PC1 ne pourra PAS pinger 2001:db8:1:100::2 (R2 via le lien serie) : echec
- R1 ne generera pas de messages Router Advertisement (RA) sur ses interfaces
- R1 n'apparaitra pas comme routeur pour les hotes du LAN

C'est un piege frequent en lab et dans l'examen. Pensez-y systematiquement quand IPv6 ne fonctionne pas entre reseaux.

</details>

**Q4 : Qu'est-ce que le format EUI-64 modifie et pourquoi ne l'utilisons-nous pas ici ?**

<details>
<summary>Reponse</summary>

Le format **EUI-64 modifie** est une methode pour generer automatiquement la partie hote (64 bits) d'une adresse IPv6 a partir de l'adresse MAC de l'interface (48 bits).

Le processus :
1. Prendre l'adresse MAC (ex: `AA:BB:CC:DD:EE:FF`)
2. Inserer `FFFE` au milieu : `AA:BB:CC:FF:FE:DD:EE:FF`
3. Inverser le 7e bit (bit U/L) : `A8:BB:CC:FF:FE:DD:EE:FF`

Le resultat donne des adresses longues et peu memorisables comme `2001:db8:1:1:a8bb:ccff:fedd:eeff`.

Dans ce lab, on configure les adresses **manuellement** (`::1`, `::10`, etc.) pour la lisibilite et la simplicite de diagnostic. En production, les serveurs et equipements d'infrastructure utilisent generalement des adresses manuelles, tandis que les postes clients utilisent SLAAC (qui peut utiliser EUI-64 ou des adresses aleatoires selon la configuration du systeme d'exploitation).

> **Point exam :** Vous devez savoir calculer une adresse EUI-64 a partir d'une adresse MAC. C'est un exercice classique.

</details>

**Q5 : Le ping de PC1 vers PC5 fonctionne en IPv4 mais echoue en IPv6. Comment diagnostiquer ?**

<details>
<summary>Reponse</summary>

Procedure de diagnostic methodique :

1. **Verifier `ipv6 unicast-routing`** sur R1 et R2 :
   ```
   R1# show running-config | include ipv6 unicast
   ```
   Si la ligne n'apparait pas, le routage IPv6 n'est pas actif.

2. **Verifier les adresses IPv6 sur les interfaces** :
   ```
   R1# show ipv6 interface brief
   R2# show ipv6 interface brief
   ```
   Chaque interface active doit avoir une GUA et une link-local.

3. **Verifier les routes statiques IPv6** :
   ```
   R1# show ipv6 route static
   R2# show ipv6 route static
   ```
   Les routes S doivent apparaitre vers les reseaux distants.

4. **Verifier la passerelle IPv6 sur PC1** : Elle doit etre `FE80::1`, pas l'adresse GUA du routeur.

5. **Tester par sauts** :
   - PC1 -> FE80::1 (routeur local)
   - PC1 -> 2001:db8:1:100::2 (interface serie de R2)
   - PC1 -> 2001:db8:1:3::10 (PC5)
   
   Le premier echec indique ou se situe le probleme.

</details>

**Q6 : Pourquoi le lien serie utilise-t-il un masque /30 en IPv4 mais un /64 en IPv6 ?**

<details>
<summary>Reponse</summary>

En **IPv4**, l'espace d'adressage est limite (4,3 milliards d'adresses). Un /24 gaspillerait 252 adresses sur un lien qui n'en a besoin que de 2. Le /30 est le choix optimal : exactement 2 adresses hotes.

En **IPv6**, l'espace d'adressage est quasi illimite (3,4 x 10^38 adresses). Un /64 offre 2^64 adresses hotes, ce qui semble absurde pour un lien point-a-point. Mais la convention est d'utiliser /64 partout pour la coherence et parce que certaines fonctionnalites IPv6 (comme SLAAC) necessitent un /64. Certaines organisations utilisent /127 sur les liens point-a-point (RFC 6164) pour eviter des attaques liees aux pings vers le sous-reseau, mais /64 reste la pratique par defaut et celle attendue a l'examen CCNA.

</details>

---

## Solution complete

<details>
<summary>Cliquez pour afficher la solution</summary>

### R1 — Configuration complete

```
enable
configure terminal
hostname R1

! Activer le routage IPv6
ipv6 unicast-routing

! Interface LAN1
interface GigabitEthernet0/0
 ip address 10.1.1.1 255.255.255.0
 ipv6 address 2001:db8:1:1::1/64
 ipv6 address FE80::1 link-local
 no shutdown
exit

! Interface serie vers R2
interface Serial0/0/0
 ip address 10.1.100.1 255.255.255.252
 ipv6 address 2001:db8:1:100::1/64
 ipv6 address FE80::1 link-local
 clock rate 128000
 no shutdown
exit

! Routes statiques IPv4
ip route 10.1.2.0 255.255.255.0 10.1.100.2
ip route 10.1.3.0 255.255.255.0 10.1.100.2

! Routes statiques IPv6
ipv6 route 2001:db8:1:2::/64 Serial0/0/0 FE80::2
ipv6 route 2001:db8:1:3::/64 Serial0/0/0 FE80::2

exit
```

### R2 — Configuration complete

```
enable
configure terminal
hostname R2

! Activer le routage IPv6
ipv6 unicast-routing

! Interface serie vers R1
interface Serial0/0/0
 ip address 10.1.100.2 255.255.255.252
 ipv6 address 2001:db8:1:100::2/64
 ipv6 address FE80::2 link-local
 no shutdown
exit

! Interface LAN2
interface GigabitEthernet0/0
 ip address 10.1.2.1 255.255.255.0
 ipv6 address 2001:db8:1:2::1/64
 ipv6 address FE80::2 link-local
 no shutdown
exit

! Interface LAN3
interface GigabitEthernet0/1
 ip address 10.1.3.1 255.255.255.0
 ipv6 address 2001:db8:1:3::1/64
 ipv6 address FE80::2 link-local
 no shutdown
exit

! Route statique IPv4
ip route 10.1.1.0 255.255.255.0 10.1.100.1

! Route statique IPv6
ipv6 route 2001:db8:1:1::/64 Serial0/0/0 FE80::1

exit
```

### PCs — Configuration IP

| PC | IPv4 | Masque | Passerelle IPv4 | IPv6 | Passerelle IPv6 |
|----|------|--------|----------------|------|----------------|
| PC1 | 10.1.1.10 | 255.255.255.0 | 10.1.1.1 | 2001:db8:1:1::10/64 | FE80::1 |
| PC2 | 10.1.1.11 | 255.255.255.0 | 10.1.1.1 | 2001:db8:1:1::11/64 | FE80::1 |
| PC3 | 10.1.2.10 | 255.255.255.0 | 10.1.2.1 | 2001:db8:1:2::10/64 | FE80::2 |
| PC4 | 10.1.2.11 | 255.255.255.0 | 10.1.2.1 | 2001:db8:1:2::11/64 | FE80::2 |
| PC5 | 10.1.3.10 | 255.255.255.0 | 10.1.3.1 | 2001:db8:1:3::10/64 | FE80::2 |

### Cablage

| Connexion | Cable | Interface source | Interface destination |
|-----------|-------|-----------------|---------------------|
| R1 - SW1 | Droit | Gi0/0 | Gi0/1 |
| PC1 - SW1 | Droit | FastEthernet0 | Fa0/1 |
| PC2 - SW1 | Droit | FastEthernet0 | Fa0/2 |
| R1 - R2 | Serie DCE | Se0/0/0 | Se0/0/0 |
| R2 - SW2 | Droit | Gi0/0 | Gi0/1 |
| PC3 - SW2 | Droit | FastEthernet0 | Fa0/1 |
| PC4 - SW2 | Droit | FastEthernet0 | Fa0/2 |
| R2 - SW3 | Droit | Gi0/1 | Gi0/1 |
| PC5 - SW3 | Droit | FastEthernet0 | Fa0/1 |

### Tests de verification

Depuis PC1 :
```
ping 10.1.1.1
ping 10.1.2.10
ping 10.1.3.10
ping 2001:db8:1:2::10
ping 2001:db8:1:3::10
tracert 10.1.3.10
```

Depuis R1 :
```
show ip interface brief
show ipv6 interface brief
show ip route
show ipv6 route
ping 10.1.100.2
ping ipv6 2001:db8:1:100::2
```

Depuis R2 :
```
show ip interface brief
show ipv6 interface brief
show ip route
show ipv6 route
ping 10.1.1.10
ping ipv6 2001:db8:1:1::10
```

</details>
