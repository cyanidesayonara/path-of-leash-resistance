# Microsoft Store listing

The record of what the Store says, and the source the Store submit workflow
copies from. Live at https://apps.microsoft.com/detail/9p5d14v8rbqx (first
submission 1.54.0.0, 2026-09-23). "Current listing" is the text for the next
submission; the rest records how the product is set up in Partner Center.
Each release, step by step: docs/MICROSOFT_STORE.md, step 7.

Before a version is tagged, "What's new in this version" below must already
describe that version (everything since the last notes that went out), and
the walk counts and lists in the description must match the game. 1.65 and
1.66 went out with 1.64's notes because this was skipped.

## Current listing

What the Store should say for the next submission. The Store submit workflow
(`.github/workflows/store-submit.yml`, mode `update_draft`) writes every field
below into the Partner Center draft, so Partner Center always matches this
section; never edit these fields in Partner Center by hand. CI checks them
against the Store's limits (`tools/store_listing.py --check`). Lists are one
item per line. After a submission goes live, copy its What's new into "Past
What's new" with the date.

### Description

```
Your human is glued to their phone and walking on autopilot. You are on the other end of the leash. Get them home in one piece, with the phone intact, while sneaking in as much dog business as you can get away with.

The leash is real rope physics. Your human outweighs you four to one and wins every straight tug, so you win the way a dog does: dig in at the right moment, wind the leash around a lamppost to hold them fast, and bark to stop them dead at the curb. Wind them around a pole and keep pulling, and they whirl off it like a tetherball. Get the timing right as a bike whizzes past and it counts as a save.

Your human answers the leash like a person. A steady pull leads them where you want to go. Haul on them constantly and their patience runs out: a glance up from the phone, a mutter, then "Hey!" and a shorter leash. Walk nicely and the reel lets you out. Everything they are about to do, they announce first: "Ring ring!", "Ooh!". They are never smarter than that.

Seven dogs, each her own. Millie the mongrel has the best nose, Pipa the galgo sprints, Mochi the French bulldog plants like a tank, Bruna the sheepdog herds your human, Tito the chihuahua slips through gaps, Perla the ratonero digs anything up, and Duna the podenco clears a bench from standing. Each has a skill goal of her own on every walk. Sniff out the finds buried along the way and meet your skill goals to earn training, then spend it on her stats, a level at a time.

Fifty walks and a tutorial, in five chapters through a sunny, slightly chaotic Barcelona and beyond.
Chapter one, the neighborhood: El Barri's little park, La Rambla's crowds, the city park, Badalona's seafront, the old town alleys, Montjuïc, the market hall and a downpour, ending at La Ciutadella, where the stone mammoth steps off its plinth.
Chapter two, up and out: the dog beach at Llevant, the cut corners of L'Eixample, Tibidabo's fairground, the old village of Sarrià, a forest trail, the skate plaza at Els Àngels and the chestnut festival, ending in the mosaic park, where El Drac comes to life.
Chapter three, the long way across town: the car-free Superilla, rush hour on the metro and at the train station, the bunkers at sunset, Plaça Reial, Badalona's devil night, El Fòrum, La Diagonal and its tram, Carrer de Blai's pintxos, Collserola's water road, Gràcia's festival, Horta's cypress maze and La Molina's ski slopes, ending at the fishing harbor, where the bronze lions of El Port come down to meet you.
Chapter four, out along the coast: the fountains of Plaça d'Espanya, the gardens of Sant Pau, El Poble Espanyol, Sitges by the sea, the rides of Les Atraccions, the airport, a work site, and Camí de Ronda's cliff path.
Chapter five, all of it: match day, a junkyard, Montserrat, Els Encants's mirrored flea market, Tarragona's Roman walls and the foggy arcades of Vic, ending on the Rambla del Raval, where a fat bronze cat climbs down off his plinth.

Nine walks are chases: the dawn street sweeper, the river surge on El Besòs, the vet clinic's assistants with their cones of shame, the wild boars down Els Senglars, the correfoc's fire devils through Gràcia, the Dimoni's rolling firework float in La Cremada, airport security, La Molina's runaway snow groomer and Montserrat's wild goats.

Every walk ends off the leash, with tug-of-war, a frisbee and fetch, in a dog park, a dog beach, a clearing in the woods, a yard or a plaça with a fountain to jump in. There are pigeons to stalk, waves to outrun and squirrels to tree, and an agility course in El Barri.

What happens on a walk changes how you feel, and how you feel changes how you move. A fright leaves you jumpy and half blind to smells, a good bark-off makes you barky, time off the leash brings on the zoomies, and running yourself empty leaves you flat. The ground matters too: grass and mud slow you down but hold far more scent than sidewalk, sand drags at your paws, and wet ground and snow make you skid.

Other dogs have lives of their own. They sniff and mark the posts you pass, and you can read who was there; meet one and it comes over to say hello, unless it is the grumpy sort, who lunges and barks at the end of its leash. Their owners are people too: on a call, carrying a coffee, stopping to type.

Every walk has its own list of goals: sniff the good spots, mark your territory, fetch, greet other dogs, herd a runaway friend home, take on dares from the characters you meet (each with their own tune), and pull off tricks: swing around a pole on the leash, run a figure eight, thread the needle between two people, and ride ledges and handrails with the zoomies. Earn stars to unlock new walks and dogs, and bones to spend on collars, bandanas and coats.

Pick the sky and the hour for a walk: clear, breeze, fog, drizzle, downpour, storm, gale, snow or Sahara dust, from dawn to night. They change how it plays, and who is out.

In English, Catalan and Spanish. Screen shake and flashes can be turned off, text made larger, and every control rebound. There is a three-part tutorial for anyone new.

Single player. No ads, no purchases, no account, and it plays offline. Keyboard or controller.
```

### Short description

```
A dog walk as a physics comedy. Your human walks on autopilot, glued to their phone, and the leash is real rope. Dig in, wrap lampposts and bark your way through fifty walks in and around Barcelona with any of seven dogs, and get them home with the phone intact.
```

### Product features

```
The leash is real rope physics: wrap it around poles, dig in, win the tug of war
A human who answers the leash: a steady pull leads them, constant hauling runs out their patience
Fifty hand-built walks in and around Barcelona and a tutorial, in any weather, by day or at night
Seven dogs, each with a skill and a skill goal of her own
Buried finds to sniff out, and training to spend on her stats
Every walk ends off the leash, with agility, tug-of-war and a frisbee
Goal lists on every walk, with stars that unlock new walks
A dare-giver on every walk, each with their own tune
Leash tricks: pole swings, figure eights, threading the needle, ledge and handrail rides
Nine chase walks: the street sweeper, the river flood, the clinic escape, the wild boars, the correfoc, the Dimoni float, airport security, the runaway snow groomer and the mountain goats
Four statue boss fights: El Mamut the stone mammoth, Els Lleons the twin bronze lions, El Drac the mosaic salamander, and El Gat a bronze cat the size of a car
Dog moods: scared, barky, zoomies and flat, each changing how you move and what you notice
Ground you can feel: grass and mud hold scent, sand drags, wet ground and snow skid
Other dogs and their people with lives of their own: they sniff, mark, greet and tangle
Nine skies and six times of day that change how each walk plays
Bones to spend on collars, bandanas and coats
In English, Catalan and Spanish, with screen shake, flashes, text size and controls all adjustable
Full controller support, and a three-part tutorial for new players
No ads, no purchases, no account, and it plays offline
```

