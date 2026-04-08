# Quiz Transversal 1 — Mi-parcours (Semaine 5)

**Modules couverts :** 1 (Network Fundamentals), 2 (Network Access), 3 (IP Connectivity)
**Topics :** 1.1-1.14, 2.1-2.9, 3.1-3.6
**Nombre de questions :** 25
**Duree suggeree :** 40 minutes
**Score vise :** >= 70 % (18/25)

---

## Questions

---

**Q1.** Dans une architecture three-tier classique d'un campus reseau, quelles sont les trois couches hierarchiques ? _(Topic 1.2)_

- A) Core, Distribution, Access
- B) Core, Aggregation, Edge
- C) Backbone, Distribution, Endpoint
- D) Spine, Leaf, Access

<details>
<summary>Reponse</summary>

**A** — Le modele hierarchique Cisco a trois couches : Core (commutation rapide entre sites), Distribution (filtrage, politiques, routage inter-VLAN) et Access (connexion des terminaux). C'est le modele de reference pour les reseaux campus.

- A) ✅ Core / Distribution / Access est le modele three-tier Cisco
- B) ❌ "Aggregation" et "Edge" sont des termes utilises dans d'autres contextes (WAN, data center) mais pas dans le modele campus classique
- C) ❌ "Backbone" et "Endpoint" ne sont pas des noms de couches du modele hierarchique Cisco
- D) ❌ Spine-Leaf est une architecture data center distincte, sans couche "Access" dans sa terminologie

</details>

---

**Q2.** Un administrateur connecte un PC a un switch via un cable UTP Cat5e. Le port du switch affiche `up/up` mais des erreurs CRC augmentent constamment. Quelle est la cause la plus probable ? _(Topic 1.4)_

- A) Le cable est un cable croise au lieu d'un cable droit
- B) Le cable presente un defaut physique (paire endommagee ou mal sertie)
- C) Le port est configure en half-duplex
- D) Le switch ne supporte pas le Cat5e

<details>
<summary>Reponse</summary>

**B** — Les erreurs CRC (Cyclic Redundancy Check) sur une interface `up/up` indiquent generalement un probleme au niveau de la couche physique : cable endommage, connecteur mal serti, ou interference electromagnetique. Le lien fonctionne (up/up) mais les trames arrivent corrompues.

- A) ❌ Les switches modernes supportent l'Auto-MDIX et s'adaptent au type de cable. De plus, un cable croise ne provoquerait pas specifiquement des erreurs CRC
- B) ✅ Un cable defectueux (paire tordue, connecteur mal serti, cable trop long) corrompt les signaux et genere des erreurs CRC
- C) ❌ Un mismatch duplex provoquerait plutot des "late collisions" cote full-duplex et des collisions excessives cote half-duplex, pas principalement des CRC
- D) ❌ Cat5e est un standard largement supporte par tous les switches modernes

</details>

---

**Q3.** Quel protocole de couche transport est utilise par le DNS pour les requetes de resolution de noms standard (non transfert de zone) ? _(Topic 1.5)_

- A) TCP port 53
- B) UDP port 53
- C) TCP port 43
- D) UDP port 443

<details>
<summary>Reponse</summary>

**B** — Les requetes DNS classiques (resolution de noms) utilisent UDP sur le port 53. UDP est prefere car ces requetes sont courtes (question-reponse) et la rapidite prime sur la fiabilite. TCP sur le port 53 est utilise pour les transferts de zone entre serveurs DNS ou quand la reponse depasse 512 octets.

- A) ❌ TCP/53 est reserve aux transferts de zone DNS ou aux reponses tronquees, pas aux requetes standard
- B) ✅ DNS utilise UDP/53 pour les requetes de resolution : faible latence, pas besoin du three-way handshake
- C) ❌ Le port 43 est celui du protocole WHOIS, pas du DNS
- D) ❌ Le port 443 est celui d'HTTPS, pas du DNS (meme si DNS-over-HTTPS existe, ce n'est pas le comportement standard)

</details>

---

**Q4.** Un reseau utilise le prefixe 172.20.0.0/22. Combien d'adresses IP utilisables sont disponibles pour des hotes ? _(Topic 1.6)_

- A) 510
- B) 1022
- C) 1024
- D) 2046

<details>
<summary>Reponse</summary>

