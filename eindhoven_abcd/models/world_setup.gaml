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
	float step <- 1 # mn;
	file eindhoven_extent <- file("../gis/UTMoutlineEindhoven.shp");
	file eindhoven_postcodes <- file("../gis/correctedUTMexternal.shp");
	file home_location <- csv_file("../data/hh_location.csv", ";");
	file road <- file("../gis/mainRoadsEindhoven.shp");
	file people_schedule <- csv_file("../data/schedule.csv", ",");
	matrix agent_schedule <- matrix(people_schedule);
	geometry shape <- envelope(eindhoven_postcodes);
	graph the_graph;
	int home_size <- 50;
	init
	{
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

	reflex simulation_stop_time when: cycle = 1740
	{
		write "time is now " + time;
		do pause;
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
	reflex male_moving
	{
		if activity_endtime contains cycle
		{
			int go_here <- activity_postcode[activity_endtime index_of cycle];
			h <- one_of(postcode where (each.dr_postcode = go_here));
			write "i am " + name + " i will go to " + go_here;
			if h = nil
			{
				h <- postcode[1];
			}

			write h;
			//postcode go_postcode <- 

		}

		do goto target: h on: the_graph speed: 50 # km / # h;
	}

	aspect default
	{
		draw circle(100) color: my_gender_color;
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
	postcode h;
	reflex male_moving
	{
		if activity_endtime contains cycle
		{
			int go_here <- activity_postcode[activity_endtime index_of cycle];
			h <- one_of(postcode where (each.dr_postcode = go_here));
			write "i am " + name + " i will go to " + go_here;
			if h = nil
			{
				h <- postcode[1];
			}

			write h;
			//postcode go_postcode <- 

		}

		do goto target: h on: the_graph speed: 50 # km / # h;
	}

	aspect default
	{
		draw circle(100) color: my_gender_color;
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
	aspect default
	{
		draw shape color: # red empty: true;
		draw string(dr_postcode) color: # black perspective: false;
	}

}

species roads
{
	aspect default
	{
		draw shape + 5 color: # black;
	}

}

experiment eindhoven type: gui
{
	float seed <- 0.7714011133031439;
	parameter "homeSize" var: home_size;
	/** Insert here the definition of the input and output of the model */
	output
	{
		display main_frame type: opengl
		{
			species postcode aspect: default;
			species homes aspect: default;
			species female aspect: default;
			species male aspect: default trace: 100;
			species roads aspect: default;
			graphics "onlyDisplay"
			{
				draw eindhoven_extent color: rgb(# tan, 0.1);
				//draw time font: font("Helvetica", 64, # plain) color: # black;
			}

		}

	}

}
