# Quiz Transversal #2 — Semaine 8 : Modules 1 a 5 (CCNA 200-301)

| Info | Detail |
|------|--------|
| **Topics couverts** | 1.1 - 5.11 |
| **Nombre de questions** | 25 |
| **Duree suggeree** | 45 minutes |
| **Score vise** | >= 70 % (18/25) |
| **Focus** | Interconnexions entre domaines |

---

**Q1.** Un administrateur configure NAT dynamique sur un routeur de perimetre. Il cree un pool NAT et une ACL standard pour identifier le trafic a traduire. Voici la configuration :

```
ip nat pool INTERNET 203.0.113.10 203.0.113.14 netmask 255.255.255.240
access-list 1 permit 192.168.10.0 0.0.0.255
ip nat inside source list 1 pool INTERNET
```

Quel est le role precis de l'ACL standard dans cette configuration NAT ? _(Topics 4.1 + 5.6)_

- A) Elle filtre le trafic entrant sur l'interface outside et bloque les paquets non autorises
- B) Elle identifie les adresses source internes eligibles a la traduction NAT
- C) Elle definit les adresses du pool NAT disponibles pour la traduction
- D) Elle protege le routeur contre les attaques par usurpation d'adresse (spoofing)

<details>
<summary>Reponse</summary>

**B** — Dans une configuration NAT, l'ACL standard ne filtre pas le trafic au sens securite du terme. Elle sert uniquement a identifier (matcher) les adresses source internes qui seront soumises a la traduction. Le mot-cle `list 1` dans la commande `ip nat inside source list 1 pool INTERNET` fait reference a l'ACL 1.

- A) ❌ L'ACL standard dans un contexte NAT ne filtre pas le trafic entrant. Ce serait le cas d'une ACL appliquee directement sur une interface avec `ip access-group`.
- B) ✅ L'ACL identifie le trafic source eligible a la traduction : ici, tout le sous-reseau 192.168.10.0/24.
- C) ❌ Le pool NAT est defini par la commande `ip nat pool`, pas par l'ACL.
- D) ❌ L'ACL dans ce contexte n'a aucune fonction de securite. Elle sert de selecteur de trafic pour NAT.

</details>

---

**Q2.** Un technicien configure OSPF single-area sur un routeur connecte au sous-reseau 172.16.48.0/20. Quelle commande `network` avec le wildcard mask correct doit-il utiliser dans le processus OSPF ? _(Topics 3.4 + 1.6)_

- A) `network 172.16.48.0 0.0.0.255 area 0`
- B) `network 172.16.48.0 0.0.15.255 area 0`
- C) `network 172.16.48.0 0.0.31.255 area 0`
- D) `network 172.16.0.0 0.0.255.255 area 0`

<details>
<summary>Reponse</summary>

**B** — Un masque /20 correspond a 255.255.240.0. Le wildcard mask est l'inverse : 0.0.15.255. La commande `network` dans OSPF utilise le wildcard mask pour identifier les interfaces dont l'adresse IP tombe dans la plage specifiee. Le wildcard 0.0.15.255 couvre les adresses de 172.16.48.0 a 172.16.63.255, ce qui correspond exactement au sous-reseau /20.

- A) ❌ Le wildcard 0.0.0.255 correspond a un /24. Cela n'inclurait que 172.16.48.0 - 172.16.48.255, trop restrictif pour un /20.
- B) ✅ 0.0.15.255 est le wildcard correct pour un /20 (255.255.240.0 inverse = 0.0.15.255).
- C) ❌ 0.0.31.255 correspond a un /19, ce qui couvrirait un reseau plus large que necessaire.
- D) ❌ 0.0.255.255 correspond a un /16. Cela fonctionnerait techniquement (le reseau 172.16.48.0 est inclus) mais c'est trop large et pourrait activer OSPF sur des interfaces non desirees.

</details>

---

**Q3.** Un administrateur reseau constate que des postes clients recoivent des adresses IP d'un serveur DHCP non autorise (rogue DHCP). Quelle fonctionnalite de securite L2 doit-il activer pour resoudre ce probleme, et sur quels ports ? _(Topics 4.6 + 5.7)_

- A) Port Security sur tous les ports, en limitant a 1 adresse MAC par port
- B) DHCP Snooping sur le switch, en configurant les ports du serveur DHCP legitime comme trusted
- C) Dynamic ARP Inspection sur tous les ports access
- D) Storm Control sur les ports trunk pour limiter le trafic broadcast DHCP

<details>
<summary>Reponse</summary>

**B** — DHCP Snooping est la fonctionnalite specifiquement concue pour contrer les serveurs DHCP non autorises. Une fois active, le switch bloque les reponses DHCP (OFFER, ACK) sur tous les ports sauf ceux explicitement configures comme `trusted`. Le serveur DHCP legitime est connecte a un port trusted ; les ports clients restent untrusted.

- A) ❌ Port Security limite le nombre d'adresses MAC par port. Il ne distingue pas le trafic DHCP et ne peut pas bloquer un rogue DHCP server.
- B) ✅ DHCP Snooping filtre les messages DHCP server (OFFER/ACK) sur les ports untrusted. Seuls les ports trusted peuvent emettre ces messages.
- C) ❌ DAI (Dynamic ARP Inspection) protege contre l'ARP spoofing, pas contre les rogue DHCP. Neanmoins, DAI s'appuie sur la table de DHCP Snooping pour valider les associations IP-MAC.
- D) ❌ Storm Control limite le debit broadcast/multicast/unicast inconnu mais ne filtre pas specifiquement le trafic DHCP.

</details>

---

**Q4.** Observez l'output suivant sur un switch Cisco :

```
SW1# show vlan brief

VLAN Name                             Status    Ports
---- -------------------------------- --------- ---------------------------
1    default                          active    Gi0/5, Gi0/6
10   VENTES                           active    Gi0/1, Gi0/2
20   COMPTA                           active    Gi0/3, Gi0/4
99   GESTION                          active
1002 fddi-default                     act/unsup
```

```
SW1# show interfaces trunk

Port        Mode         Encapsulation  Status        Native vlan
Gi0/7       on           802.1q         trunking      1

Port        Vlans allowed on trunk
Gi0/7       1-4094

Port        Vlans allowed and active in management domain
Gi0/7       1,10,20,99
```

