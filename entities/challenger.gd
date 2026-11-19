extends Node2D

const HumanLook := preload("res://entities/human_appearance.gd")
const SpeechBubble := preload("res://world/speech_bubble.gd")
const TutorialSteps := preload("res://systems/tutorial.gd")
const Cast := preload("res://entities/challenger_cast.gd")
const DareMarks := preload("res://entities/dare_marks.gd")

# The dare-giver (Combo Phase B): somebody on the walk who dares you into a
# bounded trick window as you pass. Who it is depends on the walk (WHO): a
# show-off kid on a bench by default, the bronze monkey on the Pont del
# Petroli's steps, a living statue on La Rambla, and so on. Pure flavour plus
# a proximity trigger - the challenge logic and reward live in challenge.gd
# and main.
#
# Whatever their voice, every one of them says the same three things plainly,
# because a walk is chaos and a dare has to read at a glance: how many tricks
# in how many seconds, that a bark takes it (the bubble and the card both say
# so), and what happens next. Nothing starts until she barks; walking off
# lapses the offer and it is made again when she comes back.
#
# Every giver has the same three dares, LADDER, and one rule for another go,
# which the giver says out loud and the result card repeats:
#   win   the next dare is harder; lose  the same dare again;
#   either way, stay close (RETRY_WAIT) or come back later (leave notice_r()
#   and return) and they offer it.
# After the last dare is won they have nothing left. Losing costs nothing and
# a dare can be tried as often as she likes. The autowalk bot takes the first
# dare by itself and gets no other, so its traversal stays deterministic.

const NOTICE_R := 240.0
# a follow-up: offered when she comes back within notice_r() after leaving,
# or after RETRY_WAIT while she is still within NEAR_R (on screen); an offer
# she has not taken lapses past NEAR_R
const NEAR_R := 420.0
const RETRY_WAIT := 5.0
# trick count and seconds, easiest first
# (measured with tools/dare_bot.gd: a bot that only swings round poles lands
# about one trick in four seconds; a player who mixes in flings and grinds,
# with the dare's free zoomies, does better)
const LADDER := [[4, 20.0], [6, 25.0], [8, 30.0]]

# who gives the dare on each walk; anywhere not listed (El Barri, the First
# Walk), the kid from your street. Most of the walks' own cast is drawn in
# entities/challenger_cast.gd.
const WHO := {"beach": "monkey", "street": "statue", "port": "fisher", "site": "builder", "besos": "skater",
	"oldtown": "busker", "market": "avia", "montjuic": "runner", "guell": "painter", "partit": "fan",
	"station": "commuter", "metro": "breaker",
	"park": "kite", "rain": "umbrella", "sarria": "baker", "trail": "picker", "spook": "castanyera",
	"scrap": "scrapper", "neteja": "nightowl", "reial": "flamenco", "vet": "catlady", "tibidabo": "balloons",
	"aigues": "hiker", "horta": "gardener", "llevant": "surfer", "boars": "ranger", "gracia": "drummer",
	"carmel": "photographer", "superilla": "chess", "forum": "drone", "espanya": "bubbles", "raval": "fortune",
	"eixample": "guide", "angels": "skateboarder", "poble": "potter", "ciutadella": "juggler", "cremada": "devil",
	"aeroport": "pilot", "montserrat": "monk", "diagonal": "rider", "blai": "cook", "sitges": "kitesurfer", "santpau": "sketcher", "molina": "instructor",
	"ronda": "snorkeler", "encants": "haggler"}

# where they are on a walk whose spot main's rule (either side of the
# corridor 1600 px in) would put on something or under it: El Metro's
# escalator, a palm's crown on Plaça Reial, the solar pergola on El Fòrum
const AT := {"metro": Vector2(445.0, -1430.0), "reial": Vector2(800.0, -1850.0), "forum": Vector2(820.0, -1150.0), "santpau": Vector2(780.0, -1580.0),
	"sitges": Vector2(444.0, -1460.0),
	"ronda": Vector2(655.0, -2150.0),
	"encants": Vector2(520.0, -1650.0)}

# what each of them sits or stands on, solid and wrapping the leash; the
# monkey's marble block is the walk's own (LevelBuild.beach_block_stones)
const FOOTPRINT := {"kid": Vector2(28.0, 62.0), "statue": Vector2(30.0, 30.0), "fisher": Vector2(26.0, 26.0),
	"builder": Vector2(24.0, 24.0), "skater": Vector2(20.0, 20.0), "monkey": Vector2.ZERO,
	"busker": Vector2(24.0, 24.0), "avia": Vector2(22.0, 22.0), "runner": Vector2(18.0, 18.0),
	"painter": Vector2(26.0, 26.0), "fan": Vector2(20.0, 20.0), "commuter": Vector2(28.0, 22.0), "breaker": Vector2(24.0, 24.0),
	"kite": Vector2(20.0, 20.0), "umbrella": Vector2(22.0, 22.0), "baker": Vector2(22.0, 22.0),
	"picker": Vector2(24.0, 22.0), "castanyera": Vector2(28.0, 28.0), "scrapper": Vector2(26.0, 26.0),
	"nightowl": Vector2(18.0, 18.0), "flamenco": Vector2(24.0, 24.0), "catlady": Vector2(24.0, 22.0),
	"balloons": Vector2(20.0, 20.0), "hiker": Vector2(22.0, 22.0), "gardener": Vector2(20.0, 20.0),
	"surfer": Vector2(22.0, 22.0), "ranger": Vector2(20.0, 20.0), "drummer": Vector2(22.0, 22.0),
	"photographer": Vector2(22.0, 22.0), "chess": Vector2(30.0, 30.0), "drone": Vector2(20.0, 20.0),
	"bubbles": Vector2(20.0, 20.0), "fortune": Vector2(28.0, 28.0), "guide": Vector2(20.0, 20.0),
	"skateboarder": Vector2(20.0, 20.0), "potter": Vector2(28.0, 28.0), "juggler": Vector2(20.0, 20.0),
	"devil": Vector2(20.0, 20.0), "pilot": Vector2(24.0, 22.0), "monk": Vector2(22.0, 22.0),
	"rider": Vector2(24.0, 24.0), "cook": Vector2(20.0, 20.0), "kitesurfer": Vector2(24.0, 24.0), "sketcher": Vector2(24.0, 26.0), "instructor": Vector2(22.0, 22.0), "snorkeler": Vector2(24.0, 24.0), "haggler": Vector2(26.0, 24.0)}

