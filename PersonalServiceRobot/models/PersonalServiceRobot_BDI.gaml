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
	
	int number_of_persons <- 4;
	int number_of_columns <- 40;
	int number_of_rows <- 40;
	int no_notebooks <- 5;
	int no_books <- 7;	
	
	int no_total_requests <- 0;
	int no_fulfilled_requests <- 0;

	list<string> object_names <- [book_obj, notebook_obj];
	
	string requested_object_name;
	// flag used to update the perceived location of the owner
	bool owner_changed_location;	
		
	rgb book_color <- #blue;
	rgb notebook_color <- #yellow;
	
	
	string object_at_location <- "object at location";
	string owner_at_location <- "owner at location";
	
	// desires
	predicate wander <- new_predicate("wander");
	predicate grab_object_pred <- new_predicate("grab requested object");  // after identifying its coordinates
	predicate find_owner_pred <- new_predicate(owner_at_location);
	predicate go_to_owner <- new_predicate("go to owner with requested object");
	
	// beliefs
	predicate requested_object_pred <- new_predicate(object_at_location); // belief
	
	
	init {
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
		
		create regular_person number: number_of_persons;
		create service_robot;
		create robot_owner;
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
	
		// first, collect the borders
		// the upper border
		loop times: number_of_columns {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_x <- current_x + 1;
		}
		
		// the left border
		current_x <- 0;
		current_y <- 0;
		loop times: number_of_rows {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_y <- current_y + 1;
		}
		
		// the right border
		current_x <-max_x;
		current_y <- 0;
		loop times: number_of_rows {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_y <- current_y + 1;
		}
		
		// the bottom border
		current_x <- 0;
		current_y <- max_y;
		loop times: number_of_columns {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_x <- current_x + 1;
		}
		
		current_x <- 19;
		my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = 1));
		my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = 2));
		
		current_y <- 6;
		loop times: 10 {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_y <- current_y + 1;
		}
		
		loop times: (38 - current_y) {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_x <- current_x + 1;
		}
		
		current_x <- 25;
		current_y <- 20;
		loop times: (max_y - current_y) {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_y <- current_y + 1;
		}
		
		current_x <- 0;
		current_y <- 16;
		loop times: 16 {
			my_cells << one_of(cell where (each.grid_x = current_x and each.grid_y = current_y));
			current_x <- current_x + 1;
		}
		
		ask my_cells {
			color <- #black;
			is_wall <- true;
		}
	}
}	

grid cell width: number_of_columns height: number_of_rows neighbors: 8 {
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

	action initialize (bool is_requested_object, string object_name, rgb object_color, point object_location) {
		is_requested_by_person <- is_requested_object;
		name <- object_name;
		color <- object_color;
		location <- object_location;
		ask cell overlapping self {
			has_object <- true;
		}
	}
	
	// as the robot moves to the owner with the found object, the object should also move
	reflex move when:should_move {
		location <- one_of(service_robot).location;
	}
}


// *** Derived species ***

species service_robot parent: person control: simple_bdi {
	bool is_requested_object_found <- false;
	point object_location;
	point owner_location;
	float view_distance <- 600.0;
	bool should_get_object;
	object_base target_object;
	float view_distance_owner <- 10.0;
	bool should_look_for_object <- false;

	init {
		image_file image <- image_file("../images/robot3.png");
		cell my_initial_cell <- one_of(get_available_cells());
		do initialize(5.0, image, nil, my_initial_cell.location);
		do add_desire(wander); // just let the robot move randomly 
	}
	
	perceive target: get_current_target_species() when: should_look_for_object in: view_distance {
		write "*** perceive req obj****";
		
		// i want to perceive the requested object's location. That value will be saved with the id given by 'object_at_location'
		if is_requested_by_person {
			focus id: object_at_location var: location;
			ask myself { do remove_intention(wander, false); }
			myself.should_look_for_object <- false;
		}
		
		
	}
	
	perceive target: robot_owner when: is_requested_object_found in: view_distance {
		focus id: owner_at_location var:location;
	}
	
	rule belief: new_predicate(object_at_location) new_desire: grab_object_pred strength: 5;
	rule belief: grab_object_pred new_desire: find_owner_pred strength: 4;
	rule belief: new_predicate(owner_at_location) new_desire: go_to_owner strength: 3;
	
	
	plan just_wander intention: wander {
		do move_randomly;
	}
	
	plan find_req_object intention: requested_object_pred {
		do move_randomly;
	}
	
	plan go_and_grab_req_object intention: grab_object_pred when: should_get_object {	
		 object_location <- point(get_predicate(get_belief_with_name(object_at_location)).values["location_value"]);
					
		if object_location != nil {
			list<object_base> target_objects <- get_current_target_species() where (each.location=object_location and each.is_requested_by_person);
			target_object <- first(target_objects);			
		}
		
		if target_object != nil {
			do goto target: object_location speed: 2.0 on: get_available_cells() recompute_path: true;
			
			if (self distance_to target_object.location) < 1.0 {
				ask target_object {
					should_move <- true;
				}
				is_requested_object_found <- true;
				should_get_object <- false;
				do add_desire(find_owner_pred);
			}
		}
	}
	
	plan find_owner intention: find_owner_pred when: owner_location = nil {
		do move_randomly();
	}
	
	plan bring_object_to_owner intention: go_to_owner {
		owner_location <- point(get_predicate(get_belief_with_name(owner_at_location)).values["location_value"]);
	
		if owner_location != nil and target_object != nil {			
			do goto target: owner_location speed: 2.0 on: get_available_cells() recompute_path: false;
			
			if (self distance_to owner_location) < 3.0  {				
				// let the object there
				ask target_object {
					should_move <- false;
					is_requested_by_person <- false;
					location <- myself.owner_location;
				}
				
				ask robot_owner {
					is_waiting_for_object <- false;
				}
				
				// reset all the flags and necessary variables
				is_requested_object_found <- false;
				no_fulfilled_requests <- no_fulfilled_requests + 1;
				requested_object_name <- nil;
				target_object <- nil;
				owner_location <- nil;
				object_location <- nil;
				should_look_for_object <- false;
			
				do remove_belief(requested_object_pred);
				do remove_belief(find_owner_pred);	
				do remove_intention(go_to_owner, true);
				do remove_intention(grab_object_pred, true);
				do add_desire(wander);
			}
		}
	}
	
	action move_randomly {
		cell available_cell <- one_of(get_available_cells());
		do goto target: available_cell.location speed: 2.0 on: get_available_cells();
	}
	
	species<object_base> get_current_target_species {
		switch requested_object_name {
			match book_obj {
				return book;
			}
			match notebook_obj {
				return notebook;
			}
		}
	}
}

