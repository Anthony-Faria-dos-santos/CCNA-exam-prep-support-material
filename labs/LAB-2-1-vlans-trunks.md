# Lab 2.1 — VLANs, Trunks 802.1Q et Routage Inter-VLAN (Router-on-a-Stick)

| Champ | Valeur |
|-------|--------|
| **Module** | 2 — Technologies de commutation et VLANs |
| **Topics couverts** | 2.1 (VLANs), 2.2 (Trunks 802.1Q), 2.3 (Routage inter-VLAN) |
| **Difficulté** | Intermédiaire |
| **Durée estimée** | 60 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                        Gi0/0 (trunk)
                    ┌──────── R1 ────────┐
                    │    Router-on-a-Stick│
                    │   Gi0/0.10  .20  .99│
                    └─────────┬──────────┘
                              │
                              │ Gi0/2 (trunk)
                              │
       ┌──────────────────── SW1 ────────────────────┐
       │  Fa0/1        Fa0/2        Gi0/1            │
       │   │            │            │ (trunk)       │
       │  PC1          PC2          │                │
       │ VLAN 10      VLAN 20      │                │
       └────────────────────────────┼────────────────┘
                                    │
       ┌──────────────────── SW2 ───┼────────────────┐
       │                   Gi0/1   │                 │
       │  Fa0/1        Fa0/2      (trunk)            │
       │   │            │                            │
       │  PC3          PC4                           │
       │ VLAN 10      VLAN 20                        │
       └─────────────────────────────────────────────┘
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | Passerelle | VLAN |
|----------|-----------|-----------|--------|------------|------|
| R1 | Gi0/0.10 | 192.168.10.1 | 255.255.255.0 | — | 10 |
| R1 | Gi0/0.20 | 192.168.20.1 | 255.255.255.0 | — | 20 |
| R1 | Gi0/0.99 | 192.168.99.1 | 255.255.255.0 | — | 99 |
| SW1 | VLAN 99 | 192.168.99.10 | 255.255.255.0 | 192.168.99.1 | 99 |
| SW2 | VLAN 99 | 192.168.99.11 | 255.255.255.0 | 192.168.99.1 | 99 |
| PC1 | NIC | 192.168.10.10 | 255.255.255.0 | 192.168.10.1 | 10 |
| PC2 | NIC | 192.168.20.10 | 255.255.255.0 | 192.168.20.1 | 20 |
| PC3 | NIC | 192.168.10.11 | 255.255.255.0 | 192.168.10.1 | 10 |
| PC4 | NIC | 192.168.20.11 | 255.255.255.0 | 192.168.20.1 | 20 |

---

## Objectifs

1. Creer les VLANs 10, 20 et 99 sur les deux switches et assigner les ports aux bons VLANs
2. Configurer un trunk 802.1Q entre SW1 et SW2 avec le VLAN natif 99
3. Configurer le routage inter-VLAN via des sous-interfaces sur R1 (router-on-a-stick)
4. Verifier la decouverte de voisins avec CDP/LLDP
5. Valider la connectivite inter-VLAN de bout en bout

---

## Prerequis

- Notions de base sur les VLANs et leur utilite (segmentation logique du reseau)
- Comprendre la difference entre un port access et un port trunk
- Savoir ce qu'est une sous-interface sur un routeur
- Etre a l'aise avec la navigation CLI Cisco (modes user, privileged, config)

---

## Configuration de depart

Avant de commencer, appliquez cette configuration de base sur chaque equipement. Cela vous evite de perdre du temps sur des parametres qui ne sont pas l'objet du lab.

### R1 — Configuration initiale

```
enable
configure terminal
hostname R1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 4
 password cisco
 login
banner motd # Acces non autorise interdit #
end
```

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

## Partie 1 — Creation des VLANs et attribution des ports access

L'objectif ici est de segmenter le reseau en trois VLANs. Chaque VLAN isole un groupe d'utilisateurs : la comptabilite, le developpement, et le management des equipements.