**B** — Avec un masque /22, il y a 32 - 22 = 10 bits pour la partie hote. Le nombre total d'adresses est 2^10 = 1024. On retire l'adresse reseau et l'adresse de broadcast, ce qui donne 1024 - 2 = 1022 adresses utilisables.

- A) ❌ 510 correspond a un /23 (2^9 - 2 = 510)
- B) ✅ /22 = 10 bits hote → 2^10 - 2 = 1022 adresses utilisables
- C) ❌ 1024 est le nombre total d'adresses sans retirer reseau et broadcast
- D) ❌ 2046 correspond a un /21 (2^11 - 2 = 2046)

</details>

---

**Q5.** Parmi les plages suivantes, laquelle n'est PAS une plage d'adresses privees definie par la RFC 1918 ? _(Topic 1.7)_

- A) 10.0.0.0 – 10.255.255.255
- B) 172.16.0.0 – 172.31.255.255
- C) 192.168.0.0 – 192.168.255.255
- D) 169.254.0.0 – 169.254.255.255

<details>
<summary>Reponse</summary>

**D** — La plage 169.254.0.0/16 est la plage APIPA (Automatic Private IP Addressing), attribuee automatiquement quand un client DHCP ne parvient pas a obtenir une adresse. Elle n'est pas definie par la RFC 1918 mais par la RFC 3927 (link-local).

- A) ❌ 10.0.0.0/8 est bien une plage privee RFC 1918 (classe A)
- B) ❌ 172.16.0.0/12 est bien une plage privee RFC 1918 (classe B partielle)
- C) ❌ 192.168.0.0/16 est bien une plage privee RFC 1918 (classe C)
- D) ✅ 169.254.0.0/16 est la plage link-local/APIPA (RFC 3927), pas une plage privee RFC 1918

</details>

---

**Q6.** Quelle est la taille d'un prefixe de routage global unicast IPv6 typiquement alloue a un site par un FAI ? _(Topic 1.8)_

- A) /32
- B) /48
- C) /64
- D) /128

<details>
<summary>Reponse</summary>

**B** — Un FAI attribue typiquement un prefixe /48 a un site client. Ce prefixe permet au site de creer 2^16 = 65 536 sous-reseaux /64 en interne. Le /64 est utilise pour un sous-reseau individuel, et /128 identifie un hote unique.

- A) ❌ /32 est le prefixe typiquement attribue a un FAI par un RIR, pas a un site client
- B) ✅ /48 est l'allocation standard pour un site client, permettant 65 536 sous-reseaux /64
- C) ❌ /64 est le prefixe d'un sous-reseau individuel (obligatoire pour SLAAC), pas d'un site entier
- D) ❌ /128 identifie une seule adresse IPv6, c'est l'equivalent d'un /32 en IPv4

</details>

---

**Q7.** Un technicien observe l'adresse IPv6 `fe80::1` sur une interface. De quel type d'adresse s'agit-il et quelle est sa particularite ? _(Topic 1.9)_

- A) Global unicast — routable sur Internet
- B) Unique local — routable uniquement en interne
- C) Link-local — non routable, valide uniquement sur le lien local
- D) Anycast — distribuee a plusieurs interfaces

<details>
<summary>Reponse</summary>

**C** — Le prefixe `fe80::/10` identifie une adresse link-local IPv6. Ces adresses sont automatiquement configurees sur chaque interface IPv6 et ne sont valides que sur le segment de lien local (pas transmises par les routeurs). Elles sont indispensables pour le fonctionnement d'IPv6 (NDP, routage next-hop).

- A) ❌ Les adresses global unicast commencent par 2000::/3 (typiquement 2xxx: ou 3xxx:), pas fe80::
- B) ❌ Les adresses unique local commencent par fc00::/7 (typiquement fd00::), pas fe80::
- C) ✅ fe80::/10 est le prefixe link-local : automatiquement configuree, non routable, limitee au lien
- D) ❌ Une adresse anycast n'a pas de prefixe specifique ; elle est identique a une unicast mais assignee a plusieurs noeuds

</details>

---

**Q8.** Quel mecanisme permet a un switch de determiner ou envoyer une trame unicast recue ? _(Topic 1.13)_

- A) Il consulte sa table de routage IP
- B) Il consulte sa table d'adresses MAC (CAM table) en associant l'adresse MAC destination au port de sortie
- C) Il envoie toujours la trame sur tous les ports (flooding)
- D) Il utilise le protocole ARP pour trouver le port de destination

<details>
<summary>Reponse</summary>

