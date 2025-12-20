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
	predicate is_happy		 <- new_predicate("is_happy");

	// Archetypes
	predicate is_party_animal <- new_predicate("is_party_animal");
	predicate is_introvert    <- new_predicate("is_introvert");
	predicate is_music_lover  <- new_predicate("is_music_lover");
	predicate is_foodie       <- new_predicate("is_foodie");
	predicate is_philanthropist <- new_predicate("is_philanthropist");

	predicate want_socialize <- new_predicate("want_socialize");
	predicate want_quiet     <- new_predicate("want_quiet");
	predicate want_music     <- new_predicate("want_music");
	predicate want_food      <- new_predicate("want_food");

	predicate go_bar         <- new_predicate("go_bar");
	predicate go_concert     <- new_predicate("go_concert");
	predicate socialize      <- new_predicate("socialize");
	predicate stay           <- new_predicate("stay");
	predicate eat            <- new_predicate("eat");

	init {
		create place number: 2 returns: places;
		ask places[0] {
			type <- "bar";
			location <- {20,20};
			noise_level <- 0.8;
		}
		ask places[1] {
			type <- "concert";
			location <- {80,80};
			noise_level <- 0.9;
			current_band <- one_of(['rock', 'pop', 'jazz', 'classical', 'electronic']);
		}
		place_list <- places;

		create guest number: guestNum;
	}
}

/* ============================
   GUEST AGENT
   ============================ */

