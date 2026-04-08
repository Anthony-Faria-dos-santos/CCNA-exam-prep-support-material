# LAB 4.1 — NAT statique, NAT dynamique et PAT (overload)

| Info | Valeur |
|------|--------|
| **Module** | 4 — IP Services |
| **Topics couverts** | 4.1 — Configure and verify inside source NAT using static and pools |
| **Difficulté** | Intermédiaire |
| **Durée estimée** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                          INTERNET SIMULÉ
                         ┌─────────────┐
                         │  WEB-SRV    │
                         │ 8.8.8.100/24│
                         └──────┬──────┘
                                │ Gi0/1
                         ┌──────┴──────┐
                         │   R-ISP     │
                         │             │
                         └──────┬──────┘
                                │ Gi0/0
                                │ 203.0.113.1/30
                                │
                                │ 203.0.113.2/30
                                │ Gi0/1
                         ┌──────┴──────┐
                         │     R1      │
                         │ NAT Gateway │
                         └──────┬──────┘
                                │ Gi0/0
                                │ 192.168.1.1/24
                                │
                         ┌──────┴──────┐
                         │    SW1      │
                         │  (Switch)   │
                         └─┬────┬────┬─┘
                           │    │    │
                          PC1  PC2  PC3
                        .10   .11   .12
                      192.168.1.0/24
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | Passerelle |
|----------|-----------|------------|--------|------------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | — |
| R1 | Gi0/1 | 203.0.113.2 | 255.255.255.252 | — |
| R-ISP | Gi0/0 | 203.0.113.1 | 255.255.255.252 | — |
| R-ISP | Gi0/1 | 8.8.8.1 | 255.255.255.0 | — |
| SW1 | VLAN 1 | 192.168.1.2 | 255.255.255.0 | 192.168.1.1 |
| PC1 | NIC | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |
| PC2 | NIC | 192.168.1.11 | 255.255.255.0 | 192.168.1.1 |
| PC3 | NIC | 192.168.1.12 | 255.255.255.0 | 192.168.1.1 |
| WEB-SRV | NIC | 8.8.8.100 | 255.255.255.0 | 8.8.8.1 |

**Pool NAT :** 203.0.113.10 — 203.0.113.14 (5 adresses publiques)
**PAT :** utilise l'adresse de l'interface outside (Gi0/1 = 203.0.113.2)

---

## Objectifs

1. Configurer l'adressage IP de base et vérifier la connectivité interne
2. Configurer le NAT statique pour rendre PC1 accessible depuis Internet
3. Configurer le NAT dynamique avec un pool d'adresses publiques
4. Configurer le PAT (overload) pour partager une seule adresse publique
5. Vérifier et analyser les traductions NAT avec les commandes `show` et `debug`

---

## Prérequis

- Connaissance des adresses IP privées (RFC 1918) et publiques
- Configuration de base d'un routeur Cisco (hostname, interfaces)
- Compréhension des ACL standard
- Savoir utiliser `ping` et `traceroute`

---

## Configuration de départ

Copiez-collez ces configurations **avant de commencer le lab**. Elles mettent en place le hostname et désactivent la résolution DNS pour éviter les délais.

### R1 — Configuration initiale

```
enable
configure terminal
hostname R1
no ip domain-lookup
line console 0
 logging synchronous
exit
```

### R-ISP — Configuration initiale

```
enable
configure terminal
hostname R-ISP
no ip domain-lookup
line console 0
 logging synchronous
exit
```

---

## Partie 1 : Configuration de base et connectivité interne

L'objectif de cette première partie est de monter toute l'infrastructure réseau avant de toucher au NAT. On veut que chaque appareil puisse communiquer au sein de son propre réseau, et que R1 ait une route vers Internet (et inversement).

### Étape 1.1 — Configurer les interfaces de R1

Sur **R1** :

```
configure terminal

interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
 description LAN interne
exit

interface GigabitEthernet0/1
 ip address 203.0.113.2 255.255.255.252
 no shutdown
 description Lien vers ISP
exit
```

