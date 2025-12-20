model Basic_Skeleton

global {
	int guestNum <- 50;
	list<place> place_list;

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

species guest skills: [moving] {
	place current_place <- nil;
	place target_place <- nil;
	float sociability <- rnd(0.1, 0.9);
	float happiness <- 0.5;

	reflex move {
		if (target_place = nil) {
			if (current_place = nil) {
				target_place <- one_of(place_list);
			} else {
				target_place <- one_of(place_list where (each != current_place));
			}
		} else {
			do goto target: target_place.location speed: 1.5;
			if (location distance_to target_place.location < 2.0) {
				current_place <- target_place;
				target_place <- nil;
			}
		}
	}

	reflex interact when: current_place != nil and flip(sociability * 0.1) {
		guest other <- one_of(guest at_distance 5 where (each != self));
		if (other != nil) {
			if (other.sociability > 0.5) {
				happiness <- happiness + 0.1;
				other.happiness <- other.happiness + 0.1;
			} else {
				happiness <- happiness - 0.05;
				other.happiness <- other.happiness - 0.05;
			}
		}
	}

	aspect base {
		draw circle(1.5) color: #green border: #black;
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

experiment basic_sim_skeleton type: gui {
	output {
		display main_display {
			species place aspect: base;
			species guest aspect: base;
		}
	}
}
