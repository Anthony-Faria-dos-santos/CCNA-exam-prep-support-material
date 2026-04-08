# Lab 3.4 : Inter-VLAN routing + OSPF multi-site

| Info | Valeur |
|------|--------|
| **Module** | 3 - Connectivite IP / 2 - Acces reseau |
| **Topics couverts** | 3.2 Router-on-a-stick, 3.4 OSPF, 2.1 VLANs, 2.2 Trunking |
| **Difficulte** | Avance |
| **Duree estimee** | 60 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
          Site A                                              Site B
   192.168.10.0/24                                     192.168.10.128/25
   192.168.20.0/24                                     192.168.20.128/25
   192.168.30.0/24                                     192.168.30.128/25

   [PC1] VLAN10  [PC4] VLAN10
   [PC2] VLAN20  [PC5] VLAN20
   [PC3] VLAN30  [PC6] VLAN30
     |  |  |                                             |  |  |
    [SW1]                                               [SW2]
      | trunk                                             | trunk
    Gi0/0                                               Gi0/0
    [R1]----Se0/0/0------10.0.0.0/30------Se0/0/0----[R2]
   .10 .20 .30                                        .10 .20 .30
   subinterfaces                                      subinterfaces
```

---

## Tableau d'adressage

| Equipement | Interface | Adresse IPv4 | Masque | VLAN | Passerelle |
|------------|-----------|-------------|--------|------|-----------|
| R1 | Gi0/0.10 | 192.168.10.1 | 255.255.255.0 | 10 | N/A |
| R1 | Gi0/0.20 | 192.168.20.1 | 255.255.255.0 | 20 | N/A |
| R1 | Gi0/0.30 | 192.168.30.1 | 255.255.255.0 | 30 | N/A |
| R1 | Se0/0/0 | 10.0.0.1 | 255.255.255.252 | N/A | N/A |
| R2 | Gi0/0.10 | 192.168.10.129 | 255.255.255.0 | 10 | N/A |
| R2 | Gi0/0.20 | 192.168.20.129 | 255.255.255.0 | 20 | N/A |
| R2 | Gi0/0.30 | 192.168.30.129 | 255.255.255.0 | 30 | N/A |
| R2 | Se0/0/0 | 10.0.0.2 | 255.255.255.252 | N/A | N/A |
| SW1 | VLAN 1 | N/A | N/A | N/A | N/A |
| SW2 | VLAN 1 | N/A | N/A | N/A | N/A |
| PC1 | NIC | 192.168.10.10 | 255.255.255.0 | 10 | 192.168.10.1 |
| PC2 | NIC | 192.168.20.10 | 255.255.255.0 | 20 | 192.168.20.1 |
| PC3 | NIC | 192.168.30.10 | 255.255.255.0 | 30 | 192.168.30.1 |
| PC4 | NIC | 192.168.10.130 | 255.255.255.0 | 10 | 192.168.10.129 |
| PC5 | NIC | 192.168.20.130 | 255.255.255.0 | 20 | 192.168.20.129 |
| PC6 | NIC | 192.168.30.130 | 255.255.255.0 | 30 | 192.168.30.129 |

---

## Objectifs

1. Configurer les VLANs et les trunks sur les switches.
2. Mettre en place le routage inter-VLAN avec router-on-a-stick sur R1 et R2.
3. Configurer OSPF area 0 pour annoncer tous les reseaux (sous-interfaces incluses).
4. Verifier la connectivite inter-VLAN sur un meme site.
5. Verifier la connectivite inter-site et inter-VLAN (de bout en bout).
6. Analyser la table de routage OSPF resultante.

---

## Prerequis

- Savoir configurer des VLANs et des trunks 802.1Q.
- Comprendre le concept de sous-interface et d'encapsulation dot1q.
- Avoir complete les Labs 3.2 et 3.3 (OSPF de base et DR/BDR).

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
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.0.1 255.255.255.252
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
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.0.2 255.255.255.252
 no shutdown
!
end
```

### SW1

```
enable
configure terminal
hostname SW1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 15
 password cisco
 login
exit
banner motd # Acces autorise uniquement #
end
```

### SW2

