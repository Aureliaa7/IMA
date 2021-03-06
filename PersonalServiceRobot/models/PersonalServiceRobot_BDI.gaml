/**
* Name: PersonalServiceRobotBDI
* Based on the internal empty template. 
* Author: Aurelia Bălășoiu
* Tags: 
*/
model PersonalServiceRobotBDI

global {	
	string closet_obj <- "closet";
	string bed_obj <- "bed";
	string sofa_obj <- "sofa";
	string table_obj <- "table";
	string book_obj <- "book";
	string notebook_obj <- "notebook";
	string food_obj <- "food";
	string teddy_bear_obj <- "teddy bear";
		
	int number_of_persons <- 4;
	int number_of_columns <- 40;
	int number_of_rows <- 40;
	int no_notebooks <- 5;
	int no_books <- 7;	
	int no_food_items <- 15;
	int no_teddy_bears <- 5;

	list<string> object_names <- [book_obj, notebook_obj, food_obj, teddy_bear_obj];
	string requested_object_name;
	// flag used to update the perceived location of the owner
	bool owner_changed_location;	
	
	string object_at_location <- "object at location";
	string owner_at_location <- "owner at location";
	
	// desires
	predicate wander <- new_predicate("wander");
	predicate grab_object <- new_predicate("grab requested object");
	predicate find_owner <- new_predicate(owner_at_location);
	predicate go_to_owner <- new_predicate("go to owner with requested object");
	
	// beliefs
	predicate requested_object_pred <- new_predicate(object_at_location);
	
	float time_needed_to_find_object;
	float time_needed_to_go_to_owner;
	float total_service_time;
	list<float> time_to_find_objects;
	list<float> time_to_go_to_owner;
	list<float> time_to_complete_requests;
	int max_no_requested_objects <- 10; // this is used in order to stop the simulation and compute an avg time for finding and going to owner
	int no_requested_objects <- 0; 
	string results_file_name;	
	int no_cycles_at_requested_object <- 0; // #cycles when the person requested an object
	int no_cycles_found_object <- 0; // #cycles when the robot found the object
	int no_cycles_owner_received_object <- 0; // #cycles when the person received the object
	bool should_end_simulation <- false;
	
	init {
		results_file_name <-  "../results/serviceRobotWithBDIArchitecture_" + max_no_requested_objects + "RequestedObjects.txt";
		save("\t\tPersonal Service Robot- using BDI architecture\n\n") to: results_file_name;
		
		do create_apartment_configuration();
		
		do create_object(point(5, 7), closet_obj);
		do create_object(point(67, 90), closet_obj);
		do create_object(point(6, 92), closet_obj);
		do create_object(point(80, 6), bed_obj);
		do create_object(point(90, 48), bed_obj);
		do create_object(point(30, 65), table_obj);
		do create_object(point(10, 47), sofa_obj);
		
		create notebook number: no_notebooks;
		create book number: no_books;
		create food number: no_food_items;
		create teddy_bear number: no_teddy_bears;
		
		create regular_person number: number_of_persons;
		create service_robot;
		create robot_owner;
	}
	
	reflex end_simulation when: should_end_simulation {
    	do pause;
	
		save ("\t*** average time needed to find the object: " + sum(time_to_find_objects) / no_requested_objects + " s") 
		to: results_file_name rewrite: false;
	    
    	save ("\t*** average time needed to go to owner: " 
		+ sum(time_to_go_to_owner) / no_requested_objects + " s"
		) to: results_file_name rewrite: false;
	    
	    save ("\t*** average time to complete a request:  " 
		+ sum(time_to_complete_requests) / no_requested_objects + " s"
		) to: results_file_name rewrite: false;	    		
	}
	
	action create_object(point object_location, string object_name) {
		switch object_name {
			match closet_obj {
				create closet {
					location <- object_location;
					ask cell overlapping self {
						has_object <- true;
					}
				}
			}
			match bed_obj {
				create bed {
					location <- object_location;
					ask cell overlapping self {
						has_object <- true;
					}
				}
			}
			match sofa_obj {
				create sofa {
					location <- object_location;
					ask cell overlapping self {
						has_object <- true;
					}
				}
			}
			match table_obj {
				create table {
					location <- object_location;
					ask cell overlapping self {
						has_object <- true;
					}
				}
			}
		}
	}

	action create_apartment_configuration {
		list<cell> my_cells;
		int current_y <- 0;
		int current_x <- 0;
		int max_x <- 39;
		int max_y <- 39;
	
		// the upper border
		loop times: number_of_columns {
			my_cells << get_cell(current_x, current_y);
			current_x <- current_x + 1;
		}
		
		// the left border
		current_x <- 0;
		current_y <- 0;
		loop times: number_of_rows {
			my_cells << get_cell(current_x, current_y);
			current_y <- current_y + 1;
		}
		
		// the right border
		current_x <-max_x;
		current_y <- 0;
		loop times: number_of_rows {
			my_cells << get_cell(current_x, current_y);
			current_y <- current_y + 1;
		}
		
		// the bottom border
		current_x <- 0;
		current_y <- max_y;
		loop times: number_of_columns {
			my_cells << get_cell(current_x, current_y);
			current_x <- current_x + 1;
		}
		
		current_x <- 19;
		my_cells << get_cell(current_x, 1);
		my_cells << get_cell(current_x, 2);
		
		current_y <- 6;
		loop times: 10 {
			my_cells << get_cell(current_x, current_y);
			current_y <- current_y + 1;
		}
		
		loop times: (38 - current_y) {
			my_cells << get_cell(current_x, current_y);
			current_x <- current_x + 1;
		}
		
		current_x <- 25;
		current_y <- 20;
		loop times: (max_y - current_y) {
			my_cells << get_cell(current_x, current_y);
			current_y <- current_y + 1;
		}
		
		current_x <- 0;
		current_y <- 16;
		loop times: 16 {
			my_cells << get_cell(current_x, current_y);
			current_x <- current_x + 1;
		}
		
		current_x <- 18;
		current_y <- 20;
		loop times: 7 {
			my_cells << get_cell(current_x, current_y);
			current_x <- current_x + 1;
		}
		
		current_x <- 18;
		loop times: 9 {
			my_cells << get_cell(current_x, current_y);
			current_y <- current_y + 1;
		}
		
		current_x <- 10;
		loop times: 9 {
			my_cells << get_cell(current_x, current_y);
			current_x <- current_x + 1;
		}
		
		current_x <- 10;
		loop times: 7 {
			my_cells << get_cell(current_x, current_y);
			current_y <- current_y + 1;
		}
		
		current_x <- 26;
		current_y <- 27;
		loop times: 8 {
			my_cells << get_cell(current_x, current_y);
			current_x <- current_x + 1;
		}
		
		current_x <- 30;
		current_y <- 1;
		loop times: 8 {
			my_cells << get_cell(current_x, current_y);
			current_y <- current_y + 1;
		}
		
		ask my_cells {
			color <- #black;
			is_wall <- true;
		}
	}
	
	cell get_cell(int x, int y) {
		return one_of(cell where (each.grid_x = x and each.grid_y = y));
	}
}	

