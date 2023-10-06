# Investigating the Conformist Theory for Group Behavior of American and Japanese People in an Agent-Based Model

A project for the RUG course *Design of Multi-Agent Systems* by Aylar Ziad Alizadeh, Lauren Kersten, Tom Veldhuis and Twan Vos. The model used in this project was built in NetLogo (using the *Party* model from the Models Library of the NetLogo program as a basis) to simulate interactions between agents that move between neighborhoods and a global market. 

## Usage
The NetLogo program is required for running the simulation model used in this project. Open the *base_model.nlogo* file to show the simulation model.

### Settings
The interface uses three main settings that can be adjusted:
- *number-of-people*: The number of agents being part of the simulation.
- *number-of-groups*: The number of neighborhoods the agents are divided between in the simulation.
- *ethnicity*: can be either *American* (with a high mobility rate of 0.8) or *Japanese* (with a low mobility rate of 0.3).

### Setting up the model
After pressing the *setup* button, the model will prepare itself to start the simulation. The following can be stated about the boxed view on the right, which shows the current model structure:
- American agents are colored red, while Japanese agents are colored blue.
- The global market is represented by the group of agents at the top, while the neighborhoods are represented by the other groups of agents.
- The numbers above each group represents the current amount of agents in their respective neighborhood or market.
- Agents that are being marked as being a potential partner for interaction, are colored green during the simulation.

### Running the model
When the model has been set up, you can run the model by either pressing the *go once* button (to run the model for one epoch/tick) or pressing the *go* button (to run the model continuously). While running the model, the monitors on the left show the following information:
- *interactions vs exits*: A plot that shows the exit ratio (the percentage of interactions being exited by one or both agents) over time.
- *interactions vs full cooperation*: A plot that shows the full cooperation ratio (the percentage of interactions ending with both agents cooperating) over time.
- *number of exits*: The total number of interactions that were exited by one or both agents during the current simulation.
- *nr. of full coop interactions*: The total number of interactions that ended with both agents cooperating during the current simulation.
- *avg play prob*: The average probability of each agent repeating their last play action (either choosing to enter or exit an interaction between two agents).
- *avg strat. prob*: The average probability of each agent repeating their last strategy (either cooperating or defecting during an interaction between two agents).
- *avg market prob*: The average probability of each agent repeating their last market action (either choosing to go to the global market or staying in their current neighborhood).