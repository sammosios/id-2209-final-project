model BDI_Social_Event_Skeleton

global {
	int guestNum <- 50;
	list<place> place_list;

	predicate at_bar         <- new_predicate("at_bar");
	predicate at_concert     <- new_predicate("at_concert");
	predicate want_socialize <- new_predicate("want_socialize");
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

species guest skills: [moving, fipa] control: simple_bdi {
	place current_place <- nil;
	place target_place <- nil;
	float sociability <- rnd(0.1, 0.9);
	float happiness <- 0.5;

	init {
		do add_desire(want_socialize);
	}

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
	}

	reflex generate_desires {
		if (sociability > 0.7) {
			do add_desire(want_socialize);
		}
	}

	reflex select_intention when: get_current_intention() = nil {
		if (has_desire(want_socialize)) {
			if (current_place != nil) {
				do add_intention(socialize);
			} else {
				if (flip(0.5)) {
					do add_intention(go_bar);
				} else {
					do add_intention(go_concert);
				}
			}
		} else {
			do add_intention(stay);
		}
	}

	plan execute_go_bar intention: go_bar {
		target_place <- one_of(place_list where (each.type = "bar"));
		do goto target: target_place.location speed: 1.5;

		if (distance_to(self, target_place) < 1) {
			do remove_intention(go_bar, true);
		}
	}

	plan execute_go_concert intention: go_concert {
		target_place <- one_of(place_list where (each.type = "concert"));
		do goto target: target_place.location speed: 1.5;

		if (distance_to(self, target_place) < 1) {
			do remove_intention(go_concert, true);
		}
	}

	plan execute_socialize intention: socialize {
		guest pal <- one_of(guest at_distance 5 where (each != self));
		if (pal != nil) {
			do start_conversation to: [pal] protocol: "fipa-request" performative: "propose" contents: ["chat"];
			do remove_intention(socialize, true);
			do remove_desire(want_socialize);
		} else {
			do wander;
		}
	}

	plan execute_stay intention: stay {
		do wander;
		if (flip(0.1)) {
			do remove_intention(stay, true);
		}
	}

	reflex handle_proposes when: !empty(proposes) {
		loop msg over: proposes {
			if (msg.contents[0] = "chat") {
				if (flip(sociability)) {
					do accept_proposal message: msg contents: ["yes"];
					happiness <- happiness + 0.1;
				} else {
					do reject_proposal message: msg contents: ["no"];
				}
			}
		}
	}

	reflex handle_accept_proposals when: !empty(accept_proposals) {
		happiness <- happiness + 0.2;
	}

	reflex handle_reject_proposals when: !empty(reject_proposals) {
		happiness <- happiness - 0.1;
	}

	aspect base {
		draw circle(1.5) color: #blue border: #black;
		draw string(round(happiness*100)/100.0) at: location + {0, -2} size: 8 color: #white;
	}
}

species place {
	string type;
	aspect base {
		draw square(15) color: (type = "bar" ? #lightgray : #lightyellow) border: #black;
		draw type color: #black size: 10 at: {location.x - 4, location.y - 8};
	}
}

experiment social_sim_skeleton type: gui {
	output {
		display main_display {
			species place aspect: base;
			species guest aspect: base;
		}
	}
}