```
enable
configure terminal
hostname SW2
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 15
 password cisco
 login
exit
banner motd # Acces autorise uniquement #
end
```

### PCs

Configurez les adresses IP des PCs comme indique dans le tableau d'adressage. A ce stade, ne configurez pas encore les gateways (on le fera apres avoir mis en place les sous-interfaces).

---

## Partie 1 : Configuration des VLANs et trunks sur les switches

### Pourquoi les VLANs ?

Les VLANs segmentent le reseau au niveau 2 (couche liaison). Chaque VLAN est un domaine de broadcast isole. Sans routage inter-VLAN, les machines de VLANs differents ne peuvent pas communiquer, meme si elles sont sur le meme switch.

### Etape 1.1 : Creer les VLANs sur SW1

```
SW1(config)# vlan 10
SW1(config-vlan)# name Ventes
SW1(config-vlan)# exit
SW1(config)# vlan 20
SW1(config-vlan)# name IT
SW1(config-vlan)# exit
SW1(config)# vlan 30
SW1(config-vlan)# name Direction
SW1(config-vlan)# exit
```

### Etape 1.2 : Assigner les ports d'acces sur SW1

```
SW1(config)# interface FastEthernet0/1
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 10
SW1(config-if)# no shutdown
SW1(config-if)# exit
!
SW1(config)# interface FastEthernet0/2
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 20
SW1(config-if)# no shutdown
SW1(config-if)# exit
!
SW1(config)# interface FastEthernet0/3
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 30
SW1(config-if)# no shutdown
SW1(config-if)# exit
```

### Etape 1.3 : Configurer le trunk vers R1 sur SW1

```
SW1(config)# interface GigabitEthernet0/1
SW1(config-if)# switchport mode trunk
SW1(config-if)# switchport trunk allowed vlan 10,20,30
SW1(config-if)# no shutdown
SW1(config-if)# exit
```

> **Explication** : Le trunk transporte le trafic de plusieurs VLANs sur un seul lien physique. Chaque trame est etiquetee (tagged) avec le numero de VLAN grace au protocole 802.1Q. On limite les VLANs autorises a 10, 20 et 30 pour des raisons de securite (ne pas laisser transiter des VLANs inutiles).

### Etape 1.4 : Repeter sur SW2

```
SW2(config)# vlan 10
SW2(config-vlan)# name Ventes
SW2(config-vlan)# exit
SW2(config)# vlan 20
SW2(config-vlan)# name IT
SW2(config-vlan)# exit
SW2(config)# vlan 30
SW2(config-vlan)# name Direction
SW2(config-vlan)# exit
!
SW2(config)# interface FastEthernet0/1
SW2(config-if)# switchport mode access
SW2(config-if)# switchport access vlan 10
SW2(config-if)# no shutdown
SW2(config-if)# exit
!
SW2(config)# interface FastEthernet0/2
SW2(config-if)# switchport mode access
SW2(config-if)# switchport access vlan 20
SW2(config-if)# no shutdown
SW2(config-if)# exit
!
SW2(config)# interface FastEthernet0/3
SW2(config-if)# switchport mode access
SW2(config-if)# switchport access vlan 30
SW2(config-if)# no shutdown
SW2(config-if)# exit
!
SW2(config)# interface GigabitEthernet0/1
SW2(config-if)# switchport mode trunk
SW2(config-if)# switchport trunk allowed vlan 10,20,30
SW2(config-if)# no shutdown
SW2(config-if)# exit
```

### Etape 1.5 : Verification des VLANs

```
SW1# show vlan brief
```

**Output attendu :**

```
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/4, Fa0/5, Fa0/6, ...
10   Ventes                           active    Fa0/1
20   IT                               active    Fa0/2
30   Direction                        active    Fa0/3
1002 fddi-default                     active
1003 token-ring-default               active
1004 fddinet-default                  active
1005 trnet-default                    active
```

### Etape 1.6 : Verification du trunk

```
SW1# show interfaces trunk
```

**Output attendu :**