### Etape 1.1 — Creer les VLANs sur SW1

Sur SW1, passez en mode de configuration globale et creez les trois VLANs :

```
enable
configure terminal
vlan 10
 name Comptabilite
vlan 20
 name Developpement
vlan 99
 name Management
exit
```

> **Explication** : La commande `vlan <id>` cree le VLAN s'il n'existe pas, puis entre dans le sous-mode de configuration du VLAN ou on peut lui attribuer un nom significatif. Les noms sont facultatifs mais rendent la lecture de `show vlan brief` bien plus agreable.

### Etape 1.2 — Creer les memes VLANs sur SW2

Repetez exactement les memes commandes sur SW2 :

```
enable
configure terminal
vlan 10
 name Comptabilite
vlan 20
 name Developpement
vlan 99
 name Management
exit
```

> **Important** : Les VLANs sont locaux a chaque switch. Meme si SW1 et SW2 seront relies par un trunk, il faut creer les VLANs sur les deux equipements. Sans cela, les trames taguees dans un VLAN inconnu seront jetees.

### Etape 1.3 — Assigner les ports access sur SW1

```
configure terminal
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 10
 no shutdown
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 20
 no shutdown
end
```

> **Explication** : `switchport mode access` force le port en mode acces (il ne negocie pas de trunk). `switchport access vlan 10` associe le port au VLAN 10. Toute trame entrant par ce port sera consideree comme appartenant au VLAN 10.

### Etape 1.4 — Assigner les ports access sur SW2

```
configure terminal
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 10
 no shutdown
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 20
 no shutdown
end
```

### Etape 1.5 — Verification des VLANs

Sur chaque switch, verifiez que les VLANs sont bien crees et les ports correctement assignes :

```
show vlan brief
```

**Output attendu sur SW1 :**

```
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/3, Fa0/4, Fa0/5, Fa0/6
                                                Fa0/7, Fa0/8, Fa0/9, Fa0/10
                                                Fa0/11, Fa0/12, Fa0/13, Fa0/14
                                                Fa0/15, Fa0/16, Fa0/17, Fa0/18
                                                Fa0/19, Fa0/20, Fa0/21, Fa0/22
                                                Fa0/23, Fa0/24, Gi0/1, Gi0/2
10   Comptabilite                     active    Fa0/1
20   Developpement                    active    Fa0/2
99   Management                       active
1002 fddi-default                     active
1003 token-ring-default               active
1004 fddinet-default                  active
1005 trnet-default                    active
```

> Vous devez voir PC1 (Fa0/1) dans le VLAN 10 et PC2 (Fa0/2) dans le VLAN 20. Si un port apparait encore dans le VLAN 1, c'est que la commande `switchport access vlan` n'a pas ete appliquee correctement.

---

## Partie 2 — Configuration du trunk 802.1Q entre les switches

Un trunk est un lien qui transporte les trames de plusieurs VLANs. Sans trunk entre SW1 et SW2, les machines du VLAN 10 sur SW1 ne pourraient jamais communiquer avec celles du VLAN 10 sur SW2.

### Etape 2.1 — Configurer le trunk sur SW1 (Gi0/1)

```
configure terminal
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,99
 no shutdown
end
```

> **Explication** :
> - `switchport mode trunk` : force le port en mode trunk (pas de negociation DTP).
> - `switchport trunk native vlan 99` : le VLAN natif est celui dont les trames circulent sans tag 802.1Q sur le trunk. On utilise le VLAN 99 (management) plutot que le VLAN 1 par defaut, ce qui est une bonne pratique de securite.
> - `switchport trunk allowed vlan 10,20,99` : on restreint le trunk aux seuls VLANs necessaires. Par defaut, tous les VLANs (1-4094) sont autorises, ce qui n'est pas souhaitable.