> **Pourquoi /30 sur le lien ISP ?** Un lien point-à-point entre deux routeurs n'a besoin que de 2 adresses utilisables. Le masque /30 (255.255.255.252) fournit exactement 2 adresses hôtes, ce qui est la pratique standard pour les liens WAN.

### Étape 1.2 — Configurer les interfaces de R-ISP

Sur **R-ISP** :

```
configure terminal

interface GigabitEthernet0/0
 ip address 203.0.113.1 255.255.255.252
 no shutdown
 description Lien vers client (R1)
exit

interface GigabitEthernet0/1
 ip address 8.8.8.1 255.255.255.0
 no shutdown
 description Réseau serveurs
exit
```

### Étape 1.3 — Ajouter une route par défaut sur R1

R1 doit savoir où envoyer le trafic destiné à Internet :

```
ip route 0.0.0.0 0.0.0.0 203.0.113.1
```

### Étape 1.4 — Ajouter une route de retour sur R-ISP

R-ISP doit connaître le chemin de retour vers le réseau privé de R1 (ou, plus précisément, vers les adresses NAT que R1 va utiliser). Pour l'instant, on ajoute une route vers le pool NAT et l'adresse de l'interface outside :

```
ip route 203.0.113.0 255.255.255.0 203.0.113.2
```

> **Pourquoi cette route ?** Quand le serveur web répond à une adresse traduite (203.0.113.10, par exemple), R-ISP doit savoir que ces adresses se trouvent derrière R1. Sans cette route, les paquets de retour seraient perdus.

### Étape 1.5 — Configurer les PCs et le serveur web

- **PC1** : IP 192.168.1.10/24, passerelle 192.168.1.1
- **PC2** : IP 192.168.1.11/24, passerelle 192.168.1.1
- **PC3** : IP 192.168.1.12/24, passerelle 192.168.1.1
- **WEB-SRV** : IP 8.8.8.100/24, passerelle 8.8.8.1, activer le service HTTP

### Étape 1.6 — Vérifier la connectivité

Depuis **PC1**, pingez la passerelle :

```
ping 192.168.1.1
```

Depuis **R1**, pingez R-ISP :

```
ping 203.0.113.1
```

Depuis **R1**, pingez le serveur web :

```
ping 8.8.8.100
```

**Output attendu (ping R1 vers 8.8.8.100) :**

```
R1#ping 8.8.8.100
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 8.8.8.100, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

> **Attention :** Les PCs ne peuvent **pas encore** pinger le serveur web (8.8.8.100). C'est normal : R-ISP n'a pas de route vers 192.168.1.0/24 (réseau privé), et de toute façon, les adresses privées ne sont pas routables sur Internet. C'est précisément pour cela qu'on a besoin du NAT.

---

## Partie 2 : NAT statique

Le NAT statique crée un mappage permanent un-pour-un entre une adresse privée et une adresse publique. C'est utilisé quand un hôte interne doit être accessible depuis l'extérieur (serveur web interne, serveur mail, etc.).

Ici, on va mapper PC1 (192.168.1.10) vers l'adresse publique 203.0.113.10, pour que quelqu'un sur Internet puisse joindre PC1 via 203.0.113.10.

### Étape 2.1 — Définir les interfaces inside et outside

Sur **R1**, il faut indiquer au routeur quelles interfaces sont côté "intérieur" et "extérieur" :

```
configure terminal

interface GigabitEthernet0/0
 ip nat inside
exit

interface GigabitEthernet0/1
 ip nat outside
