# Lab 3.3 : OSPF DR/BDR - Election et manipulation sur segment broadcast

| Info | Valeur |
|------|--------|
| **Module** | 3 - Connectivite IP |
| **Topics couverts** | 3.4 OSPF (DR/BDR election, network types) |
| **Difficulte** | Avance |
| **Duree estimee** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                   192.168.1.0/24
                   [PC-A]
                     |
                   Gi0/0
                   [R1]
                Gi0/1 | Se0/0/0
                  |   |       \
                  |   |        \ 10.0.12.0/30
                  |   |         \
                  | [SW-CORE]   Se0/0/0
                  |   |  |  \   [R2]
                  |   |  |   \  Gi0/1
                  |   |  |    \  |
                  Gi0/1  |   Gi0/1
                  [R3]   |   
                       Gi0/1
                       [R4]---Gi0/0---[PC-B]
                                    192.168.4.0/24

        Segment broadcast : 10.0.0.0/24
        R1 Gi0/1 = .1   R2 Gi0/1 = .2
        R3 Gi0/1 = .3   R4 Gi0/1 = .4
```

---

## Tableau d'adressage

| Equipement | Interface | Adresse IPv4 | Masque | Description |
|------------|-----------|-------------|--------|-------------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | LAN R1 |
| R1 | Gi0/1 | 10.0.0.1 | 255.255.255.0 | Segment broadcast |
| R1 | Se0/0/0 | 10.0.12.1 | 255.255.255.252 | P2P vers R2 |
| R2 | Gi0/1 | 10.0.0.2 | 255.255.255.0 | Segment broadcast |
| R2 | Se0/0/0 | 10.0.12.2 | 255.255.255.252 | P2P vers R1 |
| R3 | Gi0/1 | 10.0.0.3 | 255.255.255.0 | Segment broadcast |
| R4 | Gi0/1 | 10.0.0.4 | 255.255.255.0 | Segment broadcast |
| R4 | Gi0/0 | 192.168.4.1 | 255.255.255.0 | LAN R4 |
| PC-A | NIC | 192.168.1.10 | 255.255.255.0 | Gateway : 192.168.1.1 |
| PC-B | NIC | 192.168.4.10 | 255.255.255.0 | Gateway : 192.168.4.1 |

---

## Objectifs

1. Configurer OSPF sur un segment broadcast multi-acces et observer l'election DR/BDR.
2. Comprendre les criteres d'election : priorite, puis router-id.
3. Manipuler les priorites OSPF pour controler l'election DR/BDR.
4. Configurer un lien serie en mode point-to-point (sans DR/BDR).
5. Comprendre pourquoi un `clear ip ospf process` est necessaire apres un changement de priorite.

---

## Prerequis

- Avoir complete le Lab 3.2 (OSPF de base).
- Comprendre les concepts d'adjacence OSPF et de LSA.
- Savoir la difference entre un reseau broadcast et un lien point-to-point.

---

## Rappel theorique : DR/BDR, pourquoi ca existe ?

Sur un segment Ethernet partage (broadcast multi-access), si chaque routeur OSPF formait une adjacence FULL avec tous les autres, le nombre d'adjacences exploserait (n*(n-1)/2). Avec 10 routeurs, ca ferait 45 adjacences.

OSPF resout ce probleme en elisant un **Designated Router (DR)** et un **Backup Designated Router (BDR)**. Les autres routeurs (DROthers) ne forment une adjacence FULL qu'avec le DR et le BDR. Les DROthers restent en etat **2-WAY** entre eux.

**Criteres d'election (dans l'ordre) :**
1. La **priorite OSPF** la plus haute (par defaut = 1, configurable de 0 a 255).
2. En cas d'egalite, le **router-id** le plus eleve.
3. Priorite = 0 signifie "ne jamais etre elu DR ou BDR".

> **Point exam critique** : L'election DR/BDR n'est PAS preemptive. Si le DR tombe et qu'un nouveau routeur avec une priorite plus elevee arrive, il ne prend pas le role de DR. Le BDR devient DR, et une nouvelle election a lieu uniquement pour le role de BDR.

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
!
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
!
interface GigabitEthernet0/1
 ip address 10.0.0.1 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 clock rate 128000
 no shutdown
!
ipv6 unicast-routing
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
!
interface GigabitEthernet0/1
 ip address 10.0.0.2 255.255.255.0
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
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
!
interface GigabitEthernet0/1
 ip address 10.0.0.3 255.255.255.0
 no shutdown
!
end
```