### Etape 2.2 — Configurer le trunk sur SW2 (Gi0/1)

```
configure terminal
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,99
 no shutdown
end
```

> **Attention** : Le VLAN natif doit etre identique des deux cotes du trunk. Si SW1 a le VLAN natif 99 et SW2 le VLAN natif 1, vous obtiendrez un message d'erreur CDP "Native VLAN mismatch" et les trames non-taguees seront mal acheminees.

### Etape 2.3 — Configurer le trunk vers R1 sur SW1 (Gi0/2)

Le routeur R1 sera connecte a SW1 via Gi0/2. Ce lien doit aussi etre un trunk pour que R1 puisse router entre les VLANs.

```
configure terminal
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,99
 no shutdown
end
```

### Etape 2.4 — Configurer les SVI de management

Pour pouvoir administrer les switches a distance (SSH/Telnet), on leur attribue une adresse IP sur le VLAN de management (VLAN 99).

**Sur SW1 :**

```
configure terminal
interface vlan 99
 ip address 192.168.99.10 255.255.255.0
 no shutdown
ip default-gateway 192.168.99.1
end
```

**Sur SW2 :**

```
configure terminal
interface vlan 99
 ip address 192.168.99.11 255.255.255.0
 no shutdown
ip default-gateway 192.168.99.1
end
```

> **Explication** : Une SVI (Switch Virtual Interface) est une interface logique associee a un VLAN. Elle permet au switch d'avoir une presence IP dans ce VLAN. La passerelle par defaut pointe vers R1 pour que le switch puisse communiquer avec des reseaux distants.

### Etape 2.5 — Verification des trunks

```
show interfaces trunk
```

**Output attendu sur SW1 :**

```
Port        Mode         Encapsulation  Status        Native vlan
Gi0/1       on           802.1q         trunking      99
Gi0/2       on           802.1q         trunking      99

Port        Vlans allowed on trunk
Gi0/1       10,20,99
Gi0/2       10,20,99

Port        Vlans allowed and active in management domain
Gi0/1       10,20,99
Gi0/2       10,20,99

Port        Vlans in spanning tree forwarding state and not pruned
Gi0/1       10,20,99
Gi0/2       10,20,99
```

> Verifiez bien que le VLAN natif est 99 (pas 1) et que seuls les VLANs 10, 20 et 99 sont autorises. Si vous voyez "1-4094" dans la colonne "Vlans allowed on trunk", c'est que la commande `switchport trunk allowed vlan` n'a pas ete appliquee.

---

## Partie 3 — Configuration du routage inter-VLAN (Router-on-a-Stick)

Sans routeur, les machines de VLANs differents ne peuvent pas communiquer entre elles. C'est tout l'interet des VLANs : l'isolation. Mais dans la pratique, on veut souvent que certains VLANs puissent se joindre. Le router-on-a-stick permet cela avec une seule interface physique, divisee en sous-interfaces.

### Etape 3.1 — Activer l'interface physique

```
enable
configure terminal
interface GigabitEthernet0/0
 no shutdown
```

> **Important** : On n'assigne pas d'adresse IP a l'interface physique Gi0/0 elle-meme. Elle sert uniquement de "porteuse" pour les sous-interfaces. Mais il faut absolument la mettre en `no shutdown`, sinon toutes les sous-interfaces resteront down.

### Etape 3.2 — Configurer la sous-interface pour le VLAN 10

```
interface GigabitEthernet0/0.10
 description Passerelle VLAN 10 - Comptabilite
 encapsulation dot1Q 10
 ip address 192.168.10.1 255.255.255.0
```

> **Explication** :
> - `GigabitEthernet0/0.10` : le ".10" est un numero de sous-interface. Par convention, on utilise le meme numero que le VLAN, mais ce n'est pas obligatoire.
> - `encapsulation dot1Q 10` : indique au routeur que cette sous-interface traite les trames taguees VLAN 10 (802.1Q).
> - L'adresse IP de cette sous-interface sera la passerelle par defaut des PCs du VLAN 10.