Un PC sur le VLAN 10 ne parvient pas a joindre un serveur sur le VLAN 20 via un routeur-on-a-stick connecte sur Gi0/7. Le routeur a des sous-interfaces configurees pour les VLANs 10 et 20. Quelle est la cause la plus probable ? _(Topics 2.1 + 2.2 + 3.1)_

- A) Le trunk n'autorise pas les VLANs 10 et 20
- B) Le native VLAN sur le trunk est le VLAN 1, ce qui cree un mismatch avec le routeur
- C) Il manque une route statique sur le routeur entre les sous-reseaux des VLANs 10 et 20
- D) Les sous-interfaces du routeur sont des reseaux directement connectes, le routage inter-VLAN devrait fonctionner si les sous-interfaces sont up/up

<details>
<summary>Reponse</summary>

**D** — L'output montre que les VLANs 10 et 20 sont bien actifs et autorises sur le trunk Gi0/7. Dans une architecture router-on-a-stick, les sous-interfaces du routeur (ex : Gi0/0.10 et Gi0/0.20) sont des reseaux directement connectes dans la table de routage. Aucune route statique supplementaire n'est necessaire. Si le PC ne peut pas joindre le serveur, il faut verifier l'etat des sous-interfaces sur le routeur (show ip interface brief), les adresses IP et les encapsulations dot1q.

- A) ❌ L'output montre clairement que les VLANs 1, 10, 20 et 99 sont "allowed and active" sur le trunk.
- B) ❌ Un mismatch de native VLAN peut causer des problemes, mais cela affecterait uniquement le trafic non tague (VLAN 1 par defaut). Les VLANs 10 et 20 sont tagges et ne sont pas impactes par le native VLAN.
- C) ❌ Avec router-on-a-stick, les sous-interfaces creent des routes directement connectees. Aucune route statique n'est requise pour le routage inter-VLAN.
- D) ✅ La configuration du switch semble correcte. Le probleme est probablement cote routeur : sous-interface down, mauvaise encapsulation dot1q, ou adresse IP incorrecte.

</details>

---

**Q5.** Un administrateur souhaite securiser l'acces SSH a un switch tout en centralisant l'authentification. Voici un extrait de configuration :

```
aaa new-model
aaa authentication login default group tacacs+ local
tacacs server SERV-TAC
 address ipv4 10.0.0.50
 key Secr3tK3y!
line vty 0 15
 transport input ssh
 login authentication default
```

Si le serveur TACACS+ a l'adresse 10.0.0.50 est injoignable, que se passe-t-il lors d'une tentative de connexion SSH ? _(Topics 4.8 + 5.8)_

- A) La connexion est refusee immediatement car le serveur AAA est indisponible
- B) Le switch utilise la base locale (username/password configures localement) comme methode de secours
- C) Le switch tente une authentification RADIUS en fallback automatique
- D) Le switch autorise l'acces sans authentification apres un timeout

<details>
<summary>Reponse</summary>

**B** — La commande `aaa authentication login default group tacacs+ local` definit deux methodes d'authentification dans l'ordre : d'abord TACACS+, puis la base locale. Le mot-cle `local` en deuxieme position signifie que si le serveur TACACS+ est injoignable (timeout, pas de reponse), le switch bascule sur l'authentification locale. Attention : si TACACS+ repond avec un "reject" (mauvais mot de passe), le fallback local n'est PAS utilise.

- A) ❌ La connexion n'est pas refusee immediatement grace au fallback `local` configure.
- B) ✅ Le mot-cle `local` apres `group tacacs+` assure le fallback sur la base locale en cas d'indisponibilite du serveur TACACS+.
- C) ❌ RADIUS n'est pas configure dans cette liste de methodes. Il faudrait explicitement ajouter `group radius`.
- D) ❌ Le switch ne permet jamais un acces sans authentification sauf si le mot-cle `none` est configure (ce qui serait une tres mauvaise pratique).

</details>

---

**Q6.** Un ingenieur analyse les logs Syslog d'un routeur et remarque que les horodatages ne correspondent pas aux evenements reels. Les logs affichent un decalage de plusieurs heures. Quelle combinaison de configurations resout ce probleme ? _(Topics 4.5 + 4.2)_

- A) Configurer `logging buffered 8192` et `logging trap debugging`
- B) Configurer `ntp server 10.1.1.1` et `service timestamps log datetime msec`
- C) Configurer `logging host 10.2.2.2` et `logging source-interface Loopback0`
- D) Configurer `clock timezone CET 1` sans NTP, en utilisant l'horloge materielle du routeur

<details>
<summary>Reponse</summary>

**B** — L'horodatage precis des logs Syslog necessite deux elements : une source de temps fiable (NTP) et l'activation des timestamps dans les messages de log. La commande `ntp server` synchronise l'horloge du routeur avec un serveur NTP, et `service timestamps log datetime msec` insere la date et l'heure (avec precision a la milliseconde) dans chaque message Syslog.

- A) ❌ `logging buffered` definit la taille du buffer local et `logging trap` le niveau de severite envoye au serveur Syslog. Aucune de ces commandes ne corrige l'horodatage.
- B) ✅ NTP fournit un temps precis et synchronise, et `service timestamps log datetime msec` l'applique aux messages de log.
- C) ❌ `logging host` definit le serveur Syslog distant et `logging source-interface` l'interface source. Ces commandes concernent la destination des logs, pas leur horodatage.
- D) ❌ Configurer seulement le fuseau horaire sans NTP repose sur l'horloge interne du routeur, qui derive naturellement et ne sera pas synchronisee avec les autres equipements du reseau.

</details>

---

**Q7.** Sur un reseau d'entreprise, un trunk 802.1Q transporte les VLANs voix (VLAN 100) et donnees (VLAN 200). L'administrateur souhaite prioriser le trafic voix. Quel mecanisme QoS est le plus adapte au niveau du trunk, et quel champ est utilise ? _(Topics 4.7 + 2.2)_