**B** — Un switch de couche 2 maintient une table d'adresses MAC (aussi appelee table CAM). Quand il recoit une trame, il apprend l'adresse MAC source sur le port d'entree, puis cherche l'adresse MAC destination dans sa table pour determiner le port de sortie. Si l'adresse est inconnue, il fait du flooding (envoi sur tous les ports sauf le port source).

- A) ❌ La table de routage IP est utilisee par les routeurs (couche 3), pas par les switches L2
- B) ✅ La table MAC/CAM associe adresses MAC et ports physiques, permettant la commutation ciblee
- C) ❌ Le flooding n'a lieu que si l'adresse MAC destination est inconnue (unknown unicast) ou pour les broadcasts
- D) ❌ ARP est un protocole de resolution IP→MAC utilise par les hotes, pas un mecanisme de commutation du switch

</details>

---

**Q9.** Un ingenieur utilise la commande `ipconfig` sur un poste Windows et obtient une adresse 169.254.x.x. Que peut-il en conclure ? _(Topic 1.10)_

- A) Le poste a une adresse IPv6 link-local correctement configuree
- B) Le poste n'a pas reussi a contacter un serveur DHCP et a obtenu une adresse APIPA
- C) Le poste est configure avec une adresse statique privee
- D) Le poste est connecte a un reseau Wi-Fi public

<details>
<summary>Reponse</summary>

**B** — Une adresse dans la plage 169.254.0.0/16 est une adresse APIPA (Automatic Private IP Addressing). Windows l'attribue automatiquement quand le client DHCP ne parvient pas a joindre un serveur DHCP. Cela indique un probleme de connectivite au serveur DHCP ou l'absence de celui-ci.

- A) ❌ 169.254.x.x est une adresse IPv4 APIPA, pas une adresse IPv6 link-local (qui serait fe80::)
- B) ✅ APIPA (169.254.0.0/16) est le signe que le client DHCP n'a pas obtenu de bail
- C) ❌ Une adresse statique ne serait pas dans la plage 169.254.x.x (un administrateur configurerait une adresse RFC 1918)
- D) ❌ La plage 169.254.x.x n'a aucun lien avec le type de reseau (Wi-Fi ou filaire)

</details>

---

**Q10.** Un administrateur configure des VLANs sur un switch. Il cree le VLAN 10 (Comptabilite) et le VLAN 20 (RH). Un PC du VLAN 10 veut communiquer avec un serveur du VLAN 20. Que faut-il ? _(Topic 2.1)_

- A) Configurer les deux ports en mode trunk
- B) Mettre les deux equipements dans le meme VLAN
- C) Utiliser un equipement de couche 3 (routeur ou switch L3) pour le routage inter-VLAN
- D) Activer STP entre les deux VLANs

<details>
<summary>Reponse</summary>

**C** — Les VLANs segmentent le reseau en domaines de broadcast separes. Pour que deux VLANs communiquent, il faut un dispositif de couche 3 : soit un routeur (router-on-a-stick avec sous-interfaces), soit un switch multilayer (SVI - Switch Virtual Interface). C'est le principe fondamental du routage inter-VLAN.

- A) ❌ Le trunk transporte plusieurs VLANs sur un seul lien physique entre switches, mais ne permet pas le routage entre VLANs
- B) ❌ Mettre les deux dans le meme VLAN resoudrait la communication mais annulerait la segmentation voulue
- C) ✅ Le routage inter-VLAN necessite un equipement L3 (routeur ou switch L3 avec SVIs)
- D) ❌ STP previent les boucles de couche 2, il n'a aucun role dans la communication inter-VLAN

</details>

---

**Q11.** Voici un extrait de configuration sur un switch Cisco :

```
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,30
```

Que se passe-t-il si un PC non tague envoie une trame sur ce port ? _(Topic 2.2)_

- A) La trame est rejetee car seuls les VLANs 10, 20 et 30 sont autorises
- B) La trame est placee dans le VLAN 99 (native VLAN)
- C) La trame est placee dans le VLAN 1 par defaut
- D) La trame est floodee sur tous les VLANs autorises

<details>
<summary>Reponse</summary>

**B** — Sur un trunk 802.1Q, les trames non taguees sont associees au native VLAN. Ici, le native VLAN est explicitement configure a 99. Meme si le VLAN 99 n'est pas dans la liste `allowed vlan`, les trames non taguees sont quand meme traitees dans le VLAN 99 cote local (bien que le comportement exact puisse varier selon les plateformes, la logique 802.1Q associe le trafic non tague au native VLAN).

