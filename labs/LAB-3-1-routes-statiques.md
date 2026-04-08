# Lab 3.1 : Routes statiques IPv4/IPv6 sur topologie multi-routeurs

| Info | Valeur |
|------|--------|
| **Module** | 3 - Connectivite IP |
| **Topics couverts** | 3.1 Routage statique, 3.2 Routes par defaut, 3.3 Floating static routes |
| **Difficulte** | Intermediaire |
| **Duree estimee** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
    LAN-A                                                          LAN-B
 172.16.1.0/24                                                  172.16.4.0/24
2001:db8:a:1::/64                                             2001:db8:a:4::/64

   [PC1]                                                         [PC2]
     |                                                             |
   Gi0/0                                                         Gi0/0
   [R1]---Se0/0/0---[R2]---Se0/0/1---[R3]---Se0/0/1---[R4]
         10.0.12.0/30     10.0.23.0/30     10.0.34.0/30
       2001:db8:a:12::/64 2001:db8:a:23::/64 2001:db8:a:34::/64
```

---

## Tableau d'adressage

| Equipement | Interface | Adresse IPv4 | Masque | Adresse IPv6 | Passerelle par defaut |
|------------|-----------|-------------|--------|-------------|----------------------|
| R1 | Gi0/0 | 172.16.1.1 | 255.255.255.0 | 2001:db8:a:1::1/64 | N/A |
| R1 | Se0/0/0 | 10.0.12.1 | 255.255.255.252 | 2001:db8:a:12::1/64 | N/A |
| R2 | Se0/0/0 | 10.0.12.2 | 255.255.255.252 | 2001:db8:a:12::2/64 | N/A |
| R2 | Se0/0/1 | 10.0.23.1 | 255.255.255.252 | 2001:db8:a:23::1/64 | N/A |
| R3 | Se0/0/0 | 10.0.23.2 | 255.255.255.252 | 2001:db8:a:23::2/64 | N/A |
| R3 | Se0/0/1 | 10.0.34.1 | 255.255.255.252 | 2001:db8:a:34::1/64 | N/A |
| R4 | Se0/0/0 | 10.0.34.2 | 255.255.255.252 | 2001:db8:a:34::2/64 | N/A |
| R4 | Gi0/0 | 172.16.4.1 | 255.255.255.0 | 2001:db8:a:4::1/64 | N/A |
| PC1 | NIC | 172.16.1.10 | 255.255.255.0 | 2001:db8:a:1::10/64 | 172.16.1.1 |
| PC2 | NIC | 172.16.4.10 | 255.255.255.0 | 2001:db8:a:4::10/64 | 172.16.4.1 |

---

## Objectifs

1. Configurer l'adressage IPv4 et IPv6 sur une topologie serie de 4 routeurs.
2. Mettre en place des routes statiques next-hop pour assurer la connectivite de bout en bout.
3. Configurer des routes par defaut sur les routeurs de bordure (R1, R4).
4. Implementer une floating static route comme mecanisme de secours.
5. Configurer le routage statique IPv6.
6. Verifier le routage avec les commandes `show` et `traceroute`.

---

## Prerequis

- Savoir naviguer dans les modes CLI d'un routeur Cisco (user, privileged, config).
- Comprendre la notation CIDR et le calcul de masque (ici /30 = 255.255.255.252).
- Connaitre les bases de l'adressage IPv4 et IPv6.

---

## Configuration de depart

Copiez-collez ces commandes sur chaque equipement pour avoir une base propre avant de commencer.

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
 ip address 172.16.1.1 255.255.255.0
 ipv6 address 2001:db8:a:1::1/64
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 ipv6 address 2001:db8:a:12::1/64
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
banner motd # Acces autorise uniquement #
!
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 ipv6 address 2001:db8:a:12::2/64
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.23.1 255.255.255.252
 ipv6 address 2001:db8:a:23::1/64
 clock rate 128000
 no shutdown
!
ipv6 unicast-routing
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
interface Serial0/0/0
 ip address 10.0.23.2 255.255.255.252
 ipv6 address 2001:db8:a:23::2/64
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.34.1 255.255.255.252
 ipv6 address 2001:db8:a:34::1/64
 clock rate 128000
 no shutdown
!
ipv6 unicast-routing
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
banner motd # Acces autorise uniquement #
!
interface Serial0/0/0
 ip address 10.0.34.2 255.255.255.252
 ipv6 address 2001:db8:a:34::2/64
 no shutdown
!
interface GigabitEthernet0/0
 ip address 172.16.4.1 255.255.255.0
 ipv6 address 2001:db8:a:4::1/64
 no shutdown
!
ipv6 unicast-routing
end
```