### Etape 3.3 — Configurer la sous-interface pour le VLAN 20

```
interface GigabitEthernet0/0.20
 description Passerelle VLAN 20 - Developpement
 encapsulation dot1Q 20
 ip address 192.168.20.1 255.255.255.0
```

### Etape 3.4 — Configurer la sous-interface pour le VLAN 99

```
interface GigabitEthernet0/0.99
 description Passerelle VLAN 99 - Management
 encapsulation dot1Q 99 native
 ip address 192.168.99.1 255.255.255.0
end
```

> **Detail important** : Le mot-cle `native` apres `encapsulation dot1Q 99` indique que cette sous-interface correspond au VLAN natif du trunk. Les trames de ce VLAN circuleront sans tag sur le lien. Cela doit correspondre a la configuration `switchport trunk native vlan 99` du switch.

### Etape 3.5 — Configurer les PCs

Configurez l'adresse IP, le masque et la passerelle sur chaque PC via l'onglet Desktop > IP Configuration dans Packet Tracer.

| PC | Adresse IP | Masque | Passerelle |
|----|-----------|--------|------------|
| PC1 | 192.168.10.10 | 255.255.255.0 | 192.168.10.1 |
| PC2 | 192.168.20.10 | 255.255.255.0 | 192.168.20.1 |
| PC3 | 192.168.10.11 | 255.255.255.0 | 192.168.10.1 |
| PC4 | 192.168.20.11 | 255.255.255.0 | 192.168.20.1 |

### Etape 3.6 — Verification des sous-interfaces

Sur R1 :

```
show ip interface brief
```

**Output attendu :**

```
Interface                  IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0         unassigned      YES unset  up                    up
GigabitEthernet0/0.10      192.168.10.1    YES manual up                    up
GigabitEthernet0/0.20      192.168.20.1    YES manual up                    up
GigabitEthernet0/0.99      192.168.99.1    YES manual up                    up
```

> Les trois sous-interfaces doivent etre "up/up". Si elles sont "up/down" ou "administratively down", verifiez que l'interface physique Gi0/0 est bien en `no shutdown` et que le cable est connecte.

---

## Partie 4 — Verification CDP/LLDP

CDP (Cisco Discovery Protocol) et LLDP (Link Layer Discovery Protocol) permettent de decouvrir les equipements voisins directement connectes. C'est un outil precieux pour verifier la topologie.

### Etape 4.1 — Verifier les voisins CDP sur SW1

```
show cdp neighbors
```

**Output attendu :**

```
Capability Codes: R - Router, T - Trans Bridge, B - Source Route Bridge
                  S - Switch, H - Host, I - IGMP, r - Repeater, P - Phone

Device ID        Local Intrfce     Holdtme    Capability  Platform  Port ID
R1               Gig 0/2          167             R       ISR4300   Gig 0/0
SW2              Gig 0/1          167             S       2960      Gig 0/1
```

> Vous devez voir R1 sur Gi0/2 et SW2 sur Gi0/1. Si un voisin n'apparait pas, verifiez que le lien est up et que CDP est active (`show cdp`).

### Etape 4.2 — Voir les details d'un voisin

```
show cdp neighbors detail
```

Cette commande affiche l'adresse IP de management du voisin, la version d'IOS, la plateforme, etc. Tres utile en depannage.

### Etape 4.3 — Activer et verifier LLDP

LLDP est le standard IEEE 802.1AB, equivalent ouvert de CDP. Il est desactive par defaut sur les equipements Cisco.

```
configure terminal
lldp run
end
show lldp neighbors
```

> **Bonne pratique** : Dans un environnement multi-constructeurs, preferez LLDP a CDP car il est supporte par tous les fabricants.

---

## Partie 5 — Verification complete