- A) Marquage DSCP dans l'en-tete IP, car le champ CoS n'existe que sur les trames non taguees
- B) Marquage CoS (Class of Service) dans le tag 802.1Q, en attribuant CoS 5 au VLAN voix
- C) Policing sur le port trunk pour limiter la bande passante du VLAN donnees
- D) Queuing FIFO par defaut, car le trunk ne supporte pas la differenciation de trafic

<details>
<summary>Reponse</summary>

**B** — Le tag 802.1Q contient un champ PCP (Priority Code Point) de 3 bits, aussi appele CoS (Class of Service), qui permet de marquer la priorite des trames au niveau L2. Pour la voix sur IP, la valeur CoS 5 (EF - Expedited Forwarding) est la convention standard. Ce marquage est natif au trunking 802.1Q et permet aux switches de prioriser les trames voix dans leurs files de sortie.

- A) ❌ Le DSCP est effectivement utilise dans l'en-tete IP (L3), mais l'affirmation que le CoS n'existe que sur les trames non taguees est fausse. C'est l'inverse : le champ CoS est dans le tag 802.1Q, donc uniquement sur les trames taguees.
- B) ✅ Le champ CoS (3 bits PCP) dans le tag 802.1Q est le mecanisme L2 natif pour prioriser le trafic sur un trunk. CoS 5 est la valeur standard pour la voix.
- C) ❌ Le policing limite le debit mais ne priorise pas. Limiter le VLAN donnees n'est pas equivalent a prioriser la voix et peut causer des pertes de paquets inutiles.
- D) ❌ FIFO ne fait aucune differenciation. Les switches modernes supportent le queuing base sur CoS ou DSCP.

</details>

---

**Q8.** Un administrateur configure HSRP sur deux switches multicouche pour assurer la redondance de passerelle sur le VLAN 30. Voici la configuration du switch SW1 :

```
interface Vlan30
 ip address 192.168.30.2 255.255.255.0
 standby 30 ip 192.168.30.1
 standby 30 priority 110
 standby 30 preempt
```

Et celle du switch SW2 :

```
interface Vlan30
 ip address 192.168.30.3 255.255.255.0
 standby 30 ip 192.168.30.1
 standby 30 priority 100
```

Si SW1 tombe en panne puis revient en ligne, que se passe-t-il ? _(Topics 3.5 + 2.1)_

- A) SW1 reste en Standby car SW2 est deja Active et ne cede pas le role
- B) SW1 reprend le role Active immediatement grace a la commande `preempt` et sa priorite superieure
- C) Les deux switches entrent en conflit et l'adresse virtuelle 192.168.30.1 devient inaccessible
- D) SW2 reste Active car la preemption n'est pas configuree sur SW2

<details>
<summary>Reponse</summary>

**B** — HSRP preemption est configure sur SW1 avec `standby 30 preempt`. Cela signifie que lorsque SW1 revient en ligne, il compare sa priorite (110) avec celle du routeur Active actuel SW2 (100). Comme 110 > 100 et que preempt est active sur SW1, il reprend le role Active. La preemption doit etre configuree sur le routeur qui souhaite reprendre le role, pas sur l'autre.

- A) ❌ Sans preempt, SW1 resterait en Standby. Mais ici, preempt est explicitement configure sur SW1.
- B) ✅ La combinaison priorite superieure (110 > 100) + preempt sur SW1 lui permet de reprendre le role Active automatiquement.
- C) ❌ HSRP a des mecanismes d'election clairs. Il n'y a pas de conflit : le routeur avec la plus haute priorite et preempt actif prend le role Active.
- D) ❌ La preemption doit etre configuree sur le routeur qui veut reprendre le role (SW1), pas sur l'autre (SW2). La config est correcte.

</details>

---

**Q9.** Quel protocole de la suite TCP/IP utilise un mecanisme de three-way handshake et garantit la livraison ordonnee des segments ? _(Topic 1.5)_

- A) UDP, car il utilise des numeros de sequence
- B) TCP, grace aux numeros de sequence, acquittements et le three-way handshake (SYN, SYN-ACK, ACK)
- C) ICMP, car il envoie des messages d'erreur pour confirmer la reception
- D) IP, grace au champ TTL qui assure la livraison dans un delai garanti

<details>
<summary>Reponse</summary>

**B** — TCP (Transmission Control Protocol) est le protocole de transport oriente connexion. Il etablit une session via le three-way handshake (SYN -> SYN-ACK -> ACK), utilise des numeros de sequence pour ordonner les segments, et des acquittements (ACK) pour garantir la livraison fiable.

- A) ❌ UDP est un protocole sans connexion (connectionless). Il n'a ni three-way handshake, ni numeros de sequence, ni acquittements.
- B) ✅ TCP est le protocole de transport fiable avec three-way handshake, numeros de sequence et acquittements.
- C) ❌ ICMP est un protocole de signalisation (L3), pas de transport. Il rapporte des erreurs mais ne garantit aucune livraison.
- D) ❌ IP est un protocole de couche 3, best-effort. Le TTL limite le nombre de sauts, il ne garantit pas la livraison.

</details>

---

**Q10.** Un administrateur observe le resultat suivant sur un switch :

```
SW1# show cdp neighbors

Capability Codes: R - Router, T - Trans Bridge, B - Source Route Bridge
                  S - Switch, H - Host, I - IGMP, r - Repeater

Device ID        Local Intrfce     Holdtme    Capability  Platform  Port ID
RTR-CORE         Gi0/1             155              R S   ISR4321   Gi0/0/1
SW-DIST1         Gi0/24            133              S I   WS-C3850  Gi1/0/1
```

L'administrateur souhaite migrer vers un protocole de decouverte ouvert (non proprietaire Cisco). Quel protocole doit-il utiliser, et quelle commande l'active globalement ? _(Topic 2.3)_

- A) STP, avec la commande `spanning-tree mode rapid-pvst`
- B) LLDP, avec la commande `lldp run`
- C) LACP, avec la commande `channel-group 1 mode active`
- D) ARP, avec la commande `arp timeout 300`

<details>
<summary>Reponse</summary>