exit
```

> **Concept clé :** NAT a besoin de savoir dans quel sens effectuer la traduction. Un paquet qui entre par une interface `inside` et sort par une interface `outside` subit une traduction "inside-to-outside" (l'adresse source privée est remplacée par l'adresse publique). Un paquet qui fait le chemin inverse subit la traduction inverse.

### Étape 2.2 — Créer la règle de NAT statique

```
ip nat inside source static 192.168.1.10 203.0.113.10
```

Cette commande dit : "chaque fois qu'un paquet venant du réseau inside a pour source 192.168.1.10, remplace-la par 203.0.113.10 en sortie. Et inversement, tout paquet arrivant de l'outside à destination de 203.0.113.10, redirige-le vers 192.168.1.10".

### Étape 2.3 — Vérifier le NAT statique

Depuis **PC1**, pingez le serveur web :

```
ping 8.8.8.100
```

Ce ping devrait maintenant **réussir**, car R1 traduit l'adresse source de PC1 en 203.0.113.10 avant d'envoyer le paquet vers R-ISP.

Sur **R1**, vérifiez la table de traduction :

```
show ip nat translations
```

**Output attendu :**

```
R1#show ip nat translations
Pro  Inside global     Inside local       Outside local      Outside global
---  203.0.113.10      192.168.1.10       ---                ---
icmp 203.0.113.10:512  192.168.1.10:512   8.8.8.100:512      8.8.8.100:512
```

> **Terminologie exam CCNA — À retenir absolument :**
>
> | Terme | Signification | Exemple ici |
> |-------|--------------|-------------|
> | **Inside local** | Adresse IP de l'hôte interne vue depuis le réseau interne | 192.168.1.10 |
> | **Inside global** | Adresse IP de l'hôte interne vue depuis Internet | 203.0.113.10 |
> | **Outside local** | Adresse IP de l'hôte externe vue depuis le réseau interne | 8.8.8.100 |
> | **Outside global** | Adresse IP de l'hôte externe vue depuis Internet | 8.8.8.100 |
>
> Dans la majorité des cas, outside local = outside global (sauf si on fait aussi du NAT sur les adresses de destination, ce qui est rare).

### Étape 2.4 — Tester depuis Internet

Depuis **WEB-SRV** (ou depuis R-ISP), pingez l'adresse publique de PC1 :

```
ping 203.0.113.10
```

Le ping devrait réussir : R1 reçoit le paquet destiné à 203.0.113.10, le traduit vers 192.168.1.10, et le transmet à PC1.

> **C'est la magie du NAT statique :** le mappage fonctionne dans les deux sens. Un hôte externe peut initier une connexion vers l'adresse publique, et R1 sait qu'il faut la rediriger vers PC1.

---

## Partie 3 : NAT dynamique avec pool

Le NAT dynamique assigne automatiquement une adresse publique du pool à chaque hôte interne qui initie du trafic. Contrairement au NAT statique, le mappage n'est pas permanent : il est créé à la demande et expire après un timeout.

### Étape 3.1 — Supprimer le NAT statique précédent

Pour éviter les conflits, retirons la règle statique :

```
configure terminal
no ip nat inside source static 192.168.1.10 203.0.113.10
```

Puis nettoyons la table de traductions :

```
clear ip nat translation *
```

### Étape 3.2 — Créer le pool d'adresses publiques

```
ip nat pool POOL-PUBLIC 203.0.113.10 203.0.113.14 netmask 255.255.255.0
```

> **Pourquoi un pool ?** Un pool contient plusieurs adresses publiques. Le routeur pioche une adresse libre du pool chaque fois qu'un hôte interne initie une connexion. Ici, on a 5 adresses (203.0.113.10 à .14) pour potentiellement 5 hôtes simultanés.

### Étape 3.3 — Créer l'ACL pour identifier le trafic inside

L'ACL définit quels hôtes internes sont autorisés à être traduits :

```
access-list 1 permit 192.168.1.0 0.0.0.255
```

> **Rappel wildcard :** 0.0.0.255 est le wildcard mask pour /24. Il signifie "les 3 premiers octets doivent correspondre exactement, le dernier peut être n'importe quoi". C'est l'inverse du masque de sous-réseau.

### Étape 3.4 — Lier le pool à l'ACL

```
ip nat inside source list 1 pool POOL-PUBLIC
```

Cette commande signifie : "pour tout trafic correspondant à l'ACL 1, utilise une adresse du pool POOL-PUBLIC pour la traduction".

### Étape 3.5 — Vérifier le NAT dynamique

Depuis **PC1**, **PC2** et **PC3**, pingez le serveur web :

```
ping 8.8.8.100
```

Sur **R1**, affichez les traductions :

```
show ip nat translations
```

**Output attendu :**

```
R1#show ip nat translations
Pro  Inside global     Inside local       Outside local      Outside global
icmp 203.0.113.10:512  192.168.1.10:512   8.8.8.100:512      8.8.8.100:512
icmp 203.0.113.11:512  192.168.1.11:512   8.8.8.100:512      8.8.8.100:512
icmp 203.0.113.12:512  192.168.1.12:512   8.8.8.100:512      8.8.8.100:512
```

Chaque PC a reçu une adresse publique différente du pool.

Vérifiez les statistiques :

```
show ip nat statistics
```

**Output attendu :**

```
R1#show ip nat statistics
Total active translations: 3 (0 static, 3 dynamic; 3 extended)
Peak translations: 3, occurred 00:00:32 ago
Outside interfaces:
  GigabitEthernet0/1