C'est le moment de verite. On va tester la connectivite intra-VLAN, inter-VLAN et le management.

### Etape 5.1 — Test intra-VLAN (meme VLAN, switches differents)

Depuis PC1 (VLAN 10, SW1), pinguez PC3 (VLAN 10, SW2) :

```
ping 192.168.10.11
```

**Output attendu :**

```
Pinging 192.168.10.11 with 32 bytes of data:

Reply from 192.168.10.11: bytes=32 time<1ms TTL=128
Reply from 192.168.10.11: bytes=32 time<1ms TTL=128
Reply from 192.168.10.11: bytes=32 time<1ms TTL=128
Reply from 192.168.10.11: bytes=32 time<1ms TTL=128

Ping statistics for 192.168.10.11:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

> Ce ping passe car les deux PCs sont dans le meme VLAN (10). La trame traverse le trunk entre SW1 et SW2 avec le tag VLAN 10. Pas besoin du routeur.

### Etape 5.2 — Test inter-VLAN (VLANs differents)

Depuis PC1 (VLAN 10), pinguez PC2 (VLAN 20) :

```
ping 192.168.20.10
```

**Output attendu :**

```
Pinging 192.168.20.10 with 32 bytes of data:

Reply from 192.168.20.10: bytes=32 time<1ms TTL=127
Reply from 192.168.20.10: bytes=32 time<1ms TTL=127
Reply from 192.168.20.10: bytes=32 time<1ms TTL=127
Reply from 192.168.20.10: bytes=32 time<1ms TTL=127

Ping statistics for 192.168.20.10:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