**B** — CDP (Cisco Discovery Protocol) est proprietaire Cisco. Son equivalent standard IEEE 802.1AB est LLDP (Link Layer Discovery Protocol). La commande `lldp run` active LLDP globalement sur le switch. LLDP fournit des fonctionnalites similaires a CDP (decouverte des voisins, identification des ports, capacites) mais fonctionne entre equipements de constructeurs differents.

- A) ❌ STP (Spanning Tree Protocol) est un protocole de prevention de boucles L2, pas de decouverte de voisins.
- B) ✅ LLDP est le protocole standard IEEE 802.1AB de decouverte de voisins. `lldp run` l'active globalement.
- C) ❌ LACP (Link Aggregation Control Protocol) est un protocole d'agregation de liens, pas de decouverte.
- D) ❌ ARP (Address Resolution Protocol) resout les adresses IP en adresses MAC. Ce n'est pas un protocole de decouverte de voisins au sens reseau.

</details>

---

**Q11.** Un ingenieur reseau doit configurer un EtherChannel LACP entre deux switches. Les ports Gi0/1 et Gi0/2 de SW1 doivent initier activement la negociation. Quelle configuration est correcte sur SW1 ? _(Topic 2.4)_

- A) `channel-group 1 mode on` sur Gi0/1 et Gi0/2
- B) `channel-group 1 mode active` sur Gi0/1 et Gi0/2
- C) `channel-group 1 mode desirable` sur Gi0/1 et Gi0/2
- D) `channel-group 1 mode passive` sur Gi0/1 et Gi0/2

<details>
<summary>Reponse</summary>

**B** — LACP (Link Aggregation Control Protocol, IEEE 802.3ad) utilise les modes `active` et `passive`. Le mode `active` initie activement la negociation LACP. Pour que l'EtherChannel se forme, au moins un cote doit etre en `active`. L'autre peut etre `active` ou `passive`.

- A) ❌ Le mode `on` force l'EtherChannel sans aucune negociation (ni LACP, ni PAgP). Cela fonctionne mais n'utilise pas LACP comme demande.
- B) ✅ Le mode `active` utilise LACP et initie activement la negociation, conformement a l'enonce.
- C) ❌ Le mode `desirable` est un mode PAgP (proprietaire Cisco), pas LACP.
- D) ❌ Le mode `passive` utilise LACP mais attend que l'autre cote initie. L'enonce demande une initiation active.

</details>

---

**Q12.** Examinez l'output suivant d'un routeur :

```
RTR# show ip route
Codes: C - connected, S - static, O - OSPF, D - EIGRP

Gateway of last resort is 10.0.0.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.0.0.1
C     10.0.0.0/30 is directly connected, GigabitEthernet0/0
O     10.1.1.0/24 [110/20] via 10.0.0.1, 00:05:32, GigabitEthernet0/0
S     10.2.2.0/24 [1/0] via 10.0.0.1
O     10.2.2.0/26 [110/30] via 10.0.0.1, 00:05:32, GigabitEthernet0/0
S     10.3.3.0/24 [1/0] via 10.0.0.2
```

Un paquet arrive avec l'adresse de destination 10.2.2.15. Quelle route sera utilisee et pourquoi ? _(Topics 3.1 + 3.2)_

- A) La route statique S 10.2.2.0/24 car les routes statiques ont une AD inferieure a OSPF
- B) La route OSPF O 10.2.2.0/26 car le longest prefix match l'emporte sur l'AD
- C) La route par defaut S* 0.0.0.0/0 car elle capture tout le trafic
- D) Le paquet est rejete car il y a un conflit entre la route statique et OSPF

<details>
<summary>Reponse</summary>

**B** — Le mecanisme de selection de route suit cette logique : d'abord le longest prefix match (le masque le plus specifique), puis l'AD (Administrative Distance) en cas d'egalite de prefixe. L'adresse 10.2.2.15 correspond a la fois au /24 (statique) et au /26 (OSPF, couvrant 10.2.2.0 - 10.2.2.63). Le /26 est plus specifique que le /24, donc il est selectionne, independamment de l'AD.

- A) ❌ L'AD n'entre en jeu que lorsque deux routes ont le meme prefixe (meme reseau et meme masque). Ici, /24 et /26 sont des prefixes differents.
- B) ✅ Le longest prefix match est le critere numero 1. Le /26 est plus specifique que le /24, donc la route OSPF est preferee.
- C) ❌ La route par defaut 0.0.0.0/0 est le prefixe le moins specifique possible. Elle n'est utilisee qu'en dernier recours.
- D) ❌ Il n'y a pas de conflit. Le routeur applique le longest prefix match de maniere deterministe.

</details>

---

**Q13.** Un technicien configure un serveur DHCP sur un routeur Cisco. Les clients du VLAN 50 (sous-reseau 192.168.50.0/24) sont sur un autre segment, separes par un switch L3. Les clients ne recoivent pas d'adresse. Quelle commande doit etre ajoutee sur l'interface SVI du VLAN 50 du switch L3 ? _(Topics 4.6 + 3.1)_

- A) `ip dhcp pool VLAN50`
- B) `ip helper-address 192.168.50.1`
- C) `ip helper-address 10.0.0.100` (adresse du serveur DHCP)
- D) `ip dhcp snooping trust`

<details>
<summary>Reponse</summary>

**C** — Les messages DHCP Discover sont des broadcasts. Ils ne traversent pas les routeurs par defaut. Lorsque le serveur DHCP est sur un autre segment, il faut configurer un DHCP relay agent avec la commande `ip helper-address` sur l'interface la plus proche des clients (ici, la SVI du VLAN 50 sur le switch L3). L'adresse specifiee doit etre celle du serveur DHCP distant, pas celle de la passerelle locale.

- A) ❌ `ip dhcp pool` est la commande pour creer un pool DHCP local sur le routeur. Ici, le serveur DHCP est distant.
- B) ❌ L'adresse helper doit pointer vers le serveur DHCP (10.0.0.100), pas vers la passerelle du sous-reseau client (192.168.50.1).
- C) ✅ `ip helper-address 10.0.0.100` redirige les broadcasts DHCP du VLAN 50 vers le serveur DHCP a l'adresse 10.0.0.100 en unicast.
- D) ❌ `ip dhcp snooping trust` est une commande de securite L2 pour DHCP Snooping, pas un relay agent.