Inside interfaces:
  GigabitEthernet0/0
Hits: 15  Misses: 3
CEF Translated packets: 15, CEF Punted packets: 0
Expired translations: 0
Dynamic mappings:
-- Inside Source
[Id: 1] access-list 1 pool POOL-PUBLIC refcount 3
 pool POOL-PUBLIC: netmask 255.255.255.0
        start 203.0.113.10 end 203.0.113.14
        type generic, total addresses 5, allocated 3 (60%), misses 0
```

> **Point exam :** si les 5 adresses du pool sont déjà assignées et qu'un 6e hôte tente de sortir, la traduction **échoue**. Le compteur "misses" s'incrémente et le paquet est abandonné. C'est la limitation majeure du NAT dynamique par rapport au PAT.

---

## Partie 4 : PAT (overload)

Le PAT, aussi appelé NAT overload, permet à **tous** les hôtes internes de partager une **seule** adresse publique. C'est la forme de NAT la plus utilisée dans le monde réel (votre box Internet fait du PAT).

Le routeur distingue les différentes connexions grâce aux **numéros de port** : chaque flux reçoit un port source unique sur l'adresse publique partagée.

### Étape 4.1 — Supprimer le NAT dynamique

```
configure terminal
no ip nat inside source list 1 pool POOL-PUBLIC
clear ip nat translation *
```

> On garde le pool et l'ACL en mémoire, mais on ne les lie plus. On pourrait aussi les supprimer pour faire propre, mais ce n'est pas obligatoire.

### Étape 4.2 — Configurer le PAT avec l'interface outside

```
ip nat inside source list 1 interface GigabitEthernet0/1 overload
```

> **Le mot-clé `overload`** est ce qui différencie le PAT du NAT dynamique classique. Il dit au routeur : "tu peux assigner la même adresse publique à plusieurs hôtes internes, en utilisant les ports pour les distinguer".
>
> On utilise ici l'adresse de l'interface Gi0/1 (203.0.113.2) plutôt qu'un pool. C'est le scénario le plus courant : on n'a qu'une seule adresse publique fournie par le FAI.

### Étape 4.3 — Vérifier le PAT

Depuis les **trois PCs**, pingez le serveur web et ouvrez le navigateur vers `http://8.8.8.100` :

```
ping 8.8.8.100
```

Sur **R1** :

```
show ip nat translations
```

**Output attendu :**

```
R1#show ip nat translations
Pro  Inside global      Inside local       Outside local      Outside global
icmp 203.0.113.2:1024   192.168.1.10:1     8.8.8.100:1        8.8.8.100:1
icmp 203.0.113.2:1025   192.168.1.11:1     8.8.8.100:1        8.8.8.100:1
icmp 203.0.113.2:1026   192.168.1.12:1     8.8.8.100:1        8.8.8.100:1
tcp  203.0.113.2:1027   192.168.1.10:1025  8.8.8.100:80       8.8.8.100:80
tcp  203.0.113.2:1028   192.168.1.11:1026  8.8.8.100:80       8.8.8.100:80
tcp  203.0.113.2:1029   192.168.1.12:1027  8.8.8.100:80       8.8.8.100:80
```

Observez : **tous les hôtes partagent la même adresse Inside global (203.0.113.2)**, mais chacun a un **port différent** (1024, 1025, 1026...). C'est ainsi que le routeur sait à quel PC renvoyer les réponses.

### Étape 4.4 — Analyser avec debug (optionnel)

Pour voir le NAT en action paquet par paquet :

```
debug ip nat
```