### PC1

- IP : 172.16.1.10 / 255.255.255.0 / Gateway : 172.16.1.1
- IPv6 : 2001:db8:a:1::10/64 / Gateway : 2001:db8:a:1::1

### PC2

- IP : 172.16.4.10 / 255.255.255.0 / Gateway : 172.16.4.1
- IPv6 : 2001:db8:a:4::10/64 / Gateway : 2001:db8:a:4::1

---

## Partie 1 : Verification de l'adressage de base

Avant de configurer le moindre routage, on verifie que chaque lien direct fonctionne.

### Etape 1.1 : Verifier les interfaces sur R1

```
R1# show ip interface brief
```

**Output attendu :**

```
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     172.16.1.1      YES manual up                    up
Serial0/0/0            10.0.12.1       YES manual up                    up
```

> Toutes les interfaces doivent etre en `up/up`. Si une interface est `administratively down`, c'est que le `no shutdown` n'a pas ete applique.

### Etape 1.2 : Tester la connectivite entre voisins directs

```
R1# ping 10.0.12.2
```

**Output attendu :**

```
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.0.12.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

Repetez pour chaque lien direct :
- R2 vers R3 : `ping 10.0.23.2`
- R3 vers R4 : `ping 10.0.34.2`

### Etape 1.3 : Tenter un ping de bout en bout (il doit echouer)

```
PC1> ping 172.16.4.10
```

**Output attendu :**

```
Request timed out.
```

> C'est normal. A ce stade, aucun routeur ne sait comment atteindre les reseaux distants. La table de routage de R1 ne contient que ses reseaux directement connectes (`C` dans `show ip route`). Il faut ajouter des routes statiques.

---

## Partie 2 : Routes statiques IPv4 (next-hop)

On va configurer des routes statiques sur chaque routeur pour que chaque reseau soit joignable depuis partout. On utilise la methode **next-hop** (on indique l'adresse IP du routeur voisin).

### Pourquoi la methode next-hop ?

Avec un next-hop IP, le routeur effectue une resolution recursive : il cherche dans sa table comment joindre cette IP, puis envoie le paquet via l'interface correspondante. C'est la methode la plus courante sur les liens serie et la plus lisible.

### Etape 2.1 : Routes statiques sur R1

R1 connait deja LAN-A (172.16.1.0/24) et le lien R1-R2 (10.0.12.0/30). Il a besoin de routes vers les 3 autres reseaux.

```
R1(config)# ip route 10.0.23.0 255.255.255.252 10.0.12.2
R1(config)# ip route 10.0.34.0 255.255.255.252 10.0.12.2
R1(config)# ip route 172.16.4.0 255.255.255.0 10.0.12.2
```

> **Explication** : On dit a R1 "pour atteindre n'importe lequel de ces reseaux, envoie le paquet a R2 (10.0.12.2)". R2 saura ensuite quoi en faire.

### Etape 2.2 : Routes statiques sur R2

R2 est au milieu. Il a besoin de routes vers LAN-A (a gauche) et vers les reseaux a droite de R3.

```
R2(config)# ip route 172.16.1.0 255.255.255.0 10.0.12.1
R2(config)# ip route 10.0.34.0 255.255.255.252 10.0.23.2
R2(config)# ip route 172.16.4.0 255.255.255.0 10.0.23.2
```

### Etape 2.3 : Routes statiques sur R3

```
R3(config)# ip route 172.16.1.0 255.255.255.0 10.0.23.1
R3(config)# ip route 10.0.12.0 255.255.255.252 10.0.23.1
R3(config)# ip route 172.16.4.0 255.255.255.0 10.0.34.2
```

### Etape 2.4 : Routes statiques sur R4

```
R4(config)# ip route 172.16.1.0 255.255.255.0 10.0.34.1
R4(config)# ip route 10.0.12.0 255.255.255.252 10.0.34.1
R4(config)# ip route 10.0.23.0 255.255.255.252 10.0.34.1
```

### Etape 2.5 : Verification

```
R1# show ip route static
```

**Output attendu :**

```
      10.0.0.0/8 is variably subnetted, 4 subnets, 2 masks