</details>

---

**Q14.** Quels sont les trois piliers de la triade CIA en securite de l'information ? _(Topic 5.1)_

- A) Connectivity, Integrity, Authentication
- B) Confidentiality, Integrity, Availability
- C) Compliance, Identification, Authorization
- D) Cryptography, Intrusion detection, Access control

<details>
<summary>Reponse</summary>

**B** — La triade CIA est le modele fondamental de la securite de l'information : Confidentiality (seules les personnes autorisees accedent aux donnees), Integrity (les donnees ne sont pas modifiees sans autorisation), Availability (les donnees et services sont accessibles quand necessaire).

- A) ❌ Connectivity et Authentication ne font pas partie de la triade CIA.
- B) ✅ Confidentiality, Integrity, Availability : les trois piliers fondamentaux.
- C) ❌ Compliance, Identification et Authorization sont des concepts de securite importants mais ne constituent pas la triade CIA.
- D) ❌ Ce sont des mecanismes de securite, pas les piliers de la triade.

</details>

---

**Q15.** Un administrateur configure des ACLs sur un routeur inter-VLAN pour empecher les postes du VLAN 10 (192.168.10.0/24) d'acceder au serveur web (TCP 80/443) du VLAN 20 (192.168.20.100), tout en autorisant tout le reste. Quelle ACL etendue et quel placement sont corrects ? _(Topics 5.6 + 2.1)_

- A) ACL standard appliquee en `in` sur l'interface du VLAN 10 : `access-list 10 deny 192.168.10.0 0.0.0.255`
- B) ACL etendue appliquee en `in` sur la sous-interface du VLAN 10 :
```
ip access-list extended BLOCK-WEB
 deny tcp 192.168.10.0 0.0.0.255 host 192.168.20.100 eq 80
 deny tcp 192.168.10.0 0.0.0.255 host 192.168.20.100 eq 443
 permit ip any any
```
- C) ACL etendue appliquee en `out` sur la sous-interface du VLAN 20 :
```
ip access-list extended BLOCK-WEB
 deny tcp any host 192.168.20.100 eq 80
 permit ip any any
```
- D) ACL standard appliquee en `out` sur la sous-interface du VLAN 20 : `access-list 10 deny 192.168.10.0 0.0.0.255`

<details>
<summary>Reponse</summary>

**B** — Les ACLs etendues doivent etre placees le plus pres possible de la source du trafic pour eviter de gaspiller de la bande passante. Ici, l'ACL est placee en `in` sur l'interface/sous-interface du VLAN 10 (source). Elle bloque specifiquement le trafic TCP vers les ports 80 et 443 du serveur 192.168.20.100, et le `permit ip any any` en fin autorise tout le reste du trafic.

- A) ❌ Une ACL standard ne peut filtrer que sur l'adresse source. Elle bloquerait TOUT le trafic du VLAN 10, pas seulement le trafic web vers le serveur specifique.
- B) ✅ ACL etendue placee en `in` pres de la source. Elle filtre par source, destination, protocole et port. Le `permit ip any any` final evite de bloquer le trafic legitime.
- C) ❌ Cette ACL bloque le trafic web de TOUTES les sources (`any`), pas seulement du VLAN 10. De plus, elle ne bloque que le port 80 et oublie le port 443. Les ACLs etendues doivent etre placees pres de la source.
- D) ❌ Une ACL standard ne peut pas filtrer par destination ou port. De plus, les ACLs standard doivent etre placees pres de la destination, pas de la source.

</details>

---

**Q16.** Un administrateur souhaite surveiller un switch a distance via SNMP. Il configure SNMPv2c avec la community string `PUBLIC` en read-only. Quel risque majeur est associe a cette configuration, et quelle version SNMP resout ce probleme ? _(Topic 4.3)_

- A) SNMPv2c ne supporte pas les traps, il faut migrer vers SNMPv1 qui les supporte nativement
- B) La community string est transmise en clair sur le reseau ; SNMPv3 avec authentification et chiffrement resout ce probleme
- C) SNMPv2c ne peut pas surveiller les interfaces, il faut utiliser Syslog a la place
- D) La community string `PUBLIC` est trop courte ; il suffit de la rallonger pour securiser SNMPv2c

<details>
<summary>Reponse</summary>

**B** — SNMPv1 et SNMPv2c transmettent les community strings en texte clair (plain text) sur le reseau. Un attaquant peut capturer ces chaines avec un sniffer. SNMPv3 introduit trois niveaux de securite : noAuthNoPriv, authNoPriv, et authPriv. Le niveau authPriv offre a la fois l'authentification (MD5/SHA) et le chiffrement (DES/AES) des messages SNMP.

- A) ❌ SNMPv2c supporte les traps ET les informs (acquittement des notifications). C'est SNMPv1 qui est plus limite.
- B) ✅ La community string en clair est la faiblesse majeure de SNMPv2c. SNMPv3 authPriv offre authentification + chiffrement.
- C) ❌ SNMPv2c surveille parfaitement les interfaces et bien plus (CPU, memoire, table de routage, etc.). Syslog est complementaire, pas un remplacement.
- D) ❌ La longueur de la community string n'est pas le probleme. Meme une chaine complexe est vulnerable a l'interception car transmise en clair.

</details>

---

**Q17.** Examinez la configuration suivante sur un routeur de bordure :

```
interface GigabitEthernet0/0
 ip address 10.0.0.1 255.255.255.0
 ip nat inside

interface GigabitEthernet0/1
 ip address 203.0.113.1 255.255.255.252
 ip nat outside

ip nat inside source list 10 interface GigabitEthernet0/1 overload
access-list 10 permit 10.0.0.0 0.0.0.255
```

Dans la terminologie NAT, comment est classifiee l'adresse source 10.0.0.50 d'un poste interne qui navigue sur Internet ? _(Topic 4.1)_

- A) Inside Global
- B) Outside Local
- C) Inside Local
- D) Outside Global

<details>
<summary>Reponse</summary>

