model BDI_Social_Event

global {
	/* ----------- Simulation Parameters ----------- */
	int guestNum <- 50;
	list<place> place_list;
	
	/* ----------- Predicates Definitions ----------- */
	predicate at_bar         <- new_predicate("at_bar");
	predicate at_concert     <- new_predicate("at_concert");
	predicate likes_noise    <- new_predicate("likes_noise");
	predicate dislikes_noise <- new_predicate("dislikes_noise");

	predicate want_socialize <- new_predicate("want_socialize");
	predicate want_quiet     <- new_predicate("want_quiet");
	predicate want_music     <- new_predicate("want_music");

	predicate go_bar         <- new_predicate("go_bar");
	predicate go_concert     <- new_predicate("go_concert");
	predicate socialize      <- new_predicate("socialize");
	predicate stay           <- new_predicate("stay");

	init {
		create place number: 2 returns: places;
		ask places[0] {
			type <- "bar";
			location <- {20,20};
		}
		ask places[1] {
			type <- "concert";
			location <- {80,80};
		}
		place_list <- places;

		create guest number: guestNum;
	}
}

/* ============================
   GUEST AGENT
   ============================ */

species guest skills: [moving] control: simple_bdi {

	/* ----------- Physical state ----------- */
	place current_place <- nil;
	place target_place <- nil;

	/* ----------- Personality traits ----------- */
	float sociability <- rnd(0.1, 0.9) update: sociability + 0.001; 
	float tolerance   <- rnd(0.1, 0.9);
	string guest_type <- one_of(["party","introverted","observer","vegan","meat"]);

	init {
		do add_desire(want_socialize);
	}

	/* ============================
	   PERCEPTION → BELIEFS
	   ============================ */

	perceive target: self {
		place p <- first(place_list where (each.location distance_to self.location < 2.0));
		if (p != nil) {
			current_place <- p;
			if (p.type = "bar") {
				do replace_belief(at_concert, at_bar);
			} else {
				do replace_belief(at_bar, at_concert);
			}
		} else {
			current_place <- nil;
			do remove_belief(at_bar);
			do remove_belief(at_concert);
		}

		if (tolerance > 0.5) {
			do replace_belief(dislikes_noise, likes_noise);
		} else {
			do replace_belief(likes_noise, dislikes_noise);
		}
	}

	/* ============================
	   BELIEF → DESIRE
	   ============================ */

	reflex generate_desires {
		if (sociability > 0.7) {
			do add_desire(want_socialize);
		}
		if (has_belief(dislikes_noise)) {
			do add_desire(want_quiet);
		}
		if (has_belief(likes_noise)) {
			do add_desire(want_music);
		}
	}

	/* ============================
	   DESIRE → INTENTION (Reasoning)
	   ============================ */

	// FIX: Use get_current_intention() instead of current_intention
	reflex select_intention when: get_current_intention() = nil {
		
		if (has_desire(want_socialize) and current_place != nil) {
			do add_intention(socialize);
		} 
		else if (has_desire(want_quiet) and !has_belief(at_bar)) {
			do add_intention(go_bar);
		}
		else if (has_desire(want_music) and !has_belief(at_concert)) {
			do add_intention(go_concert);
		}
		else {
			do add_intention(stay);
		}
	}

	/* ============================
	   PLANS
	   ============================ */

	plan execute_go_bar intention: go_bar {
		target_place <- one_of(place_list where (each.type = "bar"));
		do goto target: target_place.location speed: 1.5;

		if (distance_to(self, target_place) < 1) {
			write name + " reached the Bar.";
			do remove_desire(want_quiet);
			do remove_intention(go_bar, true);
		}
	}

	plan execute_go_concert intention: go_concert {
		target_place <- one_of(place_list where (each.type = "concert"));
		do goto target: target_place.location speed: 1.5;

		if (distance_to(self, target_place) < 1) {
			write name + " reached the Concert.";
			do remove_desire(want_music);
			do remove_intention(go_concert, true);
		}
	}

	plan execute_socialize intention: socialize {
		list<guest> potential_friends <- guest at_distance(5.0) where (each != self and each.current_place = self.current_place);
		
		if (!empty(potential_friends)) {
			guest pal <- one_of(potential_friends);
			write name + " is chatting with " + pal.name;
			
			sociability <- sociability - 0.2;
			do remove_desire(want_socialize);
			do remove_intention(socialize, true);
		} else {
			do wander amplitude: 30.0 speed: 0.2;
			if (flip(0.05)) { do remove_intention(socialize, true); }
		}
	}

	plan execute_stay intention: stay {
		if (flip(0.05)) {
			sociability <- rnd(0.4, 0.9);
			do remove_intention(stay, true);
		}
	}

	/* ============================
	   VISUALIZATION
	   ============================ */

	aspect base {
		rgb agent_color <- #blue;
		
		// FIX: Use get_intention(predicate) != nil instead of has_intention
		if (get_intention(socialize) != nil) { agent_color <- #green; }
		if (get_intention(go_bar) != nil or get_intention(go_concert) != nil) { agent_color <- #red; }
		
		draw circle(1.5) color: agent_color border: #black;
	}
}

species place {
	string type;
	aspect base {
		draw square(15) color: (type = "bar" ? #lightgray : #lightyellow) border: #black;
		draw type color: #black size: 10 at: {location.x - 4, location.y - 8};
	}
}

experiment social_sim type: gui {
	output {
		display main_display {
			species place aspect: base;
			species guest aspect: base;
		}
	}
}