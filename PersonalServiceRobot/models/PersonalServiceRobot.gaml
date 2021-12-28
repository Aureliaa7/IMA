/**
* Name: PersonalServiceRobot
* Based on the internal empty template. 
* Author: Aurelia Bălășoiu
* Tags: 
*/
model PersonalServiceRobot

global {
	file wall_shapefile <- shape_file("../includes/walls.shp");
	int number_of_persons <- 2;
	int number_of_columns <- 90;
	int number_of_rows <- 90;
	list<string> object_names <- ["notebook", "book"];
	string requested_object_name;
	point owner_location;
	
	geometry shape <- envelope(wall_shapefile);

	init {
		create wall from: wall_shapefile {
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		
		create notebook;
		create book;
		
		create regular_person number: number_of_persons;
		create service_robot;
		create robot_owner;

		
	}
}

//Grid species to discretize space
grid cell width: number_of_columns height: number_of_rows neighbors: 8 {
	bool has_object <- false;
	bool has_person <- false;
	bool is_wall <- false;
	rgb color <- #white;
}

species wall {

	aspect default {
		draw shape color: #black depth: 1.2;
	}
}



// *** Base species ***

species species_base {
	
	list<cell> get_available_cells {
		list<cell> cells_without_objects <- cell where not each.has_object;
		list<cell> cells_without_persons <- cell where not each.has_person;
		list<cell> cells_without_walls <- cell where not each.is_wall;
		list<cell> available_cells <- cells_without_objects + cells_without_persons + cells_without_walls;
		
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
	
//	reflex basic_move when: every(20#cycles){
//		point my_cell <- one_of(get_available_cells()).location;
//		location <- my_cell.location;
//	}
	
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
		cell my_cell <- one_of(get_available_cells());
		do initialize(5.0, image, nil, my_cell.location);
	}
	
	reflex find_requested_object when: not is_requested_object_found and is_busy {
		write "find_requested_object reflex...";
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
		write "get_requested_object reflex...";
				
		do goto target: object_location speed: 1.0 on: get_available_cells() recompute_path: false;
		
		//TODO solve a bug without really knowing what the real issue is...
		// it crashes here when the robot brings the object to its owner
		if (self distance_to object_location) < 1.0 {
			grabbed_object <- true;
			ask requested_obj {
				should_move <- true;
			}
		}
	}
	
	reflex bring_requested_object when: grabbed_object and is_busy {
		write "bring_requested_object reflex...";
		write "bring_requested_object-- owner_location: " + owner_location;
		
		do goto target: owner_location speed: 1.0 on: get_available_cells() recompute_path: false;
		
		if (self distance_to owner_location) < 1.0 {
			ask requested_obj {
				should_move <- false;
				is_requested_by_person <- false;
			}
			
			ask robot_owner {
				is_waiting_for_object <- false;
			}
			
			//requested_obj <- nil;
			//object_location <- nil;
			grabbed_object <- false;
			is_busy <- false;
		}
	}
	
	reflex basic_move when: not is_busy {
		write "basic_move reflex ...";
		
		write "busy: " + is_busy;
		point my_next_location <- one_of(get_available_cells()).location;
		do goto target: my_next_location speed: 0.5 on: get_available_cells();
		//location <- my_cell.location;
	}
}

species robot_owner parent: person {

	object_base requested_object <- nil;
	bool is_waiting_for_object <- false;

	init {
		image_file image <- image_file("../images/robot_owner.png");
		owner_location <- one_of(get_available_cells()).location;
		do initialize(5.0, image, nil, owner_location);
		
		requested_object <- ask_for_random_object();
		write "init- requested obj: " + requested_object;
		if requested_object != nil {
			ask requested_object {
				is_requested_by_person <- true;
			}
			
			service_robot robot <- one_of(service_robot);
			ask robot {
				is_busy <- true;
			}
			
			write "init robot owner - robot.is_busy: " + robot.is_busy;
		}
	}
	
	reflex ask_for_object when: not is_waiting_for_object {
		requested_object <- ask_for_random_object();
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
	
	reflex basic_move when: every(50#cycle) {// when: not is_waiting_for_object {
		owner_location <- one_of(get_available_cells()).location;
		location <- owner_location;
	} 
	
	object_base ask_for_random_object {
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

	reflex basic_move when: every(20#cycles){
		point my_cell <- one_of(get_available_cells()).location;
		location <- my_cell.location;
	}	
}

species notebook parent: object_base {

	init {
		point my_location <- one_of(get_available_cells()).location;
		do initialize(false, "notebook", rnd_color(255), my_location);
	}

	aspect default {
		draw rectangle(1, 2) color: color;
	}
}

species book parent: object_base {

	init {
		point my_location <-one_of(get_available_cells()).location;
		do initialize(false, "book", rnd_color(255), my_location);
	}

	aspect default {
		draw rectangle(1, 2) color: color;
	}
}



// *** Experiments ***

experiment personalservicerobot type: gui {
	float minimum_cycle_duration <- 0.04;
	output {
		display display1 type: opengl {
			image "../images/floor.jpg";
			species wall refresh: false;
			species service_robot aspect: image_aspect;
			species robot_owner aspect: image_aspect;
			species regular_person aspect: image_aspect;
			species notebook aspect: default;
			species book aspect: default;
		}
	}
}