### R4

```
enable
configure terminal
hostname R4
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
interface GigabitEthernet0/1
 ip address 10.0.0.4 255.255.255.0
 no shutdown
!
interface GigabitEthernet0/0
 ip address 192.168.4.1 255.255.255.0
 no shutdown
!
end
```

### PCs

| PC | IP | Masque | Gateway |
|----|-----|--------|---------|
| PC-A | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |
| PC-B | 192.168.4.10 | 255.255.255.0 | 192.168.4.1 |

---

## Partie 1 : Configuration OSPF sur le segment broadcast

### Etape 1.1 : Activer OSPF sur R1

```
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# network 192.168.1.0 0.0.0.255 area 0
R1(config-router)# network 10.0.0.0 0.0.0.255 area 0
R1(config-router)# network 10.0.12.0 0.0.0.3 area 0
R1(config-router)# passive-interface GigabitEthernet0/0
R1(config-router)# exit
```

### Etape 1.2 : Activer OSPF sur R2

```
R2(config)# router ospf 1
R2(config-router)# router-id 2.2.2.2
R2(config-router)# network 10.0.0.0 0.0.0.255 area 0
R2(config-router)# network 10.0.12.0 0.0.0.3 area 0
R2(config-router)# exit
```

### Etape 1.3 : Activer OSPF sur R3

```
R3(config)# router ospf 1
R3(config-router)# router-id 3.3.3.3
R3(config-router)# network 10.0.0.0 0.0.0.255 area 0
R3(config-router)# exit
```

### Etape 1.4 : Activer OSPF sur R4

```
R4(config)# router ospf 1
R4(config-router)# router-id 4.4.4.4
R4(config-router)# network 10.0.0.0 0.0.0.255 area 0
R4(config-router)# network 192.168.4.0 0.0.0.255 area 0
R4(config-router)# passive-interface GigabitEthernet0/0
R4(config-router)# exit
```

> Attendez quelques secondes que les adjacences se forment. Vous devriez voir des messages `%OSPF-5-ADJCHG` sur les consoles.

---

## Partie 2 : Observer l'election DR/BDR naturelle

### Etape 2.1 : Examiner les voisins OSPF sur R1

```
R1# show ip ospf neighbor
```

**Output attendu :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/BDR        00:00:35    10.0.0.2        GigabitEthernet0/1
3.3.3.3           1   FULL/DROTHER    00:00:33    10.0.0.3        GigabitEthernet0/1
4.4.4.4           1   FULL/DR         00:00:37    10.0.0.4        GigabitEthernet0/1
2.2.2.2           0   FULL/  -        00:00:31    10.0.12.2       Serial0/0/0
```

> **Analyse de l'election :**
> - Toutes les priorites sont a 1 (valeur par defaut). L'election se fait donc sur le **router-id le plus eleve**.
> - **R4 (4.4.4.4)** a le router-id le plus haut -> il est elu **DR**.
> - **R3 (3.3.3.3)** a le deuxieme router-id -> il est elu **BDR**.
>
> Attendez -- pourquoi R1 voit R3 en DROTHER et pas en BDR ? C'est parce que R1 voit les roles depuis sa perspective. Reverifiez. En fait, l'election depend de l'ordre d'arrivee des routeurs. Si tous demarrent en meme temps, le router-id le plus haut devient DR. Mais si les routeurs sont arrives progressivement, l'election n'est pas preemptive et les roles peuvent etre differents.
>
> Pour avoir un resultat deterministe, on va forcer les priorites dans la partie suivante.

### Etape 2.2 : Voir les details OSPF de l'interface broadcast

```
R1# show ip ospf interface GigabitEthernet0/1
```

**Output attendu :**

```
GigabitEthernet0/1 is up, line protocol is up
  Internet address is 10.0.0.1/24, Area 0
  Process ID 1, Router ID 1.1.1.1, Network Type BROADCAST, Cost: 1
  Transmit Delay is 1 sec, State DROTHER, Priority 1
  Designated Router (ID) 4.4.4.4, Interface address 10.0.0.4
  Backup Designated Router (ID) 3.3.3.3, Interface address 10.0.0.3
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
  Hello due in 00:00:07
  Index 2/2, flood queue length 0
  Neighbor Count is 3, Adjacent neighbor count is 2
    Adjacent with neighbor 3.3.3.3  (Backup Designated Router)
    Adjacent with neighbor 4.4.4.4  (Designated Router)
