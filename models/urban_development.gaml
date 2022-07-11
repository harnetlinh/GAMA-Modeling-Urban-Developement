/**
* Name: urbanDevelopment.
* Based on the internal empty template. 
* Author: Linh + Tu + Dat 
* Tags: 
*/


model Urban

global {
	
	shape_file roads_shape_file <- shape_file("../includes/roads.shp");
//	float step <- 1 #day;
//	date starting_date <- date([2000,1,1,0,0,0]);
	geometry shape <- envelope(roads_shape_file);
	int house_nb <- 1;
	graph road_network;
	map<road, float> road_weights;
	int nb_increase_house <- 3;
	int nb_increase_service <- 5;
	int nb_max_decrease_house <- 3;
	int nb_max_decrease_service <- 2;
	float param_X_service_pollution <- 1.0;
	int nb_max_green_space <- 20;
	int cost_green_space_by_service <- 10;
	
	int nb_increase_green_space <- 1;
	
	init{
		create road from: roads_shape_file;
		road_network <- as_edge_graph(road);
			
		if(length(cell where each.available) > 0)
		{
			create species(house) number: 5 {
				my_cell <- one_of(cell where each.available );
				my_cell.available <- false;
				location <- my_cell.location;
			}
			create species(service) number: 3 {
				my_cell <- one_of(cell where each.available );
				my_cell.available <- false;
				location <- my_cell.location;
			}
//			create species(green_space) number: 1 {
//				my_cell <- one_of(cell where each.available );
//				my_cell.available <- false;
//				location <- my_cell.location;
//			}
		}
	}
	reflex create_house_or_service_if_none{
		if(length(cell where each.available) > 0)
		{
			if(length(house) = 0){
				create species(house) number: 1 {
					my_cell <- one_of(cell where each.available );
					my_cell.available <- false;
					location <- my_cell.location;
				}
			}
			if(length(service) = 0) {
				create species(service) number: 1 {
					my_cell <- one_of(cell where each.available );
					my_cell.available <- false;
					location <- my_cell.location;
				}
			}
		}
	}
	reflex pollution_evolution{
		//ask all cells to decrease their level of pollution
		ask cell {pollution <- pollution * 0.7;}
		
		//diffuse the pollutions to neighbor cells
		diffuse var: pollution on: cell proportion: 0.9 ;
	}
	reflex toto when: time = 3{
        do pause;
    }
	
	action create_green_space {
		list<cell> current_cell <- cell overlapping #user_location;
		write current_cell[0];
		create species(green_space) number: 1 {
			my_cell <- current_cell[0];
			my_cell.available <- false;
			location <- my_cell.location;
		}
   }
//   reflex check_winner{
//   		if(length(house) > 0 and length(service) > 0 and time = 50){
//   			bool result <- user_confirm('You win ', 'You are the winner! Do you want to continue. Click Ok to shutdown, cancel to continue');
//   			if(result){
//   				do die;
//   			}
//   			
//   		}else if((length(house) = 0 or length(service) = 0) and time < 50){
//   			bool result <- user_confirm('You lose ', 'You are the loser');
//   			do die;
//   		}
//   }
	
}
	
species house parent: generic_species {
	rgb color <- #blue;
	int nb_increase <- nb_increase_house;
	float happiness <- rnd(7.0,10.0);
	
	reflex check_happines {
		map<string,agent> list_service;
		
		list<cell> _current_cell <- (cell overlapping self);
		cell current_cell <- _current_cell[0];
		list<cell> neighbors_road <- current_cell.neighbors;
		int nb_neighbor_service <- 1;
		loop i over: neighbors_road {
			
			list<cell> neighbors <- i.neighbors;	
			loop j over: neighbors{
				list<agent> sp <- agents_inside(j);
				if(!empty(sp)){
					if(contains(sp[0].name,"service")){
						if (!(list_service contains sp[0].name)){
							add sp[0].name :: sp[0] to: list_service;
						}
					}
				}
			}
		}
		self.happiness <- self.happiness + length(list_service) - current_cell.pollution * param_X_service_pollution;
		if(self.happiness <= 0){
			do die;
		}
	}
	cell choose_cell {
		return one_of(cell where each.available );
	}
	aspect house {
		draw circle(20.0) color: #blue;
	}
	
	action decrease_species {
		int rnd_die_species <- rnd(0,nb_max_decrease_house);
		if(length(house) >= rnd_die_species)
		{
			loop times: rnd_die_species{
				list<cell> current_cell <- cell overlapping one_of(house);
				if(!empty(current_cell)){
					list<cell> choosen_species_cell <- [one_of(current_cell)];
					list<generic_species> choosen_generic_species <- house inside choosen_species_cell[0];
					ask one_of(choosen_generic_species){
						do die;
					}
					choosen_species_cell[0].available <- true;
				}
			}
		}
	}
}	