### Keywords

```
dog
leash
physics comedy
top-down
rope physics
Barcelona
dog walking
```

### What's new in this version

```
- Eight new walks, fifty in all: La Molina (our first snow walk, with a runaway snow groomer chase), Sant Pau, Sitges, Les Atraccions, Camí de Ronda, Els Encants, Tarragona and Vic.
- Two new dogs, seven in all: Perla the ratonero and Duna the podenco. Every dog now has a signature skill goal on every walk, buried finds to sniff out, training head starts and her own idle quirks and bark.
- Full Catalan and Spanish translation across menus, HUD and walks; a five-chapter walk select, paged YOUR WALKS and a Credits screen.
- Calima (Sahara dust), nine skies and six times of day in all, real wind gusts you can dig in against, and accessibility settings (screen shake, flashes, text size, remappable controls).
- Rebuilt chase films and walk threats (El Besòs's looming flood shade, barrel and tumbling furniture, charging Montserrat goats, La Molina's snowballs, L'Aeroport's dog crate, La Neteja's glaring sweeper, and boss threat displays), your human acting in films, smoother cross-walk drawing, and touch-stick menu navigation.
```

### Notes for certification

```
Update 1.76: eight new walks (50 total), two new dogs (Perla and Duna) with signature skills, buried finds and training head starts, Catalan/Spanish localization, calima sky and wind gusts, accessibility settings, chase/film threat polish, world draw performance, and touch-stick menu navigation. Update 1.74: El Drac serpentine bench and El Gat café awnings, El Gòtic retractable bollards, El Besòs riverside props, boss/near-miss camera tricks, late-campaign chase spacing, Montserrat chase fixes, NPC rig upgrades, La Rambla/La Diagonal caching, and Android readiness. Update 1.73: three new walks (La Diagonal, L'Aeroport, Montserrat), two statue bosses (Els Lleons, El Drac), boss arenas, off-leash games, riders/NPC overhaul, Barcelona pilones/panots, chases rebuilt, tug of war reworked. No change to capabilities, network use or data handling since 1.55.

Path of Leash Resistance is a single-player Win32 desktop game built with the Godot engine (4.7), packaged as MSIX.

runFullTrust: required to run the packaged Win32 game executable. The game uses no other restricted capabilities, no network access, no accounts and no in-app purchases.

How to test: launch the game; any key skips the short intro. On the main menu choose PLAY with Space (or A on a controller), then pick a walk and press Space again. Move with WASD/arrows or the left stick; hold Space/A to dig in against the leash, E/B to bark, Q/X to mark a spot, Shift for the zoomies. A walk takes about two minutes. Esc/Back opens the pause menu and goes back from any menu.

Graphics: the game renders with OpenGL 3.3, and falls back automatically to Direct3D 11 through ANGLE on machines without OpenGL 3.3 drivers.

Saves and settings are stored locally in the app's own data folder. No sign-in or test account is needed.
```

## Current listing (ca-ES)

### Description

```
El teu humà va enganxat al mòbil i camina amb el pilot automàtic. Tu ets a l'altre cap de la corretja. Porta'l a casa d'una peça, amb el mòbil intacte, mentre aprofites per fer tants assumptes de gos com puguis.

La corretja té física real de corda. El teu humà pesa quatre cops més que tu i guanya totes les estrebades directes, així que guanyes com ho fa un gos: planta't en el moment just, enrotlla la corretja al voltant d'un fanal per frenar-lo en sec i borda per aturar-lo a la vorera. Enrotlla'l a un pal i continua estirant, i sortirà voltant com una pilota lligada. Calcula bé el temps quan passi una bici a tota velocitat i comptarà com a salvada.

El teu humà respon a la corretja com una persona. Una estirada constant el guia cap on vols anar. Si l'estires sense parar, se li acaba la paciència: aixeca la vista del mòbil, rondina i després et diu «Ei!» amb una corretja més curta. Camina bé i el rodet et donarà més corda. Tot el que farà, ho avisa abans: «Ring, ring!», «Oh!». No dona per a gaire més.

Set gossos, cadascun amb el seu caràcter. La Millie, mestissa, té el millor nas; la Pipa, una llebrera, és la més ràpida; la Mochi, una bulldog francesa, es planta com un tanc; la Bruna, una gossa d'atura, guia el teu humà; el Tito, un chihuahua, s'escola per tot arreu; la Perla, una ratonera, ho desenterra tot; i la Duna, una podenca, salta un banc sense agafar carrerilla. Cadascun té la seva pròpia fita d'habilitat a cada passeig. Ensuma els tresors enterrats pel camí i compleix les fites d'habilitat per guanyar entrenament, i gasta'l en les seves qualitats, nivell a nivell.

Cinquanta passejos i un tutorial, en cinc capítols per una Barcelona assolellada, una mica caòtica, i més enllà.
Capítol u, el barri: el parquet d'El Barri, les gentades de La Rambla, el parc de la ciutat, el passeig marítim de Badalona, els carrerons del barri vell, Montjuïc, el mercat cobert i un xàfec, i per acabar La Ciutadella, on el mamut de pedra baixa del seu pedestal.
Capítol dos, amunt i enfora: la platja per a gossos de Llevant, els xamfrans de L'Eixample, la fira del Tibidabo, l'antic poble de Sarrià, un sender pel bosc, la plaça de patinadors d'Els Àngels i la castanyada, i per acabar el parc del mosaic, on El Drac cobra vida.
Capítol tres, la volta llarga per la ciutat: La Superilla sense cotxes, l'hora punta al metro i a l'estació de tren, els búnquers a la posta, la Plaça Reial, la nit del Dimoni a Badalona, El Fòrum, la Diagonal i el seu tramvia, els pintxos del Carrer de Blai, el camí de les aigües per Collserola, la festa de Gràcia, el laberint d'Horta i les pistes de La Molina, i per acabar el port pesquer, on els lleons de bronze d'El Port baixen a rebre't.
Capítol quatre, sortint per la costa: les fonts de Plaça d'Espanya, els jardins de Sant Pau, El Poble Espanyol, Sitges vora el mar, les atraccions de Les Atraccions, l'aeroport, unes obres i el camí de ronda.
Capítol cinc, tot plegat: dia de partit, un desballestament, Montserrat, el mercat sota el mirall d'Els Encants, les muralles romanes de Tarragona i els porxos amb boira de Vic, i per acabar la Rambla del Raval, on un gat gros de bronze baixa del seu pedestal.

Nou passejos són persecucions: l'escombradora de trenc d'alba, la crescuda del riu a El Besòs, els ajudants de la clínica amb els seus cons de la vergonya, els senglars d'Els Senglars, els diables del correfoc per Gràcia, la carrossa de focs del Dimoni a La Cremada, la seguretat de l'aeroport, la trepitjaneu desbocada de La Molina i les cabres salvatges de Montserrat.

Cada passeig acaba sense corretja, amb estira-i-arronsa, frisbi i pilota, en un pipicà, una platja de gossos, una clariana al bosc, un pati o una plaça amb font on capbussar-se. Hi ha coloms per empaitar, onades per esquivar i esquirols per fer pujar als arbres, i un circuit d'agilitat a El Barri.

El que passa al passeig canvia com et sents, i com et sents canvia com et mous. Un ensurt et deixa nerviós i mig cec a les olors, una bona sessió de bordar et posa bordador, l'estona sense corretja et porta la bogeria i esgotar-te et deixa fet pols. El terra també compta: la gespa i el fang t'alenteixen però guarden molta més olor que la vorera, la sorra s'enfonsa sota les potes i el terra mullat i la neu et fan relliscar.

Els altres gossos tenen vida pròpia. Ensumen i marquen els pals per on passes i pots llegir qui hi ha estat; si et creues amb un, s'acosta a saludar, llevat que sigui dels rondinaires, que es llancen i borden al cap de la corretja. Els seus humans també fan la seva: parlen per telèfon, porten un cafè, s'aturen a escriure.

Cada passeig té la seva llista de fites: ensumar els bons racons, marcar el territori, tornar la pilota, saludar altres gossos, fer tornar a casa una amiga escapada, acceptar reptes dels personatges que trobes (cadascun amb la seva melodia) i clavar trucs: fer la volta a un pal amb la corretja, dibuixar un vuit, passar pel mig de dues persones i lliscar per vores i baranes amb la bogeria. Guanya estrelles per obrir nous passejos i gossos, i ossos per gastar en collars, mocadors i pelatges.

Tria el cel i l'hora de cada passeig: serè, brisa, boira, plugim, xàfec, tempesta, ventada, neu o pols del Sàhara, de l'alba a la nit. Canvien com es juga i qui hi ha pel carrer.

En anglès, català i castellà. Pots desactivar la vibració de pantalla i els flaixos, fer el text més gran i canviar tots els controls. Hi ha un tutorial en tres parts per a qui comenci de nou.

Un jugador. Sense anuncis, sense compres, sense compte, i funciona sense connexió. Teclat o comandament.
```