**C** — La terminologie NAT definit quatre types d'adresses. L'adresse 10.0.0.50 est l'adresse d'un hote sur le reseau interne (inside), vue depuis le reseau interne (local). C'est donc une adresse **Inside Local**. Apres traduction NAT, cette adresse deviendra l'adresse **Inside Global** (203.0.113.1 dans le cas du PAT/overload).

- A) ❌ Inside Global est l'adresse de l'hote interne vue depuis le reseau externe, c'est-a-dire l'adresse traduite (ici, 203.0.113.1).
- B) ❌ Outside Local est l'adresse d'un hote externe vue depuis le reseau interne (generalement la meme que Outside Global sauf en cas de double NAT).
- C) ✅ Inside Local = adresse de l'hote interne avant traduction, vue du cote interieur du reseau.
- D) ❌ Outside Global est l'adresse d'un hote externe vue depuis le reseau externe (l'adresse IP publique du serveur distant).

</details>

---

**Q18.** Un administrateur configure la securite des ports sur un switch. Voici l'output apres qu'une violation s'est produite :

```
SW1# show port-security interface Gi0/1

Port Security              : Enabled
Port Status                : Secure-shutdown
Violation Mode             : Shutdown
Aging Time                 : 0 mins
Aging Type                 : Absolute
SecureStatic Address Aging : Disabled
Maximum MAC Addresses      : 2
Total MAC Addresses        : 3
Configured MAC Addresses   : 0
Sticky MAC Addresses       : 0
Last Source Address:Vlan   : aa11.bb22.cc33:10
Security Violation Count   : 1
```

Que doit faire l'administrateur pour retablir le port ? _(Topic 5.7)_

- A) Debrancher le peripherique non autorise, puis executer `shutdown` suivi de `no shutdown` sur l'interface
- B) Augmenter le maximum MAC a 3 avec `switchport port-security maximum 3`
- C) Changer le mode de violation a `restrict` avec `switchport port-security violation restrict`
- D) Supprimer la configuration port-security avec `no switchport port-security`

<details>
<summary>Reponse</summary>

**A** — Lorsque le mode de violation est `shutdown` et qu'une violation se produit, le port passe en etat `err-disabled` (Secure-shutdown). Pour le retablir, il faut d'abord resoudre la cause (ici, debrancher le 3e peripherique non autorise puisque le max est 2), puis effectuer un bounce du port avec `shutdown` puis `no shutdown`. Alternativement, la commande `errdisable recovery cause psecure-violation` peut automatiser la recuperation.

- A) ✅ La procedure correcte : resoudre la cause de la violation, puis bounce l'interface (shutdown / no shutdown).
- B) ❌ Augmenter le maximum ne retablira pas le port deja en err-disabled. Il faudrait quand meme faire un bounce. De plus, cela affaiblit la politique de securite.
- C) ❌ Changer le mode de violation ne retablit pas un port deja en err-disabled. Le port doit etre bounce.
- D) ❌ Supprimer la configuration port-security desactive la fonctionnalite entierement. Ce n'est pas une solution, c'est un contournement.

</details>

---

**Q19.** Dans un deploiement wireless d'entreprise, quel est l'avantage principal d'une architecture basee sur un WLC (Wireless LAN Controller) par rapport a des AP autonomes ? _(Topic 2.6)_

- A) Les AP autonomes offrent une meilleure couverture car ils fonctionnent independamment
- B) Le WLC centralise la gestion, la configuration et les politiques de securite pour tous les AP du reseau
- C) Le WLC elimine le besoin de cablage Ethernet vers les AP grace a la liaison sans fil mesh
- D) Les AP autonomes supportent plus de clients simultanement car ils n'ont pas de dependance au controleur

<details>
<summary>Reponse</summary>

**B** — Dans une architecture basee WLC, les AP fonctionnent en mode lightweight (LAP) et etablissent un tunnel CAPWAP (Control And Provisioning of Wireless Access Points) vers le WLC. Le controleur gere la configuration centralisee des SSID, les politiques de securite (WPA2/WPA3, 802.1X), le roaming entre AP, la repartition de charge, et la gestion des canaux/puissance RF.

- A) ❌ La couverture depend du placement physique des AP, pas de leur mode de fonctionnement. Les AP autonomes necessitent une configuration individuelle, ce qui complique la gestion.
- B) ✅ La gestion centralisee est le principal avantage : un seul point de configuration et de supervision pour tous les AP.
- C) ❌ Les AP lightweight necessitent toujours une connexion Ethernet (souvent PoE). Le mesh est une option specifique, pas une generalite du modele WLC.
- D) ❌ La capacite en nombre de clients depend du hardware de l'AP, pas du mode de fonctionnement. Le WLC peut meme optimiser la repartition des clients.

</details>

---

**Q20.** Un administrateur doit configurer un VPN IPsec site-to-site entre deux sites distants. Quelles sont les deux phases principales de l'etablissement du tunnel IPsec ? _(Topic 5.4)_

- A) Phase 1 : Echange des certificats SSL/TLS ; Phase 2 : Etablissement du tunnel GRE
- B) Phase 1 : Negociation IKE pour etablir un canal securise (SA ISAKMP) ; Phase 2 : Negociation des SA IPsec pour le trafic utilisateur
- C) Phase 1 : Configuration du NAT traversal ; Phase 2 : Activation du routage dynamique dans le tunnel
- D) Phase 1 : Authentification RADIUS des sites ; Phase 2 : Echange des cles pre-partagees

<details>
<summary>Reponse</summary>

**B** — L'etablissement d'un tunnel IPsec suit deux phases IKE (Internet Key Exchange). La Phase 1 etablit un canal securise bidirectionnel (ISAKMP SA) entre les deux peers en negociant les parametres de securite (chiffrement, hachage, authentification, DH group, lifetime). La Phase 2 utilise ce canal securise pour negocier les IPsec SA qui protegeront le trafic utilisateur reel (avec ESP ou AH).

- A) ❌ SSL/TLS est utilise pour les VPN remote-access (ex: AnyConnect), pas pour IPsec site-to-site. GRE est un protocole de tunneling separe.
- B) ✅ Phase 1 = ISAKMP SA (canal securise de management). Phase 2 = IPsec SA (protection du trafic donnees).
- C) ❌ NAT traversal est une fonctionnalite complementaire, pas une phase. Le routage dynamique peut fonctionner dans un tunnel mais n'est pas une phase IPsec.
- D) ❌ L'authentification des peers se fait pendant la Phase 1 (pre-shared key ou certificats), pas via RADIUS. L'echange de cles fait partie de la Phase 1, pas de la Phase 2.