- A) ❌ La restriction `allowed vlan` s'applique au trafic tague. Le trafic non tague est gere par le native VLAN
- B) ✅ Le native VLAN 99 recoit toutes les trames non taguees sur un trunk 802.1Q
- C) ❌ Le VLAN 1 serait le native VLAN par defaut uniquement si la commande `native vlan 99` n'etait pas presente
- D) ❌ Le flooding sur tous les VLANs n'est pas le comportement d'un trunk pour du trafic non tague

</details>

---

**Q12.** Quelle est la difference fondamentale entre CDP et LLDP ? _(Topic 2.3)_

- A) CDP fonctionne sur tous les equipements reseau, LLDP est proprietaire Cisco
- B) CDP est proprietaire Cisco, LLDP est un standard IEEE (802.1AB) multi-constructeur
- C) CDP utilise TCP, LLDP utilise UDP
- D) CDP decouvre uniquement les switches, LLDP decouvre tous les equipements

<details>
<summary>Reponse</summary>

**B** — CDP (Cisco Discovery Protocol) est un protocole proprietaire Cisco qui fonctionne uniquement entre equipements Cisco. LLDP (Link Layer Discovery Protocol) est standardise par l'IEEE sous la reference 802.1AB et fonctionne entre equipements de differents constructeurs. Les deux permettent de decouvrir les voisins directement connectes.

- A) ❌ C'est l'inverse : CDP est proprietaire Cisco, LLDP est multi-constructeur
- B) ✅ CDP = proprietaire Cisco, LLDP = standard IEEE 802.1AB
- C) ❌ Ni CDP ni LLDP n'utilisent TCP ou UDP. Ils operent directement en couche 2 (trames multicast)
- D) ❌ Les deux protocoles decouvrent tous types d'equipements voisins (routeurs, switches, telephones IP, etc.)

</details>

---

**Q13.** Un administrateur souhaite agreger deux liens physiques entre deux switches pour augmenter la bande passante et assurer la redondance. Quel protocole standard doit-il utiliser ? _(Topic 2.4)_

- A) PAgP
- B) LACP
- C) STP
- D) DTP

<details>
<summary>Reponse</summary>

**B** — LACP (Link Aggregation Control Protocol), defini dans IEEE 802.3ad (maintenant 802.1AX), est le protocole standard pour creer un EtherChannel. Il negocie dynamiquement l'agregation de liens entre les deux switches. PAgP est l'equivalent proprietaire Cisco. STP previent les boucles mais n'agrege pas les liens.

- A) ❌ PAgP (Port Aggregation Protocol) est proprietaire Cisco, pas un standard
- B) ✅ LACP est le protocole standard IEEE pour l'agregation de liens (EtherChannel)
- C) ❌ STP empeche les boucles mais ne fait pas d'agregation ; il bloquerait meme l'un des deux liens
- D) ❌ DTP (Dynamic Trunking Protocol) negocie les trunks, pas les EtherChannels

</details>

---

**Q14.** Dans Rapid PVST+, un switch recoit des BPDU sur plusieurs ports. Comment determine-t-il quel port devient le Root Port ? _(Topic 2.5)_

- A) Le port avec le numero de port le plus eleve
- B) Le port qui recoit le BPDU avec le cout le plus faible vers le Root Bridge
- C) Le port connecte au lien le plus rapide, independamment des BPDU
- D) Le premier port qui recoit un BPDU

<details>
<summary>Reponse</summary>

**B** — Le Root Port est le port qui offre le meilleur chemin (cout le plus faible) vers le Root Bridge. La selection suit cet ordre : (1) cout racine le plus faible, (2) Bridge ID de l'emetteur le plus faible, (3) Port ID de l'emetteur le plus faible. Un seul Root Port est elu par switch non-root.

- A) ❌ Le numero de port n'est qu'un critere de departage en dernier recours, et c'est le plus faible qui l'emporte, pas le plus eleve
- B) ✅ Le cout racine le plus faible determine le Root Port (critere principal)
- C) ❌ La vitesse du lien influence le cout, mais c'est le cout cumule vers le Root Bridge qui decide, pas la vitesse locale seule
- D) ❌ L'ordre d'arrivee des BPDU n'est pas un critere de selection

</details>