# What each of them says, as people talk, each line starting with a capital. "dare" always names
# the numbers as "N tricks in N seconds", and the bubble adds TAKE while the dare waits
# for a bark; "won" says a harder one is coming and "lost" that she can try
# again, in so many words. AGAIN, COUNT and LAST are the same for everyone.
const AGAIN := "Another go? %d tricks in %d seconds!"
const COUNT := "%d more! Keep going!"
const LAST := "One more trick!"
const TAKE := "Bark if you're in!"
const GET_READY := "Get ready..."
const LINES := {
	"kid": {"idle": "Hey, dog! Want a dare?", "dare": "Bet you can't do %d tricks in %d seconds!",
		"won": "No way! Come back for a harder one!", "lost": "Nope! Come back and try again.",
		"done": "Okay, you're unreal."},
	"monkey": {"idle": "Hey, dog! Want a dare?", "dare": "%d tricks in %d seconds! Show me you've evolved!",
		"won": "A remarkable specimen! Come back for a harder one.", "lost": "Not yet! Come back and try again.",
		"done": "Survival of the fittest. That's you."},
	"statue": {"idle": "Psst... Want a dare?", "dare": "Psst! %d tricks in %d seconds, while I stand here!",
		"won": "Bravo! Come back for a harder one!", "lost": "Too slow! Come back and try again.",
		"done": "Even I almost moved."},
	"fisher": {"idle": "Nothing's biting. Want a dare?", "dare": "%d tricks in %d seconds, before I catch a fish!",
		"won": "What a catch! Come back for a harder one.", "lost": "Slipped the hook! Come back and try again.",
		"done": "Best catch all day."},
	"builder": {"idle": "On my break. Want a dare?", "dare": "%d tricks in %d seconds, before my break's over!",
		"won": "Solid work! Come back for a harder one.", "lost": "Not up to code! Come back and try again.",
		"done": "You can work on my crew any day."},
	"skater": {"idle": "Hey, dog! Want a dare?", "dare": "%d tricks in %d seconds! Can you keep up?",
		"won": "Sick! Come back for a harder one!", "lost": "Bailed! Come back and try again.",
		"done": "Teach me your ways."},
	"busker": {"idle": "Fancy a dare, while I play?", "dare": "%d tricks in %d seconds, in time with the music!",
		"won": "Encore! Come back for a harder one!", "lost": "Off the beat! Come back and try again.",
		"done": "I'm writing a song about you."},
	"avia": {"idle": "You, dog! Want a dare?", "dare": "%d tricks in %d seconds? I'll believe it when I see it!",
		"won": "Mare meva! Come back for a harder one.", "lost": "Too slow, maco! Come back and try again.",
		"done": "Wait till I tell the fishmonger."},
	"runner": {"idle": "Hey, dog! Want a dare?", "dare": "%d tricks in %d seconds! I'll time you!",
		"won": "New record! Come back for a harder one.", "lost": "Out of breath? Come back and try again.",
		"done": "You should run the marathon."},
	"painter": {"idle": "Will you sit for a portrait? ...No? A dare, then.", "dare": "%d tricks in %d seconds, while I paint!",
		"won": "A masterpiece! Come back for a harder one.", "lost": "Smudged it! Come back and try again.",
		"done": "I'm painting you next."},
	"fan": {"idle": "Hey, dog! Want a dare?", "dare": "%d tricks in %d seconds, before the match starts!",
		"won": "GOLAZO! Come back for a harder one!", "lost": "Offside! Come back and try again.",
		"done": "Somebody sign this dog!"},
	"commuter": {"idle": "Train's delayed again. Want a dare?", "dare": "%d tricks in %d seconds, before my train comes!",
		"won": "Right on time! Come back for a harder one.", "lost": "Missed it! Come back and try again.",
		"done": "Best part of my commute."},
	"breaker": {"idle": "Yo, dog! Want a dare?", "dare": "%d tricks in %d seconds! Show me your moves!",
		"won": "Fresh! Come back for a harder one!", "lost": "Lost the beat! Come back and try again.",
		"done": "You're in the crew now."},
	"kite": {"idle": "Hey, dog! Want a dare?", "dare": "%d tricks in %d seconds, before the wind drops!",
		"won": "Up and away! Come back for a harder one.", "lost": "Tangled! Come back and try again.",
		"done": "You fly higher than my kite."},
	"umbrella": {"idle": "Umbrella? No? A dare, then.", "dare": "%d tricks in %d seconds, before the rain stops!",
		"won": "Dry as a bone! Come back for a harder one.", "lost": "Soaked! Come back and try again.",
		"done": "Take an umbrella. On the house."},
	"baker": {"idle": "Morning, dog! Want a dare?", "dare": "%d tricks in %d seconds, before the bread's out!",
		"won": "Fresh out of the oven! Come back for a harder one.", "lost": "Half-baked! Come back and try again.",
		"done": "You've earned a crust."},
	"picker": {"idle": "Shh, mushrooms. Want a dare?", "dare": "%d tricks in %d seconds, while I fill my basket!",
		"won": "A real find! Come back for a harder one.", "lost": "Wrong mushroom! Come back and try again.",
		"done": "Best find of the season."},
	"castanyera": {"idle": "Hot chestnuts! Or a dare?", "dare": "%d tricks in %d seconds, before they burn!",
		"won": "Nicely roasted! Come back for a harder one.", "lost": "Gone cold! Come back and try again.",
		"done": "A cone on the house, dog."},
	"scrapper": {"idle": "Anything metal? No? A dare, then.", "dare": "%d tricks in %d seconds! Scrap or treasure?",
		"won": "Treasure! Come back for a harder one.", "lost": "Scrap! Come back and try again.",
		"done": "Worth your weight in copper."},
	"nightowl": {"idle": "Still up? Me too. Want a dare?", "dare": "%d tricks in %d seconds, before the sun's up!",
		"won": "What a night! Come back for a harder one.", "lost": "Lights out! Come back and try again.",
		"done": "Best part of my night."},
	"flamenco": {"idle": "Olé! Want a dare?", "dare": "%d tricks in %d seconds, in time with my heels!",
		"won": "Olé, olé! Come back for a harder one!", "lost": "Missed the beat! Come back and try again.",
		"done": "You've got duende, dog."},
	"catlady": {"idle": "Mittens says hi. Want a dare?", "dare": "%d tricks in %d seconds! Mittens is watching.",
		"won": "Even Mittens is impressed! Come back for a harder one.", "lost": "Mittens yawned. Come back and try again.",
		"done": "Mittens wants your autograph."},
	"balloons": {"idle": "Balloon, dog? Or a dare?", "dare": "%d tricks in %d seconds, before one floats off!",
		"won": "Pop! Come back for a harder one!", "lost": "Floated off! Come back and try again.",
		"done": "You get the big red one."},
	"hiker": {"idle": "Long way up. Want a dare?", "dare": "%d tricks in %d seconds, while I catch my breath!",
		"won": "Peak performance! Come back for a harder one.", "lost": "Uphill battle! Come back and try again.",
		"done": "You should lead the hike."},
	"gardener": {"idle": "Mind the hedges. Want a dare?", "dare": "%d tricks in %d seconds, while I trim!",
		"won": "Neat work! Come back for a harder one.", "lost": "Overgrown! Come back and try again.",
		"done": "Even the maze is impressed."},
	"surfer": {"idle": "No waves today. Want a dare?", "dare": "%d tricks in %d seconds! Ride it out!",
		"won": "Gnarly! Come back for a harder one!", "lost": "Wiped out! Come back and try again.",
		"done": "You're shredding, dog."},
	"ranger": {"idle": "Seen any boars? A dare, then.", "dare": "%d tricks in %d seconds, before the boars show up!",
		"won": "Wild! Come back for a harder one.", "lost": "Lost the trail! Come back and try again.",
		"done": "You're going in my report."},
	"drummer": {"idle": "It's the festa! Want a dare?", "dare": "%d tricks in %d seconds, to my drum!",
		"won": "Bang on! Come back for a harder one!", "lost": "Out of time! Come back and try again.",
		"done": "Lead the parade, dog."},
	"photographer": {"idle": "Golden hour! Want a dare?", "dare": "%d tricks in %d seconds! I'll shoot the lot.",
		"won": "Got the shot! Come back for a harder one.", "lost": "Blurry! Come back and try again.",
		"done": "Cover shot, right there."},
	"chess": {"idle": "Your move. Want a dare?", "dare": "%d tricks in %d seconds. Check?",
		"won": "Checkmate! Come back for a harder one.", "lost": "Stalemate! Come back and try again.",
		"done": "Grandmaster dog."},
	"drone": {"idle": "Look up! Want a dare?", "dare": "%d tricks in %d seconds! I'm filming.",
		"won": "Great footage! Come back for a harder one.", "lost": "Battery low! Come back and try again.",
		"done": "You're going viral."},
	"bubbles": {"idle": "Pop one! Or take a dare?", "dare": "%d tricks in %d seconds, before this one pops!",
		"won": "Magic! Come back for a harder one.", "lost": "Popped! Come back and try again.",
		"done": "The fountains are jealous."},
	"fortune": {"idle": "I see a dare in your future.", "dare": "%d tricks in %d seconds. The cards say so!",
		"won": "Foreseen! Come back for a harder one.", "lost": "Not in the cards! Come back and try again.",
		"done": "Your future is very bright, dog."},
	"guide": {"idle": "This way, everyone! You too. A dare?", "dare": "%d tricks in %d seconds, then the basilica!",
		"won": "Five stars! Come back for a harder one.", "lost": "Lost the group! Come back and try again.",
		"done": "Best stop on the tour."},
	"skateboarder": {"idle": "Sup, dog? Want a dare?", "dare": "%d tricks in %d seconds! Land them clean!",
		"won": "Clean! Come back for a harder one!", "lost": "Slam! Come back and try again.",
		"done": "You run this plaza."},
	"potter": {"idle": "Careful, wet clay. Want a dare?", "dare": "%d tricks in %d seconds, while the wheel spins!",
		"won": "Fired up! Come back for a harder one.", "lost": "Cracked! Come back and try again.",
		"done": "I'll make you a bowl."},
	"juggler": {"idle": "Catch! No? A dare, then.", "dare": "%d tricks in %d seconds! Don't drop any!",
		"won": "Not one dropped! Come back for a harder one.", "lost": "Dropped it! Come back and try again.",
		"done": "Join the circus, dog."},
	"devil": {"idle": "Dare to play with fire, pup?", "dare": "%d tricks in %d seconds, before my sparks run out!",
		"won": "Devilish! Come back for a harder one!", "lost": "Fizzled out! Come back and try again.",
		"done": "You're a little devil."},
	"pilot": {"idle": "Boarding soon. Want a dare?", "dare": "%d tricks in %d seconds, before takeoff!",
		"won": "Smooth landing! Come back for a harder one.", "lost": "Grounded! Come back and try again.",
		"done": "Cleared for takeoff, captain."},
	"monk": {"idle": "Peace, dog. A dare, perhaps?", "dare": "%d tricks in %d seconds. I'll pray for you.",
		"won": "A miracle! Come back for a harder one.", "lost": "Patience, my child. Come back and try again.",
		"done": "Bless you, dog."},
	"instructor": {"idle": "Hey, pup! Fancy a lesson? A dare, then.", "dare": "%d tricks in %d seconds! Knees bent!",
		"won": "Gold medal! Come back for a harder one.", "lost": "Wipeout! Come back and try again.",
		"done": "You've graduated, dog."},
	"rider": {"idle": "My order's late anyway. Want a dare?", "dare": "%d tricks in %d seconds, before the next order!",
		"won": "Delivered! Come back for a harder one.", "lost": "Wrong address! Come back and try again.",
		"done": "Five stars, dog."},
	"cook": {"idle": "Kitchen's hot. Want a dare?", "dare": "%d tricks in %d seconds, before the croquetas burn!",
		"won": "Chef's kiss! Come back for a harder one.", "lost": "Overcooked! Come back and try again.",
		"done": "Anything on the menu, dog. On me."},
	"sketcher": {"idle": "The light's just right on the domes. Want a dare?", "dare": "%d tricks in %d seconds, before the dusk light goes!",
		"won": "Lovely color! Come back for a harder one.", "lost": "Washed out! Come back and try again.",
		"done": "You're going straight into my sketchbook."},
	"kitesurfer": {"idle": "Wind's up! Want a dare?", "dare": "%d tricks in %d seconds, before I launch my kite!",
		"won": "Full send! Come back for a harder one!", "lost": "Lulls happen! Come back and try again.",
		"done": "You've got better wind sense than me."},
	"snorkeler": {"idle": "Water's choppy today, waiting out the tramuntana. Want a dare?",
		"dare": "%d tricks in %d seconds, before the next big gust!",
		"won": "Sharp as a sea urchin! Want an even harder one?",
		"lost": "Swept right off the rock! Catch your breath and try again.",
		"done": "First cove's calmer anyway. Enjoy the shingle!"},
	"haggler": {"idle": "Forty for the crate? Fine, thirty. Want a dare while I think?",
		"dare": "%d tricks in %d seconds, and I'll throw in a button!",
		"won": "Sold! You're sharper than these lamps. Harder?",
		"lost": "No deal. Come back when you've got the goods.",
		"done": "Take the button. I've got more crates to sort."},
}