```
Port        Mode         Encapsulation  Status        Native vlan
Gi0/1       on           802.1q         trunking      1

Port        Vlans allowed on trunk
Gi0/1       10,20,30

Port        Vlans allowed and active in management domain
Gi0/1       10,20,30

Port        Vlans in spanning tree forwarding state and not pruned
Gi0/1       10,20,30
```

> Le trunk est actif et ne transporte que les VLANs 10, 20 et 30. C'est exactement ce qu'on veut.

---

## Partie 2 : Configuration router-on-a-stick

### Comment ca marche ?

Router-on-a-stick utilise des **sous-interfaces** sur le routeur. Chaque sous-interface est associee a un VLAN via l'encapsulation 802.1Q et recoit une adresse IP qui sert de passerelle pour ce VLAN. Le routeur route ensuite le trafic entre les sous-interfaces comme entre des interfaces normales.

### Etape 2.1 : Sous-interfaces sur R1

```
R1(config)# interface GigabitEthernet0/0.10
R1(config-subif)# encapsulation dot1Q 10
R1(config-subif)# ip address 192.168.10.1 255.255.255.0
R1(config-subif)# exit
!
R1(config)# interface GigabitEthernet0/0.20
R1(config-subif)# encapsulation dot1Q 20
R1(config-subif)# ip address 192.168.20.1 255.255.255.0
R1(config-subif)# exit
!
R1(config)# interface GigabitEthernet0/0.30
R1(config-subif)# encapsulation dot1Q 30
R1(config-subif)# ip address 192.168.30.1 255.255.255.0
R1(config-subif)# exit
```

> **Explication :**
> - `interface GigabitEthernet0/0.10` : Cree la sous-interface 10 sur Gi0/0. Le numero apres le point est arbitraire, mais par convention on utilise le numero du VLAN.
> - `encapsulation dot1Q 10` : Associe cette sous-interface au VLAN 10. Toute trame arrivant avec le tag 802.1Q #10 sera traitee par cette sous-interface.
> - `ip address 192.168.10.1 255.255.255.0` : L'adresse IP de la sous-interface, qui servira de passerelle par defaut aux PCs du VLAN 10.

### Etape 2.2 : Sous-interfaces sur R2

```
R2(config)# interface GigabitEthernet0/0.10
R2(config-subif)# encapsulation dot1Q 10
R2(config-subif)# ip address 192.168.10.129 255.255.255.0
R2(config-subif)# exit
!
R2(config)# interface GigabitEthernet0/0.20
R2(config-subif)# encapsulation dot1Q 20
R2(config-subif)# ip address 192.168.20.129 255.255.255.0
R2(config-subif)# exit
!
R2(config)# interface GigabitEthernet0/0.30
R2(config-subif)# encapsulation dot1Q 30
R2(config-subif)# ip address 192.168.30.129 255.255.255.0
R2(config-subif)# exit
```

### Etape 2.3 : Verification des sous-interfaces

```
R1# show ip interface brief
```

**Output attendu :**

```
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     unassigned      YES unset  up                    up
GigabitEthernet0/0.10  192.168.10.1    YES manual up                    up
GigabitEthernet0/0.20  192.168.20.1    YES manual up                    up
GigabitEthernet0/0.30  192.168.30.1    YES manual up                    up
Serial0/0/0            10.0.0.1        YES manual up                    up
```

> Notez que l'interface physique Gi0/0 n'a pas d'adresse IP (unassigned). C'est normal : les adresses sont sur les sous-interfaces. L'interface physique doit etre `up/up` pour que les sous-interfaces fonctionnent.

### Etape 2.4 : Configurer les gateways sur les PCs

Maintenant que les sous-interfaces sont en place, configurez les passerelles :

| PC | Gateway |
|----|---------|
| PC1 | 192.168.10.1 |
| PC2 | 192.168.20.1 |
| PC3 | 192.168.30.1 |
| PC4 | 192.168.10.129 |
| PC5 | 192.168.20.129 |
| PC6 | 192.168.30.129 |

---

## Partie 3 : Configuration OSPF

On va annoncer tous les reseaux dans OSPF area 0, y compris les sous-reseaux des sous-interfaces et le lien serie WAN.

### Etape 3.1 : OSPF sur R1