---

**Q15.** Un administrateur configure PortFast sur un port de switch connecte a un PC. Quel est l'effet principal de cette commande et quel est le risque associe ? _(Topic 2.5)_

- A) Le port passe immediatement en etat forwarding, mais une boucle peut se former si un switch est connecte
- B) Le port est protege contre les attaques MAC flooding
- C) Le port negocie automatiquement le VLAN avec le PC
- D) Le port desactive STP completement sur le switch

<details>
<summary>Reponse</summary>

**A** — PortFast fait passer un port directement de l'etat blocking a l'etat forwarding, sans passer par les etats listening et learning (qui prennent 30 secondes au total en STP classique). C'est utile pour les postes de travail qui ont besoin d'un acces reseau immediat. Le risque est que si un switch est connecte par erreur a ce port, une boucle L2 peut se former car STP ne bloquera pas le port.

- A) ✅ PortFast = transition immediate en forwarding. Risque de boucle si un switch est branche sur ce port
- B) ❌ La protection contre le MAC flooding releve du port security, pas de PortFast
- C) ❌ La negociation VLAN est geree par DTP ou la configuration manuelle, pas par PortFast
- D) ❌ PortFast n'affecte que le port configure, il ne desactive pas STP sur le switch entier

</details>

---

**Q16.** Quel mode AP (Access Point) est utilise dans une architecture wireless centralisee ou toute la gestion du trafic est renvoyee vers un WLC (Wireless LAN Controller) ? _(Topic 2.6)_

- A) Mode autonome (autonomous)
- B) Mode local (lightweight)
- C) Mode FlexConnect
- D) Mode monitor

<details>
<summary>Reponse</summary>

**B** — En mode local (lightweight), l'AP etablit un tunnel CAPWAP vers le WLC. Tout le trafic des clients sans fil est encapsule et envoye au WLC pour traitement. C'est l'architecture centralisee classique qui permet une gestion unifiee des politiques, de la QoS et de la securite.

- A) ❌ En mode autonome, l'AP gere tout localement sans WLC — c'est l'oppose d'une architecture centralisee
- B) ✅ Mode local/lightweight = tunnel CAPWAP vers le WLC, gestion centralisee de tout le trafic
- C) ❌ FlexConnect permet a l'AP de commuter le trafic localement meme avec un WLC, utile pour les sites distants
- D) ❌ Le mode monitor est un mode passif de surveillance RF, il ne sert pas le trafic client

</details>

---

**Q17.** Un administrateur veut securiser l'acces en ligne de commande a un switch. Quelle methode offre le meilleur niveau de securite ? _(Topic 2.8)_

- A) Telnet avec authentification locale
- B) SSH version 2 avec authentification TACACS+
- C) Console avec mot de passe simple
- D) HTTP avec authentification RADIUS

<details>
<summary>Reponse</summary>

**B** — SSH v2 chiffre l'integralite de la session (contrairement a Telnet qui transmet en clair). TACACS+ centralise l'authentification et offre un chiffrement complet du payload ainsi qu'une granularite par commande pour l'autorisation. C'est la combinaison recommandee pour l'administration CLI securisee.

- A) ❌ Telnet transmet les identifiants en clair sur le reseau, vulnerabilite majeure
- B) ✅ SSH v2 (chiffrement du transport) + TACACS+ (authentification centralisee, autorisation par commande) = meilleure securite CLI
- C) ❌ L'acces console est local uniquement et un mot de passe simple est faible (pas de nom d'utilisateur, pas de chiffrement)
- D) ❌ HTTP est non chiffre (il faudrait HTTPS), et RADIUS est moins granulaire que TACACS+ pour l'administration CLI

</details>

---

**Q18.** Voici un extrait de la table de routage d'un routeur :

```
Gateway of last resort is 10.0.0.1 to network 0.0.0.0

     10.0.0.0/8 is variably subnetted, 4 subnets, 2 masks
C       10.0.0.0/30 is directly connected, GigabitEthernet0/0
O       10.1.0.0/24 [110/20] via 10.0.0.1, 00:15:32, GigabitEthernet0/0
S       10.2.0.0/16 [1/0] via 10.0.0.1
S*      0.0.0.0/0 [1/0] via 10.0.0.1
```

Que signifie `[110/20]` sur la route OSPF ? _(Topic 3.1)_

