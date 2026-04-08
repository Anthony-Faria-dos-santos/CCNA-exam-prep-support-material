# Lab 3.2 : OSPF mono-area - Configuration de base et verification

| Info | Valeur |
|------|--------|
| **Module** | 3 - Connectivite IP |
| **Topics couverts** | 3.4 OSPF (single-area) |
| **Difficulte** | Intermediaire |
| **Duree estimee** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                    10.0.13.0/30
            Se0/0/1 _____________ Se0/0/0
           /                             \
         [R1]                           [R3]
  Gi0/0 / | Se0/0/0              Gi0/0 |
       /  |                             |
    [SW1] |  10.0.12.0/30        192.168.3.0/24
    / \   |                          (pas de PC)
[PC1][PC2]|
192.168.1.0/24
          |
          | Se0/0/0
         [R2]
  Gi0/0 / Se0/0/1
       /        \
    [SW2]   (vers R3: 10.0.23.0/30)
    / \
[PC3][PC4]
192.168.2.0/24
```

---

## Tableau d'adressage

| Equipement | Interface | Adresse IPv4 | Masque | Passerelle par defaut |
|------------|-----------|-------------|--------|----------------------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | N/A |
| R1 | Se0/0/0 | 10.0.12.1 | 255.255.255.252 | N/A |
| R1 | Se0/0/1 | 10.0.13.1 | 255.255.255.252 | N/A |
| R2 | Gi0/0 | 192.168.2.1 | 255.255.255.0 | N/A |
| R2 | Se0/0/0 | 10.0.12.2 | 255.255.255.252 | N/A |
| R2 | Se0/0/1 | 10.0.23.1 | 255.255.255.252 | N/A |
| R3 | Gi0/0 | 192.168.3.1 | 255.255.255.0 | N/A |
| R3 | Se0/0/0 | 10.0.13.2 | 255.255.255.252 | N/A |
| R3 | Se0/0/1 | 10.0.23.2 | 255.255.255.252 | N/A |
| SW1 | VLAN 1 | N/A | N/A | N/A |
| SW2 | VLAN 1 | N/A | N/A | N/A |
| PC1 | NIC | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |
| PC2 | NIC | 192.168.1.11 | 255.255.255.0 | 192.168.1.1 |
| PC3 | NIC | 192.168.2.10 | 255.255.255.0 | 192.168.2.1 |
| PC4 | NIC | 192.168.2.11 | 255.255.255.0 | 192.168.2.1 |

---

## Objectifs

1. Configurer l'adressage IP sur une topologie triangulaire de 3 routeurs.
2. Activer OSPF area 0 avec des router-ID manuels et des network statements.
3. Configurer `passive-interface` sur les interfaces LAN.
4. Verifier les adjacences OSPF et comprendre les etats de voisinage.
5. Analyser la table de routage OSPF.
6. Observer la convergence OSPF lors d'une panne de lien.

---

## Prerequis

- Savoir configurer les interfaces d'un routeur (adresses IP, no shutdown).
- Comprendre le concept de protocole de routage dynamique (vs statique).
- Connaitre la difference entre un reseau directement connecte et un reseau appris.

---

## Configuration de depart

### R1

```
enable
configure terminal
hostname R1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 4
 password cisco
 login
exit
banner motd # Acces autorise uniquement #
!
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 clock rate 128000
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.13.1 255.255.255.252
 clock rate 128000
 no shutdown
!
end
```

### R2

```
enable
configure terminal
hostname R2
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 4
 password cisco
 login
exit
banner motd # Acces autorise uniquement #
!
interface GigabitEthernet0/0
 ip address 192.168.2.1 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.23.1 255.255.255.252
 clock rate 128000
 no shutdown
!
end
```

### R3

```
enable
configure terminal
hostname R3
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 4
 password cisco
 login
exit
banner motd # Acces autorise uniquement #
!
interface GigabitEthernet0/0
 ip address 192.168.3.1 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.13.2 255.255.255.252
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.23.2 255.255.255.252
 no shutdown