Puis lancez un ping depuis PC1 vers 8.8.8.100.

**Output attendu :**

```
R1#debug ip nat
IP NAT debugging is on
*Mar  1 00:15:22.003: NAT*: s=192.168.1.10->203.0.113.2, d=8.8.8.100 [1]
*Mar  1 00:15:22.007: NAT*: s=8.8.8.100, d=203.0.113.2->192.168.1.10 [1]
*Mar  1 00:15:23.003: NAT*: s=192.168.1.10->203.0.113.2, d=8.8.8.100 [2]
*Mar  1 00:15:23.007: NAT*: s=8.8.8.100, d=203.0.113.2->192.168.1.10 [2]
```

On voit clairement :
- **Paquet sortant :** source traduite de 192.168.1.10 vers 203.0.113.2
- **Paquet retour :** destination traduite de 203.0.113.2 vers 192.168.1.10

N'oubliez pas de désactiver le debug :

```
undebug all
```

---

## Partie 5 : Vérification et analyse

### Étape 5.1 — Commandes de vérification essentielles

Voici les trois commandes NAT que vous devez absolument maîtriser pour l'examen :

| Commande | Ce qu'elle montre |
|----------|-------------------|
| `show ip nat translations` | Toutes les traductions actives (statiques + dynamiques) |
| `show ip nat statistics` | Compteurs, interfaces inside/outside, hits/misses, pool |
| `debug ip nat` | Traduction en temps réel, paquet par paquet |

### Étape 5.2 — Récapitulatif des différences

| Type | Mappage | Adresses publiques nécessaires | Accès entrant possible ? |
|------|---------|-------------------------------|--------------------------|
| **NAT statique** | 1 privée = 1 publique (permanent) | 1 par hôte | Oui |
| **NAT dynamique** | 1 privée = 1 publique (temporaire, depuis le pool) | 1 par session simultanée | Non (mappage temporaire) |
| **PAT (overload)** | N privées = 1 publique (ports différents) | 1 seule | Non (sauf port forwarding) |

---

## Vérification finale

Cochez chaque critère pour valider la réussite du lab :

- [ ] Les trois PCs peuvent pinger le serveur web (8.8.8.100) via PAT
- [ ] `show ip nat translations` affiche les traductions avec des ports différents pour chaque PC
- [ ] `show ip nat statistics` montre l'interface inside (Gi0/0) et outside (Gi0/1)
- [ ] Vous savez expliquer la différence entre inside local, inside global, outside local et outside global
- [ ] Vous savez expliquer pourquoi le NAT dynamique peut échouer quand le pool est épuisé
- [ ] Vous savez identifier le type de NAT configuré en lisant une commande `ip nat inside source`

---

## Questions de réflexion

### Question 1 — Pourquoi le PAT est-il la forme de NAT la plus répandue ?

<details>
<summary>Voir la réponse</summary>

Le PAT permet à des centaines, voire des milliers d'hôtes internes de partager une seule adresse publique. Avec la pénurie d'adresses IPv4, c'est une nécessité économique. Chaque box Internet domestique utilise le PAT : tous vos appareils (téléphone, PC, tablette, TV) partagent l'unique adresse publique fournie par votre FAI. Le routeur utilise les numéros de ports (il y en a environ 65 000) pour distinguer les flux de chaque appareil.

</details>

### Question 2 — Que se passe-t-il si on configure du NAT dynamique avec un pool de 5 adresses et que 10 hôtes tentent de sortir simultanément ?

<details>
<summary>Voir la réponse</summary>

Les 5 premiers hôtes recevront une adresse du pool et pourront communiquer normalement. Les 5 suivants seront refusés : le routeur ne trouvera pas d'adresse disponible, incrémentera le compteur "misses" dans `show ip nat statistics`, et abandonnera leurs paquets. Ces hôtes n'auront pas de connectivité Internet tant qu'une adresse ne sera pas libérée (après expiration du timeout de traduction, par défaut 24 heures pour TCP et 1 minute pour UDP). C'est pourquoi le PAT (overload) est presque toujours préféré au NAT dynamique avec pool.

</details>