### Short description

```
Un passeig de gos en clau de comèdia física. El teu humà camina amb el pilot automàtic, enganxat al mòbil, i la corretja és corda de veritat. Planta't, enrotlla fanals i borda al llarg de cinquanta passejos per Barcelona i els voltants amb qualsevol dels set gossos, i torna'l a casa amb el mòbil intacte.
```

### Product features

```
La corretja té física real de corda: enrotlla-la als pals, planta't i guanya l'estira-i-arronsa
Un humà que respon a la corretja: una estirada constant el guia, estirar sense parar li esgota la paciència
Cinquanta passejos fets a mà per Barcelona i els voltants i un tutorial, faci el temps que faci, de dia o de nit
Set gossos, cadascun amb la seva habilitat i la seva fita d'habilitat
Tresors enterrats per ensumar, i entrenament per gastar en les seves qualitats
Cada passeig acaba sense corretja, amb agilitat, estira-i-arronsa i frisbi
Llista de fites a cada passeig, amb estrelles que obren nous passejos
Un personatge amb reptes a cada passeig, cadascun amb la seva melodia
Trucs de corretja: voltes a pals, vuits, passar entre dues persones i lliscar per vores i baranes
Nou passejos de persecució: l'escombradora, la riuada, la clínica, els senglars, el correfoc, la carrossa del Dimoni, la seguretat de l'aeroport, la trepitjaneu desbocada i les cabres de muntanya
Quatre caps estàtua: El Mamut de pedra, Els Lleons de bronze, El Drac de trencadís i El Gat, un gat de bronze de la mida d'un cotxe
Estats d'ànim del gos: por, bordades, bogeria i cansament, que canvien com et mous i què notes
Terra que se sent: la gespa i el fang guarden l'olor, la sorra frena i el terra mullat i la neu fan relliscar
Altres gossos i els seus humans amb vida pròpia: ensumen, marquen, saluden i s'emboliquen
Nou cels i sis hores del dia que canvien com es juga cada passeig
Ossos per gastar en collars, mocadors i pelatges
En anglès, català i castellà, amb la vibració de pantalla, els flaixos, la mida del text i els controls ajustables
Compatibilitat total amb comandament, i un tutorial en tres parts per a nous jugadors
Sense anuncis, sense compres, sense compte, i funciona sense connexió
```

### Keywords

```
gos
corretja
comèdia física
vista zenital
física de cordes
Barcelona
passejar gossos
```

### What's new in this version

```
- Vuit nous passejos, cinquanta en total: La Molina (el primer passeig amb neu i una trepitjaneu desbocada), Sant Pau, Sitges, Les Atraccions, Camí de Ronda, Els Encants, Tarragona i Vic.
- Dos nous gossos, set en total: la Perla, una ratonera, i la Duna, una podenca. Ara cada gos té una fita d'habilitat pròpia a cada passeig, tresors enterrats per ensumar, avantatge inicial d'entrenament i els seus propis gestos i lladrucs.
- Traducció completa al català i al castellà als menús, la interfície i els passejos; selecció en cinc capítols, ELS TEUS PASSEJOS paginat i pantalla de crèdits.
- Calitja (pols del Sàhara), nou cels i sis hores del dia en total, ratxes de vent reals contra les quals plantar-se i ajustos d'accessibilitat (vibració, flaixos, mida de text, controls reconfigurables).
- Pel·lícules i amenaces de persecució refetes (l'ombra de la riuada, el barril i els bancs rodolant a El Besòs, cabres envestint a Montserrat, boles de neu a La Molina, caixa de gos a L'Aeroport, mirada de l'escombradora a La Neteja i gestos dels caps), el teu humà actuant a les pel·lícules, dibuix més lleuger i navegació pels menús amb el stick tàctil.
```

## Current listing (es-ES)

### Description