!
end
```

### PCs

| PC | IP | Masque | Gateway |
|----|-----|--------|---------|
| PC1 | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |
| PC2 | 192.168.1.11 | 255.255.255.0 | 192.168.1.1 |
| PC3 | 192.168.2.10 | 255.255.255.0 | 192.168.2.1 |
| PC4 | 192.168.2.11 | 255.255.255.0 | 192.168.2.1 |

---

## Partie 1 : Verification de l'adressage de base

### Etape 1.1 : Verifier les interfaces

```
R1# show ip interface brief
```

**Output attendu :**

```
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     192.168.1.1     YES manual up                    up
Serial0/0/0            10.0.12.1       YES manual up                    up
Serial0/0/1            10.0.13.1       YES manual up                    up
```

### Etape 1.2 : Tester les liens directs

```
R1# ping 10.0.12.2
R1# ping 10.0.13.2
```

Les deux pings doivent reussir (5/5).

### Etape 1.3 : Confirmer l'absence de routes distantes

```
R1# show ip route
```

> A ce stade, R1 ne connait que ses 3 reseaux directement connectes. Il ne peut pas atteindre 192.168.2.0/24 ni 192.168.3.0/24. C'est precisement ce que OSPF va resoudre automatiquement.

---

## Partie 2 : Activation d'OSPF

### Pourquoi OSPF ?

OSPF est un protocole de routage a etat de lien (link-state). Au lieu de partager ses routes comme RIP, chaque routeur partage une description de ses liens (LSA). Tous les routeurs construisent une carte complete du reseau et calculent le meilleur chemin avec l'algorithme SPF (Dijkstra). Le CCNA 200-301 se concentre sur OSPF single-area (area 0).

### Etape 2.1 : Activer OSPF sur R1

```
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# network 192.168.1.0 0.0.0.255 area 0
R1(config-router)# network 10.0.12.0 0.0.0.3 area 0
R1(config-router)# network 10.0.13.0 0.0.0.3 area 0
R1(config-router)# exit
```

> **Explication ligne par ligne :**
> - `router ospf 1` : Active le processus OSPF avec l'ID de processus 1. Ce numero est **local** au routeur -- il n'a pas besoin d'etre identique sur tous les routeurs (mais par convention, on utilise souvent le meme).
> - `router-id 1.1.1.1` : Definit manuellement l'identifiant du routeur OSPF. Sans cette commande, OSPF utiliserait la plus haute adresse de loopback, ou a defaut la plus haute adresse d'interface active. Le configurer manuellement est une bonne pratique.
> - `network 192.168.1.0 0.0.0.255 area 0` : Dit a OSPF "active-toi sur les interfaces dont l'adresse tombe dans ce reseau, et annonce ce reseau dans l'area 0". Le `0.0.0.255` est un **wildcard mask** (l'inverse du masque de sous-reseau 255.255.255.0).
> - `network 10.0.12.0 0.0.0.3 area 0` : Le wildcard 0.0.0.3 correspond au masque 255.255.255.252 (/30).

### Etape 2.2 : Activer OSPF sur R2

```
R2(config)# router ospf 1
R2(config-router)# router-id 2.2.2.2
R2(config-router)# network 192.168.2.0 0.0.0.255 area 0
R2(config-router)# network 10.0.12.0 0.0.0.3 area 0
R2(config-router)# network 10.0.23.0 0.0.0.3 area 0
R2(config-router)# exit
```

> Des que R2 active OSPF sur le lien 10.0.12.0/30, il devrait detecter R1 comme voisin. Vous verrez peut-etre un message console :
> ```
> %OSPF-5-ADJCHG: Process 1, Nbr 1.1.1.1 on Serial0/0/0 from LOADING to FULL
> ```
> Ce message confirme que l'adjacence OSPF est etablie.

### Etape 2.3 : Activer OSPF sur R3

```
R3(config)# router ospf 1
R3(config-router)# router-id 3.3.3.3
R3(config-router)# network 192.168.3.0 0.0.0.255 area 0
R3(config-router)# network 10.0.13.0 0.0.0.3 area 0
R3(config-router)# network 10.0.23.0 0.0.0.3 area 0
R3(config-router)# exit
```

---

## Partie 3 : Passive-interface sur les LANs

### Pourquoi passive-interface ?

Par defaut, OSPF envoie des paquets Hello sur toutes les interfaces couvertes par les `network` statements. Sur un LAN ou il n'y a que des PCs (pas de routeur voisin OSPF), ces paquets Hello sont inutiles et gaspillent de la bande passante. Pire, ils exposent des informations de routage a des machines qui n'en ont pas besoin.

`passive-interface` dit a OSPF : "annonce ce reseau dans tes LSA, mais n'envoie PAS de paquets Hello sur cette interface".

### Etape 3.1 : Configurer passive-interface sur chaque routeur

**R1 :**

```
R1(config)# router ospf 1
R1(config-router)# passive-interface GigabitEthernet0/0
R1(config-router)# exit
```

**R2 :**

```
R2(config)# router ospf 1
R2(config-router)# passive-interface GigabitEthernet0/0
R2(config-router)# exit
```

**R3 :**

```
R3(config)# router ospf 1
R3(config-router)# passive-interface GigabitEthernet0/0
R3(config-router)# exit
```

### Etape 3.2 : Verifier la configuration passive-interface

```
R1# show ip protocols
```

**Output attendu (extrait) :**

```
Routing Protocol is "ospf 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Router ID 1.1.1.1
  Number of areas in this router is 1. 1 normal 0 stub 0 nssa
  Maximum path: 4
  Routing for Networks:
    192.168.1.0 0.0.0.255 area 0
    10.0.12.0 0.0.0.3 area 0
    10.0.13.0 0.0.0.3 area 0
  Passive Interface(s):
    GigabitEthernet0/0
  Routing Information Sources:
    Gateway         Distance      Last Update
    1.1.1.1              110      00:05:12
    2.2.2.2              110      00:04:30
    3.3.3.3              110      00:03:45