S        10.0.23.0/30 [1/0] via 10.0.12.2
S        10.0.34.0/30 [1/0] via 10.0.12.2
      172.16.0.0/16 is variably subnetted, 3 subnets, 2 masks
S        172.16.4.0/24 [1/0] via 10.0.12.2
```

> Le `[1/0]` signifie : **AD (Administrative Distance) = 1**, metrique = 0. L'AD de 1 est la valeur par defaut des routes statiques. C'est un point frequent a l'examen.

Testez la connectivite de bout en bout :

```
PC1> ping 172.16.4.10
```

**Output attendu :**

```
Reply from 172.16.4.10: bytes=32 time=8ms TTL=124
Reply from 172.16.4.10: bytes=32 time=6ms TTL=124
Reply from 172.16.4.10: bytes=32 time=5ms TTL=124
Reply from 172.16.4.10: bytes=32 time=6ms TTL=124
```

---

## Partie 3 : Route par defaut sur R1 et R4

Les routeurs de bordure (R1 et R4) n'ont qu'un seul chemin vers "le reste du monde". Au lieu de lister chaque reseau distant, on peut utiliser une **route par defaut** (0.0.0.0/0).

### Etape 3.1 : Supprimer les routes statiques specifiques sur R1

```
R1(config)# no ip route 10.0.23.0 255.255.255.252 10.0.12.2
R1(config)# no ip route 10.0.34.0 255.255.255.252 10.0.12.2
R1(config)# no ip route 172.16.4.0 255.255.255.0 10.0.12.2
```

### Etape 3.2 : Configurer la route par defaut sur R1

```
R1(config)# ip route 0.0.0.0 0.0.0.0 10.0.12.2
```

> **Explication** : "Tout ce que tu ne connais pas, envoie-le a R2." L'adresse 0.0.0.0 avec le masque 0.0.0.0 correspond a n'importe quelle destination.

### Etape 3.3 : Route par defaut sur R4

```
R4(config)# no ip route 172.16.1.0 255.255.255.0 10.0.34.1
R4(config)# no ip route 10.0.12.0 255.255.255.252 10.0.34.1
R4(config)# no ip route 10.0.23.0 255.255.255.252 10.0.34.1
!
R4(config)# ip route 0.0.0.0 0.0.0.0 10.0.34.1
```

### Etape 3.4 : Verification

```
R1# show ip route
```

**Output attendu (extrait) :**

```
Gateway of last resort is 10.0.12.2 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.0.12.2
      10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        10.0.12.0/30 is directly connected, Serial0/0/0
L        10.0.12.1/32 is directly connected, Serial0/0/0
      172.16.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.16.1.0/24 is directly connected, GigabitEthernet0/0