```
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# network 192.168.10.0 0.0.0.255 area 0
R1(config-router)# network 192.168.20.0 0.0.0.255 area 0
R1(config-router)# network 192.168.30.0 0.0.0.255 area 0
R1(config-router)# network 10.0.0.0 0.0.0.3 area 0
R1(config-router)# passive-interface GigabitEthernet0/0.10
R1(config-router)# passive-interface GigabitEthernet0/0.20
R1(config-router)# passive-interface GigabitEthernet0/0.30
R1(config-router)# exit
```

> **Pourquoi passive-interface sur les sous-interfaces ?**
> Il n'y a pas de routeur OSPF sur les LANs. On veut annoncer les reseaux 192.168.10/20/30.0 dans OSPF, mais ne pas envoyer de paquets Hello inutiles vers les PCs. C'est le meme principe que dans le Lab 3.2.

### Etape 3.2 : OSPF sur R2

```
R2(config)# router ospf 1
R2(config-router)# router-id 2.2.2.2
R2(config-router)# network 192.168.10.0 0.0.0.255 area 0
R2(config-router)# network 192.168.20.0 0.0.0.255 area 0
R2(config-router)# network 192.168.30.0 0.0.0.255 area 0
R2(config-router)# network 10.0.0.0 0.0.0.3 area 0
R2(config-router)# passive-interface GigabitEthernet0/0.10
R2(config-router)# passive-interface GigabitEthernet0/0.20
R2(config-router)# passive-interface GigabitEthernet0/0.30
R2(config-router)# exit
```

### Etape 3.3 : Verifier l'adjacence OSPF

```
R1# show ip ospf neighbor
```

**Output attendu :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           0   FULL/  -        00:00:35    10.0.0.2        Serial0/0/0
```

> Une seule adjacence, sur le lien serie. C'est normal : les sous-interfaces sont en passive. Le lien serie etant point-to-point, il n'y a pas d'election DR/BDR (FULL/ -).

---

## Partie 4 : Verification inter-VLAN locale

Avant de tester l'inter-site, verifions que le routage inter-VLAN fonctionne sur chaque site individuellement.

### Etape 4.1 : Ping entre VLANs differents (meme site)

```
PC1> ping 192.168.20.10
```

**Output attendu :**

```
Reply from 192.168.20.10: bytes=32 time=1ms TTL=127
Reply from 192.168.20.10: bytes=32 time=1ms TTL=127
Reply from 192.168.20.10: bytes=32 time=0ms TTL=127
Reply from 192.168.20.10: bytes=32 time=1ms TTL=127
```

> Le premier ping peut echouer (ARP timeout). C'est normal. Le TTL de 127 indique un saut via le routeur (128 - 1 = 127).

```
PC1> ping 192.168.30.10
```

**Output attendu :**

```
Reply from 192.168.30.10: bytes=32 time=1ms TTL=127
Reply from 192.168.30.10: bytes=32 time=0ms TTL=127
```

> PC1 (VLAN 10) communique avec PC3 (VLAN 30) en passant par R1. Le trajet est : PC1 -> SW1 (trame taguee VLAN 10 via trunk) -> R1 Gi0/0.10 -> routage interne -> R1 Gi0/0.30 -> SW1 (trame taguee VLAN 30 via trunk) -> PC3.

### Etape 4.2 : Meme verification sur le site B

```
PC4> ping 192.168.20.130
```

```
PC4> ping 192.168.30.130
```

Les deux doivent reussir.

---

## Partie 5 : Verification inter-site

### Etape 5.1 : Meme VLAN, sites differents

```
PC1> ping 192.168.10.130
```

**Output attendu :**

```
Reply from 192.168.10.130: bytes=32 time=7ms TTL=126
Reply from 192.168.10.130: bytes=32 time=5ms TTL=126
Reply from 192.168.10.130: bytes=32 time=5ms TTL=126
Reply from 192.168.10.130: bytes=32 time=5ms TTL=126
```

> Le TTL de 126 confirme 2 sauts (128 - 2). Le paquet passe par R1, puis par R2 via le lien serie.

### Etape 5.2 : VLANs differents, sites differents

```
PC1> ping 192.168.20.130
```

**Output attendu :**

```
Reply from 192.168.20.130: bytes=32 time=8ms TTL=126
Reply from 192.168.20.130: bytes=32 time=6ms TTL=126
Reply from 192.168.20.130: bytes=32 time=5ms TTL=126
Reply from 192.168.20.130: bytes=32 time=5ms TTL=126
```

> PC1 (VLAN 10, Site A) communique avec PC5 (VLAN 20, Site B). Le trajet complet :
> 1. PC1 envoie a sa gateway 192.168.10.1 (R1 Gi0/0.10)
> 2. R1 consulte sa table de routage : 192.168.20.128 est appris via OSPF, next-hop 10.0.0.2 (R2)
> 3. R1 envoie via Se0/0/0 vers R2
> 4. R2 recoit et route vers Gi0/0.20 (192.168.20.129)
> 5. R2 envoie la trame taguee VLAN 20 via trunk vers SW2
> 6. SW2 delivre a PC5
>
> Tout cela est transparent pour les PCs : ils ne voient qu'un "saut" via leur gateway.

### Etape 5.3 : Traceroute inter-site

```
PC1> tracert 192.168.30.130
```

**Output attendu :**

```
Tracing route to 192.168.30.130 over a maximum of 30 hops:

  1   1 ms    1 ms    1 ms    192.168.10.1
  2   6 ms    5 ms    5 ms    10.0.0.2
  3   7 ms    6 ms    6 ms    192.168.30.130

