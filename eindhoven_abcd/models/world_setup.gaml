/**
* Name: worldsetup
* Author: skbhamidipati
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model worldsetup

global {
	/** Insert the global definitions, variables and actions here */
	file eindhoven_extent <-  file("../gis/UTMoutlineEindhoven.shp");
	file eindhoven_postcodes <-  file("../gis/correctedUTMexternal.shp");
	
	geometry shape <- envelope(eindhoven_extent);
	
	init{
		create postcode from:eindhoven_postcodes;
		write (#red).red;
	}
}

species postcode{
	
	aspect default{
		draw shape color:#red empty:true;
	}
}

experiment worldsetup type: gui {
	
	/** Insert here the definition of the input and output of the model */
	output {
		display main_frame type:opengl{
			species postcode aspect:default;
			graphics "onlyDisplay"{
				draw eindhoven_extent color:rgb(225,225,225,0.5);
			}
		}
	}
}
