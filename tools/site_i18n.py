"""The website's own words in English, Catalan and Spanish, for tools/site_walks.py.

What the game already says in three languages (walk glosses, dog traits, skill
goals, wardrobe names) comes from the game through tools/site_walks_data.json;
this holds what only the website says. Place names stay in Catalan in every
language, as in the game.
"""

LANGS = ("en", "ca", "es")

UI = {
    "en": {
        "chapter": "Chapter {n}",
        "walks_n": "{n} walks",
        "ends_on_boss": "Ends on boss: {walk} ({boss})",
        "culminates": "Culminates at {walk}",
        "boss": "Boss",
        "chase": "Chase",
        "tutorial": "Tutorial",
        "chapter_boss": "Chapter {n} boss",
        "starter": "Starter",
        "stars": "{n} stars",
        "bones": "{n} bones",
        "dog_alt": "{name}, the {breed}, side on",
        "card_alt": "{name}: {gloss}",
        "collars": "Collars",
        "collars_p": "Sets the color of the leash itself.",
        "bandanas": "Bandanas",
        "bandanas_p": "Optional cloth around the neck ({n} colors).",
        "coats": "Coats",
        "coats_p": "Coat markings ({n} styles).",
        "training": "Training &amp; New Look",
        "training_p": ("Every buried find she digs up and every skill goal she meets is a training point for her. "
                       "Each dog is born with a head start in what she is bred for; spend the points on {n} stats "
                       "({stats}), up to {max} levels each, a level costing as many points as the level it reaches. "
                       "Roll a <strong>New Look</strong> for your human before heading out: {skins} skin tones, "
                       "{hair} hair colors, {styles} hairstyles, {shirts} shirts, {trousers} trousers and "
                       "{shoes} shoe styles."),
    },
    "ca": {
        "chapter": "Capítol {n}",
        "walks_n": "{n} passejos",
        "ends_on_boss": "Acaba amb un cap: {walk} ({boss})",
        "culminates": "Culmina a {walk}",
        "boss": "Cap",
        "chase": "Persecució",
        "tutorial": "Tutorial",
        "chapter_boss": "Cap del capítol {n}",
        "starter": "D'inici",
        "stars": "{n} estrelles",
        "bones": "{n} ossos",
        "dog_alt": "{name}, {breed}, de perfil",
        "card_alt": "{name}: {gloss}",
        "collars": "Collars",
        "collars_p": "Donen el color a la mateixa corretja.",
        "bandanas": "Mocadors",
        "bandanas_p": "Un mocador al coll, si vols ({n} colors).",
        "coats": "Pelatges",
        "coats_p": "Pelatges i marques ({n} estils).",
        "training": "Entrenament i Nou aspecte",
        "training_p": ("Cada tresor que desenterra i cada fita d'habilitat que compleix li dona un punt "
                       "d'entrenament. Cada gos neix amb avantatge en allò per a què s'ha criat; gasta els punts "
                       "en {n} qualitats ({stats}), fins a {max} nivells cadascuna, i cada nivell costa tants punts "
                       "com el nivell al qual arriba. Abans de sortir, tria un <strong>Nou aspecte</strong> per al "
                       "teu humà: {skins} tons de pell, {hair} colors de cabell, {styles} pentinats, {shirts} "
                       "samarretes, {trousers} pantalons i {shoes} sabates."),
    },
    "es": {
        "chapter": "Capítulo {n}",
        "walks_n": "{n} paseos",
        "ends_on_boss": "Termina con un jefe: {walk} ({boss})",
        "culminates": "Culmina en {walk}",
        "boss": "Jefe",
        "chase": "Persecución",
        "tutorial": "Tutorial",
        "chapter_boss": "Jefe del capítulo {n}",
        "starter": "De inicio",
        "stars": "{n} estrellas",
        "bones": "{n} huesos",
        "dog_alt": "{name}, {breed}, de perfil",
        "card_alt": "{name}: {gloss}",
        "collars": "Collares",
        "collars_p": "Dan color a la propia correa.",
        "bandanas": "Bandanas",
        "bandanas_p": "Una tela al cuello, si quieres ({n} colores).",
        "coats": "Pelajes",
        "coats_p": "Pelajes y manchas ({n} estilos).",
        "training": "Entrenamiento y Nuevo look",
        "training_p": ("Cada tesoro que desentierra y cada meta de habilidad que cumple le da un punto de "
                       "entrenamiento. Cada perro nace con ventaja en aquello para lo que se crio; gasta los "
                       "puntos en {n} cualidades ({stats}), hasta {max} niveles cada una, y cada nivel cuesta "
                       "tantos puntos como el nivel al que llega. Antes de salir, elige un <strong>Nuevo "
                       "look</strong> para tu humano: {skins} tonos de piel, {hair} colores de pelo, {styles} "
                       "peinados, {shirts} camisetas, {trousers} pantalones y {shoes} zapatos."),
    },
}