```

> Points importants a observer :
> - **Network Type BROADCAST** : Detecte automatiquement sur une interface Ethernet.
> - **State DROTHER** : R1 n'est ni DR ni BDR sur ce segment.
> - **Adjacent neighbor count is 2** : R1 (DROTHER) n'a d'adjacence FULL qu'avec le DR et le BDR. Avec R2 (autre DROTHER), il est en etat 2-WAY (il le connait mais n'echange pas de LSA directement).
> - **Priority 1** : La priorite par defaut.

### Etape 2.3 : Verifier les relations entre DROthers

```
R3# show ip ospf neighbor
```

**Output attendu (si R3 est BDR) :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
1.1.1.1           1   FULL/DROTHER    00:00:32    10.0.0.1        GigabitEthernet0/1
2.2.2.2           1   FULL/DROTHER    00:00:35    10.0.0.2        GigabitEthernet0/1
4.4.4.4           1   FULL/DR         00:00:38    10.0.0.4        GigabitEthernet0/1
```

> En tant que BDR, R3 a des adjacences FULL avec **tous** les routeurs du segment (DR et DROthers). C'est normal : le BDR doit etre pret a prendre le relais si le DR tombe.

---

## Partie 3 : Manipuler les priorites pour forcer DR et BDR

On veut forcer : **DR = R1**, **BDR = R2**. Pour cela, on donne a R1 la priorite la plus haute et a R2 la deuxieme.

### Etape 3.1 : Configurer les priorites

**R1 (futur DR, priorite la plus haute) :**

```
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip ospf priority 255
R1(config-if)# exit
```

**R2 (futur BDR) :**

```
R2(config)# interface GigabitEthernet0/1
R2(config-if)# ip ospf priority 200
R2(config-if)# exit
```

**R3 et R4 (DROthers, priorite basse) :**

```
R3(config)# interface GigabitEthernet0/1
R3(config-if)# ip ospf priority 1
R3(config-if)# exit
```

```
R4(config)# interface GigabitEthernet0/1
R4(config-if)# ip ospf priority 1
R4(config-if)# exit
```

### Etape 3.2 : Observer que rien n'a change (encore)

```
R1# show ip ospf interface GigabitEthernet0/1 | include Priority|Designated
```

**Output attendu :**

```
  Process ID 1, Router ID 1.1.1.1, Network Type BROADCAST, Cost: 1
  Transmit Delay is 1 sec, State DROTHER, Priority 255
  Designated Router (ID) 4.4.4.4, Interface address 10.0.0.4
  Backup Designated Router (ID) 3.3.3.3, Interface address 10.0.0.3
```

> La priorite de R1 est bien passee a 255, mais il est toujours DROTHER. Pourquoi ? Parce que **l'election DR/BDR n'est pas preemptive**. Un changement de priorite ne provoque pas une nouvelle election. C'est un point fondamental pour l'examen.

### Etape 3.3 : Forcer une nouvelle election avec clear ip ospf process

> **Attention** : En production, cette commande interrompt temporairement le routage OSPF. En labo, c'est sans consequence.

Executez cette commande sur **tous les routeurs** :

**R1 :**

```
R1# clear ip ospf process
Reset ALL OSPF processes? [no]: yes
```

**R2 :**

