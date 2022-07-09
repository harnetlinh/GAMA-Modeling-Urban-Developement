/**
* Name: urbanDevelopment
* Based on the internal empty template. 
* Author: Linh + Tu + Dat 
* Tags: 
*/


model Urban

global {
	
	shape_file roads_shape_file <- shape_file("../includes/roads.shp");

	geometry shape <- envelope(roads_shape_file);
	float step <- 10#s;
	float house_nb <- 1;
	graph road_network;
	map<road, float> road_weights;
	int nb_increase_house <- 4;
	int nb_increase_service <- 4;
	
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
			create species(service) number: 2 {
				my_cell <- one_of(cell where each.available );
				my_cell.available <- false;
				location <- my_cell.location;
			}
		}
	}
	reflex pollution_evolution{
		//ask all cells to decrease their level of pollution
		ask cell {pollution <- pollution * 0.7;}
		
		//diffuse the pollutions to neighbor cells
		diffuse var: pollution on: cell proportion: 0.9 ;
	}
	
}
	
species house parent: generic_species {
	rgb color <- #blue;
	int nb_increase <- nb_increase_house;
	float happiness <- 0;
	
	init {
		type <- 'house';
	}
	
//	float house_hold_happiness {
//		list<cell> _current_cell <- (cell overlapping self);
//		write _current_cell;
//		cell current_cell <- _current_cell[0];
//		current_cell.color <- #red;
//		list<cell> neighbors <- current_cell.neighbors;
//		rgb rnd_color <- #blue;
//		loop i over: neighbors {
//			i.color <- rnd_color;
//		}
//		return 1.0;
//	}
//	reflex check_happines {
//		list<cell> _current_cell <- (cell overlapping self);
////		write _current_cell;
//		cell current_cell <- _current_cell[0];
//		list<cell> neighbors <- current_cell.neighbors;
//		loop i over: neighbors {
//			i.pollution <- 20.0;
//			list<agent> sp <- agents_inside(i);
//			write sp;
//		}
//	}
	cell choose_cell {
		return one_of(cell where each.available );
	}
	aspect house {
		draw circle(20.0) color: #blue;
	}
	
	action decrease_species {
		int rnd_die_species <- rnd(1,4);
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
//					write(choosen_species_cell[0]);
					choosen_species_cell[0].available <- true;
				}
			}
		}
	}
}	

species service parent: generic_species  {
	rgb color <- #orange;
	int nb_increase <- nb_increase_service;
	
	init {
		type <- 'service';
	}
	
	cell choose_cell {
		return one_of(cell where each.available );
	}
	aspect service {
		draw circle(20.0) color: #orange;
	}
	action decrease_species {
		int rnd_die_species <- rnd(1,4);
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
//					write(choosen_species_cell[0]);
					choosen_species_cell[0].available <- true;
				}
			}
		}
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
//		write _current_cell;
		cell current_cell <- _current_cell[0];
		list<cell> neighbors_road <- current_cell.neighbors;
		loop i over: neighbors_road {
			float nb_neighbor_house <- 0.0;
			float nb_neighbor_service <- 0.0;
			list<cell> neighbors <- i.neighbors;	
			loop j over: neighbors{
				list<agent> sp <- agents_inside(j);
				if(!empty(sp)){
					if(contains(sp[0].name,"house")){
						nb_neighbor_house <- nb_neighbor_house + 1.0;
					}
					if(contains(sp[0].name,"service")){
						nb_neighbor_service <- nb_neighbor_service + 1.0;

					}
				}
			}
			loop j over: neighbors {
				j.pollution <- (nb_neighbor_house + nb_neighbor_service * 20);
			}
		}
	}
}

species generic_species {
	cell my_cell;
	int nb_increase;
	string type;
	
	
	action increase_species {
		if(length(cell where each.available) >= nb_increase)
		{
			create species(self) number: nb_increase {
				my_cell <- choose_cell();
				my_cell.available <- false;
				location <- my_cell.location;
			}
		}
	}
	
	action decrease_species {
//		empty
	}
	
	reflex increase {
		do increase_species();
	}
	
	reflex decrease {
		do decrease_species();
	}
	
	cell choose_cell {
		return nil;
	}
}

species green_space parent: generic_species{
	rgb color <- #green;
	int nb_increase <- nb_increase_service;
//	cell choose_cell {
//		return one_of(my_cell.list_neighbors);
//	}
	aspect green_space {
		draw circle(80.0) color: #green;
	}
}

grid cell width: 50 height: 50 neighbors: 8 {
	//pollution level
	float pollution <- 0.0 min: 0.0 max: 100.0;
	
	//color updated according to the pollution level (from red - very polluted to green - no pollution)
	rgb color <- #red update: rgb(255 *(pollution/30.0) , 255 * (1 - (pollution/30.0)), 0.0);
//	rgb color1 <- #red;
	
	bool available <- false;
//	reflex available_cell {
//		if(available){
//			color <- #green;
//		}else{
//			color <- #white;
//		}
//	}
	
	
//	reflex test {
//		write neighbors_of(topology(self), self, 8);
//	}
//	list<cell> list_neighbors <- neighbors_of(topology(self), self, 8);
}

experiment urban_development type: gui {
	float minimum_cycle_duration <- 0.1;
	
	output {
		display map type: java2D{
			
			species road aspect: default;
			
			grid cell lines: #black elevation: pollution * 3.0 triangulation: true transparency: 0.8 refresh: true; 
			species house aspect: house refresh: true;
			species service aspect: service refresh: true;
//			species green_space aspect: green_space;
			
		}
	}
}