L        172.16.1.1/32 is directly connected, GigabitEthernet0/0
```

> Notez le `S*` : l'asterisque indique que c'est la **route candidate par defaut** (gateway of last resort). Beaucoup plus propre que 3 routes statiques specifiques.

Verifiez que la connectivite fonctionne toujours :

```
PC1> ping 172.16.4.10
```

> **Point exam : longest prefix match.** Si R1 avait a la fois une route vers 172.16.4.0/24 et la route par defaut 0.0.0.0/0, laquelle serait utilisee pour atteindre 172.16.4.10 ? La route /24, car elle est plus specifique. C'est le principe du **longest prefix match** : le routeur choisit toujours la route avec le masque le plus long.

---

## Partie 4 : Floating static route (route de secours)

Une **floating static route** est une route statique avec une AD volontairement plus elevee. Elle ne s'installe dans la table de routage que si la route principale disparait.

### Scenario

Imaginons qu'on ajoute un lien backup entre R1 et R3 (dans un vrai labo Packet Tracer, vous ajouteriez une interface serie supplementaire). Ici, on va simuler le concept en configurant une route avec une AD elevee via R2, au cas ou la route principale serait plus specifique.

### Etape 4.1 : Ajouter une route specifique puis sa floating backup sur R1

D'abord, remettons une route specifique vers LAN-B :

```
R1(config)# ip route 172.16.4.0 255.255.255.0 10.0.12.2
```

Maintenant, ajoutons une floating static route avec AD = 10 (au lieu du defaut de 1). Cette route ne sera utilisee que si la premiere disparait :

```
R1(config)# ip route 172.16.4.0 255.255.255.0 10.0.12.2 10
```

> Attendez -- on pointe vers le meme next-hop ici pour illustrer la syntaxe. Dans un scenario reel, la floating route pointerait vers un chemin physiquement different (un autre lien, un autre FAI, etc.).

### Etape 4.2 : Observer la table de routage

```
R1# show ip route 172.16.4.0
```

**Output attendu :**

```
Routing entry for 172.16.4.0/24
  Known via "static", distance 1, metric 0
  Routing Descriptor Blocks:
  * 10.0.12.2
      Route metric is 0, traffic share count is 1
```

> Seule la route avec AD=1 apparait. La floating (AD=10) est en reserve.

### Etape 4.3 : Simuler une panne

Si on supprime la route principale :

```
R1(config)# no ip route 172.16.4.0 255.255.255.0 10.0.12.2
```

```
R1# show ip route 172.16.4.0
```

**Output attendu :**

```
Routing entry for 172.16.4.0/24
  Known via "static", distance 10, metric 0
  Routing Descriptor Blocks:
  * 10.0.12.2
      Route metric is 0, traffic share count is 1
```

> La floating route avec AD=10 s'active automatiquement. C'est exactement le comportement attendu pour un lien de secours.

Remettez la route principale :

```
R1(config)# ip route 172.16.4.0 255.255.255.0 10.0.12.2
```

> **Point exam** : L'AD par defaut d'une route statique est **1**. Pour creer une floating static route, on specifie une AD superieure a celle de la route principale. Si la route principale est apprise par OSPF (AD=110), la floating static doit avoir une AD > 110 (par exemple 115).

---

## Partie 5 : Routes statiques IPv6

Le routage statique IPv6 fonctionne exactement sur le meme principe, avec la commande `ipv6 route` au lieu de `ip route`.

### Etape 5.1 : Routes IPv6 sur R1 (route par defaut)

```
R1(config)# ipv6 route ::/0 2001:db8:a:12::2
```

> La notation `::/0` est l'equivalent IPv6 de `0.0.0.0/0`.

### Etape 5.2 : Routes IPv6 sur R2

```
R2(config)# ipv6 route 2001:db8:a:1::/64 2001:db8:a:12::1
R2(config)# ipv6 route 2001:db8:a:34::/64 2001:db8:a:23::2
R2(config)# ipv6 route 2001:db8:a:4::/64 2001:db8:a:23::2
```

### Etape 5.3 : Routes IPv6 sur R3

```
R3(config)# ipv6 route 2001:db8:a:1::/64 2001:db8:a:23::1
R3(config)# ipv6 route 2001:db8:a:12::/64 2001:db8:a:23::1
R3(config)# ipv6 route 2001:db8:a:4::/64 2001:db8:a:34::2
```

### Etape 5.4 : Routes IPv6 sur R4 (route par defaut)

```
R4(config)# ipv6 route ::/0 2001:db8:a:34::1
```

### Etape 5.5 : Verification

```
R1# show ipv6 route static
```

**Output attendu :**

```
IPv6 Routing Table - 6 entries
Codes: C - Connected, L - Local, S - Static

S   ::/0 [1/0]
     via 2001:DB8:A:12::2
```

```
R2# show ipv6 route static
```

**Output attendu :**

```
S   2001:DB8:A:1::/64 [1/0]
     via 2001:DB8:A:12::1
S   2001:DB8:A:4::/64 [1/0]
     via 2001:DB8:A:23::2
S   2001:DB8:A:34::/64 [1/0]
     via 2001:DB8:A:23::2