```
Tu humano va pegado al móvil y camina con el piloto automático. Tú estás al otro lado de la correa. Llévalo a casa de una pieza, con el móvil intacto, mientras aprovechas para hacer tantos asuntos de perro como puedas.

La correa tiene física real de cuerda. Tu humano pesa cuatro veces más que tú y gana todos los tirones directos, así que ganas como lo hace un perro: plántate en el momento justo, enrolla la correa alrededor de una farola para frenarlo en seco y ladra para pararlo en el bordillo. Enróllalo en un poste y sigue tirando, y saldrá dando vueltas como una pelota atada. Calcula bien el momento cuando pase una bici a toda velocidad y contará como una salvada.

Tu humano responde a la correa como una persona. Un tirón constante lo guía adonde quieres ir. Si tiras sin parar, se le acaba la paciencia: levanta la vista del móvil, refunfuña y luego suelta un «¡Oye!» con una correa más corta. Camina bien y el carrete te dará más cuerda. Todo lo que va a hacer, lo avisa antes: «¡Ring, ring!», «¡Oh!». No da para mucho más.

Siete perros, cada uno con su carácter. Millie, una mestiza, tiene el mejor olfato; Pipa, una galga, es la más rápida; Mochi, una bulldog francesa, se planta como un tanque; Bruna, una gos d'atura, guía a tu humano; Tito, un chihuahua, se cuela por todas partes; Perla, una ratonera, lo desentierra todo; y Duna, una podenca, salta un banco sin coger carrerilla. Cada uno tiene su propia meta de habilidad en cada paseo. Olfatea los tesoros enterrados por el camino y cumple tus metas de habilidad para ganar entrenamiento, y gástalo en sus cualidades, nivel a nivel.

Cincuenta paseos y un tutorial, en cinco capítulos por una Barcelona soleada, algo caótica, y más allá.
Capítulo uno, el barrio: el parquecito de El Barri, el gentío de La Rambla, el parque de la ciudad, el paseo marítimo de Badalona, los callejones del casco antiguo, Montjuïc, el mercado cubierto y un chaparrón, y para acabar La Ciutadella, donde el mamut de piedra baja de su pedestal.
Capítulo dos, arriba y afuera: la playa para perros de Llevant, los chaflanes de L'Eixample, la feria del Tibidabo, el antiguo pueblo de Sarrià, un sendero por el bosque, la plaza de skaters de Els Àngels y la castañada, y para acabar el parque del mosaico, donde El Drac cobra vida.
Capítulo tres, la vuelta larga por la ciudad: La Superilla sin coches, la hora punta en el metro y en la estación de tren, los búnkeres al atardecer, la Plaça Reial, la noche del Dimoni en Badalona, El Fòrum, la Diagonal y su tranvía, los pintxos del Carrer de Blai, la carretera de las aguas por Collserola, la fiesta de Gràcia, el laberinto de Horta y las pistas de La Molina, y para acabar el puerto pesquero, donde los leones de bronce de El Port bajan a recibirte.
Capítulo cuatro, saliendo por la costa: las fuentes de Plaça d'Espanya, los jardines de Sant Pau, El Poble Espanyol, Sitges junto al mar, las atracciones de Les Atraccions, el aeropuerto, unas obras y el camino de ronda.
Capítulo cinco, todo junto: día de partido, un desguace, Montserrat, el mercado bajo el espejo de Els Encants, las murallas romanas de Tarragona y los porches con niebla de Vic, y para acabar la Rambla del Raval, donde un gato gordo de bronce baja de su pedestal.

Nueve paseos son persecuciones: la barredora del amanecer, la crecida del río en El Besòs, los ayudantes de la clínica con sus conos de la vergüenza, los jabalíes de Els Senglars, los diablos del correfoc por Gràcia, la carroza de fuegos del Dimoni en La Cremada, la seguridad del aeropuerto, la pisanieves desbocada de La Molina y las cabras salvajes de Montserrat.

Cada paseo acaba sin correa, con tira y afloja, frisbi y pelota, en un pipicán, una playa para perros, un claro en el bosque, un patio o una plaza con fuente donde zambullirse. Hay palomas que acechar, olas que esquivar y ardillas que hacer subir a los árboles, y un circuito de agility en El Barri.

Lo que ocurre en el paseo cambia cómo te sientes, y cómo te sientes cambia cómo te mueves. Un susto te deja nervioso y medio ciego a los olores, una buena tanda de ladridos te pone ladrador, el rato sin correa te trae la locura y vaciarte corriendo te deja agotado. El suelo también importa: el césped y el barro te frenan pero guardan mucho más olor que la acera, la arena te lastra las patas y el suelo mojado y la nieve te hacen patinar.

Los otros perros tienen vida propia. Olfatean y marcan los postes por los que pasas y puedes leer quién estuvo allí; si te cruzas con uno, se acerca a saludar, salvo que sea de los gruñones, que se lanzan y ladran al final de la correa. Sus humanos también van a lo suyo: hablan por teléfono, llevan un café, se paran a escribir.

Cada paseo tiene su lista de metas: olfatear los buenos rincones, marcar tu territorio, traer la pelota, saludar a otros perros, llevar a casa a una amiga escapada, aceptar retos de los personajes que encuentras (cada uno con su melodía) y clavar trucos: girar alrededor de un poste con la correa, trazar un ocho, pasar entre dos personas y deslizarte por bordillos y barandillas con la locura. Gana estrellas para abrir nuevos paseos y perros, y huesos para gastar en collares, pañuelos y pelajes.

Elige el cielo y la hora de cada paseo: despejado, brisa, niebla, llovizna, chaparrón, tormenta, vendaval, nieve o polvo del Sáhara, del alba a la noche. Cambian cómo se juega y quién hay por la calle.

En inglés, catalán y castellano. Puedes desactivar las sacudidas de pantalla y los destellos, agrandar el texto y cambiar todos los controles. Hay un tutorial en tres partes para quien empiece de cero.

Un jugador. Sin anuncios, sin compras, sin cuenta, y funciona sin conexión. Teclado o mando.
```

### Short description

```
Un paseo de perro en clave de comedia física. Tu humano camina en piloto automático, pegado al móvil, y la correa es cuerda de verdad. Plántate, rodea farolas y ladra a lo largo de cincuenta paseos por Barcelona y sus alrededores con cualquiera de los siete perros, y llévalo a casa con el móvil intacto.
```

### Product features