```

> La section `Passive Interface(s)` confirme que Gi0/0 est bien passive. Le reseau 192.168.1.0/24 est toujours annonce (il apparait dans les LSA), mais aucun Hello n'est envoye sur cette interface.

---

## Partie 4 : Verification des adjacences OSPF

### Etape 4.1 : show ip ospf neighbor

```
R1# show ip ospf neighbor
```

**Output attendu :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           0   FULL/  -        00:00:35    10.0.12.2       Serial0/0/0
3.3.3.3           0   FULL/  -        00:00:38    10.0.13.2       Serial0/0/1
```

> **Lecture du resultat :**
> - **Neighbor ID** : C'est le router-id du voisin (celui qu'on a configure avec `router-id`).
> - **State FULL** : L'adjacence est completement etablie. Les bases de donnees LSDB sont synchronisees. C'est l'etat normal et souhaite.
> - **FULL/ -** : Le tiret apres FULL indique un lien point-to-point (pas de DR/BDR). Sur un segment broadcast (Ethernet), vous verriez FULL/DR ou FULL/BDR.
> - **Pri 0** : Priorite OSPF. Sur les liens serie, la priorite n'a pas d'importance (pas d'election DR/BDR).

### Etape 4.2 : Verifier sur R2

```
R2# show ip ospf neighbor
```

**Output attendu :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
1.1.1.1           0   FULL/  -        00:00:32    10.0.12.1       Serial0/0/0
3.3.3.3           0   FULL/  -        00:00:36    10.0.23.2       Serial0/0/1
```

> R2 voit R1 et R3 comme voisins FULL. La topologie triangulaire est completement convergee.

### Etape 4.3 : Examiner les details OSPF d'une interface

```
R1# show ip ospf interface Serial0/0/0
```

**Output attendu :**

```
Serial0/0/0 is up, line protocol is up
  Internet address is 10.0.12.1/30, Area 0
  Process ID 1, Router ID 1.1.1.1, Network Type POINT-TO-POINT, Cost: 64
  Transmit Delay is 1 sec, State POINT-TO-POINT,
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
  Hello due in 00:00:04
  Index 2/2, flood queue length 0
  Next 0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2
```

> Points importants :
> - **Network Type POINT-TO-POINT** : IOS detecte automatiquement que c'est un lien serie. Pas d'election DR/BDR.
> - **Cost: 64** : Le cout OSPF de cette interface. Il est calcule comme 10^8 / bande passante (en bps). Pour un lien serie a 1.544 Mbps (T1), le cout est 64.
> - **Hello 10, Dead 40** : Les timers OSPF par defaut. Un Hello est envoye toutes les 10 secondes. Si aucun Hello n'est recu pendant 40 secondes, le voisin est declare mort.

---

## Partie 5 : Verification de la table de routage OSPF

### Etape 5.1 : Afficher les routes OSPF

```
R1# show ip route ospf
```

**Output attendu :**

```
      10.0.0.0/8 is variably subnetted, 5 subnets, 2 masks
O        10.0.23.0/30 [110/128] via 10.0.12.2, 00:10:15, Serial0/0/0
                      [110/128] via 10.0.13.2, 00:10:15, Serial0/0/1
      192.168.2.0/24 is variably subnetted, 2 subnets, 2 masks
O        192.168.2.0/24 [110/65] via 10.0.12.2, 00:10:15, Serial0/0/0
      192.168.3.0/24 is variably subnetted, 2 subnets, 2 masks
O        192.168.3.0/24 [110/65] via 10.0.13.2, 00:10:15, Serial0/0/1
```

> **Lecture du resultat :**
> - **O** : Route apprise par OSPF.
> - **[110/65]** : AD=110 (valeur par defaut d'OSPF), metrique=65 (cout OSPF total : 64 pour le lien serie + 1 pour le GigabitEthernet du voisin).
> - Pour le reseau 10.0.23.0/30, il y a **deux chemins de cout egal** (via R2 et via R3). C'est de l'**equal-cost load balancing**, une fonctionnalite native d'OSPF. Le trafic sera reparti sur les deux chemins.

### Etape 5.2 : Table de routage complete

```
R1# show ip route
```

**Output attendu :**

```
Gateway of last resort is not set

      10.0.0.0/8 is variably subnetted, 5 subnets, 2 masks
C        10.0.12.0/30 is directly connected, Serial0/0/0
L        10.0.12.1/32 is directly connected, Serial0/0/0
C        10.0.13.0/30 is directly connected, Serial0/0/1
L        10.0.13.1/32 is directly connected, Serial0/0/1
O        10.0.23.0/30 [110/128] via 10.0.12.2, 00:10:15, Serial0/0/0
                      [110/128] via 10.0.13.2, 00:10:15, Serial0/0/1
      192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.1.0/24 is directly connected, GigabitEthernet0/0
L        192.168.1.1/32 is directly connected, GigabitEthernet0/0
O     192.168.2.0/24 [110/65] via 10.0.12.2, 00:10:15, Serial0/0/0
O     192.168.3.0/24 [110/65] via 10.0.13.2, 00:10:15, Serial0/0/1
```

> On voit clairement les 3 types de routes : C (Connected), L (Local), O (OSPF). Tous les reseaux de la topologie sont presents. La connectivite de bout en bout est assuree.

### Etape 5.3 : Test de bout en bout

```
PC1> ping 192.168.2.10
```

**Output attendu :**

```
Reply from 192.168.2.10: bytes=32 time=5ms TTL=126
Reply from 192.168.2.10: bytes=32 time=4ms TTL=126
Reply from 192.168.2.10: bytes=32 time=3ms TTL=126
Reply from 192.168.2.10: bytes=32 time=4ms TTL=126
```

```
PC1> ping 192.168.3.1
```

**Output attendu :**

```
Reply from 192.168.3.1: bytes=32 time=5ms TTL=254
Reply from 192.168.3.1: bytes=32 time=4ms TTL=254
```

---

## Partie 6 : Test de convergence OSPF

L'un des grands avantages d'OSPF par rapport au routage statique : si un lien tombe, OSPF recalcule automatiquement les chemins.

### Etape 6.1 : Identifier le chemin actuel vers 192.168.2.0/24

```
R1# show ip route 192.168.2.0
```

**Output attendu :**

```
Routing entry for 192.168.2.0/24
  Known via "ospf 1", distance 110, metric 65, type intra area
  Routing Descriptor Blocks:
  * 10.0.12.2, from 2.2.2.2, 00:15:30, via Serial0/0/0
      Route metric is 65, traffic share count is 1
```

> Le chemin optimal passe par le lien direct R1-R2 (Se0/0/0).

### Etape 6.2 : Simuler une panne du lien R1-R2

```
R1(config)# interface Serial0/0/0
R1(config-if)# shutdown
```

> Vous devriez voir un message console :
> ```
> %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on Serial0/0/0 from FULL to DOWN, Neighbor Down: Interface down or detached
> ```

### Etape 6.3 : Observer la nouvelle route

Attendez quelques secondes (le temps que OSPF recalcule), puis :

```
R1# show ip route 192.168.2.0
```

**Output attendu :**

```
Routing entry for 192.168.2.0/24
  Known via "ospf 1", distance 110, metric 129, type intra area
  Routing Descriptor Blocks:
  * 10.0.13.2, from 2.2.2.2, 00:00:12, via Serial0/0/1
      Route metric is 129, traffic share count is 1
```

> OSPF a automatiquement bascule sur le chemin alternatif via R3 (Se0/0/1). Le cout a augmente (129 au lieu de 65) car le paquet doit maintenant traverser R1 -> R3 -> R2, soit deux liens serie au lieu d'un. La connectivite est preservee sans aucune intervention manuelle.

### Etape 6.4 : Verifier que la connectivite fonctionne toujours

```
PC1> ping 192.168.2.10
```

Le ping doit reussir, meme si le temps de reponse est un peu plus long (chemin plus long).

### Etape 6.5 : Reactiver le lien

```
R1(config)# interface Serial0/0/0
R1(config-if)# no shutdown
```

Attendez quelques secondes et verifiez que l'adjacence se retablit :

```
R1# show ip ospf neighbor
```

**Output attendu :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           0   FULL/  -        00:00:37    10.0.12.2       Serial0/0/0
3.3.3.3           0   FULL/  -        00:00:34    10.0.13.2       Serial0/0/1
```

> Les deux voisins sont de nouveau en FULL. Le chemin optimal via R2 direct est restaure.

---

## Verification finale - Criteres de reussite

- [ ] Les 3 routeurs ont des adjacences OSPF en etat FULL avec leurs voisins
- [ ] `show ip protocols` affiche le bon router-id sur chaque routeur (1.1.1.1, 2.2.2.2, 3.3.3.3)
- [ ] Les interfaces LAN (Gi0/0) sont listees comme passive-interface
- [ ] `show ip route ospf` affiche les routes vers les reseaux distants avec le code "O"
- [ ] PC1 peut pinger PC3 (192.168.1.10 -> 192.168.2.10)
- [ ] PC2 peut pinger PC4 (192.168.1.11 -> 192.168.2.11)
- [ ] PC1 peut pinger R3 Gi0/0 (192.168.3.1)
- [ ] Apres shutdown de Se0/0/0 sur R1, la route vers 192.168.2.0/24 bascule via R3
- [ ] Apres no shutdown, l'adjacence R1-R2 se retablit en FULL

---

## Questions de reflexion

**Q1 : Pourquoi utilise-t-on un wildcard mask (0.0.0.255) au lieu d'un masque de sous-reseau (255.255.255.0) dans les network statements OSPF ?**

<details>
<summary>Voir la reponse</summary>

C'est une convention historique de Cisco. Le wildcard mask est l'inverse bit-a-bit du masque de sous-reseau. Un bit a 0 dans le wildcard signifie "ce bit doit correspondre exactement", un bit a 1 signifie "peu importe". Ainsi, `network 192.168.1.0 0.0.0.255 area 0` signifie "toute interface dont l'adresse commence par 192.168.1.x". C'est le meme concept que les ACL (Access Control Lists). Pour convertir : 255.255.255.0 -> 0.0.0.255, 255.255.255.252 -> 0.0.0.3.

</details>

**Q2 : Que se passerait-il si on configurait un router-id identique sur R1 et R2 ?**

<details>
<summary>Voir la reponse</summary>

OSPF refuserait d'etablir l'adjacence. Les deux routeurs se detecteraient mutuellement mais le processus OSPF genererait un message d'erreur de type "Duplicate Router ID detected". Les LSA seraient en conflit et le routage ne fonctionnerait pas correctement. C'est pourquoi il est essentiel de s'assurer que chaque router-id est unique dans un domaine OSPF.

</details>

**Q3 : Si on supprime la commande `passive-interface GigabitEthernet0/0` sur R1, est-ce que le reseau 192.168.1.0/24 disparait de la table de routage des autres routeurs ?**

<details>
<summary>Voir la reponse</summary>

Non. Le reseau 192.168.1.0/24 reste annonce par OSPF. La commande `passive-interface` empeche uniquement l'envoi de paquets Hello sur l'interface, pas l'annonce du reseau. Le reseau est toujours inclus dans les LSA (Link-State Advertisements) de R1. La seule difference est que R1 n'essaiera plus de former une adjacence OSPF sur cette interface, ce qui est le comportement souhaite sur un LAN sans routeur OSPF voisin.

</details>

**Q4 : Pourquoi la route vers 10.0.23.0/30 affiche deux chemins de cout egal dans la table de routage de R1 ?**

<details>
<summary>Voir la reponse</summary>

Le reseau 10.0.23.0/30 (lien R2-R3) est accessible depuis R1 par deux chemins de cout identique : via R2 (Se0/0/0, cout = 64 + 64 = 128) et via R3 (Se0/0/1, cout = 64 + 64 = 128). OSPF supporte nativement le **load balancing a cout egal** (ECMP - Equal-Cost Multi-Path). Les paquets sont repartis sur les deux chemins. Par defaut, OSPF peut utiliser jusqu'a 4 chemins de cout egal (configurable avec `maximum-paths`).

</details>

**Q5 (Troubleshoot) : Vous avez configure OSPF sur R1 et R2 mais `show ip ospf neighbor` sur R1 est vide. Quelles sont les causes possibles ?**

<details>
<summary>Voir la reponse</summary>

Causes possibles (par ordre de frequence) :

1. **L'interface est down** : Verifier avec `show ip interface brief` que le lien est up/up.
2. **Mauvais network statement** : Le reseau dans `network` ne correspond pas a l'adresse de l'interface. Verifier avec `show ip protocols`.
3. **Area mismatch** : R1 et R2 ne sont pas dans la meme area. Les routeurs OSPF ne forment une adjacence que s'ils sont dans la meme area sur le meme lien.
4. **Hello/Dead timers differents** : Si les timers ont ete modifies sur un routeur mais pas l'autre, l'adjacence ne se formera pas. Verifier avec `show ip ospf interface`.
5. **Authentication mismatch** : Si l'authentification OSPF est activee sur un cote mais pas l'autre.
6. **passive-interface sur le lien serie** : Si `passive-interface Serial0/0/0` est configure, aucun Hello n'est envoye et aucune adjacence ne se forme.

</details>

---

## Solution complete

<details>
<summary>Voir la solution complete</summary>

### R1 - Configuration finale

```
enable
configure terminal
hostname R1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 4
 password cisco
 login
exit
!
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 clock rate 128000
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.13.1 255.255.255.252
 clock rate 128000
 no shutdown
!
router ospf 1
 router-id 1.1.1.1
 passive-interface GigabitEthernet0/0
 network 192.168.1.0 0.0.0.255 area 0
 network 10.0.12.0 0.0.0.3 area 0
 network 10.0.13.0 0.0.0.3 area 0
!
end
```

### R2 - Configuration finale

```
enable
configure terminal
hostname R2
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 4
 password cisco
 login
exit
!
interface GigabitEthernet0/0
 ip address 192.168.2.1 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.23.1 255.255.255.252
 clock rate 128000
 no shutdown
!
router ospf 1
 router-id 2.2.2.2
 passive-interface GigabitEthernet0/0
 network 192.168.2.0 0.0.0.255 area 0
 network 10.0.12.0 0.0.0.3 area 0
 network 10.0.23.0 0.0.0.3 area 0
!
end
```

### R3 - Configuration finale

```
enable
configure terminal
hostname R3
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 4
 password cisco
 login
exit
!
interface GigabitEthernet0/0
 ip address 192.168.3.1 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.13.2 255.255.255.252
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.23.2 255.255.255.252
 no shutdown
!
router ospf 1
 router-id 3.3.3.3
 passive-interface GigabitEthernet0/0
 network 192.168.3.0 0.0.0.255 area 0
 network 10.0.13.0 0.0.0.3 area 0
 network 10.0.23.0 0.0.0.3 area 0
!
end
```

</details>