species robot_owner parent: person {
	bool is_waiting_for_object <- false;

	init {
		image_file image <- image_file("../images/robot_owner.png");
		point initial_location <- one_of(get_available_cells()).location;
		do initialize(5.0, image, nil, initial_location);
	}
	
	reflex ask_for_object when: not is_waiting_for_object {
		
		object_base requested_object <- get_random_object();
		if requested_object != nil {
			ask requested_object {
				is_requested_by_person <- true;
			}
			
			is_waiting_for_object <- true;
			
			service_robot robot <- one_of(service_robot);
			ask robot {
				is_requested_object_found <- false;
				owner_location <- nil;
				should_get_object <- true;
				should_look_for_object <- true;
			}
		}	
	}
	
	reflex basic_move when: every(30#cycle) {
		point next_location <- one_of(get_available_cells()).location;
		
		// once the robot owner changes the location, the robot's belief referring to that location should also be updated	
		service_robot robot <- one_of(service_robot);
		ask robot {
			do remove_belief(find_owner_pred);
			do add_belief(new_predicate(owner_at_location, ["location_value"::next_location]));
			
		}
		location <- next_location;
	} 
	
	object_base get_random_object {
		no_total_requests <- no_total_requests + 1;
		requested_object_name <- one_of(object_names);
		object_base object;
		
		if requested_object_name = "book" {
			object <- one_of(book);
 		} else if requested_object_name = "notebook" {
 			object <- one_of(notebook);
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

	reflex basic_move when: every(10#cycles){
		location <- one_of(get_available_cells()).location;
	}	
}

species notebook parent: object_base {
	init {
		point my_location <- one_of(get_available_cells()).location;
		do initialize(false, "notebook", notebook_color, my_location);
	}

	aspect default {
		draw rectangle(1, 2) color: color;
	}
}

species book parent: object_base {
	init {
		point my_location <-one_of(get_available_cells()).location;
		do initialize(false, "book", book_color, my_location);
	}

	aspect default {
		draw rectangle(1, 2) color: color;
	}
}

species closet parent: object_base {
	image_file icon <- image_file("../images/closet.png");
	
	init {
		is_requested_by_person <- false;
		name <- closet_obj;		
	}
	
	aspect image_aspect {
		draw icon size: 7;
	}
}

species bed parent: object_base {
	image_file icon <- image_file("../images/bed.png");
	
	init {
		is_requested_by_person <- false;
		name <- bed_obj;		
	}
	
	aspect image_aspect {
		draw icon size: 8;
	}
}

species table parent: object_base {
	image_file icon <- image_file("../images/table.png");
	
	init {
		is_requested_by_person <- false;
		name <- table_obj;		
	}
	
	aspect image_aspect {
		draw icon size: 8;
	}
}

species sofa parent: object_base {
	image_file icon <- image_file("../images/sofa.png");
	
	init {
		is_requested_by_person <- false;
		name <- sofa_obj;		
	}
	
	aspect image_aspect {
		draw icon size: 8;
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
			species closet aspect: image_aspect;
			species bed aspect: image_aspect;
			species table aspect: image_aspect;
			species sofa aspect: image_aspect;
		}
	}
}