```
R2# clear ip ospf process
Reset ALL OSPF processes? [no]: yes
```

**R3 :**

```
R3# clear ip ospf process
Reset ALL OSPF processes? [no]: yes
```

**R4 :**

```
R4# clear ip ospf process
Reset ALL OSPF processes? [no]: yes
```

> Attendez 30 a 40 secondes que les adjacences se reforment completement.

### Etape 3.4 : Verifier la nouvelle election

```
R1# show ip ospf interface GigabitEthernet0/1
```

**Output attendu :**

```
GigabitEthernet0/1 is up, line protocol is up
  Internet address is 10.0.0.1/24, Area 0
  Process ID 1, Router ID 1.1.1.1, Network Type BROADCAST, Cost: 1
  Transmit Delay is 1 sec, State DR, Priority 255
  Designated Router (ID) 1.1.1.1, Interface address 10.0.0.1
  Backup Designated Router (ID) 2.2.2.2, Interface address 10.0.0.2
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
```

> R1 est maintenant **DR** (Priority 255) et R2 est **BDR** (Priority 200). R3 et R4 sont DROthers.

```
R3# show ip ospf neighbor
```

**Output attendu :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
1.1.1.1         255   FULL/DR         00:00:36    10.0.0.1        GigabitEthernet0/1
2.2.2.2         200   FULL/BDR        00:00:33    10.0.0.2        GigabitEthernet0/1
4.4.4.4           1   2WAY/DROTHER    00:00:38    10.0.0.4        GigabitEthernet0/1
```

> Observez que R3 est en **2WAY** avec R4 (deux DROthers ne forment pas d'adjacence FULL entre eux) mais en FULL avec R1 (DR) et R2 (BDR).

### Etape 3.5 : Tester avec priorite 0

Pour empecher un routeur de devenir DR ou BDR, on met sa priorite a 0 :

```
R4(config)# interface GigabitEthernet0/1
R4(config-if)# ip ospf priority 0
R4(config-if)# exit
```

```
R4# clear ip ospf process
Reset ALL OSPF processes? [no]: yes
```

Apres reconvergence :

```
R4# show ip ospf interface GigabitEthernet0/1 | include Priority|State
```

**Output attendu :**

```
  Transmit Delay is 1 sec, State DROTHER, Priority 0
```

> Avec une priorite de 0, R4 ne sera **jamais** elu DR ni BDR, quelles que soient les circonstances. C'est utile pour les routeurs peu puissants ou non critiques.

---

## Partie 4 : Lien serie en mode point-to-point

Le lien serie entre R1 et R2 est un lien point-to-point. Verifions qu'il n'y a pas de DR/BDR sur ce type de lien.

### Etape 4.1 : Verifier le type de reseau du lien serie

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
  Hello due in 00:00:03
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2
```

> **Network Type POINT-TO-POINT** : Pas de DR, pas de BDR. Il n'y a que 2 routeurs sur ce lien, donc l'election n'a aucun sens. L'adjacence est directe entre les deux routeurs.

### Etape 4.2 : Comprendre la difference avec la commande ip ospf network

Sur une interface Ethernet, on peut forcer le type de reseau. C'est rarement necessaire sur les liens serie (qui sont deja P2P par defaut), mais c'est utile de connaitre la commande :

```
R1(config)# interface Serial0/0/0
R1(config-if)# ip ospf network point-to-point
R1(config-if)# exit
```

> Cette commande est surtout utile dans l'autre sens : pour forcer une interface Ethernet en point-to-point (quand il n'y a que 2 routeurs sur un segment Ethernet, par exemple un lien fibre directe). Cela evite l'overhead de l'election DR/BDR et accelere la convergence.

### Etape 4.3 : Comparer les timers

```
R1# show ip ospf interface GigabitEthernet0/1 | include Timer
R1# show ip ospf interface Serial0/0/0 | include Timer
```

**Output attendu :**

```
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
```

> Sur Cisco IOS, les timers par defaut sont identiques pour les reseaux broadcast et point-to-point : Hello = 10s, Dead = 40s. Sur les reseaux NBMA (Non-Broadcast Multi-Access, comme Frame Relay), les timers sont differents (Hello = 30s, Dead = 120s), mais ce type de reseau n'est plus au programme CCNA.