```
La correa tiene física real de cuerda: enróllala en postes, plántate y gana el tira y afloja
Un humano que responde a la correa: un tirón constante lo guía, tirar sin parar le agota la paciencia
Cincuenta paseos hechos a mano por Barcelona y alrededores y un tutorial, haga el tiempo que haga, de día o de noche
Siete perros, cada uno con su habilidad y su meta de habilidad
Tesoros enterrados que olfatear, y entrenamiento para gastar en sus cualidades
Cada paseo acaba sin correa, con agilidad, tira y afloja y frisbi
Listas de metas en cada paseo, con estrellas que desbloquean nuevos paseos
Un personaje con retos en cada paseo, cada uno con su melodía
Trucos de correa: giros en postes, ochos, pasar entre dos personas y deslizarse por bordillos y barandillas
Nueve paseos de persecución: la barredora, la riada, la clínica, los jabalíes, el correfoc, la carroza del Dimoni, la seguridad del aeropuerto, la pisanieves desbocada y las cabras de montaña
Cuatro jefes estatua: El Mamut de piedra, Els Lleons de bronce, El Drac de trencadís y El Gat, un gato de bronce del tamaño de un coche
Estados de ánimo del perro: miedo, ladridos, locura y cansancio, que cambian cómo te mueves y qué percibes
Suelo que se siente: el césped y el barro guardan el olor, la arena frena y el suelo mojado y la nieve hacen patinar
Otros perros y sus humanos con vida propia: olfatean, marcan, saludan y se enredan
Nueve cielos y seis horas del día que cambian cómo se juega cada paseo
Huesos para gastar en collares, bandanas y pelajes
En inglés, catalán y castellano, con sacudidas de pantalla, destellos, tamaño del texto y controles ajustables
Compatibilidad total con mando, y un tutorial en tres partes para nuevos jugadores
Sin anuncios, sin compras, sin cuenta, y funciona sin conexión
```

### Keywords

```
perro
correa
comedia física
vista cenital
física de cuerdas
Barcelona
pasear perros
```

### What's new in this version

```
- Ocho nuevos paseos, cincuenta en total: La Molina (el primer paseo con nieve y una pisanieves desbocada), Sant Pau, Sitges, Les Atraccions, Camí de Ronda, Els Encants, Tarragona y Vic.
- Dos nuevos perros, siete en total: Perla, una ratonera, y Duna, una podenca. Cada perro tiene su propia meta de habilidad en cada paseo, tesoros enterrados que olfatear, ventaja inicial de entrenamiento y sus propios gestos y ladridos.
- Traducción completa al catalán y al castellano en menús, interfaz y paseos; selección en cinco capítulos, TUS PASEOS paginado y pantalla de Créditos.
- Calima (polvo del Sáhara), nueve cielos y seis horas del día, rachas de viento reales contra las que plantarse y ajustes de accesibilidad (sacudida de pantalla, destellos, tamaño de texto, controles reconfigurables).
- Películas y amenazas de persecución rehechas (la sombra de la riada, el barril y bancos rodando en El Besòs, cabras embistiendo en Montserrat, bolas de nieve en La Molina, transportín en L'Aeroport, mirada de la barredora en La Neteja y despliegues de los jefes), tu humano actuando en las películas, dibujo más ligero y navegación por los menús con el stick táctil.
```

## Properties

- Category: Games. Genres: Action + adventure, Family + kids.
- Privacy: collects no personal information. Policy text: see "Privacy
  policy" below.
- Product declarations: alternate drives on, OneDrive backup on, Game Bar
  recording on; everything else off. Accessibility stays off until there has
  been a real accessibility pass (remappable controls, #9).
- System requirements: Keyboard minimum, Xbox controller recommended,
  DirectX 11 minimum. Touch screen off: touch controls are untested on
  Windows. Memory, video memory and processor left unspecified (unmeasured).

## Age ratings

IARC questionnaire answered for this game (not imported). Result: ESRB E
(Mild Violence, Crude Humor), PEGI 3, USK 6, ACB PG, IARC 3+, Microsoft 3+.

Lessons from the first attempt:

- Never import another product's IARC ID (stemma's was offered first). A
  certificate belongs to one product.
- "Can innocent or defenseless characters be seriously injured or killed?"
  is **No**. The sweeper game-over is a joke card, and nothing is shown or
  said to be injured. Answering yes produced PEGI 16 / Strong Violence.
- "Violence against real-world animals" is **Yes** (the dog is a real
  species that gets knocked over). It is what makes Russia 16+.

## Packages and device families

Windows 10/11 Desktop only. "Let Microsoft decide future device families"
off. Xbox off: a full-trust Win32 package cannot run there.

## Store listing (English, United States)

Screenshots and logos are regenerated, not stored here:

- Screenshots: 1920x1080 from the shipped build via
  `--shot --shot-at=N --autowalk --fixed-fps 60 --resolution 1920x1080`
  (see `docs/MICROSOFT_STORE.md` step 5). First set: station, beach, market,
  park, street in snow, spook, old town, trail. 1.55 added El Mosaic
  (`--level=guell --shot-at=3100`, with `tools/stamp_version.sh` run first so
  the corner says the version, not "dev"), captioned "El Mosaic: the winding
  terrace and its broken-tile mosaic". 1.57 replaces the set with the
  rebuilt walks, and 1.60 and 1.71 replace it again (the current set is
  "Screenshots for 1.71" below). The chase can be shot
  since #20 (`--level=neteja --shot-y=-4300 --shot-home --shot-sweeper`),
  and pick frames where no two feed lines overlap.
- Logos: `tools/make_store_art.gd` writes the 9:16 poster (1440x2160), 1:1
  box art (2160) and the 300/150/71 tiles into `build/store-art/`. No hero
  art, trailers or Xbox images.

### Screenshots for 1.71

Ten 1920x1080 images from a checkout of the v1.71 tag
(`tools/stamp_version.sh` first, so the corner reads v1.71), uploaded in this
order with these captions:

1. Festa de Gràcia: the correfoc's dragon and fire devils, and a head start
   home
   (`--level=gracia --shot-y=-2000 --shot-home --shot-sweeper --shot-at=170`)
2. Rambla del Raval: El Gat charges, and the leash is the answer
   (`--resolution 1920x1080 --script res://tools/boss_shots.gd -- --no-films`, its
   `06_charge_run.png`; the waking shot showed his title card, which named a sculptor)
3. Plaça d'Espanya: the cascade, lit up at night
   (`--level=espanya --shot-y=-3800 --shot-at=300`)
4. La Neteja: the street sweeper at first light, coming your way
   (`--level=neteja --shot-y=-4300 --shot-home --shot-sweeper --shot-at=200`)
5. L'Eixample: cut corners, a planter, and a dare on the bench
   (`--level=eixample --shot-y=-1200 --shot-at=300`)
6. El Parc: a swim in the pond, leash and all
   (`--level=park --shot-y=-2600 --shot-at=300`)
7. El Barri: off the leash, with an agility course and fetch
   (`--level=barri --at-freedom --autowalk --fixed-fps 60 --shot-at=300`)
