model BDI_Social_Event_Skeleton

global {
	int guestNum <- 50;
	list<place> place_list;
	float happiness_increment <- 0.05;
	float global_happiness <- 0.5;

	list<map<string, unknown>> interaction_data <- [
		["from"::"Party Animal", "to"::"Party Animal", "mod"::2.0, "init"::"WOOO! Another legend!", "resp"::"HELL YEAH!"],
		["from"::"Party Animal", "to"::"Chill Introvert", "mod"::0.0, "init"::"Yo! Why so quiet?", "resp"::"Sure, but stop whispering!"],
		["from"::"Party Animal", "to"::"Vegan", "mod"::0.5, "init"::"Need a drink or a salad?", "resp"::"Party on, plant person!"],
		["from"::"Party Animal", "to"::"Sociable", "mod"::1.5, "init"::"Life of the party!", "resp"::"New best friend!"],
		["from"::"Party Animal", "to"::"Cultured Trivia Lover", "mod"::0.2, "init"::"Stop reading and start dancing!", "resp"::"Knowledge is cool, but let's shout!"],
		["from"::"Chill Introvert", "to"::"Party Animal", "mod"::-1.0, "init"::"...Hi. Don't scream.", "resp"::"My head hurts."],
		["from"::"Chill Introvert", "to"::"Chill Introvert", "mod"::2.0, "init"::"I like your vibe.", "resp"::"Finally, silence."],
		["from"::"Chill Introvert", "to"::"Vegan", "mod"::0.5, "init"::"Like plants?", "resp"::"Yes, plants are quiet."],
		["from"::"Chill Introvert", "to"::"Sociable", "mod"::0.0, "init"::"Um, hello.", "resp"::"Social battery is low."],
		["from"::"Chill Introvert", "to"::"Cultured Trivia Lover", "mod"::1.5, "init"::"Book recommendations?", "resp"::"18th-century poetry!"],
		["from"::"Vegan", "to"::"Vegan", "mod"::3.0, "init"::"Did you try the kale?", "resp"::"Plant-powered soul!"],
		["from"::"Vegan", "to"::"Party Animal", "mod"::-0.5, "init"::"Is that leather?", "resp"::"Don't spill on my hemp shirt."],
		["from"::"Vegan", "to"::"Chill Introvert", "mod"::1.0, "init"::"Plants are best listeners.", "resp"::"They never interrupt."],
		["from"::"Vegan", "to"::"Sociable", "mod"::1.0, "init"::"Help advocate for menus?", "resp"::"Tell me more!"],
		["from"::"Vegan", "to"::"Cultured Trivia Lover", "mod"::0.8, "init"::"Etymology of broccoli?", "resp"::"Fascinating!"],
		["from"::"Sociable", "to"::"Party Animal", "mod"::1.5, "init"::"Historic night!", "resp"::"What's the plan?"],
		["from"::"Sociable", "to"::"Chill Introvert", "mod"::0.5, "init"::"Don't be shy!", "resp"::"You're very welcoming."],
		["from"::"Sociable", "to"::"Vegan", "mod"::1.0, "init"::"Interesting perspectives!", "resp"::"Happy to share!"],
		["from"::"Sociable", "to"::"Sociable", "mod"::2.0, "init"::"Have we met?", "resp"::"We're about to be inseparable!"],
		["from"::"Sociable", "to"::"Cultured Trivia Lover", "mod"::1.2, "init"::"Best stories!", "resp"::"Ready for an audience!"],
		["from"::"Cultured Trivia Lover", "to"::"Party Animal", "mod"::-0.5, "init"::"Sumerian bars?", "resp"::"Unrefined energy."],
		["from"::"Cultured Trivia Lover", "to"::"Chill Introvert", "mod"::1.5, "init"::"Quiet corner?", "resp"::"Perfect evening."],
		["from"::"Cultured Trivia Lover", "to"::"Vegan", "mod"::1.0, "init"::"Vegan Society 1944?", "resp"::"Well-informed!"],
		["from"::"Cultured Trivia Lover", "to"::"Sociable", "mod"::1.2, "init"::"Coffee lecture?", "resp"::"I'm all ears!"],
		["from"::"Cultured Trivia Lover", "to"::"Cultured Trivia Lover", "mod"::2.5, "init"::"Nobel 1921?", "resp"::"Einstein! Obviously."]
	];

	predicate at_bar <- new_predicate("at_bar");
	predicate at_concert <- new_predicate("at_concert");
	predicate at_library <- new_predicate("at_library");
	predicate want_socialize <- new_predicate("want_socialize");
	predicate go_bar <- new_predicate("go_bar");
	predicate go_concert <- new_predicate("go_concert");
	predicate go_library <- new_predicate("go_library");
	predicate socialize <- new_predicate("socialize");
	predicate stay <- new_predicate("stay");

	init {
		create place number: 3 returns: places;
		ask places[0] { type <- "bar"; location <- {20,20}; }
		ask places[1] { type <- "concert"; location <- {80,80}; }
		ask places[2] { type <- "library"; location <- {85,25}; }
		place_list <- places;
		create guest number: guestNum;
	}

	reflex update_global_stats {
		global_happiness <- mean(guest collect each.happiness);
	}
}