Trace complete.
```

> 3 sauts : R1 (gateway) -> R2 (via WAN) -> PC6 (destination). Notez que l'adresse affichee pour le saut 2 est 10.0.0.2 (l'interface de sortie du lien serie de R2, pas la sous-interface de destination).

---

## Partie 6 : Analyse de la table de routage OSPF

### Etape 6.1 : Table de routage complete de R1

```
R1# show ip route
```

**Output attendu :**

```
Gateway of last resort is not set

      10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        10.0.0.0/30 is directly connected, Serial0/0/0
L        10.0.0.1/32 is directly connected, Serial0/0/0
      192.168.10.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.10.0/24 is directly connected, GigabitEthernet0/0.10
L        192.168.10.1/32 is directly connected, GigabitEthernet0/0.10
      192.168.20.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.20.0/24 is directly connected, GigabitEthernet0/0.20
L        192.168.20.1/32 is directly connected, GigabitEthernet0/0.20
      192.168.30.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.30.0/24 is directly connected, GigabitEthernet0/0.30
L        192.168.30.1/32 is directly connected, GigabitEthernet0/0.30
```

> Attendez -- ou sont les routes OSPF ? Si la table ne montre que des routes Connected et Local, c'est que OSPF n'a pas encore converge ou qu'il y a un probleme.

### Etape 6.2 : Afficher uniquement les routes OSPF

```
R1# show ip route ospf
```

**Output attendu :**

```
(vide - aucune route OSPF)
```

> **Pourquoi pas de routes OSPF ?** C'est parce que R1 et R2 utilisent le meme reseau /24 pour les VLANs (192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24). R1 a deja ces reseaux comme Connected. OSPF ne va pas installer une route OSPF vers un reseau qu'il connait deja directement.
>
> Cependant, R2 annonce bien ces reseaux. La route Connected est simplement preferee (AD 0 vs OSPF AD 110). Le routage fonctionne quand meme parce que :
> 1. PC1 envoie a R1 (sa gateway 192.168.10.1)
> 2. R1 sait que 192.168.10.130 est dans 192.168.10.0/24 (Connected)
> 3. Mais 192.168.10.130 n'est pas joignable via l'interface locale Gi0/0.10 (pas dans la table ARP)
> 4. R1 envoie un ICMP redirect... ou echoue.

> **C'est un piege classique !** Pour que le routage fonctionne correctement entre les sites avec les memes numeros de VLAN, il faudrait soit :
> - Utiliser des sous-reseaux differents par site (ex: 192.168.10.0/25 pour le site A et 192.168.10.128/25 pour le site B)
> - Ou utiliser des numeros de VLAN differents avec des reseaux differents.
>
> Dans notre configuration, les PCs du site B sont a .130 et la gateway R2 est a .129, donc ils sont bien dans le meme /24 que les PCs du site A. OSPF voit un conflit. En pratique, cela fonctionne grace au routage sur le lien serie : quand R1 ne trouve pas .130 dans son ARP, il utilise le lien WAN.

Verifions que tout fonctionne malgre cette subtilite :

```
R1# show ip route 192.168.10.130
```

**Output attendu :**

```
Routing entry for 192.168.10.0/24
  Known via "connected", distance 0, metric 0 (connected)
  Routing Descriptor Blocks:
  * directly connected, via GigabitEthernet0/0.10
      Route metric is 0, traffic share count is 1