8. El Poble Espanyol: the village square, dressed for a festa
   (`--level=poble --shot-y=-2000 --shot-at=300`)
9. Els Àngels: the skate plaza outside the white museum
   (`--level=angels --shot-y=-2600 --shot-at=420`)
10. Els Búnquers: sunset on the path up the hill
    (`--level=carmel --shot-y=-1200 --shot-at=300`)

All with `--rendering-method gl_compatibility --resolution 1920x1080` and
`-- --shot --shot-quit --shot-out=FILE`. A `--shot-y` shot needs
`--shot-at=300` or so: sooner, the menu's prompt bar is still fading out. A
chase shot (`--shot-home --shot-sweeper`) is the exception: by frame 300 the
shout and the threat have moved on, so take it at 170-200. The El Barri shot
uses `--autowalk`, which is not frame-exact, so take a few and keep one with
the agility course in view.

Shoot from a fresh profile. The saved settings carry the goal list's open or
closed state (`goals_expanded`), and an open list covers a third of the
frame. Pointing `APPDATA` at an empty folder for the run gives the defaults
without touching the real records:
`APPDATA=$PWD/build/appdata godot ... -- --shot ...`. A fresh profile can show
the first-time question on some frames; skip those.

The Store logos for 1.71 are `tools/make_store_art.gd`'s output, unchanged in
design since #230 (googly eyes) and regenerated from the v1.71 tag: the 9:16
poster, the 1:1 box art and the 300/150/71 tiles. `tools/make_icon.gd` has not
changed since the icon was last generated, so the icon is as it was.

### Other fields

| Field | Value |
|---|---|
| Short title | Leash Resistance |
| Copyright and trademark info | © 2026 Santtu Nykänen |
| Developed by | Santtu Nykänen |
| Voice title, additional license terms | blank |

## Past What's new

As submitted, newest first. The current one is in "Current listing".

### What's new in 1.74 (tagged 2026-11-16)

```
- Boss arena additions: El Drac's trencadís serpentine bench in El Mosaic (herd him along the curve for a grind and daze), El Gat's striped café awnings on Rambla del Raval (bait his pounce onto the canvas to bounce him back), and harbour wakes, lake ripples and feathered beach surf.
- El Gòtic's retractable lit bollards (pilones retràctils) with amber warning lights, plus new riverside lampposts, benches and a drinking fountain on El Besòs.
- Camera tricks for bosses and close shaves: boss arena zoom-out, reveal letterbox, enrage tilt, and near-miss slow-motion.
- Late-campaign chases spaced evenly across all thirty-nine walks, plus Montserrat goat-herd respite checkpoints and boulder targeting fixes.
- Remaining passers-by upgraded to the full character rig, faster La Rambla and La Diagonal rendering, and Android safe-area and back-button readiness.
```

### What's new in 1.73 (tagged 2026-11-15)

```
- Three new walks, thirty-nine in all: L'Aeroport (Terminal 1's pier and security chase), Montserrat (funicular trail and wild goats), and La Diagonal (seen at a 45-degree angle, with its tram and two-way bike lanes).
- Two new statue bosses: Els Lleons (twin bronze lions at El Port) and El Drac (El Mosaic's salamander), each with story films, plus boss arenas for all four statues (El Mamut's jetty and chairs, El Drac's jets and riding tiles, Els Lleons' crane net, mooring bollards and boat horn, El Gat's yarn stalls).
- Chases rebuilt (cartoon sweeper and Dimoni vehicles; vet, boar, devil and airport squads on foot) and tug of war reworked with a bending rope, wind-up tells and meter.
- Off the leash: El Barri's agility chalk line, pause table and medals; frisbee leap catches and streaks; fetch on the bounce; pigeons in every plaça; waves at the dog beaches; and squirrels in the woodland clearings.
- Barcelona streets and polish: pilona bollards instead of hydrants, panot flower and Gaudí hex tiles, riders in eight styles with painted bike crossings, passers-by redrawn like dog walkers, place-fitting props, home walk-in steps, and gentle night lighting.
```

### What's new in 1.72 (tagged 2026-11-11)

```
- Two new walks, thirty-six in all:
  - La Ciutadella: the grand park avenue to the waterfall cascade, rowboats on the lake, and El Mamut, a full-size stone mammoth who climbs off his plinth as the first statue boss (with his own victory payoff film).
  - La Cremada: Badalona's devil night down Carrer del Mar to the beach, the Dimoni's rolling float chase, and a hot churro cart live event on the Rambla.
- Castellers in Gràcia and El Gòtic: living dynamic human towers with l'aleta crowning, traditional musicians, and equilibri and cheering tricks.
- The Fur-goneta: a shaggy Mutt Cutts dog van homage with floppy ears, wagging tail and tongue, touring four walks with a mobile groomer style dare.
- The street after dark comes alive: doorways ajar, lit shopfronts, amber bars, and television blue spill soft fans of light onto paving and wet rain reflections.
- El Gat pounces: below half health, the Raval's bronze cat wiggles his rear and leaps through the air with a landing ring. Catch him mid-leap or steer him into obstacles.
- Who is out follows the weather and the hour: sunbathers, picnics and ice-cream carts stay in when it rains or after dark, and crowds thin in foul weather.
- Badalona seafront kite flyer live event, clearer boss health bars, and fair patience costs for live-event bumps.
```

### What's new in 1.71 (tagged 2026-11-10)

```
- Three new walks, thirty-four in all:
  - L'Eixample: one street of the grid to the basilica, an octagon at every crossing, and a tour group following its guide's umbrella.
  - Els Àngels: the skate plaza outside the white museum. Grind the ledges and mind the runaway board.
  - El Poble Espanyol: the walled village of copied towns, with an arcaded square, craft workshops and a neighbor watering the geraniums overhead.
- The First Walk, rebuilt: the basics, then the tricks, then free practice in a yard and the dog park.
- A dog has standards. When nature calls, grass, earth or a tree's pit is a perfect spot, and the sidewalk gets a "Here? Really?". Snacks and zoomies bring the call sooner.
- El Barri and El Parc filled in: shops and balconies round the square, a chess table, petanca, a kiosk, a boat-hire hut and neighbors on the benches.
- Plaça d'Espanya lit at night: lamps, glowing halls and towers, traffic, and a crowd round the Magic Fountain.
- A clearer status card: phone, pee, marked spots and zoomies each labeled, and a poop bar while nature calls.
- Front yards on bending streets can be walked into, and one bump from a performer or a skater no longer empties your human's patience.
```

### What's new in 1.70 (tagged 2026-11-07)