species guest skills: [moving, fipa] control: simple_bdi {

	/* ----------- Physical state ----------- */
	place current_place <- nil;
	place target_place <- nil;

	/* ----------- Personality traits ----------- */
	float sociability <- rnd(0.1, 0.9); 
	float generosity <- rnd(0.1, 0.9);
	string musical_taste <- one_of(['rock', 'pop', 'jazz', 'classical', 'electronic']);
	string favorite_food <- one_of(['pizza', 'burger', 'sushi', 'salad', 'pasta']);
	string archetype <- one_of(["Party Animal", "Introvert", "Music Lover", "Foodie", "Philanthropist"]);
	float happiness <- 0.5;

	init {
		if (archetype = "Party Animal") {
			sociability <- rnd(0.7, 1.0);
		} else if (archetype = "Introvert") {
			sociability <- rnd(0.0, 0.3);
		} else {
			sociability <- rnd(0.3, 0.7);
		}
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

		// Update beliefs based on archetype
		if (archetype = "Party Animal") {
			do add_belief(is_party_animal);
			do replace_belief(dislikes_noise, likes_noise);
		} else if (archetype = "Introvert") {
			do add_belief(is_introvert);
			do replace_belief(likes_noise, dislikes_noise);
		} else if (archetype = "Music Lover") {
			do add_belief(is_music_lover);
			do replace_belief(dislikes_noise, likes_noise);
		} else if (archetype = "Foodie") {
			do add_belief(is_foodie);
		} else if (archetype = "Philanthropist") {
			do add_belief(is_philanthropist); 
		}

		if (happiness > 0.6) {
			do add_belief(is_happy);
		} else {
			do remove_belief(is_happy);
		}
	}

	/* ============================
	   BELIEF → DESIRE
	   ============================ */

	reflex generate_desires {
		if (has_belief(is_party_animal) and sociability > 0.6) {
			do add_desire(want_socialize);
		}
		if (has_belief(is_introvert) and sociability < 0.4) {
			do add_desire(want_quiet);
		}
		if (has_belief(is_music_lover)) {
			do add_desire(want_music);
		}
		if (has_belief(is_foodie)) {
			do add_desire(want_food);
		}
		if (has_belief(is_philanthropist) and generosity > 0.6) {
			do add_desire(want_socialize);
		}
	}

	/* ============================
	   DESIRE → INTENTION (Reasoning)
	   ============================ */

	reflex select_intention when: get_current_intention() = nil {
		
		if (has_desire(want_socialize)) {
			if(current_place != nil){
				do add_intention(socialize);
			} else {
				if(flip(0.5)){
					do add_intention(go_bar);
				} else {
					do add_intention(go_concert);
				}
			}
		} 
		else if (has_desire(want_quiet)) {
			if (has_belief(at_bar) or has_belief(at_concert)) {
				do add_intention(stay); // wander around, but not engaging
			} else {
				// if not in a place, just stay where it is
				do add_intention(stay);
			}
		}
		else if (has_desire(want_music) and !has_belief(at_concert)) {
			do add_intention(go_concert);
		}
		else if (has_desire(want_food)) {
			do add_intention(eat); 
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

	plan execute_eat intention: eat {
		if (!has_belief(at_bar)) {
			target_place <- one_of(place_list where (each.type = "bar"));
			do goto target: target_place.location speed: 1.5;
		} else {
			// once at the bar, "eat"
			write name + " is eating " + favorite_food;
			happiness <- happiness + 0.3;
			do remove_desire(want_food);
			do remove_intention(eat, true);
		}
	}

	plan execute_socialize intention: socialize {
		list<guest> potential_friends <- guest at_distance(5.0) where (each != self and each.current_place = self.current_place);
		
		if (!empty(potential_friends)) {
			guest pal <- one_of(potential_friends);
			// Propose to chat with the potential friend
			do propose to: pal with: "chat";
			
			// After sending the proposal, remove the intention.
			// The response will be handled by the handle_messages reflex.
			do remove_intention(socialize, true);
			do remove_desire(want_socialize);
		} else {
			// If no one is around, just wander
			do wander amplitude: 30.0 speed: 0.2;
			if (flip(0.05)) { 
				do remove_intention(socialize, true); 
			}
		}
	}

	plan execute_stay intention: stay {
		if (flip(0.05)) {
			sociability <- rnd(0.4, 0.9);
			do remove_intention(stay, true);
		}
	}

	reflex handle_proposes when: !empty(proposes) {
		loop msg over: proposes {
			if ((msg.contents at 0) = "chat") {
				// Someone wants to chat. Decide whether to accept.
				bool accept <- false;
				if (has_belief(is_introvert)) {
					// Introverts are less likely to accept
					if (flip(0.2)) {
						accept <- true;
					}
				} else if (has_belief(is_party_animal)) {
					// Party animals are very likely to accept
					if (flip(0.9)) {
						accept <- true;
					}
				} else {
					// Other archetypes have a medium chance
					if (flip(0.6)) {
						accept <- true;
					}
				}

				if (accept) {
					// Accept the proposal
					do accept_proposal message: msg contents: ["chat_accepted"];
					happiness <- happiness + 0.1;
					write name + " accepted chat with " + msg.sender;
				} else {
					// Reject the proposal
					do reject_proposal message: msg contents: ["chat_rejected"];
					write name + " rejected chat with " + msg.sender;
				}
			}
		}
	}

	reflex handle_accept_proposals when: !empty(accept_proposals) {
		loop msg over: accept_proposals {
			happiness <- happiness + 0.2;
			write name + " is happy to chat with " + msg.sender;
		}
	}

	reflex handle_reject_proposals when: !empty(reject_proposals) {
		loop msg over: reject_proposals {
			happiness <- happiness - 0.1;
			write name + " was rejected by " + msg.sender;
		}
	}

	/* ============================
	   VISUALIZATION
	   ============================ */

	aspect base {
		rgb color;
		if (archetype = "Party Animal") {
			color <- #red;
		} else if (archetype = "Introvert") {
			color <- #green;
		} else if (archetype = "Music Lover") {
			color <- #yellow;
		} else if (archetype = "Foodie") {
			color <- #purple;
		} else if (archetype = "Philanthropist") {
			color <- #orange;
		}

		// Tint the color based on intention
		if (get_current_intention() != nil) {
			if (get_current_intention() = socialize) {
				color <- #green;
			} else if (get_current_intention() = go_bar or get_current_intention() = go_concert or get_current_intention() = eat) {
				color <- #red;
			}
		}
		
		draw circle(1.5) color: color border: #black;
		draw string(archetype) color: #white size: 8 at: {location.x, location.y - 2};
		draw string("H:" + round(happiness*100)/100.0) color: #white size: 8 at: {location.x, location.y + 2};
	}
}

species place {
	string type;
	float noise_level;
	string current_band;

	aspect base {
		draw square(15) color: (type = "bar" ? #lightgray : #lightyellow) border: #black;
		draw type color: #black size: 10 at: {location.x - 4, location.y - 8};
		if (current_band != nil) {
			draw "♫ " + current_band + " ♫" color: #black size: 10 at: {location.x - 10, location.y + 8};
		}
	}
}

experiment social_sim type: gui {
	output {
		display main_display {
			species place aspect: base;
			species guest aspect: base;
		}

//		chart "Global Happiness" type: series {
//			data "Average" value: guest mean (each.happiness) color: #blue;
//			data "Party Animal" value: guest with (each.archetype = "Party Animal") mean (each.happiness) color: #red;
//			data "Introvert" value: guest with (each.archetype = "Introvert") mean (each.happiness) color: #green;
//			data "Music Lover" value: guest with (each.archetype = "Music Lover") mean (each.happiness) color: #yellow;
//			data "Foodie" value: guest with (each.archetype = "Foodie") mean (each.happiness) color: #purple;
//			data "Philanthropist" value: guest with (each.archetype = "Philanthropist") mean (each.happiness) color: #orange;
//		}
//
//		chart "Agent Distribution" type: pie {
//			data "Bar" value: length(guest where (each.current_place != nil and each.current_place.type = "bar")) color: #lightgray;
//			data "Concert" value: length(guest where (each.current_place != nil and each.current_place.type = "concert")) color: #lightyellow;
//			data "Roaming" value: length(guest where (each.current_place = nil)) color: #lightblue;
//		}
	}
}