</details>

---

**Q21.** Observez la sortie suivante sur un switch :

```
SW1# show spanning-tree vlan 10

VLAN0010
  Spanning tree enabled protocol rstp
  Root ID    Priority    24586
             Address     aabb.cc00.1000
             Cost        4
             Port        1 (GigabitEthernet0/1)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32778  (priority 32768 sys-id-ext 10)
             Address     aabb.cc00.2000
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

Interface           Role Sts   Cost      Prio.Nbr Type
------------------- ---- ---   --------- -------- ------
Gi0/1               Root FWD   4         128.1    P2p
Gi0/2               Altn BLK   4         128.2    P2p
Gi0/3               Desg FWD   4         128.3    P2p
```

Quel est le role du port Gi0/2 et pourquoi est-il dans cet etat ? _(Topic 2.5)_

- A) Designated port bloque car il detecte une boucle sur ce segment
- B) Alternate port bloque car il offre un chemin de secours vers le root bridge avec un cout egal mais un Port ID superieur a Gi0/1
- C) Root port bloque car le root bridge a change et le port est en transition
- D) Backup port bloque car il est connecte au meme segment que Gi0/1

<details>
<summary>Reponse</summary>

**B** — Dans RSTP (Rapid Spanning Tree Protocol), un port Alternate est un port qui recoit des BPDU superieurs d'un autre switch et offre un chemin alternatif vers le root bridge. Gi0/1 est deja le Root port (meilleur chemin vers le root). Gi0/2, avec le meme cout (4), perd la selection car son Port ID (128.2) est superieur a celui de Gi0/1 (128.1). Il est bloque en tant qu'Alternate, pret a prendre le relais si Gi0/1 tombe.

- A) ❌ Un Designated port est le port qui transmet les BPDU sur un segment. Gi0/2 est marque "Altn" (Alternate), pas "Desg" (Designated).
- B) ✅ Alternate port = chemin de secours vers le root bridge. Le cout est identique (4), mais Gi0/1 gagne grace a son Port ID inferieur (128.1 < 128.2).
- C) ❌ Le Root port est Gi0/1, pas Gi0/2. Un Root port n'est jamais bloque (sauf transition tres breve en RSTP).
- D) ❌ Un Backup port est un port qui recoit ses propres BPDU (connecte au meme segment que lui-meme via un hub). Les deux ports ont des connections P2p distinctes.

</details>

---

**Q22.** Quelle est la difference fondamentale entre TACACS+ et RADIUS en termes d'architecture de protocole ? _(Topic 5.8)_

- A) TACACS+ utilise UDP port 1812 et RADIUS utilise TCP port 49
- B) TACACS+ separe les fonctions AAA (Authentication, Authorization, Accounting) tandis que RADIUS combine Authentication et Authorization
- C) RADIUS chiffre l'integralite du paquet tandis que TACACS+ ne chiffre que le mot de passe
- D) TACACS+ est un standard ouvert IEEE tandis que RADIUS est proprietaire Cisco

<details>
<summary>Reponse</summary>

**B** — TACACS+ (developpee par Cisco) separe completement les trois fonctions AAA, ce qui offre un controle granulaire (par exemple, autoriser un utilisateur a executer certaines commandes specifiques). RADIUS combine Authentication et Authorization dans le meme echange (Access-Request / Access-Accept), ce qui est moins flexible pour le controle des commandes mais suffisant pour l'authentification reseau (802.1X, VPN).

- A) ❌ C'est l'inverse : TACACS+ utilise TCP port 49, RADIUS utilise UDP ports 1812 (authentication) et 1813 (accounting).
- B) ✅ TACACS+ separe A-A-A, RADIUS combine authn+authz. C'est la difference architecturale cle.
- C) ❌ C'est l'inverse : TACACS+ chiffre l'integralite du corps du paquet, RADIUS ne chiffre que le mot de passe dans l'Access-Request.
- D) ❌ C'est l'inverse : RADIUS est un standard ouvert (RFC 2865/2866), TACACS+ est developpe par Cisco (bien que la specification soit publique).

</details>

---

**Q23.** Un administrateur configure les niveaux de securite des mots de passe sur un routeur. Voici la configuration actuelle :

```
enable secret 5 $1$xyz$AbCdEfGh123456
enable password cisco123
service password-encryption
username admin secret Str0ngP@ss!
line console 0
 password console123
 login
line vty 0 4
 password vty123
 login local
```

Quel mot de passe est utilise lorsqu'un administrateur tape la commande `enable` depuis le mode utilisateur, et pourquoi `service password-encryption` n'affecte-t-il pas `enable secret` ? _(Topics 5.3 + 4.8)_

- A) Le mot de passe `cisco123` est utilise car `enable password` a priorite sur `enable secret`
- B) Le mot de passe hache derriere `enable secret` est utilise car il a priorite sur `enable password` ; `service password-encryption` n'affecte pas `enable secret` car celui-ci utilise deja MD5 (type 5), un algorithme plus fort que le chiffrement type 7
- C) Les deux mots de passe sont demandes successivement pour une double authentification
- D) Le mot de passe `console123` est utilise car la connexion est via la console

<details>
<summary>Reponse</summary>

**B** — Lorsque `enable secret` et `enable password` coexistent, `enable secret` a toujours la priorite. Le `enable secret` est stocke avec un hachage MD5 (type 5) ou SCRYPT (type 9), qui sont des algorithmes a sens unique. La commande `service password-encryption` applique un chiffrement reversible type 7 (algorithme Vigenere faible) aux mots de passe en clair dans la configuration. Elle n'affecte pas `enable secret` car celui-ci est deja protege par un algorithme bien plus robuste.