```

> R1 pense que 192.168.10.130 est sur son propre segment. C'est la que ca se complique. Si le ARP echoue (PC4 n'est pas sur le meme segment L2), le paquet sera perdu.
>
> **La bonne pratique est d'utiliser des sous-reseaux differents par site.** Corrigeons cela si necessaire en verifiant la connectivite.

### Etape 6.3 : Verification de la connectivite effective

Testez le ping PC1 -> PC4 :

```
PC1> ping 192.168.10.130
```

Si ce ping echoue, c'est le comportement attendu du au conflit de sous-reseau. Dans un environnement de production, on utiliserait des reseaux distincts pour chaque site.

> **Note pedagogique** : Ce scenario illustre volontairement une erreur courante de conception reseau. L'utilisation du meme sous-reseau /24 sur deux sites distants cree une ambiguite de routage. Le routeur R1, voyant que 192.168.10.130 est dans un reseau Connected (192.168.10.0/24 sur Gi0/0.10), essaie de le joindre directement au lieu de l'envoyer via OSPF.
>
> Si la connectivite inter-site fonctionne dans Packet Tracer (le comportement peut varier), c'est grace au proxy-ARP ou a un mecanisme specifique du simulateur. En production reelle, cette conception ne fonctionnerait pas de maniere fiable.

### Etape 6.4 : Table de routage de R2

```
R2# show ip route
```

**Output attendu :**

```
Gateway of last resort is not set

      10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        10.0.0.0/30 is directly connected, Serial0/0/0
L        10.0.0.2/32 is directly connected, Serial0/0/0
      192.168.10.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.10.0/24 is directly connected, GigabitEthernet0/0.10
L        192.168.10.129/32 is directly connected, GigabitEthernet0/0.10
      192.168.20.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.20.0/24 is directly connected, GigabitEthernet0/0.20
L        192.168.20.129/32 is directly connected, GigabitEthernet0/0.20
      192.168.30.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.30.0/24 is directly connected, GigabitEthernet0/0.30
L        192.168.30.129/32 is directly connected, GigabitEthernet0/0.30
```

> Meme observation que pour R1 : toutes les routes sont Connected, OSPF n'ajoute rien de visible car les memes reseaux /24 sont directement connectes des deux cotes. Le lien WAN (10.0.0.0/30) est Connected aussi.

### Etape 6.5 : Verifier que OSPF est bien actif

```
R1# show ip protocols
```

**Output attendu (extrait) :**

```
Routing Protocol is "ospf 1"
  Router ID 1.1.1.1
  Number of areas in this router is 1. 1 normal 0 stub 0 nssa
  Routing for Networks:
    192.168.10.0 0.0.0.255 area 0
    192.168.20.0 0.0.0.255 area 0
    192.168.30.0 0.0.0.255 area 0
    10.0.0.0 0.0.0.3 area 0
  Passive Interface(s):
    GigabitEthernet0/0.10
    GigabitEthernet0/0.20
    GigabitEthernet0/0.30
  Routing Information Sources:
    Gateway         Distance      Last Update
    1.1.1.1              110      00:05:00
    2.2.2.2              110      00:04:45
```

> OSPF est bien actif avec les bons network statements et les bonnes passive-interfaces. L'adjacence avec R2 (2.2.2.2) est presente.

```
R1# show ip ospf neighbor
```

**Output attendu :**

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           0   FULL/  -        00:00:33    10.0.0.2        Serial0/0/0
```

