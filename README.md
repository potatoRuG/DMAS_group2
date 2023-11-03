# Investigating the Conformist Theory for Group Behavior of American and Japanese People in an Agent-Based Model

A project for the RUG course *Design of Multi-Agent Systems* by Aylar Ziad Alizadeh, Lauren Kersten, Tom Veldhuis and Twan Vos (Group 2). The model used in this project was built in NetLogo (using the *Party* model from the Models Library of the NetLogo program as a basis) to simulate interactions between agents that move between neighborhoods. 

## Usage
The NetLogo program is required for running the simulation model used in this project. Open the *base_model.nlogo* file to show the simulation model.

### Settings
The interface uses three main settings that can be adjusted:
- *number-of-people*: The number of agents being part of the simulation.
- *number-of-groups*: The number of neighborhoods the agents are divided between in the simulation.
- *ethnicity*: can be either *American* (with a high mobility rate of 0.8) or *Japanese* (with a low mobility rate of 0.3).
- *model*: can be either *Macy/Sato* (using the simplified Macy & Sato model) or *Henrich/Boyd* (using the punishment model).

### Setting up the model
After pressing the *setup* button, the model will prepare itself to start the simulation. The following can be stated about the boxed view on the right, which shows the current model structure:
- American agents are colored red, while Japanese agents are colored blue.
- The numbers above each group represents the current amount of agents in their respective neighborhood.
- Agents that are being marked as being a potential partner for interaction, are colored green during the simulation.

### Running the model
When the model has been set up, you can run the model by either pressing the *go once* button (to run the model for one epoch/tick) or pressing the *go* button (to run the model continuously). While running the model, the plots on the left show the following information:
- *interactions vs exits*: Shows the exit ratio (the percentage of interactions being exited by one or both agents) over time.
- *interactions vs full cooperation*: Shows the full cooperation ratio (the percentage of interactions ending with both agents cooperating) over time.
- *average payoff over time*: Shows the average change in payoff per agent over time.
- *newcomer interact. vs. full coop*: Shows the full cooperation ratio (the percentage of interactions ending with both agents cooperating) for interactions involving a newcomer over time.

On the right, the following monitors are shown:
- *nr. of interactions*: The total number of interactions during the current simulation.
- *nr. of exit interactions*: The total number of interactions that were exited by one or both agents during the current simulation.
- *nr. of interactions (newcomer)*: The number of interactions that involved a newcomer during the current simulation.
- *nr. of full coop interactions*: The total number of interactions that ended with both agents cooperating during the current simulation.
- *nr. of full coop interactions (newcomer)*: The total number of interactions that involved a newcomer and that ended with both agents cooperating during the current simulation.
- *avg play prob*: (*Macy/Sato* model only) The average probability of each agent repeating their last play action (either choosing to enter or exit an interaction between two agents).
- *avg strat. prob*: (*Macy/Sato* model only) The average probability of each agent repeating their last strategy (either cooperating or defecting during an interaction between two agents).
- *p-variants stage 0*: (*Henrich/Boyd* model only) The current number of agents that have a P-variant at stage 0.
- *p-variants stage 1*: (*Henrich/Boyd* model only) The current number of agents that have a P-variant at stage 1.
- *interactions-punish*: (*Henrich/Boyd* model only) The total number of interactions that ended with an agent punishing another agent during the current simulation.