- A) ❌ `enable secret` a TOUJOURS priorite sur `enable password`. Si les deux sont configures, `enable password` est ignore.
- B) ✅ `enable secret` (MD5 type 5) prime sur `enable password`. `service password-encryption` (type 7) n'a pas d'effet sur un secret deja hache en MD5.
- C) ❌ Il n'y a pas de double authentification. `enable secret` prend le dessus et `enable password` est completement ignore.
- D) ❌ Le mot de passe console est utilise pour la connexion initiale a la console (mode user). La commande `enable` utilise `enable secret` ou `enable password`, quel que soit le type de connexion.

</details>

---

**Q24.** Un reseau utilise les standards de securite wireless suivants sur differents SSID. Classez-les du moins securise au plus securise : _(Topic 5.9)_

1. WPA2-Personal (PSK) avec AES
2. WPA3-Enterprise avec 192-bit security
3. WEP 64-bit
4. WPA-Personal (PSK) avec TKIP

- A) 3, 4, 1, 2
- B) 4, 3, 1, 2
- C) 3, 1, 4, 2
- D) 3, 4, 2, 1

<details>
<summary>Reponse</summary>

**A** — L'evolution de la securite Wi-Fi suit cet ordre : WEP (casse en quelques minutes, cle statique RC4) < WPA/TKIP (amelioration temporaire de WEP, TKIP a des faiblesses connues) < WPA2/AES (CCMP robuste, standard depuis 2004) < WPA3 (SAE remplace PSK, protection contre les attaques par dictionnaire, forward secrecy, mode 192-bit pour Enterprise).

- A) ✅ WEP (3) < WPA/TKIP (4) < WPA2/AES (1) < WPA3-Enterprise 192-bit (2). C'est l'ordre correct du moins securise au plus securise.
- B) ❌ WPA/TKIP n'est pas moins securise que WEP. WEP est fondamentalement casse.
- C) ❌ WPA2/AES est plus securise que WPA/TKIP, pas l'inverse.
- D) ❌ WPA3-Enterprise 192-bit est le plus securise, pas WPA2.

</details>

---

**Q25.** Un ingenieur reseau analyse la configuration Syslog d'un routeur et les niveaux de severite. Voici un message de log :

```
*Mar 15 14:22:05.123: %OSPF-5-ADJCHG: Process 1, Nbr 10.0.0.2 on GigabitEthernet0/0 from LOADING to FULL, Loading Done
```

Quel est le niveau de severite de ce message, que represente le champ "OSPF" et que signifie "ADJCHG" ? De plus, si l'administrateur configure `logging trap 4`, ce message sera-t-il envoye au serveur Syslog ? _(Topics 4.5 + 3.4)_

- A) Severite 5 (Notification) ; OSPF est la facility ; ADJCHG est le mnemonic. Oui, le message sera envoye car le niveau 5 est inferieur a 4
- B) Severite 5 (Notification) ; OSPF est la facility ; ADJCHG est le mnemonic. Non, le message ne sera pas envoye car `logging trap 4` n'envoie que les niveaux 0 a 4
- C) Severite 4 (Warning) ; OSPF est le protocole source ; ADJCHG est le code d'erreur. Oui, le message sera envoye
- D) Severite 5 (Notification) ; OSPF est le protocole source ; ADJCHG est le type d'evenement. Oui, le message sera envoye car les notifications sont critiques

<details>
<summary>Reponse</summary>

**B** — Le format d'un message Syslog Cisco est : `%FACILITY-SEVERITY-MNEMONIC`. Ici : OSPF est la facility (module generateur), 5 est le niveau de severite (Notification), et ADJCHG est le mnemonic (description courte de l'evenement = Adjacency Change). La commande `logging trap 4` configure le switch/routeur pour n'envoyer au serveur Syslog que les messages de severite 0 (Emergency) a 4 (Warning). Le niveau 5 (Notification) est exclu.

- A) ❌ L'identification du message est correcte, mais la conclusion est fausse. En Syslog, un numero de severite plus BAS signifie plus critique. Le niveau 5 n'est PAS envoye avec `logging trap 4` car seuls les niveaux 0-4 sont inclus.
- B) ✅ Severite 5 = Notification. `logging trap 4` = niveaux 0 a 4 uniquement. Le message de niveau 5 ne sera PAS envoye au serveur Syslog.
- C) ❌ Le niveau est 5, pas 4. Le chiffre apres le premier tiret dans le format %FACILITY-SEVERITY-MNEMONIC est la severite.
- D) ❌ L'identification de la severite est correcte (5) mais la conclusion est fausse. Les notifications (niveau 5) ne sont pas envoyees avec `logging trap 4`.

</details>

---

## Tableau des resultats

| Score | Appreciation | Recommandation |
|-------|-------------|----------------|
| **23-25** (90-100 %) | Maitrise excellente | Pret pour l'examen. Revisez les rares erreurs et passez aux labs pratiques. |
| **18-22** (70-89 %) | Bonne comprehension | Solide base. Renforcez les topics ou vous avez hesite, surtout les interconnexions entre domaines. |
| **13-17** (50-69 %) | Lacunes a combler | Revoir les modules concernes en priorite. Concentrez-vous sur les concepts fondamentaux avant les details. |
| **< 13** (< 50 %) | Retravailler les bases | Reprenez les modules un par un. Utilisez les labs Packet Tracer pour ancrer la theorie dans la pratique. |

---

**Repartition par module :**

| Module | Questions |
|--------|-----------|
| 1 — Network Fundamentals | Q9, Q10, Q11 |
| 2 — Network Access | Q4, Q11, Q19, Q21 |
| 3 — IP Connectivity | Q2, Q8, Q12, Q13 |
| 4 — IP Services | Q1, Q6, Q7, Q16, Q17, Q25 |
| 5 — Security Fundamentals | Q3, Q5, Q14, Q15, Q18, Q20, Q22, Q23, Q24 |

**Questions interconnexions (multi-domaines) :**
Q1 (NAT+ACL), Q2 (OSPF+Subnetting), Q3 (DHCP+Securite L2), Q4 (VLANs+Trunk+Routage), Q5 (SSH+AAA), Q6 (Syslog+NTP), Q7 (QoS+Trunk), Q8 (HSRP+VLAN), Q13 (DHCP Relay+Routage), Q15 (ACLs+VLANs), Q23 (MdP+Acces gestion), Q25 (Syslog+OSPF)