# who they are, for the result card
const NAMES := {"kid": "the kid", "monkey": "the monkey", "statue": "the statue", "fisher": "the fisherman",
	"builder": "the builder", "skater": "the skater", "busker": "the busker", "avia": "the àvia",
	"runner": "the runner", "painter": "the painter", "fan": "the fan", "commuter": "the commuter",
	"breaker": "the breakdancer", "kite": "the kite flyer", "umbrella": "the umbrella seller", "baker": "the baker",
	"picker": "the mushroom picker", "castanyera": "the chestnut seller", "scrapper": "the scrap dealer",
	"nightowl": "the night owl", "flamenco": "the flamenco dancer", "catlady": "the cat owner",
	"balloons": "the balloon seller", "hiker": "the hiker", "gardener": "the gardener", "surfer": "the surfer",
	"ranger": "the ranger", "drummer": "the drummer", "photographer": "the photographer",
	"chess": "the chess player", "drone": "the drone pilot", "bubbles": "the bubble maker",
	"fortune": "the fortune teller", "guide": "the tour guide", "skateboarder": "the skateboarder",
	"potter": "the potter", "juggler": "the juggler", "devil": "the devil", "pilot": "the pilot",
	"monk": "the monk", "rider": "the delivery rider", "cook": "the cook", "kitesurfer": "the kitesurfer",
	"instructor": "the ski instructor", "sketcher": "the watercolor painter", "snorkeler": "the snorkeler",
	"haggler": "the flea-market haggler"}

var main: Node2D
var my_dog: Node2D
var who := "kid"
var fired := false
var result := ""  # "", "win", "lose": how the last dare went
var rung := 0     # the dare on offer next: an index into LADDER
var seed_o := 0.0
# the time since the last dare ended, and whether she has left since it did
var since_end := 0.0
var left_since := false
var _said := ""
# whether the dare on offer is one she lost before (kept if the offer lapses)
var _was_again := false
# whether this giver's drawing moves (see _physics_process)
var _moves := false


func setup(m: Node2D, mine: Node2D, giver := "kid") -> void:
	add_to_group("challengers")
	main = m
	my_dog = mine
	who = giver if LINES.has(giver) else "kid"
	# everybody moves (the bronze monkey is the walk's own drawing)
	_moves = who != "monkey"
	# derived from position, never the global RNG - spawning this must not
	# desync the deterministic autowalk traversal
	seed_o = fmod(absf(position.x) * 0.017, TAU)
	# the trick spots near her, marked while this giver's dare is up
	var marks := Node2D.new()
	marks.set_script(DareMarks)
	add_child(marks)
	marks.setup(m)
	var size: Vector2 = FOOTPRINT[who]
	if size == Vector2.ZERO:
		return
	var centre := -_facing() * (10.0 if who == "kid" else 4.0)
	var body := StaticBody2D.new()
	body.position = centre
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	main.add_rope_rect(Rect2(global_position + centre - size * 0.5, size))


# Who gives the dare on this walk.
static func giver_for(lvl: String) -> String:
	return String(WHO.get(lvl, "kid"))


# The music cue for a giver's dare: every giver has a tune of their own
# (audio/music.gd DARES).
static func tune_of(giver: String) -> String:
	return "dare_" + giver