```
- Four new places: La Superilla's play streets, Els Búnquers above the city, the seaside esplanade at El Fòrum, and the fountain avenue of Plaça d'Espanya. Thirty-one walks in all.
- A real dawn and dusk. Walks now have their own hour: La Neteja opens in blue early light with a low gold sun and morning mist, Els Búnquers sits in golden hour. After a walk, FREE WALK lets you pick any weather and hour.
- Cleaner streets: the buildings along winding streets stand square, with front yards you can walk in, and edges are smoother.
- Three new galleries to wander into: L'Estel, El Colom and El Drac.
- A victory scene on the plinth at the Rambla del Raval finale.
- A signature live event on every walk, with a true near-miss save. Every hazard is telegraphed 0.8 seconds ahead.
- Snatch dropped snacks, boop snouts, and hear the street in Catalan: "Compte!", "Epa!", "Visca la Festa!".
```

### What's new in 1.68 (tagged 2026-11-01, submitted the same day)

```
- Story films: a short scene before the threat strikes on every chase walk (La Neteja's sweeper, El Besòs's flood, El Veterinari, Els Senglars, Festa de Gràcia's correfoc), and before El Gat wakes on the Rambla del Raval, where she stands her ground. Any button skips.
- The threats look the part, the same in the films and on the walk: the street sweeper glares down the road, the flood comes as a wave over your human's head, the vet's staff come at you with syringes, clippers, a cone and a net, the boars charge as a herd, and the correfoc brings the Drac de Gràcia.
- NEW LOOK: on GET READY, give your human a different look, him or her, any skin tone and hairstyle. The films show the same person, and your choice is remembered.
- Each threat has its own words when it sets off, stops and catches you.
- The walks in a new order, La Neteja the first chase. Your save keeps every walk it had open.
- Other dogs come over to say hello, or lunge and bark if grumpy. Their owners take calls, carry coffee and stop to type.
- LEASH letters fly into their coins, and the goal list shows them, your time against the clock and more.
- Dares show the bark button glowing, and it presses when you take one.
- Dia de Partit in deeper blue and garnet, with the senyera.
- Your human walks in the door at the end instead of sliding.
- Smoother in the browser: La Rambla runs about twice as fast.
```

### What's new in 1.67 (tagged 2026-10-31, submitted the same day)

```
- Six new walks:
  - La Carretera de les Aigües, the old water road along Collserola, and El Laberint d'Horta, the cypress maze.
  - Platja de Llevant, the dog beach at the far end of the coast.
  - Els Senglars, a forest trail with wild boars to outrun on the way home, and Festa de Gràcia, a festival street with the correfoc after you.
  - The finale, Rambla del Raval: El Gat, a fat bronze cat, climbs off his plinth and your human will not pass him. Dodge his paw, trip his charges with the leash, then tie his legs up.
- Five dogs to walk, each with a knack of their own, opened with stars, and bones to train them.
- A dare-giver on every walk, each with their own tune. Bark to take a dare, then land the tricks before the music runs out.
- Fifteen goals on every walk, among them spelling LEASH, a hidden pernil and a par time.
- Pooping and picking up have buttons of their own, there are four key layouts, and every key and button can be rebound.
- Passeig Marítim is Badalona's seafront now, with the Pont del Petroli and its monkey.
- Every walk spells its name on the ground in its own stuff, with a line under it in English, Català or Español (a new LANGUAGE setting).
```

### What's new in 1.64 (tagged 2026-10-24; 1.65 and 1.66 went out with it unchanged)

```
- Two new walks:
  - El Veterinari, open at 33 stars: Millie is taken to the vet and bolts. Get out past the clinic assistants and their cones of shame, weigh in on the pet scale on the way, bark at the cats in their carriers, and snatch the liver treat jar from reception.
  - El Tibidabo, open at 35 stars: a winding mountain road up to the Mirador, the funicular climbing beside it, Aleppo pines to wrap the leash round, and a plaça off leash at the top. The walk ends at the funicular's bottom station, with its own accordion tune.
- Every walk now ends somewhere real: an apartment block of its own neighborhood, the station concourse, a metro stair, the funicular, a trail gate or the ramp up the flood wall. You walk the last stretch in, legs going, the leash pulled straight.
- The agility course now stands in El Barri's dog park only. Tug-of-war and frisbee are still in every off-leash area.
- Fixes: El Veterinari's chase no longer crashes, the cats hiss when barked at, El Somni and Plaça Reial's goals ask for what they say, the leash wraps the detour's lampposts properly, and the results screen stops filling the log with errors.
- El Port has quayside bins for the bag chore.
```

### What's new in 1.63 (live by 2026-10-24)

```
- Two new walks:
  - El Port: Barceloneta's working wharf along Moll dels Pescadors, with wooden boardwalk timber, quayside mooring bollards, fish market crate stacks, flapping seagulls, and Plaça del Far lighthouse.
  - Plaça Reial: Barcelona's grand neoclassical arcaded square in the Gothic Quarter, with Antoni Gaudí's six-armed dragon lampposts, the Three Graces central fountain, outdoor tapas terraces, and a Spanish guitar busker.
- Free Play (Demo) mode in Settings: choose any walk in the game freely without star gates. Career saves and stats are safely bypassed during practice.
- Artsy Detours: the first secret-in-plain-sight side gallery, «El Somni» (homage to Salvador Dalí) hidden along Carrer del Gòtic, featuring melting elastic lampposts and a floating golden dream bone.
- HUD vitals & iconography polish: redesigned smartphone HP pips with hairline cracked glass, liquid bladder and sprint energy tubes with vector droplet and lightning glyphs, arcade combo streak badge, and concentric territory mark target rings.
- Dynamic mood-driven tail wagging, crisp kerb skid juice, and smoother menu typography across all screen resolutions.
```

### What's new in 1.62 (tagged 2026-10-23)

```
- A new walk, El Besòs: a river park between L'Estació and Les Obres, open at 14 stars. The way out is dry. The way home is the flood.
- Shallow water pushes you south and wets your human. Plant to hold a spot. The deep channel, and the swell from the river, ends the walk. A raised apron stays dry until the water spills.
- The flood warns you, then gives a head start, the same as the sweeper. Your human hears the siren and decides it is not their problem.
- Every walk comes home to its own door. Your human looks up, pockets the phone, and follows you in.
- Rain, wind, snow, night and dawn each have their own light. Lamps stay warm after dark.
- Walk names sit in plain type, and a lost walk's title keeps its last letter.
- The Daily Walk is gone. A walk's own weather stays on that walk.
- Bring Tofu home works: she only hides where you can reach her.
- The leash runs round a stall, a van or a bench instead of through it.
- Caught by the sweeper, the two of you go up into the brooms. Fear waits until the threat is on screen.
- On a rainy El Bosc, one run in five raises the stream. Carry the branch or the ball to the bank.
- Visual polish across all seventeen walks: Doric columns and Jujol medallions in El Mosaic, travelator handrail grinds in L'Estació, Pont del Bisbe in El Gòtic, wave paving and Miró's mosaic on La Rambla, riprap banks and inflatable weir on El Besòs, and new landmarks across the city.
```