- A) 110 est la metrique OSPF et 20 est la distance administrative
- B) 110 est la distance administrative OSPF et 20 est la metrique (cout)
- C) 110 est le numero de processus OSPF et 20 le cout du lien
- D) 110 est le numero AS et 20 le nombre de sauts

<details>
<summary>Reponse</summary>

**B** — Dans la notation `[AD/metrique]`, le premier nombre est la distance administrative (AD) et le second est la metrique. OSPF a une AD par defaut de 110. La metrique 20 represente le cout OSPF cumule pour atteindre le reseau 10.1.0.0/24. Plus l'AD est basse, plus la source de routage est de confiance.

- A) ❌ C'est l'inverse : le premier chiffre est l'AD, le second la metrique
- B) ✅ [110/20] = AD 110 (OSPF par defaut) / metrique 20 (cout OSPF)
- C) ❌ Le numero de processus OSPF n'apparait pas dans la table de routage
- D) ❌ OSPF n'utilise pas de numero AS (c'est BGP) et ne mesure pas en sauts (c'est RIP)

</details>

---

**Q19.** Un routeur recoit un paquet destine a 172.16.5.130. Sa table de routage contient les entrees suivantes :

```
S    172.16.0.0/16 via 10.0.0.1
O    172.16.4.0/22 via 10.0.0.2
O    172.16.5.0/24 via 10.0.0.3
S    172.16.5.128/26 via 10.0.0.4
```

Vers quel next-hop le paquet sera-t-il envoye ? _(Topic 3.2)_

- A) 10.0.0.1
- B) 10.0.0.2
- C) 10.0.0.3
- D) 10.0.0.4

<details>
<summary>Reponse</summary>

**D** — Le routeur applique la regle du **longest prefix match** : il choisit la route avec le prefixe le plus specifique (le plus long) qui correspond a l'adresse de destination. Verifions :

- 172.16.0.0/16 → correspond (172.16.x.x) — prefixe /16
- 172.16.4.0/22 → couvre 172.16.4.0 a 172.16.7.255 — correspond — prefixe /22
- 172.16.5.0/24 → couvre 172.16.5.0 a 172.16.5.255 — correspond — prefixe /24
- 172.16.5.128/26 → couvre 172.16.5.128 a 172.16.5.191 — 130 est dans cette plage — prefixe /26

Le prefixe /26 est le plus long : le paquet est envoye vers 10.0.0.4.

- A) ❌ /16 correspond mais c'est le prefixe le moins specifique
- B) ❌ /22 correspond mais /26 est plus specifique
- C) ❌ /24 correspond mais /26 est plus specifique
- D) ✅ /26 est le longest prefix match — le paquet va vers 10.0.0.4

</details>

---

**Q20.** Un administrateur configure une route statique flottante. A quoi sert-elle ? _(Topic 3.3)_

- A) A distribuer le trafic equitablement sur deux liens (load balancing)
- B) A fournir une route de secours qui ne s'active que si la route principale tombe
- C) A forcer le trafic a passer par un chemin specifique, independamment des protocoles de routage
- D) A permettre le routage inter-VLAN sans switch L3

<details>
<summary>Reponse</summary>

**B** — Une route statique flottante est une route statique configuree avec une distance administrative superieure a celle du protocole de routage principal (par exemple AD 130 pour une backup d'OSPF qui a AD 110). Elle reste "cachee" dans la configuration tant que la route principale est active. Si la route principale disparait, la route flottante est installee dans la table de routage.

- A) ❌ Le load balancing necessite deux routes avec la meme AD et la meme metrique, pas une floating static
- B) ✅ La floating static route a une AD plus elevee, elle ne s'active que quand la route preferee disparait
- C) ❌ C'est le role d'une route statique classique (AD 1), pas specifiquement d'une flottante
- D) ❌ Le routage inter-VLAN necessite un routeur ou un switch L3, pas une route flottante

</details>

---

**Q21.** Dans OSPF single-area, quel type de reseau utilise une election DR/BDR et pourquoi ? _(Topic 3.4)_

- A) Point-to-point — pour reduire le nombre de LSA echangees entre deux routeurs
- B) Broadcast (multi-access) — pour reduire le nombre d'adjacences et optimiser la distribution des LSA
- C) Point-to-multipoint — pour gerer les reseaux NBMA
- D) Virtual-link — pour connecter une area non directement reliee a l'area 0

<details>
<summary>Reponse</summary>