func tune() -> String:
	return tune_of(who)


# How close she has to come before they notice her. The monkey sits up on
# the pier's steps, off the promenade, so he calls to her from further off.
func notice_r() -> float:
	return 330.0 if who == "monkey" else NOTICE_R


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	# the bubble says what the dare is doing, so redraw when that changes
	var said := _line()
	if said != _said:
		_said = said
		Redraw.later(self)
	# a giver whose act moves (the breakdancer's routine, the juggler's clubs,
	# the devil's sparks) redraws while she is near enough to see it; the
	# rest hold their pose between lines
	if _moves and my_dog.global_position.distance_squared_to(global_position) < 640000.0:
		Redraw.later(self)
	# only offer while walking out - not mid off-leash romp or the way home
	if main.phase != "out":
		return
	# the First Walk's kid waits for the dare lesson
	if bool(main.tutorial_mode) and not main.tut_dares_open():
		return
	var d: float = my_dog.global_position.distance_to(global_position)
	# walked off without barking: the offer lapses, and is made again when
	# she comes back (never for the bot, which takes it by itself)
	var ch: Node = main.challenge
	if main.challenge_giver == self and String(ch.phase) == "offer" and bool(ch.waiting) and d > NEAR_R \
			and not bool(main.auto_walk):
		ch.lapse()
		result = "lapsed"
		since_end = 0.0
		left_since = true
		Redraw.later(self)
		return
	if not fired:
		if d < notice_r():
			fired = true
			_offer(false)
		return
	if not can_go_again():
		return
	since_end += delta
	if d > notice_r():
		left_since = true
	# back here, or still close by after a moment: the next dare
	if (left_since and d < notice_r()) or (since_end >= RETRY_WAIT and d < NEAR_R):
		_offer(true)


func _offer(follow_up: bool) -> void:
	var again := result == "lose" or (result == "lapsed" and _was_again)
	_was_again = again
	result = ""
	queue_redraw()
	var dare: Array = ladder()[rung]
	main.start_challenge(self, int(dare[0]), float(dare[1]), follow_up, again)


# Another dare is on offer once the last one is over: never once the ladder
# is climbed, and never for the autowalk bot.
func can_go_again() -> bool:
	return result != "" and has_another_go() and not main.challenge.showing()


# The dares on offer: the First Walk's are easier (systems/tutorial.gd).
func ladder() -> Array:
	return TutorialSteps.YARD_LADDER if main != null and bool(main.tutorial_mode) else LADDER


func has_another_go() -> bool:
	return rung < ladder().size() and main != null and not bool(main.auto_walk)


# Which dare is on offer, counting from 1, and how many there are.
func dare_number() -> int:
	return mini(rung, ladder().size() - 1) + 1


func dare_count() -> int:
	return ladder().size()


func display_name() -> String:
	return I18n.of_english(String(NAMES[who]))


func resolve(win: bool) -> void:
	result = "win" if win else "lose"
	if win:
		rung += 1
	since_end = 0.0
	left_since = false
	queue_redraw()


func _facing() -> Vector2:
	# they are at the side of the path watching it, so they face the middle
	# of the corridor rather than always east
	if main == null:
		return Vector2.RIGHT
	return Vector2.RIGHT if position.x < main.walk_cx else Vector2.LEFT


func _draw() -> void:
	# Drawn from ABOVE, like every other person in this game, in the same
	# anatomy language as human.gd: feet, a body disc, a head with hair on
	# the back of it, all turned by which way they are facing.
	var fd := _facing()
	match who:
		"monkey":
			pass  # the statue is the walk's own drawing (systems/passeig.gd)
		"statue":
			_draw_statue(fd)
		"fisher":
			_draw_fisher(fd)
		"builder":
			_draw_builder(fd)
		"skater":
			_draw_skater(fd)
		"busker":
			_draw_busker(fd)
		"avia":
			_draw_avia(fd)
		"runner":
			_draw_runner(fd)
		"painter":
			_draw_painter(fd)
		"fan":
			_draw_fan(fd)
		"commuter":
			_draw_commuter(fd)
		"breaker":
			_draw_breaker(fd)
		_:
			if not Cast.draw(self, who, fd, AnimClock.msec() / 1000.0, seed_o):
				_draw_kid(fd)


# What they are saying, for the world's speech layer (world/pops_layer.gd),
# which draws it over everything in the world: the tail points at their head.
func speech() -> Dictionary:
	if main == null or main.pops == null:
		return {}
	var head := Vector2(0.0, -28.0) if who == "monkey" else _facing() * 26.0 + Vector2(0.0, -22.0)
	return {"tip": main.pops.to_local(to_global(head)), "text": _line(), "split": I18n.of_english(TAKE),
		"paper": SpeechBubble.PAPER_WIN if result == "win" else SpeechBubble.PAPER}


func _person(at: Vector2, fd: Vector2, shirt: Color, skin: Color, hair: Color, hair_style: String,
		headwear: String, headwear_col: Color) -> void:
	var env: Array = HumanLook.env(self)
	var dress: Dictionary = HumanLook.outfit(String(env[0]), String(env[1]), bool(env[2]), 5, shirt, headwear,
		headwear_col, "none")
	HumanLook.draw_torso(self, at, fd, Vector2(10.0, 12.5), dress["shirt"], bool(dress["coat"]), dress["scarf"])
	HumanLook.draw_head(self, at + fd * 5.0, fd, 8.0, skin, hair, hair_style, String(dress["headwear"]),
		dress["headwear_col"])


