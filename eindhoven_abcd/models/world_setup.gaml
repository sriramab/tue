/**
* Name: worldsetup
* Author: Srirama Bhamidipati
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/
model worldsetup


global
{
/** Insert the global definitions, variables and actions here */
	date starting_date <- date([2017,4,2,0,0,0]);
	
	float step <- 1 # minute;
	file eindhoven_extent <- file("../gis/UTMoutlineEindhoven.shp");
	file selected_buildings <- file("../gis/selBuildings.shp");
	file eindhoven_postcodes <- file("../gis/correctedUTMexternal.shp");
	file home_location <- csv_file("../data/onlyEindhoven.csv", ",");
	//file home_location <- csv_file("../data/hh_location.csv", ";");
	file road <- file("../gis/mainRoadsEindhoven.shp");
	file people_schedule <- csv_file("../data/schedule.csv", ",");
	matrix agent_schedule <- matrix(people_schedule);
	geometry shape <- envelope(eindhoven_postcodes);
	graph the_graph;
	int home_size <- 50;
	
	
	init
	{
		create buildings from:selected_buildings;
		create roads from: road;
		//map<road,float> weights_map <- road as_map (each:: (each.destruction_coeff * each.shape.perimeter));
		the_graph <- as_edge_graph(roads); //with_weights weights_map;
		create postcode from: eindhoven_postcodes with: [dr_postcode::float(get("postcode"))];
		create homes from: home_location header: true with: [id::int(read("Hhid")), pc::int(read("PPC"))]
		{
			shape <- square(home_size);
			//write pc;
			ask postcode
			{
				if myself.pc = dr_postcode
				{
					myself.location <- any_location_in(self);
				}

			}

		}

		// put people in homes
		loop i over: homes
		{
			create male number: 1
			{
				location <- any_location_in(i);
				myname <- i.id * 10 + mygender;
				myhome <- i.id;
				my_gender_color <- # blue;
				my_postcode <- i.pc;
			}

		}

		loop i over: homes
		{
			create female number: 1
			{
				location <- any_location_in(i);
				myname <- i.id * 10 + mygender;
				myhome <- i.id;
				my_gender_color <- # pink;
				my_postcode <- i.pc;
			}

			i.family_size <- length(agents_inside(i));
		}

		ask male
		{
			loop k from: 1 to: agent_schedule.rows - 1
			{
				if myname = agent_schedule[0, k]
				{
					add int(agent_schedule[15, k]) to: activity_starttime;
					add int(agent_schedule[17, k]) to: activity_endtime;
					add int(agent_schedule[19, k]) to: activity_postcode;
				}

			}

		}

		ask female
		{
			loop k from: 1 to: agent_schedule.rows - 1
			{
				if myname = agent_schedule[0, k]
				{
					add int(agent_schedule[15, k]) to: activity_starttime;
					add int(agent_schedule[17, k]) to: activity_endtime;
					add int(agent_schedule[19, k]) to: activity_postcode;
				}

			}

		}

	}

	reflex simulation_stop_time when: cycle = 1720
	{
		write "time is now " + time;
		do pause;
	}

}

