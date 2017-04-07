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
	file eindhoven_extent <- file("../gis/UTMoutlineEindhoven.shp");
	file eindhoven_postcodes <- file("../gis/correctedUTMexternal.shp");
	file home_location <- csv_file("../data/hh_location.csv", ";");
	file people_schedule <- csv_file("../data/schedule.csv", ";");
	geometry shape <- envelope(eindhoven_postcodes);
	init
	{
		create postcode from: eindhoven_postcodes with: [dr_postcode::float(get("postcode"))];
		create homes from: home_location header: true with: [id::int(read("Hhid")), pc::int(read("PPC"))]
		{
			write pc;
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
			create people number: 2
			{
				location <- any_location_in(i);
				mygender <- flip(0.50) ? 1 : 0;
				myname <- i.id * 10 + mygender;
			}

		}

	}

}

species people skills: [moving]
{
	int myname;
	int mygender;
	aspect default
	{
		if mygender = 1
		{
			draw circle(20) color: # blue at: location - { 30, 0, 0 };
		}

		draw circle(20) color: # pink at: location + { 30, 0, 0 };
	}

}

species homes
{
	int id; // household ID
	int pc; //postcode
	init
	{
	}

	aspect default
	{
		draw square(200) color: # green;
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

experiment worldsetup type: gui
{
	float seed <- 0.7714011133031439;
	/** Insert here the definition of the input and output of the model */
	output
	{
		display main_frame type: opengl
		{
			species postcode aspect: default;
			species homes aspect: default;
			species people aspect: default;
			graphics "onlyDisplay"
			{
				draw eindhoven_extent color: rgb(# tan, 0.1);
			}

		}

	}

}