**B** — Sur un reseau broadcast multi-access (comme un segment Ethernet), sans DR/BDR, chaque routeur devrait former une adjacence OSPF complete avec tous les autres, soit n(n-1)/2 adjacences. Le DR (Designated Router) et le BDR (Backup DR) centralisent la collecte et la redistribution des LSA, reduisant les adjacences a n-1 et le nombre de paquets OSPF echanges.

- A) ❌ Un reseau point-to-point n'a que deux routeurs, pas besoin de DR/BDR — l'adjacence est directe
- B) ✅ Broadcast multi-access necessite DR/BDR pour eviter une explosion combinatoire d'adjacences
- C) ❌ Point-to-multipoint traite chaque voisin comme un lien point-to-point, pas d'election DR/BDR
- D) ❌ Virtual-link est un mecanisme pour connecter une area a l'area 0, pas un type de reseau avec DR/BDR

</details>

---

**Q22.** **Scenario inter-modules :** Un administrateur configure un reseau avec 3 VLANs (10, 20, 30) et utilise un routeur-on-a-stick pour le routage inter-VLAN. Chaque VLAN a un sous-reseau /24 (192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24). Le lien entre le switch et le routeur est un trunk 802.1Q. Voici un extrait de la configuration du routeur :

```
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
```

Un PC dans le VLAN 10 (192.168.10.50) ne parvient pas a joindre un serveur dans le VLAN 20 (192.168.20.100). Le ping vers 192.168.10.1 fonctionne. Quelle est la cause la plus probable ? _(Topics 2.1 + 2.2 + 3.1)_

- A) L'interface physique GigabitEthernet0/0 est en etat shutdown
- B) Le VLAN 20 n'est pas autorise sur le trunk entre le switch et le routeur
- C) Le PC n'a pas de passerelle par defaut configuree
- D) Le routeur n'a pas de route OSPF vers le reseau 192.168.20.0/24

<details>
<summary>Reponse</summary>

**B** — Le PC peut joindre sa passerelle (192.168.10.1), donc la connectivite L2 du VLAN 10 et la sous-interface du routeur fonctionnent. L'interface physique n'est pas down (reponse A eliminee). Puisque le PC ping sa gateway, il a bien une passerelle configuree (reponse C eliminee). Les sous-reseaux sont directement connectes au routeur (routes C), pas besoin d'OSPF (reponse D eliminee). La cause probable est que le VLAN 20 n'est pas autorise sur le trunk, empechant le trafic tague VLAN 20 de transiter.

- A) ❌ Si Gi0/0 etait shutdown, le ping vers 192.168.10.1 echouerait aussi
- B) ✅ Si `allowed vlan` sur le trunk exclut le VLAN 20, le trafic de retour du routeur vers le VLAN 20 est bloque
- C) ❌ Le ping vers la passerelle 192.168.10.1 fonctionne, donc la passerelle par defaut est configuree
- D) ❌ Les sous-reseaux sont directement connectes via les sous-interfaces, les routes sont automatiquement dans la table

</details>

---

**Q23.** **Scenario inter-modules :** Un reseau comporte deux switches interconnectes par deux liens physiques. STP bloque l'un des liens pour eviter une boucle. L'administrateur souhaite utiliser les deux liens simultanement tout en maintenant la protection contre les boucles. Quelle solution doit-il mettre en place ? _(Topics 2.4 + 2.5)_

- A) Desactiver STP sur les deux switches
- B) Configurer un EtherChannel (LACP) entre les deux switches
- C) Configurer PortFast sur les deux ports inter-switch
- D) Changer le cout STP pour equilibrer le trafic sur les deux liens

<details>
<summary>Reponse</summary>

**B** — L'EtherChannel (via LACP) agrege les deux liens physiques en un seul lien logique. STP voit alors un seul lien et ne bloque plus. Les deux liens sont actifs, offrant le double de bande passante et une redondance. Si un lien physique tombe, l'EtherChannel continue de fonctionner avec le lien restant.

- A) ❌ Desactiver STP provoquerait des boucles de couche 2 catastrophiques (broadcast storms)
- B) ✅ EtherChannel/LACP agrege les liens en un lien logique unique — STP ne bloque plus, les deux liens sont actifs
- C) ❌ PortFast est destine aux ports d'acces vers les hotes, pas aux liens inter-switch — cela pourrait creer des boucles
- D) ❌ Modifier le cout STP pourrait changer quel lien est bloque, mais pas activer les deux simultanement