# The kid on a bench: long axis across the path, slats, back rail behind,
# legs out in front and one arm up mid-dare.
func _draw_kid(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var skin := Color(0.88, 0.73, 0.58)
	var jeans := Color(0.28, 0.34, 0.48)
	var seat_l := 62.0
	if main != null:
		main.cast_shadow(self, -fd * 4.0, 20.0, 16.0, 0.18)
	draw_colored_polygon(_bar(-fd * 20.0, side, seat_l, 7.0), Color(0.40, 0.29, 0.19))
	draw_colored_polygon(_bar(-fd * 6.0, side, seat_l, 22.0), Color(0.54, 0.40, 0.26))
	# slats: three planks with a dark gap between them, which is what stops a
	# bench reading as one brown blob from above
	for s: float in [-7.0, 0.0, 7.0]:
		draw_colored_polygon(_bar(-fd * 6.0 + fd * s, side, seat_l - 4.0, 2.4), Color(0.31, 0.22, 0.14, 0.85))
	for e: float in [-1.0, 1.0]:
		draw_colored_polygon(_bar(side * e * (seat_l * 0.42) - fd * 6.0, side, 7.0, 20.0), Color(0.33, 0.24, 0.16))
	var bob := sin(t * 3.0 + seed_o) * 1.2
	var sit := -fd * 7.0 + fd * bob * 0.3
	for e: float in [-1.0, 1.0]:
		draw_line(sit + side * e * 5.0, sit + side * e * 6.5 + fd * 17.0, jeans, 6.0)
		draw_circle(sit + side * e * 6.5 + fd * 19.0, 3.6, Color(0.22, 0.22, 0.26))
	var env: Array = HumanLook.env(self)
	var dress: Dictionary = HumanLook.outfit(String(env[0]), String(env[1]), bool(env[2]), 5,
		Color(0.82, 0.28, 0.33), "cap", Color(0.20, 0.36, 0.62), "none")
	HumanLook.draw_torso(self, sit, fd, Vector2(10.0, 12.5), dress["shirt"], bool(dress["coat"]), dress["scarf"])
	draw_line(sit + side * 9.0, sit + side * 15.0 - fd * 9.0, skin, 4.5)
	var wave := sit - side * 9.0 + fd * 4.0
	var tip := wave - side * (9.0 + sin(t * 6.0 + seed_o) * 3.0) + fd * 13.0
	draw_line(wave, tip, skin, 4.5)
	draw_circle(tip, 3.2, skin)
	var head := sit + fd * 5.0 + fd * bob * 0.4
	HumanLook.draw_head(self, head, fd, 8.0, skin, Color(0.24, 0.17, 0.12), "short", String(dress["headwear"]),
		dress["headwear_col"])


# La Rambla's living statue: on a low box, painted gold from head to toe,
# arms held out stock still, a hat upturned on the paving for coins. Every
# few seconds the head turns, just a little, which is the whole act.
func _draw_statue(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var gold := Color(0.80, 0.64, 0.26)
	var at := -fd * 4.0
	if main != null:
		main.cast_shadow(self, at, 18.0, 18.0, 0.2)
	draw_rect(Rect2(at - Vector2(15.0, 15.0), Vector2(30.0, 30.0)), Color(0.30, 0.26, 0.24))
	draw_rect(Rect2(at - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), Color(0.42, 0.37, 0.33))
	# the hat for coins, out front, with a coin or two in it
	var hat := fd * 26.0 + side * 8.0
	draw_circle(hat, 7.0, Color(0.16, 0.14, 0.14))
	draw_circle(hat, 4.5, Color(0.26, 0.22, 0.20))
	draw_circle(hat + Vector2(1.0, -1.0), 1.4, Color(0.92, 0.82, 0.40))
	draw_circle(hat + Vector2(-1.5, 1.0), 1.2, Color(0.82, 0.82, 0.80))
	# both arms out, as still as the box
	for e: float in [-1.0, 1.0]:
		draw_line(at + side * e * 9.0, at + side * e * 19.0 + fd * 6.0, gold.darkened(0.1), 4.5)
		draw_circle(at + side * e * 19.0 + fd * 6.0, 3.0, gold)
	var turn := 0.35 * sin(t * 0.7 + seed_o) if fmod(t + seed_o, 6.0) < 1.2 else 0.0
	HumanLook.draw_torso(self, at, fd, Vector2(10.0, 12.5), gold)
	HumanLook.draw_head(self, at + fd * 4.0, fd.rotated(turn), 8.0, gold.lightened(0.08), gold.darkened(0.12),
		"short", "cap", gold.darkened(0.05))


# A fisherman on an upturned crate at the quay's edge, rod back over his
# shoulder and out behind him, a bucket at his feet.
func _draw_fisher(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var at := -fd * 4.0
	if main != null:
		main.cast_shadow(self, at, 16.0, 16.0, 0.2)
	draw_rect(Rect2(at - Vector2(13.0, 13.0), Vector2(26.0, 26.0)), Color(0.52, 0.40, 0.26))
	for k in range(3):
		var o := -13.0 + 6.5 * float(k + 1)
		draw_line(at + side * o - fd * 12.0, at + side * o + fd * 12.0, Color(0.38, 0.28, 0.18), 1.5)
	var butt := -fd * 2.0 + side * 6.0
	var rod_tip := butt - fd * 46.0 + side * (14.0 + sin(t * 1.3 + seed_o) * 2.0)
	draw_line(butt, rod_tip, Color(0.20, 0.18, 0.16), 1.8)
	draw_line(rod_tip, rod_tip - fd * 10.0 + side * 3.0, Color(0.85, 0.85, 0.80, 0.6), 0.8)
	var bucket := fd * 18.0 - side * 10.0
	draw_circle(bucket, 6.0, Color(0.20, 0.42, 0.62))
	draw_circle(bucket, 4.2, Color(0.30, 0.48, 0.58))
	for e: float in [-1.0, 1.0]:
		draw_line(at + side * e * 5.0, at + side * e * 6.0 + fd * 16.0, Color(0.26, 0.30, 0.26), 6.0)
		draw_circle(at + side * e * 6.0 + fd * 18.0, 3.6, Color(0.18, 0.16, 0.14))
	_person(at, fd, Color(0.36, 0.44, 0.30), Color(0.80, 0.62, 0.48), Color(0.62, 0.60, 0.58), "bald_spot",
		"cap", Color(0.18, 0.26, 0.40))


# A builder on his break, sat on an upturned bucket in his hi-vis, hard hat
# on, a bocadillo in one hand.
func _draw_builder(fd: Vector2) -> void:
	var side := fd.orthogonal()
	var at := -fd * 4.0
	if main != null:
		main.cast_shadow(self, at, 14.0, 14.0, 0.2)
	# the bucket under him shows behind, its rim and handle
	var bucket := at - fd * 9.0
	draw_circle(bucket, 11.0, Color(0.90, 0.90, 0.88))
	draw_circle(bucket, 8.5, Color(0.70, 0.70, 0.68))
	draw_arc(bucket, 13.0, fd.angle() + PI - 1.0, fd.angle() + PI + 1.0, 8, Color(0.40, 0.40, 0.42), 1.5)
	for e: float in [-1.0, 1.0]:
		draw_line(at + side * e * 5.0, at + side * e * 7.0 + fd * 16.0, Color(0.30, 0.32, 0.38), 6.5)
		draw_circle(at + side * e * 7.0 + fd * 18.0, 4.0, Color(0.36, 0.26, 0.16))
	var hivis := Color(0.98, 0.56, 0.12)
	_person(at, fd, hivis, Color(0.76, 0.58, 0.44), Color(0.20, 0.16, 0.12), "short", "none", Color.BLACK)
	# the reflective band across the vest
	draw_line(at + side * 10.0 + fd * 2.0, at - side * 10.0 + fd * 2.0, Color(0.92, 0.92, 0.86), 2.0)
	# the hard hat: a dome with its brim all round and a ridge front to back
	var head := at + fd * 5.0
	draw_circle(head + Vector2(0.8, 1.0), 8.6, Color(0.0, 0.0, 0.0, 0.22))
	draw_circle(head, 8.6, Color(0.96, 0.84, 0.14))
	draw_circle(head - fd * 0.8, 6.6, Color(0.99, 0.90, 0.30))
	draw_line(head - fd * 5.5, head + fd * 5.5, Color(0.88, 0.74, 0.10), 1.6)
	# the bocadillo, half eaten, up to his mouth for a bite every few seconds
	var t := AnimClock.msec() / 1000.0
	var c := fmod(t + seed_o, 3.4)
	var bite := clampf(minf(c / 0.35, (1.2 - c) / 0.35), 0.0, 1.0) if c < 1.2 else 0.0
	# and between bites he waves it about as he talks
	var talk := side * sin(t * 2.6 + seed_o) * 1.6 * (1.0 - bite)
	var hand := (at + side * 13.0 + fd * 8.0 + talk).lerp(at + side * 6.0 + fd * 13.0, bite)
	draw_line(at + side * 9.0, hand, hivis.darkened(0.1), 4.5)
	var loaf := (fd * 9.0).lerp(-side * 7.0 + fd * 2.0, bite)
	draw_line(hand - side * 2.0, hand + loaf - side * 2.0, Color(0.86, 0.66, 0.38), 5.0)


# A skater on rollerblades, the way the seafront and the river parks are full
# of them: standing, rocking heel to toe, helmet and knee pads on.
func _draw_skater(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var rock := sin(t * 2.4 + seed_o) * 2.0
	if main != null:
		main.cast_shadow(self, Vector2.ZERO, 12.0, 14.0, 0.2)
	for e: float in [-1.0, 1.0]:
		# feet apart in a skater's stance, one a little ahead of the other
		var foot := side * e * 11.0 + fd * rock * e
		# the boot along its frame, four bright wheels showing either side
		draw_line(foot - fd * 10.0, foot + fd * 10.0, Color(0.14, 0.14, 0.16), 5.0)
		for w in range(4):
			draw_circle(foot - fd * 8.5 + fd * 5.6 * float(w), 2.0, Color(0.30, 0.86, 0.80))
		draw_circle(foot + fd * 2.0, 3.2, Color(0.22, 0.22, 0.26))
		# the knee pad, above the boot
		draw_circle(foot * 0.7 + fd * 4.0, 2.6, Color(0.10, 0.10, 0.10))
	var torso := -fd * 1.0
	HumanLook.draw_torso(self, torso, fd, Vector2(8.0, 10.0), Color(0.24, 0.70, 0.64))
	# arms out wide for balance
	for e: float in [-1.0, 1.0]:
		draw_line(torso + side * e * 7.0, torso + side * e * 19.0 + fd * 2.0, Color(0.84, 0.66, 0.50), 3.6)
		draw_circle(torso + side * e * 19.0 + fd * 2.0, 2.4, Color(0.84, 0.66, 0.50))
	var head := torso + fd * 3.0
	# the helmet, vented, no bigger than a head
	draw_circle(head + Vector2(0.8, 1.0), 6.6, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(head, 6.4, Color(0.94, 0.30, 0.38))
	draw_circle(head - fd * 1.0 + Vector2(-1.5, -1.5), 3.0, Color(0.98, 0.52, 0.58))
	for e: float in [-1.0, 1.0]:
		draw_line(head - fd * 4.0 + side * e * 2.4, head + fd * 2.0 + side * e * 2.4, Color(0.62, 0.16, 0.22), 1.2)
	# her face peering out under the peak
	draw_circle(head + fd * 5.0, 2.6, Color(0.84, 0.66, 0.50))


# A busker on a folding stool with an acoustic guitar across him, the case
# open on the ground in front for coins, his foot tapping.
func _draw_busker(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var at := -fd * 4.0
	if main != null:
		main.cast_shadow(self, at, 15.0, 15.0, 0.2)
	# the open case, lined in red, a few coins in it
	var case_at := fd * 26.0
	draw_colored_polygon(_bar(case_at, side, 34.0, 14.0), Color(0.16, 0.14, 0.14))
	draw_colored_polygon(_bar(case_at, side, 30.0, 10.0), Color(0.62, 0.14, 0.18))
	for k in range(3):
		draw_circle(case_at + side * (float(k) - 1.0) * 7.0 + fd * (float(k % 2) - 0.5) * 3.0, 1.5,
			Color(0.92, 0.82, 0.40))
	var glint := clampf(sin(t * 3.5 + seed_o), 0.0, 1.0)
	if glint > 0.7:
		draw_circle(case_at + side * 7.0, 2.0, Color(1.0, 0.98, 0.75, (glint - 0.7) / 0.3 * 0.75))
	draw_rect(Rect2(at - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), Color(0.30, 0.24, 0.18))
	var tap := maxf(0.0, sin(t * 7.0 + seed_o)) * 2.0
	for e: float in [-1.0, 1.0]:
		var foot := at + side * e * 6.0 + fd * (16.0 + (tap if e > 0.0 else 0.0))
		draw_line(at + side * e * 5.0, foot, Color(0.22, 0.24, 0.30), 6.0)
		draw_circle(foot + fd * 2.0, 3.6, Color(0.16, 0.12, 0.10))
	_person(at, fd, Color(0.86, 0.80, 0.66), Color(0.80, 0.60, 0.46), Color(0.16, 0.12, 0.10), "long", "none",
		Color.BLACK)
	# the guitar across his lap: the body, the sound hole, the neck to one side
	var body := at + fd * 8.0 + side * 3.0
	draw_circle(body + side * 3.0, 6.0, Color(0.78, 0.52, 0.24))
	draw_circle(body - side * 3.5, 7.0, Color(0.78, 0.52, 0.24))
	draw_circle(body - side * 1.0, 2.2, Color(0.20, 0.12, 0.06))
	# rosette ring around sound hole
	draw_arc(body - side * 1.0, 3.4, 0.0, TAU, 10, Color(0.92, 0.74, 0.44, 0.7), 1.0)
	var neck_end := body + side * 22.0 - fd * 3.0
	draw_line(body + side * 6.0, neck_end, Color(0.36, 0.22, 0.12), 3.0)
	# headstock, tuning pegs and classical strings
	var head := neck_end + side * 2.5
	draw_circle(head, 2.2, Color(0.36, 0.22, 0.12))
	draw_circle(head + side * 1.5, 1.3, Color(0.86, 0.86, 0.88))
	draw_line(body - side * 2.0, head, Color(0.95, 0.94, 0.90, 0.6), 1.0)
	# the strumming hand
	draw_circle(body - side * 1.0 + fd * (2.0 + sin(t * 9.0 + seed_o) * 1.5), 2.6, Color(0.80, 0.60, 0.46))


# An àvia from the market: grey hair in a bun, cardigan, her tartan shopping
# trolley at her side with a leek poking out of it.
func _draw_avia(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var at := -fd * 2.0
	# she jiggles the trolley as she talks, and shakes her head at you now
	# and then: tut-tut
	var jig := sin(t * 7.0 + seed_o) * 1.2
	var tut := 0.3 * sin(t * 9.0) if fmod(t + seed_o, 5.0) < 0.9 else 0.0
	if main != null:
		main.cast_shadow(self, at, 13.0, 14.0, 0.2)
	# the trolley: two wheels, the tartan bag, the handle back to her hand
	var trol := at + side * 20.0 - fd * 2.0 + fd * jig
	draw_circle(trol - fd * 7.0 + side * 6.0, 3.0, Color(0.14, 0.14, 0.14))
	draw_circle(trol - fd * 7.0 - side * 6.0, 3.0, Color(0.14, 0.14, 0.14))
	draw_colored_polygon(_bar(trol, side, 16.0, 18.0), Color(0.62, 0.14, 0.18))
	for k in range(-1, 2):
		draw_line(trol + side * float(k) * 4.5 - fd * 9.0, trol + side * float(k) * 4.5 + fd * 9.0,
			Color(0.16, 0.30, 0.22), 1.4)
		draw_line(trol - side * 8.0 + fd * float(k) * 4.5, trol + side * 8.0 + fd * float(k) * 4.5,
			Color(0.16, 0.30, 0.22), 1.4)
	# a leek out of the top
	draw_line(trol + fd * 2.0, trol + fd * 2.0 - side * 4.0 - fd * 16.0, Color(0.88, 0.92, 0.80), 3.0)
	draw_line(trol - side * 4.0 - fd * 14.0, trol - side * 6.0 - fd * 22.0, Color(0.30, 0.56, 0.26), 4.0)
	draw_line(at + side * 8.0, trol - side * 6.0 + fd * 6.0, Color(0.30, 0.30, 0.32), 1.6)
	for e: float in [-1.0, 1.0]:
		draw_circle(at + side * e * 5.0 + fd * 10.0, 3.4, Color(0.20, 0.16, 0.14))
	_person(at, fd.rotated(tut), Color(0.56, 0.36, 0.52), Color(0.86, 0.70, 0.58), Color(0.80, 0.80, 0.82), "bun",
		"none", Color.BLACK)


# A runner on Montjuïc, stopped to stretch: one leg out behind in a lunge,
# ponytail, a headband, hands on her front knee.
func _draw_runner(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var at := Vector2.ZERO
	var lean := (0.5 + 0.5 * sin(t * 1.6 + seed_o)) * 2.0
	if main != null:
		main.cast_shadow(self, at, 12.0, 16.0, 0.2)
	var skin := Color(0.70, 0.50, 0.36)
	# the lunge: front foot forward, back leg long behind
	draw_line(at + side * 4.0, at + side * 5.0 + fd * (14.0 + lean), Color(0.12, 0.12, 0.16), 5.5)
	draw_circle(at + side * 5.0 + fd * (16.0 + lean), 3.4, Color(0.96, 0.40, 0.48))
	draw_line(at - side * 4.0, at - side * 5.0 - fd * 18.0, Color(0.12, 0.12, 0.16), 5.0)
	draw_circle(at - side * 5.0 - fd * 21.0, 3.2, Color(0.96, 0.40, 0.48))
	var torso := at + fd * lean * 0.5
	HumanLook.draw_torso(self, torso, fd, Vector2(8.5, 10.5), Color(0.98, 0.78, 0.18))
	# hands on the front knee
	draw_line(torso + side * 7.0, at + side * 6.0 + fd * 9.0, skin, 3.4)
	draw_line(torso - side * 7.0, at + side * 3.0 + fd * 9.0, skin, 3.4)
	var head := torso + fd * 4.0
	HumanLook.draw_head(self, head, fd, 7.0, skin, Color(0.14, 0.10, 0.08), "short")
	# the ponytail swinging behind, and the headband
	var swing := sin(t * 3.2 + seed_o) * 2.0
	draw_line(head - fd * 5.0, head - fd * 13.0 + side * swing, Color(0.14, 0.10, 0.08), 3.6)
	draw_line(head + side * 6.6 + fd * 1.0, head - side * 6.6 + fd * 1.0, Color(0.16, 0.62, 0.86), 2.2)


# A painter at her easel in Park Güell: a beret, a palette in one hand, the
# canvas on its three legs in front of her with the view half done.
func _draw_painter(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var at := -fd * 4.0
	if main != null:
		main.cast_shadow(self, at, 14.0, 14.0, 0.2)
	draw_circle(at, 9.0, Color(0.36, 0.28, 0.20))
	# the easel: three legs, the canvas across them, painted
	var easel := fd * 20.0
	for e: float in [-1.0, 1.0]:
		draw_line(easel + side * e * 4.0, easel + side * e * 13.0 + fd * 6.0, Color(0.52, 0.36, 0.20), 1.8)
	draw_line(easel, easel - fd * 8.0, Color(0.52, 0.36, 0.20), 1.8)
	var canvas := PackedVector2Array([easel - side * 12.0 - fd * 1.0, easel + side * 12.0 - fd * 1.0,
		easel + side * 12.0 + fd * 3.0, easel - side * 12.0 + fd * 3.0])
	draw_colored_polygon(canvas, Color(0.96, 0.95, 0.90))
	for k in range(4):
		var c: Color = [Color(0.26, 0.56, 0.86), Color(0.96, 0.70, 0.20), Color(0.30, 0.66, 0.36),
			Color(0.90, 0.30, 0.24)][k]
		draw_line(easel - side * (9.0 - 5.5 * float(k)) + fd * 1.0, easel - side * (5.0 - 5.5 * float(k)) + fd * 1.0, c, 2.6)
	for e: float in [-1.0, 1.0]:
		draw_line(at + side * e * 5.0, at + side * e * 6.0 + fd * 14.0, Color(0.22, 0.20, 0.26), 6.0)
		draw_circle(at + side * e * 6.0 + fd * 16.0, 3.4, Color(0.18, 0.14, 0.12))
	_person(at, fd, Color(0.96, 0.96, 0.92), Color(0.88, 0.72, 0.60), Color(0.66, 0.30, 0.16), "long", "none",
		Color.BLACK)
	# the beret, tipped to one side
	var head := at + fd * 5.0
	draw_circle(head - fd * 1.0 + side * 1.5, 8.2, Color(0.18, 0.16, 0.18))
	draw_circle(head - fd * 1.5 + side * 2.5, 1.4, Color(0.10, 0.10, 0.12))
	# the palette, and the brush hand dabbing at the canvas
	var pal := at - side * 13.0 + fd * 4.0
	draw_circle(pal, 5.0, Color(0.84, 0.70, 0.50))
	for k in range(3):
		draw_circle(pal + Vector2.from_angle(float(k) * 2.0) * 2.6, 1.2,
			[Color(0.90, 0.30, 0.24), Color(0.26, 0.56, 0.86), Color(0.96, 0.80, 0.20)][k])
	var dab := at + side * 9.0 + fd * (12.0 + sin(t * 2.8 + seed_o) * 2.0)
	draw_line(at + side * 8.0, dab, Color(0.88, 0.72, 0.60), 3.2)
	draw_line(dab, dab + fd * 5.0, Color(0.30, 0.20, 0.12), 1.2)


# A football fan on match day: home colours, a striped scarf round the neck
# and the flag up over his head, waving.
func _draw_fan(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var blue := Color(0.16, 0.30, 0.62)
	var claret := Color(0.56, 0.12, 0.24)
	var at := Vector2.ZERO
	if main != null:
		main.cast_shadow(self, at, 12.0, 14.0, 0.2)
	for e: float in [-1.0, 1.0]:
		draw_circle(at + side * e * 5.0 + fd * 9.0, 3.4, Color(0.92, 0.92, 0.90))
	HumanLook.draw_torso(self, at, fd, Vector2(9.5, 12.0), claret, false, blue)
	# the flag: the pole up from his hand, the cloth flying off it in stripes
	var hand := at + side * 12.0 + fd * 2.0
	var top := hand - fd * 4.0 + side * 6.0
	draw_line(at + side * 8.0, hand, Color(0.84, 0.66, 0.50), 3.6)
	draw_line(hand, top, Color(0.30, 0.26, 0.22), 1.6)
	var wave := sin(t * 5.0 + seed_o) * 3.0
	for k in range(5):
		var c := blue if k % 2 == 0 else claret
		var a0 := top - fd * float(k) * 3.0
		draw_line(a0, a0 + side * (16.0 + wave * (float(k) * 0.3)) - fd * 2.0, c, 3.0)
	HumanLook.draw_head(self, at + fd * 4.0, fd, 8.0, Color(0.86, 0.68, 0.54), Color(0.30, 0.20, 0.14), "short",
		"cap", blue)


# A commuter sat on his wheeled suitcase at L'Estació, tie loosened, phone in
# hand, waiting on a late train.
func _draw_commuter(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var at := -fd * 4.0
	# a foot tapping, and every few seconds a look up the line for the train
	var tap := maxf(0.0, sin(t * 9.0 + seed_o)) * 2.5
	var look := 0.5 * smoothstep(0.0, 0.3, fmod(t + seed_o, 4.5)) * (1.0 - smoothstep(1.0, 1.3, fmod(t + seed_o, 4.5))) 		if fmod(t + seed_o, 4.5) < 1.3 else 0.0
	if main != null:
		main.cast_shadow(self, at, 15.0, 13.0, 0.2)
	# the suitcase, on its side, the handle out
	draw_colored_polygon(_bar(at, side, 28.0, 18.0), Color(0.18, 0.24, 0.34))
	draw_colored_polygon(_bar(at, side, 24.0, 14.0), Color(0.24, 0.32, 0.44))
	draw_line(at + side * 14.0, at + side * 22.0, Color(0.50, 0.52, 0.56), 2.0)
	for e: float in [-1.0, 1.0]:
		var toe := fd * (tap if e > 0.0 else 0.0)
		draw_line(at + side * e * 5.0, at + side * e * 6.0 + fd * 16.0 + toe, Color(0.22, 0.22, 0.26), 6.0)
		draw_circle(at + side * e * 6.0 + fd * 18.0 + toe, 3.6, Color(0.10, 0.08, 0.08))
	var shirt := Color(0.86, 0.90, 0.96)
	_person(at, fd.rotated(look), Color(0.30, 0.32, 0.38), Color(0.84, 0.66, 0.52), Color(0.20, 0.16, 0.12), "short", "none",
		Color.BLACK)
	# the open collar and the loosened tie
	draw_circle(at + fd * 7.0, 3.4, shirt)
	draw_line(at + fd * 6.0, at + fd * 13.0 + side * 1.5, Color(0.70, 0.20, 0.22), 2.4)
	# the phone in both hands, lit
	var ph := at + fd * 12.0
	draw_line(at + side * 8.0, ph + side * 3.0, Color(0.84, 0.66, 0.52), 3.2)
	draw_line(at - side * 8.0, ph - side * 3.0, Color(0.84, 0.66, 0.52), 3.2)
	draw_colored_polygon(_bar(ph, side, 6.0, 9.0), Color(0.10, 0.10, 0.12))
	draw_colored_polygon(_bar(ph, side, 4.4, 7.0), Color(0.60, 0.82, 0.96).lightened(0.15 * maxf(0.0, sin(t * 3.0))))


# A breakdancer practising in the ticket hall: a sheet of flattened cardboard
# taped down for a floor, a boombox against the wall behind, and the b-boy on
# it, toprocking in his tracksuit and backwards cap, then dropping into a
# headspin, legs out in a V and turning.
func _draw_breaker(fd: Vector2) -> void:
	var t := AnimClock.msec() / 1000.0
	var side := fd.orthogonal()
	var skin := Color(0.62, 0.44, 0.32)
	var hoodie := Color(0.94, 0.50, 0.16)
	var pants := Color(0.14, 0.16, 0.22)
	var stripe := Color(0.92, 0.92, 0.90)
	var shoe := Color(0.96, 0.96, 0.94)
	if main != null:
		main.cast_shadow(self, -fd * 4.0, 16.0, 16.0, 0.18)
	# the cardboard: two flattened boxes side by side, their fold, the tape
	var mat := fd * 12.0
	draw_colored_polygon(_bar(mat, side, 44.0, 36.0), Color(0.60, 0.46, 0.28))
	draw_colored_polygon(_bar(mat, side, 42.0, 34.0), Color(0.72, 0.58, 0.38))
	draw_line(mat - side * 21.0, mat + side * 21.0, Color(0.58, 0.44, 0.26), 1.2)
	for e: float in [-1.0, 1.0]:
		draw_colored_polygon(_bar(mat + side * e * 19.0 + fd * 14.0, side, 6.0, 4.0), Color(0.86, 0.80, 0.62, 0.9))
		draw_colored_polygon(_bar(mat + side * e * 19.0 - fd * 14.0, side, 6.0, 4.0), Color(0.86, 0.80, 0.62, 0.9))
	# the boombox against the wall, its two speakers thumping
	var box := -fd * 14.0
	draw_colored_polygon(_bar(box + Vector2(1.5, 2.0), side, 28.0, 13.0), Color(0.0, 0.0, 0.0, 0.25))
	draw_colored_polygon(_bar(box, side, 28.0, 13.0), Color(0.16, 0.16, 0.18))
	draw_colored_polygon(_bar(box - fd * 4.5, side, 18.0, 2.0), Color(0.62, 0.64, 0.68))
	var thump := 0.6 if fmod(t * 2.1 + seed_o, 1.0) < 0.2 else 0.0
	for e: float in [-1.0, 1.0]:
		var sp := box + side * e * 8.0
		draw_circle(sp, 5.0, Color(0.30, 0.30, 0.33))
		draw_circle(sp, 3.4 + thump, Color(0.08, 0.08, 0.09))
		draw_circle(sp, 1.2, Color(0.50, 0.50, 0.54))
	draw_circle(box, 1.6, Color(0.96, 0.40, 0.20))
	var u := fmod(t + seed_o * 0.6, 4.4)
	if u < 3.0:
		# toprock: stepping across and back, arms swinging in front
		var step := sin(t * 6.2 + seed_o)
		var at := mat - fd * 2.0
		for e: float in [-1.0, 1.0]:
			var foot := at + side * e * (9.0 - step * e * 4.0) + fd * (9.0 + step * e * 5.0)
			draw_line(at + side * e * 4.0, foot, pants, 5.5)
			draw_line(at + side * e * 6.5, foot + side * e * 1.5, stripe, 1.0)
			draw_circle(foot + fd * 2.0, 3.4, shoe)
		HumanLook.draw_torso(self, at, fd, Vector2(10.0, 12.0), hoodie)
		for e: float in [-1.0, 1.0]:
			var hand := at + fd * (6.0 + e * step * 5.0) + side * e * (15.0 - step * e * 6.0)
			draw_line(at + side * e * 8.0, hand, hoodie.darkened(0.08), 4.0)
			draw_circle(hand, 2.8, skin)
		var head := at + fd * 4.0
		HumanLook.draw_head(self, head, fd, 8.0, skin, Color(0.10, 0.08, 0.08), "short", "none", Color.BLACK)
		# the cap on backwards, its peak over the back of his neck
		draw_circle(head, 7.4, Color(0.12, 0.42, 0.56))
		draw_colored_polygon(_bar(head - fd * 7.0, side, 9.0, 4.0), Color(0.08, 0.30, 0.42))
	else:
		# the headspin: on his head in the middle of the mat, hands planted
		# either side, legs out in a V and turning
		var at := mat
		var spin := (u - 3.0) * 11.0 + seed_o
		for e: float in [-1.0, 1.0]:
			draw_circle(at + side * e * 11.0 + fd * 3.0, 2.8, skin)
		HumanLook.draw_torso(self, at, Vector2.from_angle(spin), Vector2(9.0, 9.0), hoodie)
		for k in range(2):
			var leg := Vector2.from_angle(spin + (0.0 if k == 0 else 2.3))
			var tip := at + leg * 26.0
			draw_line(at + leg * 5.0, tip, pants, 5.5)
			draw_line(at + leg * 6.0 + leg.orthogonal() * 2.2, tip + leg.orthogonal() * 2.2, stripe, 1.0)
			draw_circle(tip, 3.6, shoe)
		draw_circle(at, 6.6, Color(0.12, 0.42, 0.56))
		draw_circle(at - Vector2(1.5, 1.5), 2.6, Color(0.20, 0.56, 0.70))


# What they are saying, as people talk: the dare spelled out while it is on
# offer (and that a bark takes it), a count while it runs, how it went and
# what comes next.
func _line() -> String:
	var said: Dictionary = LINES[who]
	var ch: Node = main.challenge if main != null else null
	var mine: bool = ch != null and main.challenge_giver == self
	if mine and String(ch.phase) == "offer":
		var dare: String = I18n.of_english(AGAIN if bool(ch.retry) else String(said["dare"])) % [int(ch.target),
			int(round(float(ch.duration)))]
		return dare + " " + I18n.of_english(TAKE) if bool(ch.waiting) else I18n.of_english(GET_READY)
	if mine and String(ch.phase) == "live":
		var left := int(ch.target) - int(ch.count)
		return I18n.of_english(COUNT) % left if left > 1 else I18n.of_english(LAST)
	if result == "win":
		return I18n.of_english(String(said["won" if has_another_go() else "done"]))
	if result == "lose":
		return I18n.of_english(String(said["lost"]))
	return I18n.of_english(String(said["idle"]))


func _bar(at: Vector2, side: Vector2, length: float, depth: float) -> PackedVector2Array:
	# an oriented rectangle, so the bench turns with the sitter
	var fwd := side.orthogonal()
	var h := side * (length * 0.5)
	var d := fwd * (depth * 0.5)
	return PackedVector2Array([at - h - d, at + h - d, at + h + d, at - h + d])