### What's new in 1.61 (tagged 2026-10-20)

```
- A new walk, Dia de Partit: match day in Les Corts, opening at 27 stars. The avenue fills with fans. Kick-off is on the clock, or when you reach the gate.
- Keep your human out of the away march. After the final whistle the crowd comes home the other way, fast after a win and slow after a loss. The score is on their phone.
- Off the avenue, a lost scarf and a kickabout. Off the leash is PLAÇA DEL GOL, goal square.
- The leash catches a car, a stall or a bench on the shape you see. She slides along a wall instead of sticking to it.
- El Diluvi's shoppers stroll the covered street. El Barri, El Bosc, L'Estació, Les Obres, La Ferralla, El Mosaic, La Castanyada and La Neteja are redrawn.
- La Neteja gives a warning and a head start, then the sweeper. Lost on the way home, continue from the destination or the halfway point.
- The dare kid sits clear of the trees, and the browser build has sound again.
- The opening film is finished, and the title theme has some get-up-and-go.
```

### What's new in 1.59 (live by 2026-10-09)

```
- A new walk, Montjuïc: the climb up the hill, with a hidden cable car, escalators, the Font Màgica and the castle at the top.
- A way in for new players: a two-part tutorial, gentler first walks and first-time tips.
- A lost walk says how to avoid it next time, and keeps the goals you ticked.
- Readable on small screens: the menus and HUD grow, the walk keeps its view.
- Tricks reworked: ride ledges and handrails with the zoomies, new leash tricks, and golden zoomies for stringing tricks together.
- Clearer words throughout, and many smaller fixes.
```

### What's new in 1.58 (submitted 2026-10-05, live 2026-10-05)

```
- A short animated intro, and a new soundtrack with its own arrangement for every walk.
- Games off the leash: an agility course against the clock, tug-of-war over a rope toy, and frisbee.
- Your human answers the leash: lead them nicely and they give you slack; haul and they lose patience.
- A smoother leash, footsteps that change with the ground, and every walk ending at its own gate.
- La Rambla and El Parc upgraded, the off-leash spaces fenced in properly, and many smaller fixes.
```

### What's new in 1.57 (submitted 2026-10-03)

```
- Two new walks. El Barri, the everyday walk, comes first. La Neteja is a narrow back street at dawn: a street sweeper careens after you, flinging junk, and you drag your human home ahead of it. It is the only walk with a chase now.
- Every walk rebuilt as its own place: La Rambla's crowds, sellers and pickpockets, the park's lake, a wood with wild boar, a rainy shopping street, the station and its train, roadworks, a scrapyard, a covered market hall, a chestnut festival at night, and a hilltop park with a mosaic salamander.
- Each walk's name is laid out on the ground in its own stuff (flowers, fruit, sand, cones, chestnuts, tiles) and you can kick it about.
- The town walks end off the leash in a square with a fountain to jump in.
- New menus: a clear screen for each step, and every message on the walk in its own place.
- Other dogs sniff and mark posts you can read, stop to say hello (some grumble), and their people look alive.
- The leash: the reel warns before it changes, plant and get hauled and you skid, and a dragged human leans back.
- A facelift for everyone, with outfits for the weather, and a brighter icon.
- A gentler first walk, and the Catalan names spelt properly.
- Button prompts show whatever you last used, keyboard or controller.
```

### What's new in 1.56 (prepared, never submitted)

```
- A thirteenth walk: La Neteja, a narrow back street at dawn. The street sweeper comes through every time, it fills the lane, and you have to drag your human home ahead of it. Keep more than a leash length clear the whole way for a new goal.
- The chase lives on its own walk now, so the other walks no longer end in one.
- On-screen prompts show the buttons of whatever you last used: keyboard, controller or touch.
- Touch controls on phones and tablets: RUN, MENU, SKIP and SHARE buttons, tap the goals card to open it, and the restart button only appears once the walk has stopped.
- Messages no longer write over each other, and labels at the dog keep clear of them.
- Snow now lies along the path on the walks that bend, and paint, oil, fish and confetti spills look like spills.
- Fixes: a walk with a chase no longer leaves you scared from the very first step, the sweeper no longer draws over your human, and the ground reaches the bottom of the screen at the finish.
```

### What's new in 1.55 (for the record)

```
- A twelfth walk: El Mosaic, a winding terrace path paved in broken glazed tile. The tile is the fastest footing in the game and the slipperiest, and it holds no scent at all.
- Dog moods. What happens on a walk can leave you scared, barky, full of zoomies or flat, and each one changes how you move and what you notice. Moods fade on their own, and the HUD shows how long is left.
- The ground matters: grass and mud slow you a little but hold far more scent than pavement.
- A rebuilt seafront, sand drifting across the promenade, and picnics, stumps and bushes along the verges.
- The street sweeper is a proper machine now.
- Much smoother, especially in the browser: far fewer draw calls per frame, and no more stutter when you step into the off-leash area.
- Fixes: the walk status (NEED A WEE, LOOSE LEASH, FETCH and more) shows again, the mood badge no longer covers the phone, the results card is easier to read, and a dog standing still no longer gets knocked over for no reason.
```

## Submission options

Publishing hold: "Don't publish until I select Publish now". The notes for
certification are in "Current listing" above; the Store submit workflow sends
them.

## Privacy policy

```
Path of Leash Resistance Privacy Policy
Last updated: 2026-09-23

Summary

Path of Leash Resistance is a single-player game that runs entirely on your device.
We do not require account creation.
We do not operate any online service or backend for the game.
The game makes no network connections.

Data We Process

The game processes only:
your game progress, records and unlocked items;
your settings (audio volumes, display and control preferences);
log files the game engine writes for troubleshooting.

All of this stays on your device.

Data Collection and Sharing

We do not collect personal data.
We do not use analytics, advertising or tracking of any kind.
We do not sell or share personal data, because we do not have any.
Nothing is uploaded to us or to any third party.

Local Storage

The game stores its data locally in your Windows user profile. For the Microsoft Store version this is inside the app's private package folder (under %LOCALAPPDATA%\Packages), including:
your save file (progress, records, unlocks and settings);
engine log files.

Uninstalling the game removes this data.

Security

We take reasonable steps to keep the game and its engine up to date, but no software can guarantee absolute security.

Children

The game collects no personal information from anyone, including children.

Changes to This Policy

We may update this policy. The latest version will be published with an updated Last updated date.

Contact

For privacy questions, open an issue on the project repository:
https://github.com/cyanidesayonara/path-of-leash-resistance/issues
```

If the game ever makes a network connection or collects anything, this
policy and the Partner Center privacy answer must change before that build
ships.