grid cell width: number_of_columns height: number_of_rows neighbors: 4 {
	bool is_wall <- false;
	bool has_object <- false;
	bool has_person <- false;
	rgb color <- #grey;
}


// *** Base species ***

species species_base {
	list<cell> get_available_cells {
		list<cell> available_cells <- cell where not (each.is_wall or each.has_person);
		remove cell where each.has_object from: available_cells ;
		
		return available_cells;
	}
}

species person parent: species_base skills: [moving] {
	float icon_size;
	image_file icon;
	point target;

	action initialize (float image_size, image_file image, point target_location, point agent_location) {
		icon_size <- image_size;
		icon <- image;
		target <- target_location;
		location <- agent_location;
		ask cell overlapping self {
			has_person <- true;
		}
	}
	
	aspect image_aspect {
		draw icon size: icon_size;
	}
}


species object_base parent: species_base {
	bool is_requested_by_person;
	string name;
	rgb color;
	bool should_move;
	image_file icon;

	action initialize (bool is_requested_object, string object_name, rgb object_color, point object_location, image_file image <- nil) {
		is_requested_by_person <- is_requested_object;
		name <- object_name;
		color <- object_color;
		location <- object_location;
		icon <- image;
		ask cell overlapping self {
			has_object <- true;
		}
	}
	
	action initialize_big_object(string object_name, image_file image) {
		name <- object_name;
		icon <- image;
	}
	
	// as the robot moves to the owner with the found object, the object should also move
	reflex move when:should_move {
		location <- one_of(service_robot).location;
	}
	
	aspect image_aspect {
		draw icon size: 5;
	}
	
	aspect default {
		draw square(1.5) color: color;
	}
}

// *** Derived species ***