> **Notez le TTL=127** (au lieu de 128 pour l'intra-VLAN). Cela prouve que le paquet a traverse le routeur (un hop de moins). Le chemin est : PC1 -> SW1 -> R1 (Gi0/0.10 -> table de routage -> Gi0/0.20) -> SW1 -> PC2.

### Etape 5.3 — Test inter-VLAN entre switches differents

Depuis PC1 (VLAN 10, SW1), pinguez PC4 (VLAN 20, SW2) :

```
ping 192.168.20.11
```

Ce ping doit aussi reussir. Le chemin est : PC1 -> SW1 -> R1 -> SW1 -> SW2 (trunk) -> PC4.

### Etape 5.4 — Test management

Depuis R1, pinguez les SVI des switches :

```
ping 192.168.99.10
ping 192.168.99.11
```

Les deux pings doivent reussir, confirmant que le VLAN de management est operationnel.

### Etape 5.5 — Recapitulatif show commands

Sur SW1, executez :

```
show vlan brief
show interfaces trunk
show interfaces status
```

Sur R1, executez :

```
show ip interface brief
show ip route
```

**Output attendu de `show ip route` sur R1 :**

```
Gateway of last resort is not set

     192.168.10.0/24 is variably subnetted, 2 subnets, 2 masks
C       192.168.10.0/24 is directly connected, GigabitEthernet0/0.10
L       192.168.10.1/32 is directly connected, GigabitEthernet0/0.10
     192.168.20.0/24 is variably subnetted, 2 subnets, 2 masks
C       192.168.20.0/24 is directly connected, GigabitEthernet0/0.20
L       192.168.20.1/32 is directly connected, GigabitEthernet0/0.20
     192.168.99.0/24 is variably subnetted, 2 subnets, 2 masks
C       192.168.99.0/24 is directly connected, GigabitEthernet0/0.99
L       192.168.99.1/32 is directly connected, GigabitEthernet0/0.99
```

> Les trois reseaux apparaissent comme "directly connected" via les sous-interfaces. C'est grace a ces routes que R1 sait comment acheminer le trafic entre VLANs.

---

## Verification finale

Cochez chaque critere pour confirmer que votre lab fonctionne correctement :

- [ ] Les VLANs 10, 20 et 99 apparaissent dans `show vlan brief` sur SW1 et SW2
- [ ] Fa0/1 est dans le VLAN 10 et Fa0/2 dans le VLAN 20 sur les deux switches
- [ ] Les trunks Gi0/1 (SW1-SW2) et Gi0/2 (SW1-R1) sont actifs avec le VLAN natif 99
- [ ] Seuls les VLANs 10, 20 et 99 sont autorises sur les trunks
- [ ] Les trois sous-interfaces de R1 sont up/up avec les bonnes adresses IP
- [ ] Ping intra-VLAN reussi : PC1 -> PC3 (VLAN 10)
- [ ] Ping intra-VLAN reussi : PC2 -> PC4 (VLAN 20)
- [ ] Ping inter-VLAN reussi : PC1 -> PC2 (VLAN 10 -> VLAN 20)
- [ ] Ping inter-VLAN reussi : PC1 -> PC4 (VLAN 10 sur SW1 -> VLAN 20 sur SW2)
- [ ] Ping management reussi : R1 -> SW1 SVI et R1 -> SW2 SVI
- [ ] CDP/LLDP montre les voisins attendus

---

## Questions de reflexion

### Question 1 — Pourquoi faut-il configurer le meme VLAN natif des deux cotes d'un trunk ?

<details>
<summary>Voir la reponse</summary>

Le VLAN natif determine quelles trames circulent **sans tag 802.1Q** sur le trunk. Si SW1 considere que le VLAN natif est 99 et SW2 considere que c'est le VLAN 1, une trame non-taguee envoyee par SW1 (destinee au VLAN 99) sera interpretee par SW2 comme appartenant au VLAN 1. Cela provoque un "VLAN hopping" involontaire, un dysfonctionnement du reseau, et un risque de securite. CDP detecte cette incoherence et affiche un message "Native VLAN mismatch".

</details>

### Question 2 — Que se passe-t-il si on desactive l'interface physique Gi0/0 de R1 ?

<details>
<summary>Voir la reponse</summary>

Toutes les sous-interfaces (Gi0/0.10, Gi0/0.20, Gi0/0.99) passent en etat "down/down" car elles dependent de l'interface physique parente. Concretement :
- Le routage inter-VLAN cesse completement (plus aucun ping entre VLANs differents)
- La communication intra-VLAN continue de fonctionner (PC1 peut toujours pinguer PC3 car le trafic reste dans le switch sans passer par le routeur)
- Les switches perdent l'acces a leur passerelle par defaut (192.168.99.1)

</details>

### Question 3 — Un utilisateur du VLAN 10 sur SW2 ne peut pas pinguer sa passerelle (192.168.10.1). Comment depanner ?

<details>
<summary>Voir la reponse</summary>

Demarche systematique de depannage :

1. **Verifier le cablage** : le lien physique entre SW1 et SW2 est-il up ? (`show interfaces Gi0/1 status`)
2. **Verifier le trunk SW1-SW2** : `show interfaces trunk` — le VLAN 10 est-il autorise sur le trunk ? Est-il actif ?
3. **Verifier le trunk SW1-R1** : meme verification sur Gi0/2 de SW1
4. **Verifier les VLANs** : le VLAN 10 existe-t-il bien sur SW2 ? (`show vlan brief`) — si le VLAN n'existe pas localement sur SW2, les trames taguees VLAN 10 recues sur le trunk sont ignorees
5. **Verifier la sous-interface R1** : `show ip interface brief` — Gi0/0.10 est-elle up/up ? L'encapsulation est-elle correcte ? (`show interfaces Gi0/0.10`)
6. **Verifier le port access** : le port du PC sur SW2 est-il bien en `switchport mode access` et `switchport access vlan 10` ?
7. **Verifier le PC** : l'adresse IP, le masque et la passerelle sont-ils corrects ?

L'erreur la plus frequente : avoir oublie de creer le VLAN 10 sur SW2, ou ne pas l'avoir autorise dans le trunk.

</details>

### Question 4 — Pourquoi utiliser un VLAN de management (99) separe au lieu de laisser les SVI dans le VLAN 1 ?

<details>
<summary>Voir la reponse</summary>

Le VLAN 1 est le VLAN par defaut sur tous les equipements Cisco. Il est utilise par plusieurs protocoles de controle (DTP, VTP, CDP, STP BPDU). Laisser le traffic de management dans le VLAN 1 pose plusieurs problemes :

1. **Securite** : tout port non-configure est dans le VLAN 1. Un attaquant branchant un cable sur un port inutilise aurait potentiellement acces au plan de management.
2. **Bruit** : le VLAN 1 transporte du broadcast lie aux protocoles de controle, ce qui pollue le trafic de management.
3. **Bonne pratique** : le CCNA (et la documentation Cisco) recommande explicitement de deplacer le management dans un VLAN dedie. C'est un point souvent evalue a l'examen.

</details>

### Question 5 — Quel est l'inconvenient majeur du router-on-a-stick par rapport a un switch L3 ?

<details>
<summary>Voir la reponse</summary>

Le principal inconvenient est le **goulot d'etranglement**. Tout le trafic inter-VLAN doit passer par un seul lien physique (le trunk entre le switch et le routeur). Ce lien est partage par tous les VLANs dans les deux directions.

Dans un petit reseau (quelques dizaines d'utilisateurs), ce n'est pas un probleme. Mais dans un reseau d'entreprise avec des centaines d'utilisateurs et du trafic important, cette unique interface GigabitEthernet devient un point de congestion.

Un switch de couche 3 (L3) effectue le routage inter-VLAN en materiel (ASICs), a la vitesse du wire-speed, sans passer par un lien externe. C'est beaucoup plus performant et scalable. Le router-on-a-stick reste neanmoins une solution simple et peu couteuse pour les petits reseaux, et c'est un concept fondamental du CCNA.

</details>

---

## Solution complete

<details>
<summary>Voir la solution complete</summary>

### R1 — Configuration complete

```
enable
configure terminal
hostname R1
no ip domain-lookup
enable secret class
line console 0
 password cisco
 login
line vty 0 4
 password cisco
 login
banner motd # Acces non autorise interdit #
!
interface GigabitEthernet0/0
 no shutdown
!
interface GigabitEthernet0/0.10
 description Passerelle VLAN 10 - Comptabilite
 encapsulation dot1Q 10
 ip address 192.168.10.1 255.255.255.0
!
interface GigabitEthernet0/0.20
 description Passerelle VLAN 20 - Developpement
 encapsulation dot1Q 20
 ip address 192.168.20.1 255.255.255.0
!
interface GigabitEthernet0/0.99
 description Passerelle VLAN 99 - Management
 encapsulation dot1Q 99 native
 ip address 192.168.99.1 255.255.255.0
!
end
copy running-config startup-config
```

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
 name Comptabilite
vlan 20
 name Developpement
vlan 99
 name Management
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
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,99
 no shutdown
!
interface GigabitEthernet0/2
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,99
 no shutdown
!
interface vlan 99
 ip address 192.168.99.10 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.99.1
!
lldp run
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
 name Comptabilite
vlan 20
 name Developpement
vlan 99
 name Management
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
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,99
 no shutdown
!
interface vlan 99
 ip address 192.168.99.11 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.99.1
!
lldp run
!
end
copy running-config startup-config
```

### PCs — Adressage

| PC | Adresse IP | Masque | Passerelle |
|----|-----------|--------|------------|
| PC1 | 192.168.10.10 | 255.255.255.0 | 192.168.10.1 |
| PC2 | 192.168.20.10 | 255.255.255.0 | 192.168.20.1 |
| PC3 | 192.168.10.11 | 255.255.255.0 | 192.168.10.1 |
| PC4 | 192.168.20.11 | 255.255.255.0 | 192.168.20.1 |

</details>
