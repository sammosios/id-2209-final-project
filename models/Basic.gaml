/**
* Name: Basic
* Based on the internal empty template. 
* Author: Group 10
* Tags: 
*/


model Basic

global {
	int placeRange <- 10;
	int guestNum <- 50;
	list<place> place_list;
	init {
		//Create 2 different places
		create place number: 2 returns: places;
		ask places[0] {
			type <- 'bar';
			location <- {20,20};
			noise_level <- 0.8;
		}
		ask places[1] {
			type <- 'concert';
			location <- {80,80};
			noise_level <- 0.9;
			current_band <- one_of(['rock', 'pop', 'jazz', 'classical', 'electronic']);
		}
		place_list <- places;
		
		//Create guests.
		create guest number: guestNum {
			archetype <- one_of(["Party Animal", "Introvert", "Music Lover", "Foodie", "Philanthropist"]);
			if (archetype = "Party Animal") {
				sociability <- rnd(0.7, 1.0);
			} else if (archetype = "Introvert") {
				sociability <- rnd(0.0, 0.3);
			} else {
				sociability <- rnd(0.3, 0.7);
			}
			generosity <- rnd(0.1, 0.9);
			musical_taste <- one_of(['rock', 'pop', 'jazz', 'classical', 'electronic']);
			favorite_food <- one_of(['pizza', 'burger', 'sushi', 'salad', 'pasta']);
		}
	}

}

species guest skills:[moving,fipa] {
	
//Below are the simulation for the moving of the guests.
	place cur_place <- nil;
	place target_place <- nil;
	int stay_time <- 0;
	string state <- "leave";
	
	reflex decide_target when: target_place = nil and state = "leave" {
		if (cur_place = nil) {
			int coin <- rnd(1);
			target_place <- place_list[coin];
		} else if (cur_place = place_list[0]) {
			target_place <- place_list[1];
		} else if (cur_place = place_list[1]) {
			target_place <- place_list[0];
		}
	}
	reflex gotoTarget when: state = "leave" {
		do goto target: target_place.location speed: 5.0;
	}
	reflex outOfPlace when: cur_place != nil and state = "leave" {
		if ((location distance_to cur_place.location) > placeRange) {
			cur_place <- nil;
		}
	}
	reflex placeInRange when: target_place != nil and (location distance_to target_place.location) <= placeRange {
		cur_place <- target_place;
		target_place <- nil;
		state <- "stay";
	}
	reflex stay_or_leave {
		if (stay_time > 5) {
			state <- "leave";
		}
	}
	reflex count_stay_time {
		if (cur_place = nil) {
			stay_time <- 0;
		} else {
			stay_time <- stay_time + 1;
		}
	}
	
//Below are the code for the interactions between different guests.
	float sociability;
	float generosity;
	string musical_taste;
	string favorite_food;
	string archetype;
	float happiness <- 0.5;
	
	reflex interact when: cur_place != nil and flip(sociability * 0.1) {
		guest other <- one_of(guest at_distance 5);
		if (other != nil and other != self) {
			// A simple interaction model based on archetypes
			bool compatible <- false;
			if (archetype = "Party Animal" and other.archetype = "Party Animal") {
				compatible <- true;
			} else if (archetype = "Introvert" and other.archetype = "Introvert") {
				compatible <- true;
			} else if (archetype = "Music Lover" and other.archetype = "Music Lover" and musical_taste = other.musical_taste) {
				compatible <- true;
			} else if (archetype = "Foodie" and other.archetype = "Foodie" and favorite_food = other.favorite_food) {
				compatible <- true;
			}

			if (compatible) {
				happiness <- happiness + 0.1;
				other.happiness <- other.happiness + 0.1;
				write name + " had a nice chat with " + other.name;
			} else {
				happiness <- happiness - 0.05;
				other.happiness <- other.happiness - 0.05;
			}
		}
	}
//	reflex happiness{
//		if(type = 'party'){
//			write 'Happiness of '+ name+': '+ happiness;
//		} else if(type = 'introverted'){
//			write 'Happiness of '+ name+': '+ happiness;
//		} else if(type = 'observer'){
//			write 'Happiness of '+ name+': '+ happiness;
//		} else if(type = 'vegan'){
//			write 'Happiness of '+ name+': '+ happiness;
//		} else if(type = 'meat'){
//			write 'Happiness of '+ name+': '+ happiness;
//		}
//	}
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

experiment guests_simulation {
	output {
		display my_display {
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
//			data "Bar" value: length(guest where (each.cur_place != nil and each.cur_place.type = "bar")) color: #lightgray;
//			data "Concert" value: length(guest where (each.cur_place != nil and each.cur_place.type = "concert")) color: #lightyellow;
//			data "Roaming" value: length(guest where (each.cur_place = nil)) color: #lightblue;
//		}
	}
}