species service_robot parent: person control: simple_bdi {
	bool is_requested_object_found <- false;
	point object_location;
	point owner_location;
	float perception_distance <- rnd(5.0, 15.0)#m;
	bool should_get_object;
	object_base target_object;
	bool should_look_for_object <- false;
	float speed <- 6#km/#h;

	init {
		image_file image <- image_file("../images/robot3.png");
		cell my_initial_cell <- one_of(get_available_cells());
		do initialize(5.0, image, nil, my_initial_cell.location);
		do add_desire(wander); // just let the robot move randomly 
		
		write "perception_distance: " + perception_distance;
		save ("\tperception_distance: " + perception_distance + "\n") to: results_file_name rewrite: false;
	}
	
	perceive target: get_current_target_species() when: should_look_for_object in: perception_distance {		
		// i want to perceive the requested object's location. 
		// That value will be saved with the id given by 'object_at_location'
		if is_requested_by_person {
			focus id: object_at_location var: location;
			ask myself { 
				do remove_intention(wander, false);
			}
			myself.should_look_for_object <- false;
		}		
	}
	
	perceive target: robot_owner when: is_requested_object_found in: perception_distance {
		focus id: owner_at_location var:location;
	}
	
	rule belief: new_predicate(object_at_location) new_desire: grab_object strength: 5;
	rule belief: grab_object new_desire: find_owner strength: 4;
	rule belief: new_predicate(owner_at_location) new_desire: go_to_owner strength: 3;
	
	
	plan just_wander intention: wander {
		do move_randomly;
	}
	
	plan find_req_object intention: requested_object_pred {
		if target_object != nil {
			do remove_intention(get_predicate(get_current_intention_op(self)), true);
			do add_intention(grab_object);
		}
				
		do move_randomly;
	}

	plan go_and_grab_req_object intention: grab_object when: should_get_object {
		object_location <- point(get_predicate(get_belief_with_name(object_at_location)).values["location_value"]);
					
		if object_location != nil {
			list<object_base> target_objects <- get_current_target_species() where (each.location=object_location and each.is_requested_by_person);
			target_object <- first(target_objects);			
		}
		
		if target_object != nil {
			do goto target: object_location speed: speed on: get_available_cells() recompute_path: true;
			
			if (self distance_to target_object.location) < 1.0 {
				no_cycles_found_object <- cycle;
				time_needed_to_find_object <- (no_cycles_found_object - no_cycles_at_requested_object) * step;
				time_to_find_objects << time_needed_to_find_object;
				save ("\ttime needed to find the object: " + time_needed_to_find_object + " s") to: results_file_name rewrite: false;
					
				ask target_object {
					should_move <- true;
				}
				is_requested_object_found <- true;
				should_get_object <- false;
				do add_desire(find_owner);
			}
		}
	}
	
	plan find_owner intention: find_owner when: owner_location = nil {
		do move_randomly();
	}
	
	plan bring_object_to_owner intention: go_to_owner {
		if target_object = nil {
 			do add_subintention(get_current_intention(), requested_object_pred, true);
        	do current_intention_on_hold();
		}		
		
		owner_location <- point(get_predicate(get_belief_with_name(owner_at_location)).values["location_value"]);
	
		if owner_location != nil and target_object != nil {			
			do goto target: owner_location speed: speed on: get_available_cells() recompute_path: false;
			
			if (self distance_to owner_location) < 3.0  {	
				no_cycles_owner_received_object <- cycle;
				time_needed_to_go_to_owner <- (no_cycles_owner_received_object - no_cycles_found_object) * step;
				time_to_go_to_owner << time_needed_to_go_to_owner;
				
				save ("\ttime needed to go to owner with the found object: " + time_needed_to_go_to_owner + " s") 
					to: results_file_name rewrite: false;
				total_service_time <- (no_cycles_owner_received_object - no_cycles_at_requested_object) * step;
				time_to_complete_requests << total_service_time;
				save("\ttotal time: " + total_service_time + " s") to: results_file_name rewrite: false;
				save("-------------------------------------------------------------------------------") 
					to: results_file_name rewrite: false;
							
				// let the object there
				ask target_object {
					should_move <- false;
					is_requested_by_person <- false;
					location <- myself.owner_location;
				}
				
				ask robot_owner {
					should_receive_object <- false;
				}
				
				// reset all the flags and necessary variables
				is_requested_object_found <- false;
				requested_object_name <- nil;
				target_object <- nil;
				owner_location <- nil;
				object_location <- nil;
				should_look_for_object <- false;
			
				do remove_belief(requested_object_pred);
				do remove_belief(find_owner);	
				do remove_intention(go_to_owner, true);
				do remove_intention(grab_object, true);
				do remove_intention(wander, true);
				do add_intention(requested_object_pred);
			}
		}
	}
	
	action move_randomly {
		cell available_cell <- one_of(get_available_cells());		
		location <- available_cell.location;
	}
	
	species<object_base> get_current_target_species {
		switch requested_object_name {
			match book_obj {
				return book;
			}
			match notebook_obj {
				return notebook;
			}
			match food_obj {
				return food;
			}
			match teddy_bear_obj {
				return teddy_bear;
			}
		}
	}
	
	aspect image_aspect {
		draw icon size: icon_size;
		// also draw a circle so that we can see how big the perception_distance is
		draw circle(perception_distance) color: #blue border: #black depth: 1 empty: true;
	}
}