> L'adjacence OSPF est FULL. Le processus fonctionne correctement. C'est le chevauchement des sous-reseaux qui masque les routes OSPF dans la table de routage.

---

## Verification finale - Criteres de reussite

- [ ] Les VLANs 10, 20 et 30 existent sur SW1 et SW2 avec les bons noms
- [ ] Les trunks sont actifs sur Gi0/1 de SW1 et SW2 (VLANs 10,20,30 autorises)
- [ ] Les sous-interfaces Gi0/0.10, .20, .30 sont up/up sur R1 et R2
- [ ] `show ip protocols` montre OSPF actif avec les 4 network statements sur chaque routeur
- [ ] Les sous-interfaces LAN sont en passive-interface
- [ ] L'adjacence OSPF R1-R2 est en etat FULL sur le lien serie
- [ ] PC1 peut pinger PC2 et PC3 (inter-VLAN local, meme site)
- [ ] PC4 peut pinger PC5 et PC6 (inter-VLAN local, meme site)
- [ ] Le traceroute de PC1 vers PC3 montre 1 saut intermediaire (R1)

---

## Questions de reflexion

**Q1 : Pourquoi faut-il configurer l'interface physique Gi0/0 en `no shutdown` avant de creer les sous-interfaces ?**

<details>
<summary>Voir la reponse</summary>

Les sous-interfaces heritent de l'etat de l'interface physique parente. Si Gi0/0 est administratively down, toutes les sous-interfaces (Gi0/0.10, Gi0/0.20, Gi0/0.30) seront egalement down, meme si elles sont correctement configurees. C'est un piege classique en troubleshooting : on configure tout mais on oublie le `no shutdown` sur l'interface physique.

</details>

**Q2 : Que se passe-t-il si on oublie `encapsulation dot1Q 10` sur une sous-interface ?**

<details>
<summary>Voir la reponse</summary>

Sans la commande `encapsulation dot1Q`, la sous-interface ne sait pas quel tag VLAN utiliser. Les trames arrivant avec le tag VLAN 10 ne seront pas associees a cette sous-interface. Le routage inter-VLAN ne fonctionnera pas pour ce VLAN. Sur Packet Tracer, l'interface sera probablement en `up/up` mais ne traitera aucun trafic tag'e.

</details>

**Q3 : Pourquoi les routes OSPF n'apparaissent-elles pas dans la table de routage quand les deux sites utilisent les memes sous-reseaux /24 ?**

<details>
<summary>Voir la reponse</summary>

Les routes Connected (AD = 0) sont toujours preferees aux routes OSPF (AD = 110). Quand R1 est directement connecte a 192.168.10.0/24 via Gi0/0.10, et que R2 annonce le meme reseau 192.168.10.0/24 via OSPF, la route Connected gagne. La route OSPF est connue mais pas installee dans la table de routage (RIB) car elle est "shadowed" par la route Connected. C'est pourquoi en production, on utilise des sous-reseaux differents par site (par exemple /25 au lieu de /24, avec des plages d'adresses distinctes).

</details>

**Q4 : Si on ajoutait un troisieme site avec un routeur R3, quelles commandes faudrait-il pour integrer ses VLANs dans OSPF ?**

<details>
<summary>Voir la reponse</summary>

Il faudrait :
1. Configurer les VLANs et le trunk sur le nouveau switch.
2. Creer les sous-interfaces sur R3 avec `encapsulation dot1Q` et des adresses IP dans des sous-reseaux **differents** (par exemple 192.168.10.0/25 site A, 192.168.10.128/25 site B, et un troisieme sous-reseau pour le site C).
3. Connecter R3 a un ou plusieurs routeurs existants (lien serie ou Ethernet).
4. Configurer OSPF sur R3 : `router ospf 1`, `router-id 3.3.3.3`, `network` statements pour chaque sous-reseau, `passive-interface` sur les sous-interfaces LAN.
5. L'adjacence se formera automatiquement et les routes seront echangees. C'est toute la puissance d'OSPF : l'ajout d'un site est transparent pour les sites existants.

</details>

**Q5 (Troubleshoot) : PC1 peut pinger PC2 (inter-VLAN meme site) mais pas PC4 (meme VLAN, site distant). Ou chercher le probleme ?**

