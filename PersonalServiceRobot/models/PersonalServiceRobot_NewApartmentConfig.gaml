/**
* Name: PersonalServiceRobotNewApartmentConfig
* Based on the internal empty template. 
* Author: Aurelia Bălășoiu
* Tags: 
*/
model PersonalServiceRobotNewApartmentConfig

global {	
	string closet_obj <- "closet";
	string bed_obj <- "bed";
	string sofa_obj <- "sofa";
	string table_obj <- "table";
	
	int number_of_persons <- 4;
	int number_of_columns <- 40;
	int number_of_rows <- 40;
	int no_notebooks <- 5;
	int no_books <- 7;	
	
	int no_total_requests <- 0;
	int no_fulfilled_requests <- 0;

	list<string> object_names <- ["notebook", "book"];
	
	string requested_object_name;
	
	point owner_location;
	
	rgb book_color <- #blue;
	rgb notebook_color <- #yellow;
	
	
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
	
		// first, color the borders
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

//Grid species to discretize space
grid cell width: number_of_columns height: number_of_rows neighbors: 8 {
	bool is_wall <- false;
	bool has_object <- false;
	bool has_person <- false;
	rgb color <- #grey;
}


species wall {
	aspect default {
		draw shape color: #black depth: 1.2;
	}
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

species service_robot parent: person {
	object_base requested_obj;
	bool is_requested_object_found <- false;
	point object_location;
	bool grabbed_object <- false;
	bool is_busy <- false;

	init {
		image_file image <- image_file("../images/robot3.png");
		cell my_initial_cell <- one_of(get_available_cells());
		do initialize(5.0, image, nil, my_initial_cell.location);
	}
	
	reflex find_requested_object when: not is_requested_object_found and is_busy {
		requested_obj <- nil;
		
		if requested_object_name = "book" {
			requested_obj <- one_of(book where each.is_requested_by_person);
		} else if requested_object_name = "notebook" {
			requested_obj <- one_of(notebook where each.is_requested_by_person);
		}
				
		if requested_obj != nil {
			is_requested_object_found <- true;
			object_location <- requested_obj.location;
		}
	}


	reflex get_requested_object when: is_requested_object_found and is_busy and not grabbed_object {
				
		do goto target: object_location speed: 2.0 on: get_available_cells() recompute_path: false;
		
		if (self distance_to object_location) < 1.0 {
			grabbed_object <- true;
			ask requested_obj {
				should_move <- true;
			}
		}
	}
	
	reflex bring_requested_object when: grabbed_object and is_busy {		
		if owner_location != nil and requested_obj != nil {
			do goto target: owner_location speed: 2.0 on: get_available_cells() recompute_path: false;
			
			if (self distance_to owner_location) < 1.0 {
				ask requested_obj {
					should_move <- false;
					is_requested_by_person <- false;
					location <- owner_location;
				}
				
				ask robot_owner {
					is_waiting_for_object <- false;
				}
				
				// reset all the flags
				grabbed_object <- false;
				is_busy <- false;
				is_requested_object_found <- false;
				no_fulfilled_requests <- no_fulfilled_requests + 1;
			}
		}
	}
	
	reflex basic_move when: not is_busy {		
		point my_next_location <- one_of(get_available_cells()).location;
		do goto target: my_next_location speed: 0.5 on: get_available_cells();
	}
}

species robot_owner parent: person {

	object_base requested_object <- nil;
	bool is_waiting_for_object <- false;

	init {
		image_file image <- image_file("../images/robot_owner.png");
		owner_location <- one_of(get_available_cells()).location;
		do initialize(5.0, image, nil, owner_location);
	}
	
	reflex ask_for_object when: not is_waiting_for_object {
		requested_object <- nil;
		
		requested_object <- get_random_object();
		if requested_object != nil {
			ask requested_object {
				is_requested_by_person <- true;
			}
			
			is_waiting_for_object <- true;
			
			service_robot robot <- one_of(service_robot);
			ask robot {
				is_busy <- true;
			}
		}	
	}
	
	reflex basic_move when: every(25#cycle) {// when: not is_waiting_for_object {
		owner_location <- one_of(get_available_cells()).location;
		location <- owner_location;
	} 
	
	object_base get_random_object {
		no_total_requests <- no_total_requests + 1;
		requested_object_name <- one_of(object_names);
		write "requested_object_name: " + requested_object_name;
		object_base object;
		
		if requested_object_name = "book" {
			object <- one_of(book);
			write "object: " + object;
 		} else if requested_object_name = "notebook" {
 			object <- one_of(notebook);
 			write "object: " + object;
 		}
 		
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

experiment personalservicerobotnewapartmentconfig type: gui {
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