---

## Partie 5 : Verification des types de reseau et adjacences

### Etape 5.1 : Resume complet des interfaces OSPF sur R1

```
R1# show ip ospf interface brief
```

**Output attendu :**

```
Interface    PID   Area            IP Address/Mask    Cost  State Nbrs F/C
Gi0/1        1     0               10.0.0.1/24        1     DR    3/3
Se0/0/0      1     0               10.0.12.1/30       64    P2P   1/1
Gi0/0        1     0               192.168.1.1/24     1     DR    0/0
```

> **Lecture du resultat :**
> - **Gi0/1** : State DR (on a force la priorite a 255), 3 voisins dont 3 adjacences FULL (Nbrs F/C = 3/3). Le DR a une adjacence FULL avec tout le monde.
> - **Se0/0/0** : State P2P, 1 voisin et 1 adjacence FULL.
> - **Gi0/0** : State DR avec 0 voisins (passive-interface, aucun routeur OSPF sur le LAN).

### Etape 5.2 : Test de connectivite de bout en bout

```
PC-A> ping 192.168.4.10
```

**Output attendu :**

```
Reply from 192.168.4.10: bytes=32 time=3ms TTL=126
Reply from 192.168.4.10: bytes=32 time=2ms TTL=126
Reply from 192.168.4.10: bytes=32 time=2ms TTL=126
Reply from 192.168.4.10: bytes=32 time=2ms TTL=126
```

### Etape 5.3 : Traceroute pour voir le chemin

```
PC-A> tracert 192.168.4.10
```

**Output attendu :**

```
Tracing route to 192.168.4.10 over a maximum of 30 hops:

  1   1 ms    1 ms    1 ms    192.168.1.1
  2   2 ms    1 ms    1 ms    10.0.0.4
  3   2 ms    2 ms    2 ms    192.168.4.10

Trace complete.
```

> Le trafic passe par R1 (gateway) puis directement vers R4 via le segment broadcast (10.0.0.0/24), ce qui est le chemin le plus court.

---

## Verification finale - Criteres de reussite

- [ ] R1 est DR sur le segment broadcast (Gi0/1), avec priorite 255
- [ ] R2 est BDR sur le segment broadcast (Gi0/1), avec priorite 200
- [ ] R3 et R4 sont DROthers sur le segment broadcast
- [ ] R4 a une priorite OSPF de 0 (ne peut jamais etre DR/BDR)
- [ ] Le lien serie R1-R2 est en mode POINT-TO-POINT (pas de DR/BDR)
- [ ] Les DROthers (R3, R4) sont en etat 2WAY entre eux et FULL avec DR/BDR
- [ ] `show ip ospf neighbor` sur chaque routeur montre les bons roles (DR, BDR, DROTHER)
- [ ] PC-A peut pinger PC-B (192.168.1.10 -> 192.168.4.10)

---

## Questions de reflexion

**Q1 : Pourquoi l'election DR/BDR n'est-elle pas preemptive ?**

<details>
<summary>Voir la reponse</summary>

Si l'election etait preemptive, chaque fois qu'un routeur avec une priorite plus elevee rejoindrait le segment, il declencherait une nouvelle election. Tous les routeurs devraient resynchroniser leurs bases LSDB avec le nouveau DR, ce qui causerait une interruption de service. En rendant l'election non-preemptive, OSPF garantit la stabilite : un DR reste DR tant qu'il est operationnel, meme si un "meilleur" candidat apparait. La stabilite est privilegiee par rapport a l'optimalite.

</details>

**Q2 : Dans quel etat sont deux DROthers entre eux ? Pourquoi ?**

<details>
<summary>Voir la reponse</summary>