### Question 3 — Vous configurez le NAT statique mais le ping depuis Internet vers l'adresse publique échoue. Quelle est la cause la plus probable ?

<details>
<summary>Voir la réponse</summary>

La cause la plus probable est l'absence de route de retour sur le routeur ISP. Quand WEB-SRV envoie un paquet vers 203.0.113.10, R-ISP doit savoir que cette adresse est joignable via R1 (203.0.113.2). Sans la route `ip route 203.0.113.0 255.255.255.0 203.0.113.2` sur R-ISP, le paquet est perdu. Autres causes possibles :
- Les interfaces inside/outside ne sont pas correctement désignées (`ip nat inside` / `ip nat outside`)
- L'interface est en état `down`
- Un pare-feu ou une ACL bloque le trafic

</details>

### Question 4 — Quelle est la différence entre `ip nat inside source list 1 pool MON-POOL` et `ip nat inside source list 1 pool MON-POOL overload` ?

<details>
<summary>Voir la réponse</summary>

Sans le mot-clé `overload`, c'est du NAT dynamique classique : chaque hôte interne reçoit une adresse publique différente du pool (mappage 1:1 temporaire). Quand le pool est épuisé, les nouvelles connexions échouent.

Avec `overload`, c'est du PAT appliqué au pool : plusieurs hôtes internes peuvent partager la même adresse publique du pool grâce à la différenciation par numéros de port. Le pool ne sera jamais "épuisé" au sens strict, car chaque adresse du pool peut gérer environ 65 000 connexions simultanées.

</details>

### Question 5 — Dans la sortie de `show ip nat translations`, vous voyez "Inside global = 203.0.113.2:1024" et "Inside local = 192.168.1.10:3025". Expliquez ce que chaque champ représente.

<details>
<summary>Voir la réponse</summary>

- **Inside local (192.168.1.10:3025)** : c'est l'adresse IP et le port source vus depuis le réseau interne. C'est l'adresse réelle configurée sur le PC (192.168.1.10) avec le port source original choisi par l'application (3025).
- **Inside global (203.0.113.2:1024)** : c'est l'adresse IP et le port source vus depuis Internet après traduction NAT. L'adresse privée a été remplacée par l'adresse publique de l'interface outside (203.0.113.2), et le port a été modifié en 1024 par le routeur pour éviter les conflits avec d'autres traductions.

Le routeur maintient cette correspondance dans sa table NAT pour pouvoir traduire correctement les paquets de retour.

</details>

---

## Solution complète

<details>
<summary>Voir la solution complète de R1</summary>

```
enable
configure terminal

hostname R1
no ip domain-lookup

! --- Interfaces ---
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 ip nat inside
 no shutdown
 description LAN interne
exit

interface GigabitEthernet0/1
 ip address 203.0.113.2 255.255.255.252
 ip nat outside
 no shutdown
 description Lien vers ISP
exit

! --- Route par défaut ---
ip route 0.0.0.0 0.0.0.0 203.0.113.1

! --- ACL pour identifier le trafic inside ---
access-list 1 permit 192.168.1.0 0.0.0.255

! --- Option A : NAT statique (PC1 accessible depuis Internet) ---
! ip nat inside source static 192.168.1.10 203.0.113.10

! --- Option B : NAT dynamique avec pool ---
! ip nat pool POOL-PUBLIC 203.0.113.10 203.0.113.14 netmask 255.255.255.0
! ip nat inside source list 1 pool POOL-PUBLIC

! --- Option C : PAT (overload) — configuration finale ---
ip nat inside source list 1 interface GigabitEthernet0/1 overload

end
write memory
```

</details>

<details>
<summary>Voir la solution complète de R-ISP</summary>

```
enable
configure terminal

hostname R-ISP
no ip domain-lookup

interface GigabitEthernet0/0
 ip address 203.0.113.1 255.255.255.252
 no shutdown
 description Lien vers client (R1)
exit

interface GigabitEthernet0/1
 ip address 8.8.8.1 255.255.255.0
 no shutdown
 description Réseau serveurs
exit

! --- Route vers le bloc d'adresses NAT du client ---
ip route 203.0.113.0 255.255.255.0 203.0.113.2

end
write memory
```

</details>