```

Test de bout en bout en IPv6 :

```
PC1> ping 2001:db8:a:4::10
```

**Output attendu :**

```
Reply from 2001:DB8:A:4::10: bytes=32 time=9ms TTL=124
Reply from 2001:DB8:A:4::10: bytes=32 time=7ms TTL=124
```

---

## Partie 6 : Verification finale

### Etape 6.1 : Traceroute IPv4

```
PC1> tracert 172.16.4.10
```

**Output attendu :**

```
Tracing route to 172.16.4.10 over a maximum of 30 hops:

  1   1 ms    1 ms    1 ms    172.16.1.1
  2   3 ms    2 ms    2 ms    10.0.12.2
  3   5 ms    4 ms    4 ms    10.0.23.2
  4   7 ms    6 ms    5 ms    10.0.34.2
  5   8 ms    7 ms    6 ms    172.16.4.10

Trace complete.
```

> Le traceroute confirme le chemin : PC1 -> R1 -> R2 -> R3 -> R4 -> PC2. Chaque saut correspond a un routeur intermediaire.

### Etape 6.2 : Table de routage complete de R2

```
R2# show ip route
```

**Output attendu :**

```
Gateway of last resort is not set

      10.0.0.0/8 is variably subnetted, 5 subnets, 2 masks
C        10.0.12.0/30 is directly connected, Serial0/0/0
L        10.0.12.2/32 is directly connected, Serial0/0/0
C        10.0.23.0/30 is directly connected, Serial0/0/1
L        10.0.23.1/32 is directly connected, Serial0/0/1
S        10.0.34.0/30 [1/0] via 10.0.23.2
      172.16.0.0/16 is variably subnetted, 2 subnets