species buildings{
	aspect default{
		draw shape color: rgb(#tan) depth:rnd(self.shape.area/1000);
	}
}

species roads
{
	int people_counts;
	aspect default
	{
		draw shape + 5 + people_counts color: # green;
	}
	aspect traffic_flow
	{
		
		draw shape+5+people_counts color:#green;
		
		
	}

}

species male skills: [moving]
{
	int myname;
	int mygender <- 0;
	int myhome;
	int my_postcode;
	rgb my_gender_color; // <- (mygender = 0) ? # blue : # red;
	matrix my_schedule;
	list<int> activity_starttime;
	list<int> activity_endtime;
	list<int> activity_postcode;
	postcode h;
	int current_postcode;
	
	reflex male_moving
	{
		if activity_endtime contains cycle
		{
			int go_here <- activity_postcode[activity_endtime index_of cycle];
			h <- one_of(postcode where (each.dr_postcode = go_here));
			write "i am " + name + " i will go to " + go_here;
			if h = nil
			{
				h <- one_of(postcode);
			}

			write h;
			//postcode go_postcode <- 

		}

		do goto target: h on: the_graph speed: 10 #km/ #h;
		
		//current_postcode <- (one_of(postcode overlapping self).dr_postcode=my_postcode)?1:0;
	}

	aspect default
	{
		draw circle(50) color: #blue;
	}

}

species female skills: [moving]
{
	int myname;
	int mygender <- 1;
	int myhome;
	int my_postcode;
	rgb my_gender_color; // <- (mygender = 0) ? # blue : # red;
	list<int> activity_starttime;
	list<int> activity_endtime;
	list<int> activity_postcode;
	int current_postcode;
	postcode h;
	reflex female_moving
	{
		if activity_endtime contains cycle
		{
			int go_here <- activity_postcode[activity_endtime index_of cycle];
			h <- one_of(postcode where (each.dr_postcode = go_here));
			//write "i am " + name + " i will go to " + go_here;
			if h = nil
			{
				h <- one_of(postcode);
			}

			write h;
			//postcode go_postcode <- 

		}

		path path_followed <- self goto [target::h, on::the_graph, return_path:: true, speed::10 #km/#h];
		list<geometry> segments <- path_followed.segments;
		
		loop line over: segments {
			float dist <- line.perimeter;
			roads the_road <- roads(path_followed agent_from_geometry line);
                    ask the_road {
               						people_counts  <- people_counts + 1;
            }
		}
		//do goto target: h on: the_graph speed: 10 #km/#h;
		//current_postcode <- (one_of(postcode overlapping self).dr_postcode=my_postcode)?1:0;
		//current_postcode<-int(one_of(postcode) overlaps self);
		//write current_postcode;
		/*
		 * float dist <- line.perimeter;
				road rd <- road(path_followed agent_from_geometry line); 
				rd.nb_people_on_road <- rd.nb_people_on_road +dist / rd.shape.perimeter;
		 */
		
		
	}

	aspect default
	{
		draw circle(50) color: #red;
	}

}

species homes
{
	int id; // household ID
	int pc; //postcode
	int family_size;
	init
	{
	}

	aspect default
	{
		draw square(home_size) color: # green;
	}

}

species postcode
{
	int dr_postcode;
	rgb postcode_color ;//<-rgb(255,255,255,0.1);
	
	reflex coloration when:every(30.0){
		 postcode_color <- rgb((int(length(male inside self))+int(length(male inside self)))*10,100,180);
		 //write postcode_color.red;
	}
	aspect default
	{
		rgb c<-#gray;
		draw shape color: rgb(c.red,c.green,c.blue,0.4) empty:true ;//
		draw string(dr_postcode) color: # black perspective: false font:font("Helvetica", 16 , #plain);
		
	}
	aspect FlowHeight
	{
		if cycle>30{
			
		draw shape color: postcode_color  depth:(length(male inside self)*10);//
		}
		else{
			rgb c<-#gray;
			draw shape color: rgb(c.red,c.green,c.blue,0.4) empty:true ;//
		}
		draw string(dr_postcode) color: # black perspective: false font:font("Helvetica", 16 , #plain);
		
	}

}



experiment eindhoven type: gui
{
	float seed <- 0.7714011133031439;
	float minimum_cycle_duration<-0.2;
	
	/** Insert here the definition of the input and output of the model */
	output
	{
		
		display "datalist_pie_chart" type: java2D
		{
			chart "datalist_pie_chart" type: pie style: exploded
			{
				datalist legend: ["At Home", "Not Home"] 
				value: [sum(male collect (each.current_postcode)),sum(female collect (each.current_postcode))] 
				
				
				color: [ # blue, # red];
			}

		}
		display main_frame type: opengl
		{
			
			
			species postcode aspect: default ;
			species buildings aspect:default;
			//species postcode aspect: FlowHeight;
			species female aspect: default;
			species male aspect: default ;//trace: 100;
			species roads aspect: default;
			species roads aspect: traffic_flow;
			species homes aspect: default;
			
			
			graphics "onlyDisplay"
			{
				//draw selected_buildings color: rgb(# tan, 1.0);// depth:rnd(40);
				//draw time font: font("Helvetica", 64, # plain) color: # black;
				draw  string(current_date, "%Y %N %D %h %m %s")  color:°black font:font("Helvetica", 24 , #plain) at: {world.shape.width, world.shape.height} perspective: false;
			}

		}
		
		display landuse_transport type: opengl
		{
			
			
			//species postcode aspect: default transparency:0.3;
			species postcode aspect: FlowHeight;
			
			
			
			graphics "onlyDisplay"
			{
				//draw selected_buildings color: rgb(# tan, 1.0) depth:rnd(40);
				//draw time font: font("Helvetica", 64, # plain) color: # black;
				draw  string(current_date, "%Y %N %D %h %m %s")  color:°black font:font("Helvetica", 24 , #plain) at: {world.shape.width, world.shape.height} perspective: false;
			}

		}
		
		

	}

}