SKY = {
    "en": {"clear": "Clear", "wind": "Windy", "rain": "Rain", "snow": "Snow", "fog": "Fog"},
    "ca": {"clear": "Serè", "wind": "Vent", "rain": "Pluja", "snow": "Neu", "fog": "Boira"},
    "es": {"clear": "Despejado", "wind": "Viento", "rain": "Lluvia", "snow": "Nieve", "fog": "Niebla"},
}

HOUR = {
    "en": {"day": "day", "dawn": "dawn", "dusk": "dusk", "night": "night"},
    "ca": {"day": "dia", "dawn": "alba", "dusk": "capvespre", "night": "nit"},
    "es": {"day": "día", "dawn": "alba", "dusk": "atardecer", "night": "noche"},
}

# the five training stats, as the dog cards name them
STATS = {
    "en": {"speed": "Speed", "agility": "Agility", "plant": "Grip", "nose": "Nose", "herd": "Herding"},
    "ca": {"speed": "Velocitat", "agility": "Agilitat", "plant": "Aferrament", "nose": "Olfacte", "herd": "Guiatge"},
    "es": {"speed": "Velocidad", "agility": "Agilidad", "plant": "Agarre", "nose": "Olfato", "herd": "Guía"},
}

SKILL = {
    "en": {"millie": "The nose", "pipa": "The sprint", "mochi": "The plant", "bruna": "The herd",
           "tito": "The squeeze", "perla": "The dig", "duna": "The leap"},
    "ca": {"millie": "L'olfacte", "pipa": "L'esprint", "mochi": "La plantada", "bruna": "El guiatge",
           "tito": "L'escletxa", "perla": "L'excavada", "duna": "El salt"},
    "es": {"millie": "El olfato", "pipa": "El esprint", "mochi": "La plantada", "bruna": "El pastoreo",
           "tito": "El hueco", "perla": "La excavación", "duna": "El salto"},
}

BREED = {
    "ca": {"Mongrel": "Mestissa", "Galgo": "Llebrer", "French bulldog": "Bulldog francès",
           "Gos d'atura": "Gos d'atura", "Chihuahua": "Chihuahua", "Ratonero bodeguero": "Ratonero bodeguer",
           "Podenco": "Podenc"},
    "es": {"Mongrel": "Mestiza", "Galgo": "Galgo", "French bulldog": "Bulldog francés",
           "Gos d'atura": "Perro de pastor catalán", "Chihuahua": "Chihuahua",
           "Ratonero bodeguero": "Ratonero bodeguero", "Podenco": "Podenco"},
}