</details>

---

**Q24.** Un reseau utilise HSRP pour assurer la redondance de la passerelle par defaut. Le routeur actif tombe en panne. Que se passe-t-il ? _(Topic 3.5)_

- A) Les hotes doivent reconfigurer manuellement leur passerelle par defaut
- B) Le routeur standby prend le relais et repond a l'adresse IP virtuelle, la transition est transparente pour les hotes
- C) Le switch detecte la panne et redirige le trafic via STP
- D) Le protocole ARP met a jour automatiquement les caches des hotes avec la nouvelle adresse MAC physique

<details>
<summary>Reponse</summary>

**B** — HSRP (Hot Standby Router Protocol) cree une adresse IP virtuelle partagee entre un routeur actif et un routeur standby. Les hotes configurent cette IP virtuelle comme passerelle par defaut. Quand le routeur actif tombe, le standby devient actif et repond a la meme IP virtuelle (et MAC virtuelle). La transition est transparente : les hotes n'ont rien a changer.

- A) ❌ C'est precisement ce que HSRP evite — aucune reconfiguration necessaire cote hote
- B) ✅ Le routeur standby prend le role actif, l'adresse IP/MAC virtuelle reste identique, transparence totale
- C) ❌ STP opere en couche 2 pour prevenir les boucles, il ne gere pas la redondance de passerelle L3
- D) ❌ HSRP utilise une adresse MAC virtuelle (0000.0c07.acXX), pas une MAC physique — les caches ARP restent valides

</details>

---

**Q25.** Un ingenieur reseau doit configurer OSPF sur un routeur. Voici la configuration :

```
router ospf 1
 router-id 1.1.1.1
 network 192.168.1.0 0.0.0.255 area 0
 network 10.0.0.0 0.0.0.3 area 0
```

Le voisin OSPF sur le lien 10.0.0.0/30 ne forme pas d'adjacence. La commande `show ip ospf neighbor` ne montre aucun voisin sur ce lien. Le lien est `up/up`, les deux routeurs sont dans l'area 0, et les reseaux sont correctement declares. Quelle verification l'ingenieur doit-il effectuer en priorite ? _(Topic 3.4)_

- A) Verifier que les timers Hello/Dead sont identiques des deux cotes
- B) Verifier que le VLAN est le meme des deux cotes
- C) Verifier que le routeur a une route statique vers le voisin
- D) Verifier que le spanning-tree n'est pas en mode blocking sur le port

<details>
<summary>Reponse</summary>

**A** — Quand un lien est up/up et que la configuration area/network semble correcte, les causes les plus frequentes d'echec d'adjacence OSPF sont : (1) mismatch des timers Hello/Dead, (2) mismatch du type de reseau (broadcast vs point-to-point), (3) MTU mismatch, (4) authentification incorrecte, (5) masque de sous-reseau different. Verifier les timers est la premiere etape de diagnostic.

- A) ✅ Un mismatch Hello/Dead empeche la formation d'adjacence OSPF — c'est une cause classique et la premiere chose a verifier
- B) ❌ Les VLANs sont un concept L2 entre switches. Sur un lien routeur-routeur point-to-point, c'est rarement la cause
- C) ❌ OSPF decouvre les routes dynamiquement, il n'a pas besoin de routes statiques pour former des adjacences
- D) ❌ Si le lien est up/up, STP n'est pas en cause (et STP concerne les switches, pas les routeurs)

</details>

---

## Resultats

Comptez le nombre de bonnes reponses sur 25 et evaluez votre niveau :

| Score | Pourcentage | Niveau |
|-------|-------------|--------|
| 23-25 | 90-100 % | Maitrise solide — Vous etes pret pour les modules suivants |
| 18-22 | 70-89 % | Bonne comprehension — Revisez les points faibles identifies |
| 13-17 | 50-69 % | Lacunes a combler — Reprenez les modules concernes avant de continuer |
| 0-12 | < 50 % | A retravailler — Revoyez en profondeur les modules 1 a 3 |

### Repartition par module

| Module | Questions | Votre score |
|--------|-----------|-------------|
| 1 — Network Fundamentals | Q1-Q9 | /9 |
| 2 — Network Access | Q10-Q17 | /8 |
| 3 — IP Connectivity | Q18-Q21, Q25 | /5 |
| Inter-modules | Q22-Q24 | /3 |
| **Total** | **25** | **/25** |