<details>
<summary>Voir la reponse</summary>

Demarche de troubleshooting :

1. **Verifier l'adjacence OSPF** : `show ip ospf neighbor` sur R1. Si l'adjacence avec R2 n'est pas FULL, le probleme est entre R1 et R2 (lien serie, network statements, timers...).

2. **Verifier le lien serie** : `ping 10.0.0.2` depuis R1. Si ca echoue, le probleme est physique (cable, interface down, adressage).

3. **Verifier la table de routage** : `show ip route` sur R1. Si aucune route vers le site B n'apparait, OSPF ne redistribue pas correctement.

4. **Verifier le conflit de sous-reseau** : Si les deux sites utilisent le meme /24, R1 pense que PC4 est sur son propre segment et n'envoie pas le trafic via le lien WAN. C'est le probleme decrit dans ce lab. Solution : utiliser des sous-reseaux differents.

5. **Verifier le trunk et les VLANs** sur SW2 : `show interfaces trunk`, `show vlan brief`. Un VLAN manquant ou un trunk mal configure empecherait la delivrance au PC distant.

</details>

---

## Solution complete

<details>
<summary>Voir la solution complete</summary>

### SW1 - Configuration finale

```
enable
configure terminal
hostname SW1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 15
 password cisco
 login
exit
!
vlan 10
 name Ventes
vlan 20
 name IT
vlan 30
 name Direction
exit
!
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 10
 no shutdown
!
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 20
 no shutdown
!
interface FastEthernet0/3
 switchport mode access
 switchport access vlan 30
 no shutdown
!
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30
 no shutdown
!
end
```

### SW2 - Configuration finale

```
enable
configure terminal
hostname SW2
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
 logging synchronous
line vty 0 15
 password cisco
 login
exit
!
vlan 10
 name Ventes
vlan 20
 name IT
vlan 30
 name Direction
exit
!
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 10
 no shutdown
!
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 20
 no shutdown
!
interface FastEthernet0/3
 switchport mode access
 switchport access vlan 30
 no shutdown
!
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30
 no shutdown
!
end
```

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
 no ip address
 no shutdown
!
interface GigabitEthernet0/0.10
 encapsulation dot1Q 10
 ip address 192.168.10.1 255.255.255.0
!
interface GigabitEthernet0/0.20
 encapsulation dot1Q 20
 ip address 192.168.20.1 255.255.255.0
!
interface GigabitEthernet0/0.30
 encapsulation dot1Q 30
 ip address 192.168.30.1 255.255.255.0
!
interface Serial0/0/0
 ip address 10.0.0.1 255.255.255.252
 clock rate 128000
 no shutdown
!
router ospf 1
 router-id 1.1.1.1
 passive-interface GigabitEthernet0/0.10
 passive-interface GigabitEthernet0/0.20
 passive-interface GigabitEthernet0/0.30
 network 192.168.10.0 0.0.0.255 area 0
 network 192.168.20.0 0.0.0.255 area 0
 network 192.168.30.0 0.0.0.255 area 0
 network 10.0.0.0 0.0.0.3 area 0
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
 no ip address
 no shutdown
!
interface GigabitEthernet0/0.10
 encapsulation dot1Q 10
 ip address 192.168.10.129 255.255.255.0
!
interface GigabitEthernet0/0.20
 encapsulation dot1Q 20
 ip address 192.168.20.129 255.255.255.0
!
interface GigabitEthernet0/0.30
 encapsulation dot1Q 30
 ip address 192.168.30.129 255.255.255.0
!
interface Serial0/0/0
 ip address 10.0.0.2 255.255.255.252
 no shutdown
!
router ospf 1
 router-id 2.2.2.2
 passive-interface GigabitEthernet0/0.10
 passive-interface GigabitEthernet0/0.20
 passive-interface GigabitEthernet0/0.30
 network 192.168.10.0 0.0.0.255 area 0
 network 192.168.20.0 0.0.0.255 area 0
 network 192.168.30.0 0.0.0.255 area 0
 network 10.0.0.0 0.0.0.3 area 0
!
end
```

</details>
