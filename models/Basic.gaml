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
	float total_happiness;
	list<place> place_list;
	list<guest>party_list;
	list<guest>introverted_list;
	list<guest>observer_list;
	list<guest>vegan_list;
	list<guest>meat_list;
	init {
		//Create 2 different places
		create place number: 2 returns: places;
		ask places[0] {
			set type <- 'bar';
			set location <- point(20,20);
		}
		ask places[1] {
			set type <- 'concert';
			set location <- point(80,80);
		}
		place_list <- places;
		
		//Create 5 types of guests.
		create guest number:guestNum returns: Guests;
		loop i from: 0 to: guestNum-1{
			ask Guests[i]{
				if(i>=0 and i<10){
					set type <- 'party';
					//set place <- 'bar';
					set sociability <- rnd(0.5,0.9);
					set generosity <- rnd(0.4,0.8);
					set tolerance <- rnd(0.2,0.8);
					
				} else if(i>=10 and i<20){
					set type <- 'introverted';
					//set place <- 'bar';
					set sociability <- rnd(0.1,0.5);
					set generosity <- rnd(0.4,0.8);
					set tolerance <- rnd(0.2,0.8);
				} else if(i>=20 and i<30){
					set type <- 'observer';
					set sociability <- rnd(0.1,0.9);
					set generosity <- rnd(0.4,0.8);
					set tolerance <- rnd(0.2,0.8);
				} else if(i>=30 and i <40){
					set type <- 'vegan';
					set sociability <- rnd(0.1,0.9);
					set generosity <- rnd(0.4,0.8);
					set tolerance <- rnd(0.2,0.8);
				} else{
					set type <- 'meat';
					set sociability <- rnd(0.1,0.9);
					set generosity <- rnd(0.4,0.8);
					set tolerance <- rnd(0.2,0.8);
				}
			}
		}
		loop i from: 0 to: guestNum-1{
			if(i>=0 and i<10){
				party_list <- party_list + Guests[i];
			} else if(i>=10 and i<20){
				introverted_list <- introverted_list + Guests[i];
			} else if(i>=20 and i<30){
				observer_list <- observer_list + Guests[i];
			} else if(i>=30 and i <40){
				vegan_list <- vegan_list + Guests[i];
			} else{
				meat_list <- meat_list + Guests[i];
			}
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
	string type <- nil;
	float sociability;
	float generosity;
	float tolerance;
	float happiness <- 1.0;
	
	reflex act{
		//If it is in the bar
		if(cur_place = place_list[0]){
			if(type = 'party'){
				if(sociability >= 0.5 and generosity>=0.5){
					do start_conversation to: introverted_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'want to have drink?'];
					write name+ ': I invited introverted to drink';
				}
				if(sociability >= 0.6){
					do start_conversation to: observer_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'want to dance?'];
					write name+ ': I invited observers to drink';
				}
			}
			else if(type = 'observer'){
				if(sociability >= 0.5){
					do start_conversation to: meat_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'what brings you here?'];
					write name+ ': I ask meat_eater';
				}
			}
			else if(type = 'vegan'){
				if(sociability >= 0.5 and generosity>=0.5){
					do start_conversation to: introverted_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'want to small talk?'];
					write name+ ': I invited introverted to small talk';
				}
			}
			else if(type = 'meat'){
				if(sociability >= 0.5 and generosity>=0.5){
					do start_conversation to: vegan_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'want to have steak?'];
					write name+ ': I invited vegan_eater to have steak';
				}
			}
		}
		//If it is in the concert
		else if(cur_place = place_list[1]){
			if(type = 'party'){
				if(sociability >= 0.6){
					do start_conversation to: vegan_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'do you like the music?'];
				}
			}
			else if(type = 'introverted'){
				if(sociability >= 0.4){
					do start_conversation to: observer_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'what do you think of the band?'];
				}
			}
			else if(type = 'observer'){
				if(sociability >= 0.5){
					do start_conversation to: introverted_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'you must be enjoying it.'];
				}
			}
			else if(type = 'vegan'){
				if(sociability >= 0.5 and generosity>=0.5){
					do start_conversation to: meat_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'the salad is amazing!'];
				}
			}
			else if(type = 'meat'){
				if(sociability >= 0.5 and generosity>=0.5){
					do start_conversation to: party_list protocol: 'no-protocol' performative: 'inform' contents:[cur_place,'have some burgers together?'];
				}
			}
		}
	}
	reflex react when: !empty(informs){
		int numberOfMsgs <- length(informs);
		loop informMsg over: informs{
			//If they are in the same place, then react.
			if(cur_place = informMsg.contents[0]){
				if(type = 'introverted'){
					if(informMsg.contents[1] = 'want to have drink?'){
						if(sociability >= 0.4 and tolerance >= 0.5){
							do end_conversation message: informMsg contents: ['Sure, thank you!'];
							happiness <- happiness + 0.3;
						} else if(tolerance <0.5){
							do end_conversation message: informMsg contents: ['No!'];
							happiness <- happiness - 0.5;
						}
					}
					else if(informMsg.contents[1] = 'want to small talk?'){
						if(sociability >= 0.3){
							do end_conversation message: informMsg contents: ['Sure, thank you!'];
							happiness <- happiness + 0.5;
							//write name+ ': I start a small talk with ' + agent(informMsg.sender).name;
						} else{
							do end_conversation message: informMsg contents: ['Not now, but thanks.'];
							happiness <- happiness + 0.1;
						}
					}
					else if(informMsg.contents[1] = 'you must be enjoying it.'){
						if(tolerance >= 0.3){
							do end_conversation message: informMsg contents: ['Yes, how do you know?'];
							happiness <- happiness + 0.4;
						} else{
							do end_conversation message: informMsg contents: ['No, it is not good.'];
							happiness <- happiness - 0.2;
						}
					}
				}
				else if(type = 'party'){
					if(informMsg.contents[1] = 'have some burgers together?'){
						if(tolerance >= 0.3){
							do end_conversation message: informMsg contents: ['Sure, thank you!'];
							happiness <- happiness + 0.5;
						}
						else{
							do end_conversation message: informMsg contents: ['No, I am full'];
							happiness <- happiness + 0.1;
						}
					}
				}
				else if(type = 'observer'){
					if(informMsg.contents[1] = 'want to dance?'){
						if(sociability >= 0.4){
							do end_conversation message: informMsg contents: ['Sure, come on!'];
							happiness <- happiness + 0.4;
						} else{
							do end_conversation message: informMsg contents: ['No, thanks'];
							happiness <- happiness - 0.1;
						}
					}
					else if(informMsg.contents[1] = 'what do you think of the band?'){
						if(tolerance >= 0.3){
							do end_conversation message: informMsg contents: ['It is excellent!'];
							happiness <- happiness + 0.4;
						} else{
							do end_conversation message: informMsg contents: ['Not good enough'];
							happiness <- happiness + 0.1;
						}
					}
				}
				else if(type = 'vegan'){
					if(informMsg.contents[1] = 'want to have steak?'){
						if(tolerance >= 0.4){
							do end_conversation message: informMsg contents: ['Thanks, but I do not have meat'];
							happiness <- happiness + 0.1;
						} else{
							do end_conversation message: informMsg contents: ['No!!'];
							happiness <- happiness - 0.4;
						}
					} else if(informMsg.contents[1] = 'do you like the music?'){
						if(tolerance >= 0.3){
							do end_conversation message: informMsg contents: ['Yes, I do.'];
							happiness <- happiness + 0.4;
						} else{
							do end_conversation message: informMsg contents: ['No, not my type.'];
							happiness <- happiness - 0.1;
						}
					}
				}
				else if(type = 'meat'){
					if(informMsg.contents[1] = 'what brings you here?'){
						if(sociability >= 0.3){
							do end_conversation message: informMsg contents: ['The food here.'];
							happiness <- happiness + 0.4;
						} else if(tolerance <= 0.4){
							do end_conversation message: informMsg contents: ['Mind your own bussiness.'];
							happiness <- happiness - 0.2;
						}
					} else if(informMsg.contents[1] = 'the salad is amazing!'){
						if(tolerance >= 0.4){
							do end_conversation message: informMsg contents: ['Yes, but I do not have salad.'];
							happiness <- happiness + 0.1;
						} else{
							do end_conversation message: informMsg contents: ['No, it is unpalatable.'];
							happiness <- happiness - 0.4;
						}
					}
				}
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
		if(type = 'party'){
			draw circle(1) color: #red;
		} else if(type = 'introverted'){
			draw circle(1) color: #black;
		} else if(type = 'observer'){
			draw circle(1) color: #pink;
		} else if(type = 'meat'){
			draw circle(1) color: #blue;
		} else{
			draw circle(1) color: #green;
		}
	}
}

species place {
	
	string type;
	
	aspect base {
		draw square(20) border: #black;
		draw type color: #white;
	}
}

experiment guests_simulation {
	output {
		display my_display {
			// todo: table of guest, cur_place, state, stay_time
			// todo: happiness graph
			// todo: graph of happiness of each guest
			species place aspect: base;
			species guest aspect: base;
		}
	}
}