DOG_DESC = {
    "ca": {
        "millie": "De tot una mica, mestra de l'ensumada",
        "pipa": "Una llebrera llampec que odia plantar-se",
        "mochi": "Un tanc petit i tossut que no es mou",
        "bruna": "Una gossa d'atura pelluda que guia el teu humà sense esforç",
        "tito": "Un chihuahua minúscul que s'escola entre obstacles i recull la corretja de seguida",
        "perla": "Una ratera tricolor de celler que desenterra més de pressa que ningú",
        "duna": "Una podenca rogenca i blanca que salta un banc des de parada",
    },
    "es": {
        "millie": "De todo un poco, maestra del olfateo",
        "pipa": "Una galga relámpago que odia plantarse",
        "mochi": "Un tanque pequeño y testarudo que no se mueve",
        "bruna": "Una perra pastora peluda que guía a tu humano sin esfuerzo",
        "tito": "Un chihuahua diminuto que se cuela entre obstáculos y recoge la correa enseguida",
        "perla": "Una ratonera tricolor de bodega que desentierra más rápido que nadie",
        "duna": "Una podenca roja y blanca que salta un banco desde parada",
    },
}

BOSS = {
    "en": {
        "ciutadella": ("El Mamut", "The life-size stone mammoth by Parc de la Ciutadella's cascada steps off its plinth. Wrap it up or bait its charge into the boating lake."),
        "guell": ("El Drac", "The trencadís mosaic dragon holds the grand stairway. Wind the leash round the stone columns, dodge the tail sweep, and trip the beast on the tiles."),
        "port": ("Els Lleons", "Twin bronze harbor lions guard Columbus's column along the wharf. Lead their pincer charge round the iron mooring bollards and into one another."),
        "girona": ("La Lleona", "Girona's stone lioness climbs down off her column and looks for you. Hide from her gaze, lead her under the rain spout, and kiss her where the whole town does."),
        "raval": ("El Gat", "Rambla del Raval's plump bronze cat prowls beneath the palms, scattering pigeons and leaping across awnings until you fling your human straight into him."),
    },
    "ca": {
        "ciutadella": ("El Mamut", "El mamut de pedra de mida real que hi ha vora la cascada del Parc de la Ciutadella baixa del pedestal. Embolica'l o fes que carregui dret cap a l'estany de les barques."),
        "guell": ("El Drac", "El drac de trencadís guarda l'escalinata. Enrotlla la corretja a les columnes de pedra, esquiva el cop de cua i fes-lo ensopegar a les rajoles."),
        "port": ("Els Lleons", "Dos lleons de bronze guarden la columna de Colom al moll. Porta'ls a envestir-te en pinça al voltant dels norais de ferro i que xoquin entre ells."),
        "girona": ("La Lleona", "La lleona de pedra de Girona baixa de la columna i et busca. Amaga't de la seva mirada, porta-la sota la gàrgola i fes-li el petó que li fa tota la ciutat."),
        "raval": ("El Gat", "El gat de bronze gras de la Rambla del Raval ronda sota les palmeres, espanta els coloms i salta d'un tendal a l'altre fins que hi llances el teu humà a sobre."),
    },
    "es": {
        "ciutadella": ("El Mamut", "El mamut de piedra a tamaño real junto a la cascada del Parc de la Ciutadella baja de su pedestal. Enróllalo o haz que cargue directo al estanque de las barcas."),
        "guell": ("El Drac", "El dragón de trencadís guarda la escalinata. Enrolla la correa en las columnas de piedra, esquiva el coletazo y hazle tropezar en las baldosas."),
        "port": ("Els Lleons", "Dos leones de bronce guardan la columna de Colón en el muelle. Llévalos a embestirte en pinza alrededor de los noráis de hierro y que choquen entre ellos."),
        "girona": ("La Lleona", "La leona de piedra de Girona baja de su columna y te busca. Escóndete de su mirada, llévala bajo la gárgola y dale el beso que le da toda la ciudad."),
        "raval": ("El Gat", "El gato de bronce gordo de la Rambla del Raval ronda bajo las palmeras, espanta a las palomas y salta de toldo en toldo hasta que le lanzas a tu humano encima."),
    },
}