Deux DROthers restent en etat **2-WAY** entre eux. Ils ne forment pas d'adjacence FULL. Pourquoi ? Pour reduire le nombre d'adjacences et donc le volume de LSA echanges. Sur un segment avec n routeurs, au lieu de n*(n-1)/2 adjacences, on n'a que 2*(n-1) adjacences (chaque routeur avec le DR + chaque routeur avec le BDR, moins les doublons). Avec 10 routeurs : 45 adjacences deviennent 18. Les DROthers se connaissent (2-WAY = "je te vois dans tes Hellos et tu me vois dans les miens") mais n'echangent pas directement de LSA.

</details>

**Q3 : On change la priorite de R3 a 255 sans faire de `clear ip ospf process`. R3 devient-il DR ?**

<details>
<summary>Voir la reponse</summary>

Non. L'election DR/BDR n'est pas preemptive. R3 restera DROTHER malgre sa priorite de 255. R1 restera DR tant qu'il est operationnel. Pour que R3 devienne DR, il faudrait soit :
1. Faire un `clear ip ospf process` sur **tous** les routeurs du segment (ce qui force une reelection).
2. Faire tomber R1 ET R2 (le BDR deviendrait DR, puis si R2 tombe aussi, une nouvelle election aurait lieu).

C'est un scenario tres frequent dans les questions d'examen CCNA.

</details>

**Q4 : Pourquoi est-il recommande de ne pas utiliser les interfaces physiques comme base pour le router-id ?**

<details>
<summary>Voir la reponse</summary>

Si le router-id est derive d'une interface physique et que cette interface tombe, le router-id pourrait changer au prochain redemarrage du processus OSPF. Cela causerait une confusion dans le domaine OSPF (les voisins verraient un "nouveau" routeur). C'est pourquoi on configure toujours le router-id manuellement avec la commande `router-id` ou on utilise une interface loopback (qui ne tombe jamais physiquement). La meilleure pratique est la commande `router-id` explicite.

</details>

**Q5 (Troubleshoot) : Vous voyez `show ip ospf neighbor` afficher un voisin en etat EXSTART/EXCHANGE depuis plusieurs minutes. Quelle est la cause probable ?**

<details>
<summary>Voir la reponse</summary>

L'etat EXSTART/EXCHANGE indique que les routeurs essaient d'echanger leurs LSDB mais n'y arrivent pas. La cause la plus frequente est un **MTU mismatch** : les deux interfaces n'ont pas la meme MTU configuree. OSPF verifie que les MTU correspondent pendant la phase de Database Description (DBD). Si elles different, l'echange reste bloque. Solution : verifier les MTU avec `show interface` et les aligner, ou utiliser `ip ospf mtu-ignore` sur l'interface (pas recommande en production mais utile en depannage).

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
interface GigabitEthernet0/1
 ip address 10.0.0.1 255.255.255.0
 ip ospf priority 255
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 ip ospf network point-to-point
 clock rate 128000
 no shutdown
!
router ospf 1
 router-id 1.1.1.1
 passive-interface GigabitEthernet0/0
 network 192.168.1.0 0.0.0.255 area 0
 network 10.0.0.0 0.0.0.255 area 0
 network 10.0.12.0 0.0.0.3 area 0
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
interface GigabitEthernet0/1
 ip address 10.0.0.2 255.255.255.0
 ip ospf priority 200
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 ip ospf network point-to-point
 no shutdown
!
router ospf 1
 router-id 2.2.2.2
 network 10.0.0.0 0.0.0.255 area 0
 network 10.0.12.0 0.0.0.3 area 0
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
interface GigabitEthernet0/1
 ip address 10.0.0.3 255.255.255.0
 ip ospf priority 1
 no shutdown
!
router ospf 1
 router-id 3.3.3.3
 network 10.0.0.0 0.0.0.255 area 0
!
end
```

### R4 - Configuration finale

```
enable
configure terminal
hostname R4
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
interface GigabitEthernet0/1
 ip address 10.0.0.4 255.255.255.0
 ip ospf priority 0
 no shutdown
!
interface GigabitEthernet0/0
 ip address 192.168.4.1 255.255.255.0
 no shutdown
!
router ospf 1
 router-id 4.4.4.4
 passive-interface GigabitEthernet0/0
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.4.0 0.0.0.255 area 0
!
end
```

</details>
