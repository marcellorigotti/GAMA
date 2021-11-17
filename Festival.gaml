/**
* Name: NewModel
* Based on the internal empty template. 
* Author: marcello
* Tags: 
*/


model NewModel

/* Insert your model definition here */
global {
    int nb_guest_init <- 50;
    int nb_store_init <- 5;
    int nb_info_init <- 3;
    int distanceThreshold <- 1;
    list<Store> storesFood;
    list<Store> storesDrink;
    list<Store> storesBoth;
    
    init {
    	create Guest number: nb_guest_init;
    	create Store number: nb_store_init;
    	create InformationCenter number: nb_info_init;
    	create SecurityGuard;
    	
    	loop counter from: 1 to: nb_guest_init {
        	Guest my_agent <- Guest[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
		
		loop counter from: 1 to: nb_store_init {
        	Store my_agent <- Store[counter - 1];
        	my_agent <- my_agent.setName(counter);
        	if(!Store[counter - 1].hasFood and !Store[counter - 1].hasDrink){
        		Store[counter - 1].hasFood <- true;
        	}
        	if (Store[counter - 1].hasFood){
        		if(Store[counter - 1].hasDrink){
        			add Store[counter - 1] to: storesBoth;
        		}
        	if (Store[counter - 1].hasFood){
        			add Store[counter - 1] to: storesFood;
        		}
        	}
        	if (Store[counter - 1].hasDrink){
        		add Store[counter - 1] to: storesDrink;
        	}
        }
	}
}

species Guest skills:[moving] {
    bool isHungry <- false update: updateHungry(isHungry);
	bool isThirsty <- false update: updateThirsty(isThirsty);
	bool bad <- flip(0.05);
    point targetPoint <- nil;
    string guestName <- "Undefined";
    list<Store> foodMemory;
    list<Store> drinkMemory;
        
    action updateHungry(bool input){
    	if (!input){
    		return flip(0.01);
    	}
    	return input;
    }
    action updateThirsty(bool input){
    	if (!input){
    		return flip(0.01);
    	}
    	return input;
    }
    action setName(int num) {
		guestName <- "Guest " + num;
	}
	
	reflex checkDestination{
		if(targetPoint = nil){
			if(isHungry){
				if(empty(foodMemory) or flip(0.3)){
					ask InformationCenter closest_to(self){
						myself.targetPoint <- self.location;
					}
				}
				else{
						int len <- length(foodMemory);
						targetPoint <- foodMemory[rnd(len-1)].location;
				}
			}
			
			if(isThirsty){
				if(empty(drinkMemory) or flip(0.3)){
					ask InformationCenter closest_to(self){
						myself.targetPoint <- self.location;
					}
				}
				else{
						int len <- length(drinkMemory);
						targetPoint <- drinkMemory[rnd(len-1)].location;
				}
				
			}
		}
	}
	
    reflex beIdle when: targetPoint = nil{
    	do wander;
    }
    reflex moveToTarget when: targetPoint != nil{
    	do goto target:targetPoint;
    }
    
    reflex reportApproachingInfo when: !empty(InformationCenter at_distance distanceThreshold) {
		ask InformationCenter at_distance distanceThreshold {
			if(myself.isHungry or myself.isThirsty){
				myself.targetPoint <- self.getInfo(myself.isHungry, myself.isThirsty);
			}
			if(myself.bad){
				write ("I'm bad");
				return self.callGuard(myself);
			}
			
			
		}
	}
    
    reflex enterStore when: !empty(Store at_distance distanceThreshold){
    	ask Store at_distance distanceThreshold{
    		if(myself.isHungry){
    			if(self.hasFood){
    				myself.isHungry <- false;
    				myself.targetPoint <- nil;
    				if(!(myself.foodMemory contains self)){
						add self to:myself.foodMemory;
					}
    			}
    		}
    		if(myself.isThirsty){
    			if(self.hasDrink){
    				myself.isThirsty <- false;
    				myself.targetPoint <- nil;
    				if(!(myself.drinkMemory contains self)){
						add self to:myself.drinkMemory;
					}
    			}
    		}
    	}
    }
    
    
    
    aspect base {
		rgb agentColor <- rgb("green");
		if (isHungry and isThirsty) {
			agentColor <- rgb("blue");
		} else if (isThirsty) {
			agentColor <- rgb("yellow");
		} else if (isHungry) {
			agentColor <- rgb("purple");
		}
		if (bad){
			agentColor <- rgb("red");
		}
		draw circle(1) color: agentColor;
	}
} 

species Store {
	bool hasFood <- flip(0.2);
	bool hasDrink <- flip(0.5);	
	string storeName <- "Undefined";
        
    action setName(int num) {
		storeName <- "Store " + num;
	}
	
	aspect base {
		rgb agentColor <- rgb("purple");
		if (hasFood and hasDrink) {
			agentColor <- rgb("blue");
		} else if (hasFood) {
			agentColor <- rgb("purple");
		} else if (hasDrink) {
			agentColor <- rgb("yellow");
		}
		
		draw square(2) color: agentColor;
	}
}

species SecurityGuard skills:[moving]{
	bool hasFood <- flip(0.2);
	bool hasDrink <- flip(0.5);	
	list<Guest> targets;
	
	action kill(agent guestName){
		if(!(targets contains guestName)){
			add guestName to:targets;
		}
	}
	reflex followBadActor when: !empty(targets){
		do goto target: targets[0].location;
	}
	reflex killBadActor when: !empty(targets) and !empty(targets at_distance distanceThreshold){
		ask targets closest_to(self){
			remove self from: myself.targets;
			write (myself.targets);
			return self.die();
		}
	}
	aspect base {
		rgb agentColor <- rgb("red");
		draw triangle(3) color: agentColor;
	}
}

species InformationCenter {
	string storeName <- "InformationCenter";
    
    point getInfo(bool food, bool drink){
    	if(food and drink){
    		if (!empty(storesBoth)){
    			ask storesBoth closest_to(self){
    				return self.location;
    			}
    		}
    	}
    	if(food){
    		ask storesFood closest_to(self){
    			return self.location;
    		}
    	}
    	if(drink){
    		ask storesDrink closest_to(self){
    			return self.location;
    		}
    	}
    }
    action callGuard(agent guestName){
    	ask SecurityGuard{
    		write("security");
    		return kill(guestName);
    	}
    }
    
	aspect base {
		rgb agentColor <- rgb("black");

		draw square(8) color: agentColor;
	}
}

experiment Festival type: gui {
    parameter "Initial number of guests: " var: nb_guest_init min: 1 max: 1000 category: "FestivalGuest" ;
    output {
	    display main_display {
	        species Guest aspect: base;
	        species Store aspect: base;
	        species InformationCenter aspect: base;
	        species SecurityGuard aspect: base;
	    }
    }
}