species service parent: generic_species  {
	rgb color <- #orange;
	int nb_increase <- nb_increase_service;
	
	cell choose_cell {
//		return one_of(cell where each.available );
		cell backup_cell <- nil;
		loop i over: (cell where each.available) {
			
			list<cell> neighbors <- i.neighbors;
			int nb_house <- 0;
			loop j over: neighbors{
				list<agent> sp <- agents_inside(j);
				
				if(!empty(sp)){
//					write(sp);
					if(contains(sp[0].name,"house")){
						nb_house <- nb_house + 1;
						backup_cell <- i;
					}
					if(nb_house >= 2){
						break;
					}
				}else{
					break;
				}
			}
			if(nb_house >= 2){
				return i;
				break;
			}
		}
		return backup_cell;
	}
	
	aspect service {
		draw circle(20.0) color: #orange;
	}
	action decrease_species {
		int rnd_die_species <- rnd(0,nb_max_decrease_service);
		if(length(service) >= rnd_die_species)
		{
			loop times: rnd_die_species{
				list<cell> current_cell <- cell overlapping one_of(service);
				if(!empty(current_cell)){
					list<cell> choosen_species_cell <- [one_of(current_cell)];
					list<generic_species> choosen_generic_species <- service inside choosen_species_cell[0];
					ask one_of(choosen_generic_species){
						do die;
					}
					choosen_species_cell[0].available <- true;
				}
			}
		}
	}
}

species green_space parent: generic_species{
	rgb color <- #green;
	int nb_increase <- nb_increase_green_space;
	cell choose_cell {
		cell backup_cell <- nil;
		if(length(service) >= cost_green_space_by_service){
			if(length(green_space) >= nb_max_green_space){
				list<cell> current_cell <- cell overlapping one_of(green_space);
				if(!empty(current_cell)){
					list<cell> choosen_species_cell <- [one_of(current_cell)];
					list<generic_species> choosen_generic_species <- green_space inside choosen_species_cell[0];
					ask one_of(choosen_generic_species){
						do die;
					}
					choosen_species_cell[0].available <- true;
				}
			}
			loop i over: (cell where each.available) {
				
				list<cell> neighbors <- i.neighbors;
				int nb_house <- 0;
				loop j over: neighbors{
					list<agent> sp <- agents_inside(j);
					
					if(!empty(sp)){
	//					write(sp);
						if(contains(sp[0].name,"house")){
							nb_house <- nb_house + 1;
							backup_cell <- i;
						}
						if(nb_house >= 2){
							break;
						}
					}else{
						break;
					}
				}
				if(nb_house >= 2){
					return i;
					break;
				}
			}
		}
		return backup_cell;
	}
	
	aspect green_space {
		draw circle(20.0) color: #green;
	}
}

species road{
	aspect default{
		draw shape color: #black;
	}
	
	list<cell> list_overlapped_cell <- cell overlapping shape;
	
	init {
		loop i over: list_overlapped_cell {
			list<cell> neighbors <- i.neighbors;
			loop j over: neighbors {
				if(j overlaps shape){
					j.available <- false;
				}else{
					j.available <- true;
				}
			}
		}
	}
	reflex check_overlap {
		loop i over: list_overlapped_cell {
			i.available <- false;
		}
	}
	reflex check_pollution {
		list<cell> _current_cell <- (cell overlapping self);
		cell current_cell <- _current_cell[0];
		list<cell> neighbors_road <- current_cell.neighbors;
		map<string,agent> list_service;
		map<string,agent> list_house;
		map<string,agent> list_green_space;
		loop i over: neighbors_road {
			list<cell> neighbors <- i.neighbors;	
			loop j over: neighbors{
				list<agent> sp <- agents_inside(j);
				if(!empty(sp)){
					if(contains(sp[0].name,"service")){
						if (!(list_service contains sp[0].name)){
							add sp[0].name :: sp[0] to: list_service;
						}
					}
					if(contains(sp[0].name,"house")){
						if (!(list_house contains sp[0].name)){
							add sp[0].name :: sp[0] to: list_house;
						}
					}
					if(contains(sp[0].name,"green_space")){
						if (!(list_green_space contains sp[0].name)){
							add sp[0].name :: sp[0] to: list_green_space;
						}
					}
					}
				}
			}
		loop i over: neighbors_road{
			list<cell> neighbors <- i.neighbors;	
			loop j over: neighbors{
				j.pollution <- (length(list_house) + length(list_service) * 10 - length(list_green_space) * 10);
			}
		}
		
	}
}