# each chase walk's film: the clip, then (alt, caption) per language
CHASE_FILMS = {
    "neteja": ("sweeper", {
        "en": ("A street sweeper with teeth bears down on the dog and her human.", "La Neteja: the dawn street sweeper"),
        "ca": ("Una escombradora amb dents s'acosta al gos i al seu humà.", "La Neteja: l'escombradora de l'alba"),
        "es": ("Una barredora con dientes se echa encima del perro y su humano.", "La Neteja: la barredora del alba"),
    }),
    "besos": ("flood", {
        "en": ("A wall of flood water surges down the riverbed after them.", "El Besòs: the river in flood"),
        "ca": ("Una paret d'aigua baixa per la llera del riu darrere seu.", "El Besòs: la riuada"),
        "es": ("Una pared de agua baja por el cauce del río tras ellos.", "El Besòs: la riada"),
    }),
    "vet": ("vet", {
        "en": ("Vets in scrubs come after the dog with a giant needle and a cone.", "El Veterinari: the clinic escape"),
        "ca": ("Veterinaris amb bata persegueixen el gos amb una xeringa gegant i un con.", "El Veterinari: la fugida de la clínica"),
        "es": ("Veterinarios con bata persiguen al perro con una jeringa gigante y un cono.", "El Veterinari: la huida de la clínica"),
    }),
    "boars": ("boars", {
        "en": ("Wild boars burst out of the forest after the dog and her human.", "Els Senglars: wild Collserola boars"),
        "ca": ("Els senglars surten del bosc rere el gos i el seu humà.", "Els Senglars: els senglars de Collserola"),
        "es": ("Los jabalíes salen del bosque tras el perro y su humano.", "Els Senglars: los jabalíes de Collserola"),
    }),
    "cremada": ("cremada", {
        "en": ("The Dimoni float rolls after them, firing rockets ahead.", "La Cremada: the Dimoni float"),
        "ca": ("La carrossa del Dimoni els persegueix disparant coets.", "La Cremada: la carrossa del Dimoni"),
        "es": ("La carroza del Dimoni los persigue disparando cohetes.", "La Cremada: la carroza del Dimoni"),
    }),
    "aeroport": ("aeroport", {
        "en": ("Airport security sprints down the concourse after the dog.", "L'Aeroport: airport security"),
        "ca": ("La seguretat de l'aeroport corre per la terminal darrere el gos.", "L'Aeroport: la seguretat de l'aeroport"),
        "es": ("La seguridad del aeropuerto corre por la terminal tras el perro.", "L'Aeroport: la seguridad del aeropuerto"),
    }),
    "molina": ("molina", {
        "en": ("A runaway snow groomer churns down the piste after them.", "La Molina: the runaway groomer"),
        "ca": ("Una trepitjaneu desbocada baixa per la pista darrere seu.", "La Molina: la trepitjaneu desbocada"),
        "es": ("Una pisanieves desbocada baja por la pista tras ellos.", "La Molina: la pisanieves desbocada"),
    }),
    "atraccions": ("mascots", {
        "en": ("Five grinning theme park mascots step off their stage and come for a hug.", "Les Atraccions: the mascots"),
        "ca": ("Cinc mascotes somrients baixen de l'escenari a buscar una abraçada.", "Les Atraccions: les mascotes"),
        "es": ("Cinco mascotas sonrientes bajan del escenario a por un abrazo.", "Les Atraccions: las mascotas"),
    }),
    "montserrat": ("montserrat", {
        "en": ("Mountain goats come leaping down the rocks after the dog.", "Montserrat: the mountain goats"),
        "ca": ("Les cabres baixen saltant per les roques darrere el gos.", "Montserrat: les cabres de muntanya"),
        "es": ("Las cabras bajan saltando por las rocas tras el perro.", "Montserrat: las cabras monteses"),
    }),
    "gracia": ("gracia", {
        "en": ("Correfoc devils with sparklers chase the dog through the festival street.", "Festa de Gràcia: the correfoc devils"),
        "ca": ("Els diables del correfoc persegueixen el gos pel carrer guarnit.", "Festa de Gràcia: els diables del correfoc"),
        "es": ("Los diablos del correfoc persiguen al perro por la calle engalanada.", "Festa de Gràcia: los diablos del correfoc"),
    }),
}


def ui(lang: str, key: str, **kw) -> str:
    return UI[lang][key].format(**kw)
