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
	list<cell> list_cell;
	graph road_network;
	map<road, float> road_weights;
	int nb_increase_house <- 3;
	int nb_increase_service <- 3;
	
	init{
		create road from: roads_shape_file;
		road_network <- as_edge_graph(road);
		create house number: 1;
		create service number: 4;
//		create green_space number: 1;

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
	
	aspect house {
		draw circle(20.0) color: #blue;
	}
}	

species service parent: generic_species  {
	rgb color <- #orange;
	int nb_increase <- nb_increase_service;
	cell choose_cell {
//		return (my_cell.neighbors2)
		return one_of(cell where each.available );
	}
	aspect service {
		draw circle(20.0) color: #orange;
	}
}

species road{
	aspect default{
		draw shape color: #black;
	}
	
	list<cell> list_cell <- cell overlapping shape;
	
	init {
		loop i over: list_cell {
			list<cell> neighbors <- i.neighbors;
			i.available <- false;
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
		loop i over: list_cell {
			i.available <- false;
		}
	}
//	reflex check {
//		//loop i over: list_cell {
//		//	i.available <- false;
//		//}
//		loop i over: cell {
//			if(i.available){
//				i.color <- #green;	
//			}
//		}
//	}
}

species generic_species {
	cell my_cell <- one_of(cell where each.available);
	int nb_increase;
	
	init {
		location <- my_cell.location;
	}
	
	reflex increase {
		if(length(cell where each.available) > 0)
		{
			create species(self) number: nb_increase {
				my_cell <- my_cell;
				my_cell.available <- false;
				location <- my_cell.location;
			}
		}
		
	}
	
	cell choose_cell {
		return nil;
	}
}

species green_space parent: generic_species{
	rgb color <- #green;
	int nb_increase <- nb_increase_service;
	cell choose_cell {
//		return (my_cell.neighbors2)
		return one_of(my_cell.list_neighbors);
	}
	aspect green_space {
		draw circle(20.0) color: #green;
	}
}

grid cell width: 50 height: 50 neighbors: 8 {
	//pollution level
	float pollution <- 0.0 min: 0.0 max: 100.0;
	
	//color updated according to the pollution level (from red - very polluted to green - no pollution)
//	rgb color <- #green update: rgb(255 *(pollution/30.0) , 255 * (1 - (pollution/30.0)), 0.0);
//	rgb color1 <- #red;
	
	bool available <- false;
	
//	reflex test {
//		write neighbors_of(topology(self), self, 8);
//	}
	list<cell> list_neighbors <- neighbors_of(topology(self), self, 8);
}

experiment urban_development type: gui {
	float minimum_cycle_duration <- 0.1;
	
	output {
		display map type: java2D{
			
			species road aspect: default;
			
			grid cell lines: #black elevation: pollution * 3.0 triangulation: true transparency: 0.7; 
			species house aspect: house;
			species service aspect: service;
//			species green_space aspect: green_space;
			
		}
	}
}