species robot_owner parent: person {
	bool should_receive_object <- false;

	init {
		image_file image <- image_file("../images/robot_owner.png");
		point initial_location <- one_of(get_available_cells()).location;
		do initialize(5.0, image, nil, initial_location);
	}
	
	reflex ask_for_object when: not should_receive_object {
		if no_requested_objects = max_no_requested_objects {
			should_end_simulation <- true;
			return;
		}
		
		object_base requested_object <- get_random_object();
		no_requested_objects <- no_requested_objects + 1;
		
		save ("\trequested object: " + requested_object) to: results_file_name rewrite: false;
		
		if requested_object != nil {
			no_cycles_at_requested_object <- cycle;
		
			ask requested_object {
				is_requested_by_person <- true;
			}
			
			should_receive_object <- true;
			
			service_robot robot <- one_of(service_robot);
			ask robot {
				is_requested_object_found <- false;
				owner_location <- nil;
				should_get_object <- true;
				should_look_for_object <- true;
			}
		}	
	}
	
	reflex basic_move when: every(20#cycle) {
		point next_location <- one_of(get_available_cells()).location;
		
		// once the robot owner changes the location, the robot's belief referring to that location should also be updated	
		service_robot robot <- one_of(service_robot);
		ask robot {
			do remove_belief(find_owner);
			do add_belief(new_predicate(owner_at_location, ["location_value"::next_location]));
		}
		location <- next_location;
	} 
	
	object_base get_random_object {
		requested_object_name <- one_of(object_names);
		object_base object;
				
		switch requested_object_name {
			match book_obj {
				object <- one_of(book);
			}
			match notebook_obj {				
				object <- one_of(notebook);
			}
			match food_obj {				
				object <- one_of(food);
			}
			match teddy_bear_obj {				
				object <- one_of(teddy_bear);
			}
		}
 		write "^^^^^ get_random_object--- object: " + object;
 		write "^^^^^ get_random_object--- object--loc: " + object.location;
 		
 		return object;
	}	
}

species regular_person parent: person {
	init {
		image_file image <- image_file("../images/person1.png");
		point initial_location <- one_of(get_available_cells()).location;
		do initialize(5.2, image, nil, initial_location);
	}

	reflex basic_move when: every(7#cycles){
		location <- one_of(get_available_cells()).location;
	}	
}

species notebook parent: object_base {
	rgb notebook_color <- #yellow;
	
	init {
		point my_location <- one_of(get_available_cells()).location;
		do initialize(false, notebook_obj, notebook_color, my_location);
	}
}

species book parent: object_base {
	rgb book_color <- #blue;
	
	init {
		point my_location <-one_of(get_available_cells()).location;
		do initialize(false, book_obj, book_color, my_location);
	}
}

species food parent: object_base {
	rgb color <- #coral;
	
	init {
		point my_location <-one_of(get_available_cells()).location;
		do initialize(false, food_obj, color, my_location);
	}	
}

species teddy_bear parent: object_base {
	rgb color <- #darkgrey;
	
	init {
		point my_location <-one_of(get_available_cells()).location;
		do initialize(false, teddy_bear_obj, color, my_location);
	}	
}

species closet parent: object_base {
	image_file icon <- image_file("../images/closet.png");
	
	init {
		do initialize_big_object(closet_obj, icon);		
	}
}

species bed parent: object_base {
	image_file icon <- image_file("../images/bed.png");
	
	init {
		do initialize_big_object(bed_obj, icon);			
	}
}

species table parent: object_base {
	image_file icon <- image_file("../images/table.png");
	
	init {
		do initialize_big_object(table_obj, icon);			
	}
}

species sofa parent: object_base {
	image_file icon <- image_file("../images/sofa.png");
		
	init {
		do initialize_big_object(sofa_obj, icon);			
	}
}


// *** Experiments ***

experiment personalservicerobot_BDI type: gui {
	float minimum_cycle_duration <- 0.04;
	
	output {
		display display1 type: opengl {
			grid cell lines: #black;
			species service_robot aspect: image_aspect;
			species robot_owner aspect: image_aspect;
			species regular_person aspect: image_aspect;
			species notebook aspect: default;
			species book aspect: default;
			species food aspect: default;
			species teddy_bear aspect: default;
			species closet aspect: image_aspect;
			species bed aspect: image_aspect;
			species table aspect: image_aspect;
			species sofa aspect: image_aspect;
		}
	}
}