/**
* Name: urbanDevelopment
* Based on the internal empty template. 
* Author: Linh + Tu + Dat 
* Tags: 
*/


model Urban

global {
	
	shape_file roads_shape_file <- shape_file("../includes/roads.shp");
	shape_file house_shape_file <- shape_file("../includes/buildings.shp");

	geometry shape <- envelope(roads_shape_file);
	float step <- 10#s;
	float house_nb <- 1;
	graph road_network;
	map<road, float> road_weights;
	
	reflex update_weight {
		road_weights <- road as_map(each::each.shape.perimeter/each.speed_rate);

	}
	
	init{
		create road from: roads_shape_file;
		create house from: house_shape_file with:(height: float(get("HEIGHT")));
		road_network <- as_edge_graph(road);
//		ask house{
//			int num_to_create <- round(house_nb*shape.area);
//			create household number:num_to_create{
//				location <- any_location_in(one_of(myself));
//			}
	}
	
	}
	
species house {
	int height;
	
	aspect default{
		draw shape color: #gray;
	}
	aspect threeD{
		draw shape depth: height texture: ["../includes/roof_top.png","../includes/texture5.jpg"];
	}
}	
species service {
	//chiem 1 o trong grid
}

//same inhabitant -- Ho 
species household skills:[moving] {
	// độ vui vẻ : proba_
	// speed ;
	// color
	point start;
	float happy <- 0.05;
	float speed <- 5 #km/#h;
	rgb color <- rnd_color(255);
	
	float pollution_produced <- rnd(90.0,250.0);
	
	reflex leave when: start = nil and flip(happy){
		start <- any_location_in(one_of(house));
		write name + " " + start;
	}
	
	reflex move when: start != nil{
		do goto target: start on: road_network move_weights: road_weights;
		if (location = start){
			start <- nil;
		} else{
			urban_cell my_cell <- urban_cell(location);
			my_cell.grid_value <- my_cell.grid_value + pollution_produced; 
		}
	}
	
	
	
	aspect default{
		draw circle(5) color:color;
	}
	
	
	//cho diem next the city
	
}

species road{
	float capacity <- 1 + shape.perimeter/30;
	int nb_household <- 0 update: length(household at_distance 1#m); //
	float speed_rate <- 1.0 update: exp(-nb_household/capacity) min: 0.1;
	
	aspect default{
		draw shape buffer ((1- speed_rate)*5) color: #red;
	}
}

//grid urban_cell width: 50 height: 50   toan map 
grid urban_cell width: 50 height: 50 {
	reflex decrease_urban when: every(1 #h){
		grid_value <- grid_value * 0.9;
	}	
}

experiment urban_development type: gui {
	output {
		display map type: opengl{
			mesh urban_cell color: #red transparency: 0.5 scale: 0.05 triangulation: true smooth: true refresh: true; 
			species road aspect: default;
			species house aspect: default;
			species household aspect: default;
			
		}
	}
}