species guest skills: [moving, fipa] control: simple_bdi {
	float happiness <- rnd(0.2,0.8);
	string archetype;
	float initiative;
	float sociability;
	list<predicate> fav_place_intentions;
	place current_place <- nil;

	init {
		archetype <- one_of(["Party Animal", "Chill Introvert", "Vegan", "Sociable", "Cultured Trivia Lover"]);
		switch archetype {
			match "Party Animal" { initiative <- rnd(0.7, 1.0); sociability <- rnd(0.7, 1.0); fav_place_intentions <- [go_bar, go_concert]; }
			match "Chill Introvert" { initiative <- rnd(0.2, 0.5); sociability <- rnd(0.2, 0.5); fav_place_intentions <- [go_library, go_bar]; }
			match "Vegan" { initiative <- rnd(0.4, 0.8); sociability <- rnd(0.4, 0.8); fav_place_intentions <- [go_library, go_bar, go_concert]; }
			match "Sociable" { initiative <- rnd(0.5, 0.9); sociability <- rnd(0.7, 1.0); fav_place_intentions <- [go_library, go_bar, go_concert]; }
			match "Cultured Trivia Lover" { initiative <- rnd(0.3, 0.7); sociability <- rnd(0.5, 0.8); fav_place_intentions <- [go_library, go_bar]; }
		}
	}

	float get_social_drive {
		return max(sociability, (1.0 - happiness));
	}

	map<string, unknown> get_interaction_info(guest other) {
		map<string, unknown> info <- interaction_data first_with (each["from"] = self.archetype and each["to"] = other.archetype);
		return (info != nil) ? info : ["mod"::1.0, "init"::"Hello!", "resp"::"Hi!"];
	}

	perceive target: self {
		place p <- first(place_list where (each.location distance_to self.location < 2.0));
		if (p != nil) {
			current_place <- p;
			if (p.type = "bar") { do add_belief(at_bar); do remove_belief(at_concert); do remove_belief(at_library); }
			else if (p.type = "concert") { do add_belief(at_concert); do remove_belief(at_bar); do remove_belief(at_library); }
			else if (p.type = "library") { do add_belief(at_library); do remove_belief(at_bar); do remove_belief(at_concert); }
		} else {
			current_place <- nil;
			do remove_belief(at_bar); do remove_belief(at_concert); do remove_belief(at_library);
		}
	}

	reflex generate_desires {
		if (flip(self.get_social_drive()) and !(has_desire(want_socialize))) { 
			do add_desire(want_socialize);
		}
	}

	reflex select_intention when: get_current_intention() = nil {
		if (has_desire(want_socialize)) {
			// FIXED: High happiness -> Stay and talk. Low happiness -> Move to new place.
			if (current_place != nil and flip(happiness)) { 
				do add_intention(socialize); 
			} else { 
				do add_intention(one_of(fav_place_intentions)); 
			}
		} else { 
			do add_intention(stay); 
		}
	}

	plan execute_go_bar intention: go_bar { 
		point loc <- (place_list first_with (each.type="bar")).location;
		do goto target: loc speed: 1.5; 
		if (self.location distance_to loc < 1.5) { do remove_intention(go_bar, true); } 
	}
	plan execute_go_library intention: go_library { 
		point loc <- (place_list first_with (each.type="library")).location;
		do goto target: loc speed: 1.5; 
		if (self.location distance_to loc < 1.5) { do remove_intention(go_library, true); } 
	}
	plan execute_go_concert intention: go_concert { 
		point loc <- (place_list first_with (each.type="concert")).location;
		do goto target: loc speed: 1.5; 
		if (self.location distance_to loc < 1.5) { do remove_intention(go_concert, true); } 
	}

	plan execute_socialize intention: socialize {
		guest pal <- one_of(guest at_distance 10 where (each != self));
		if (pal != nil and flip(initiative)) {
			map<string, unknown> info <- self.get_interaction_info(pal);
			do start_conversation to: [pal] protocol: "fipa-request" performative: "propose" contents: [string(info["init"])];
			do remove_intention(socialize, true);
			do remove_desire(want_socialize);
		} else {
			// If lonely/no one near, increase wander or drop intention to move elsewhere
			do wander;
			if (flip(0.2)) { do remove_intention(socialize, true); }
    	}
	}

	plan execute_stay intention: stay { do wander; if (flip(0.1)) { do remove_intention(stay, true); } }

	reflex handle_proposes when: !empty(proposes) {
		loop msg over: proposes {
			guest sender <- guest(msg.sender);
			map<string, unknown> info <- self.get_interaction_info(sender);
			if (flip(self.get_social_drive())) {
				do accept_proposal message: msg contents: [string(info["resp"])];
				happiness <- max(0.0, min(1.0, happiness + (float(info["mod"]) * happiness_increment)));
			} else {
				do reject_proposal message: msg contents: ["Not now."];
			}
		}
		do remove_intention(socialize, true);
		do remove_desire(want_socialize);
	}

	reflex handle_accept_proposals when: !empty(accept_proposals) {
		loop msg over: accept_proposals {
			guest partner <- guest(msg.sender);
			map<string, unknown> info <- self.get_interaction_info(partner);
			happiness <- max(0.0, min(1.0, happiness + (float(info["mod"]) * happiness_increment)));
		}
	}

	reflex handle_reject_proposals when: !empty(reject_proposals) {
		loop msg over: reject_proposals { 
			happiness <- max(0.0, happiness - 0.01); 
		}
	}

	aspect base {
		rgb mood_color <- hsb(happiness * 0.33, 1.0, 1.0); 
		draw circle(1.5) color: mood_color border: #black;
		draw archetype at: location + {0, 2} size: 6 color: #black;
	}
}

species place {
	string type;
	aspect base {
		draw square(15) color: (type = "bar" ? #lightgray : (type="library" ? #lightblue : #lightyellow)) border: #black;
		draw type color: #black size: 10 at: {location.x - 4, location.y - 8};
	}
}

experiment bdi_sim_skeleton type: gui {
	output {
		display main_display {
			species place aspect: base;
			species guest aspect: base;
			graphics "Dashboard" {
				draw "Avg Happiness: " + round(global_happiness * 100) / 100 at: {world.shape.width - 45, 5} color: #black font: font("SansSerif", 18, #bold);
				draw rectangle(38, 6) at: {world.shape.width - 25, 5} color: rgb(255, 255, 255, 150) border: #black;
			}
		}
		display "Happiness Evolution" {
			chart "Average Happiness over Time" type: series {
				data "Global Happiness" value: global_happiness color: #blue;
				data "Target Level" value: 0.8 color: #red style: dot;
			}
		}
	}
}