species generic_species {
	cell my_cell;
	int nb_increase;
	string type;
	
	
	action increase_species {
		loop times: nb_increase {
			cell _my_cell <- self.choose_cell();
			if((length(cell where each.available) >= 1) and (_my_cell != nil))
			{
				create species(self) number: 1 {
					my_cell <- _my_cell;
					my_cell.available <- false;
					location <- my_cell.location;
				}
			}
		}
		
	}
	
	action decrease_species {
//		empty
	}
	
	reflex increase{
		do increase_species();
	}
	
	reflex decrease{
		do decrease_species();
	}
	
	cell choose_cell {
		return nil;
	}
}



grid cell width: 50 height: 50 neighbors: 8 {
	//pollution level
	float pollution <- 0.0 min: 0.0 max: 100.0;
	

	rgb color <- #red update: rgb(255 *(pollution/10.0) , 255 * (1 - (pollution/10.0)), 0.0);

	
	bool available <- false;
	
//	action create_cell{
//		cell this_cell <- self;
//		create species(green_space) number: 1 {
//			my_cell <- this_cell;
//			my_cell.available <- false;
//			location <- my_cell.location;
//		}
//	}
}

experiment urban_development type: gui until: (length(house) < 1 or length(service) < 1){
	float minimum_cycle_duration <- 0.01;
	parameter "Household max leave:" var: nb_max_decrease_house min: 0 max: 10 step: 1;
	parameter "Household increase each year:" var: nb_increase_house min: 1 max: 10 step: 1;
	parameter "Service max leave:" var: nb_max_decrease_service min: 0 max: 10 step: 1;
	parameter "Service increase each year:" var: nb_increase_service min: 1 max: 10 step: 1;
	parameter "X parameter service pollution:" var: param_X_service_pollution min: 0.1 max: 2.0 step: 0.01;
	parameter "Green Space each year:" var: nb_increase_green_space min: 0 max: 2 step: 1;
	parameter "Max number of Green Space:" var: nb_max_green_space min: 1 max: 100 step: 1;
	parameter "Cost of Green Space (by service)" var: cost_green_space_by_service min: 0 max: 300 step: 1;
	output {
		monitor "1.Number of house" value: length(house);
		monitor "2.Number of service" value: length(service);
		monitor "3.Number of green space" value: length(green_space);
		monitor "4.Max happiness" value: (house with_max_of(each.happiness)).happiness;
		monitor "5.Min happiness" value: (house with_min_of(each.happiness)).happiness;
		monitor "6.Average happiness" value: (house mean_of(each.happiness));
//		monitor "7.Number of house leave per cycle" value: length(house where (each.happiness <= 0)) ;
//		monitor "Step" value: current_date;
		// số lượng house leave mỗi cycle
		
		display map type: java2D{
			
			species road aspect: default;
			
			grid cell lines: #black elevation: pollution * 3.0 triangulation: true transparency: 0.8 refresh: true; 
			species house aspect: house refresh: true;
			species service aspect: service refresh: true;
			species green_space aspect: green_space;
			event mouse_down action: create_green_space;
		}
		
		display chart_house_and_service_display refresh: every(1 #cycles) {
			chart "House and service" type: series {
				data "Number of house" value: length(house) color: #blue;
				data "Number of service" value: length(service) color: #orange;
			}
		}
		display chart_happiness_display refresh: every(1 #cycles) {
			chart "Average happiness" type: series {
				data "Average happiness" value: (house mean_of(each.happiness)) color: #pink;
			}
		}
	}
}