S        172.16.1.0/24 [1/0] via 10.0.12.1
S        172.16.4.0/24 [1/0] via 10.0.23.2
```

> On voit bien les 3 types de routes : **C** (Connected), **L** (Local) et **S** (Static).

---

## Verification finale - Criteres de reussite

- [ ] PC1 peut pinger PC2 en IPv4 (172.16.4.10)
- [ ] PC2 peut pinger PC1 en IPv4 (172.16.1.10)
- [ ] PC1 peut pinger PC2 en IPv6 (2001:db8:a:4::10)
- [ ] Le traceroute depuis PC1 vers PC2 montre 4 sauts intermediaires (R1, R2, R3, R4)
- [ ] R1 et R4 utilisent une route par defaut (`S*` dans `show ip route`)
- [ ] R2 et R3 ont des routes statiques specifiques vers tous les reseaux
- [ ] La floating static route (AD=10) n'apparait PAS dans la table quand la route principale est presente
- [ ] `show ipv6 route` montre les routes statiques IPv6 sur chaque routeur

---

## Questions de reflexion

**Q1 : Pourquoi utilise-t-on des masques /30 sur les liens serie et pas /24 ?**

<details>
<summary>Voir la reponse</summary>

Un lien point-to-point ne connecte que 2 equipements. Un /30 fournit exactement 2 adresses hotes utilisables (sur 4 adresses totales : reseau, 2 hotes, broadcast). Utiliser un /24 gaspillerait 252 adresses. En production, on utilise meme parfois des /31 (RFC 3021) sur les liens point-to-point pour economiser une adresse supplementaire, mais le CCNA se concentre sur le /30.

</details>

**Q2 : Que se passe-t-il si on oublie de configurer les routes sur R2 mais qu'on configure tout le reste ?**

<details>
<summary>Voir la reponse</summary>

Le ping de PC1 vers PC2 echouerait. Meme si R1 envoie le paquet a R2 (via la route par defaut), R2 ne saurait pas comment atteindre 172.16.4.0/24 et rejetterait le paquet. Le routage doit etre coherent dans les deux sens : aller ET retour. C'est une erreur classique en troubleshooting.

</details>

**Q3 : Si R2 a une route vers 172.16.0.0/16 via R1 et une route vers 172.16.4.0/24 via R3, laquelle est utilisee pour atteindre 172.16.4.10 ?**

<details>
<summary>Voir la reponse</summary>

La route vers 172.16.4.0/24 (via R3) est utilisee, grace au **longest prefix match**. Le masque /24 est plus specifique que /16. Le routeur choisit toujours l'entree avec le prefixe le plus long (le masque le plus specifique) qui correspond a l'adresse de destination. C'est un concept fondamental teste a l'examen CCNA.

</details>

**Q4 : Quelle AD faudrait-il donner a une floating static route si la route principale est apprise par OSPF ?**

<details>
<summary>Voir la reponse</summary>

L'AD de OSPF est 110. La floating static route doit avoir une AD superieure a 110 pour ne s'activer que si OSPF disparait. On pourrait utiliser 115 ou 200, par exemple : `ip route 172.16.4.0 255.255.255.0 10.0.12.2 115`. Attention : si on utilise l'AD par defaut (1) d'une route statique, elle serait preferee a OSPF et prendrait le dessus en permanence, ce qui n'est pas l'effet desire.

</details>

**Q5 (Troubleshoot) : Vous configurez `ip route 172.16.4.0 255.255.255.0 10.0.99.1` sur R1, mais la route n'apparait pas dans `show ip route`. Pourquoi ?**

<details>
<summary>Voir la reponse</summary>

L'adresse next-hop 10.0.99.1 n'est pas joignable (aucune interface de R1 n'est dans le reseau 10.0.99.0/x). IOS refuse d'installer une route statique dont le next-hop est injoignable -- la resolution recursive echoue. La route reste dans la running-config mais n'est pas inseree dans la table de routage (RIB). C'est un piege classique.

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
 ip address 172.16.1.1 255.255.255.0
 ipv6 address 2001:db8:a:1::1/64
 no shutdown
!
interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 ipv6 address 2001:db8:a:12::1/64
 clock rate 128000
 no shutdown
!
ipv6 unicast-routing
!
ip route 0.0.0.0 0.0.0.0 10.0.12.2
ip route 172.16.4.0 255.255.255.0 10.0.12.2
ip route 172.16.4.0 255.255.255.0 10.0.12.2 10
!
ipv6 route ::/0 2001:db8:a:12::2
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
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 ipv6 address 2001:db8:a:12::2/64
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.23.1 255.255.255.252
 ipv6 address 2001:db8:a:23::1/64
 clock rate 128000
 no shutdown
!
ipv6 unicast-routing
!
ip route 172.16.1.0 255.255.255.0 10.0.12.1
ip route 10.0.34.0 255.255.255.252 10.0.23.2
ip route 172.16.4.0 255.255.255.0 10.0.23.2
!
ipv6 route 2001:db8:a:1::/64 2001:db8:a:12::1
ipv6 route 2001:db8:a:34::/64 2001:db8:a:23::2
ipv6 route 2001:db8:a:4::/64 2001:db8:a:23::2
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
interface Serial0/0/0
 ip address 10.0.23.2 255.255.255.252
 ipv6 address 2001:db8:a:23::2/64
 no shutdown
!
interface Serial0/0/1
 ip address 10.0.34.1 255.255.255.252
 ipv6 address 2001:db8:a:34::1/64
 clock rate 128000
 no shutdown
!
ipv6 unicast-routing
!
ip route 172.16.1.0 255.255.255.0 10.0.23.1
ip route 10.0.12.0 255.255.255.252 10.0.23.1
ip route 172.16.4.0 255.255.255.0 10.0.34.2
!
ipv6 route 2001:db8:a:1::/64 2001:db8:a:23::1
ipv6 route 2001:db8:a:12::/64 2001:db8:a:23::1
ipv6 route 2001:db8:a:4::/64 2001:db8:a:34::2
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
interface Serial0/0/0
 ip address 10.0.34.2 255.255.255.252
 ipv6 address 2001:db8:a:34::2/64
 no shutdown
!
interface GigabitEthernet0/0
 ip address 172.16.4.1 255.255.255.0
 ipv6 address 2001:db8:a:4::1/64
 no shutdown
!
ipv6 unicast-routing
!
ip route 0.0.0.0 0.0.0.0 10.0.34.1
!
ipv6 route ::/0 2001:db8:a:34::1
!
end
```

</details>
