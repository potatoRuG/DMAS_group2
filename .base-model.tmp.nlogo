;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; SETUP ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals [
  neighborhoods       ;; Set of patches where groups are located

  ;; Macy/Sato model parameters
  payoff-exit         ;; payoff when there is no exchange

  ;; Henrich/Boyd model parameters
  ;; Note: B > C and \phi < \rho < C
  p0                  ;; frequency of P-variant at punishment stage 0
  p1                  ;; frequency of P-variant at punishment stage 0
  coop-cost           ;; cost of cooperation (C)
  group-benefit       ;; benefit of group (B)
  error-rate          ;; chance of P-variants mistakenly defecting or failing to punish (e)
  punishee-cost       ;; cost of being punished (\rho)
  punisher-cost       ;; cost of punishing (\phi)
  alpha               ;; strength of conformist transmission

  number-interactions              ;; total number of interactions
  interactions-newcomer            ;; number of interactions which involved a newcomer
  interactions-exit                ;; number of interactions that were exited
  interactions-full-coop           ;; number of interactions in which there was full cooperation
  interactions-full-coop-newcomer  ;; number of newcomer interactions in which there was full cooperation
  avg-payoff                       ;; average change in payoff
  interactions-punish              ;; number of interactions
]

turtles-own [
  mobility-rate      ;; float
  newcomer?          ;; true or false
  my-neighborhood    ;; to which group agent belongs to

  ;; Macy/Sato parameters
  last-play-action   ;; last play action (play or exit)
  play-prob          ;; probability of repeating last play action
  last-strategy      ;; last strategy (cooperate or defect)
  strategy-prob      ;; probability of repeating last strategy

  ;; Henrich/Boyd parameters
  p0-agent           ;; True if agent has P-variant at stage 0
  p1-agent           ;; True if agent has P-variant at stage 1
  last-action        ;; Last action that the agent did

  last-payoff        ;; how much payoff agent has at the start of a tick
  payoff             ;; how much payoff agent currently has
  encountered-agents ;; list of agents that the agent has encountered so far
]

to setup
  clear-all
  ;; create patches where groups are located
  set neighborhoods patches with [neighborhood?]
  set-default-shape turtles "person"

  set p0 0.5
  set p1 0.5
  set group-benefit 20
  set coop-cost 2
  ;set punishee-cost 1
  ;set punisher-cost 0.5 ;cost rules ascending order: punisher -> punishee -> coop -> group
  set error-rate 0.01
  set alpha 0.2

  create-turtles number-of-people [
    ;; set size of agent
    set size 3
    ;; assign different color and mobility rate to
    ;; agents with different ethnicity
    ifelse (ethnicity = "American") [
      set color red
      set mobility-rate 0.8
      set punishee-cost 0.5
      set punisher-cost 0.2
    ] [
      set color blue
      set mobility-rate 0.3
      set punishee-cost 1
      set punisher-cost 0.5
    ]

    ;; -- learning parameters --
    set last-play-action one-of ["play" "exit"]
    set last-strategy one-of ["cooperate" "defect"]
    set play-prob random-float 1.0
    set strategy-prob random-float 1.0
    ;; -------------------------

    ;; assign each agent to a group
    set my-neighborhood one-of neighborhoods
    ;; move agents to their group
    move-to my-neighborhood
    ;; agent is not a newcomer in the beginning
    set newcomer? false
    ;; each agent starts with a clean pay off
    set payoff 0
    ;; each agent has not encountered any other agent yet
    set encountered-agents (list)
  ]

  set payoff-exit 0
  determine-p-variants

  ;; interactions numbers
  set number-interactions 0.00000001
  set interactions-newcomer 0.00000001
  set interactions-exit 0
  set interactions-full-coop 0
  set interactions-full-coop-newcomer 0
  set interactions-punish 0

  ;; count amount of agents in one group
  update-labels
  ask turtles [
    spread-out-vertically
  ]
  reset-ticks
end

to determine-p-variants
  ;; p0
  let p0-length floor(number-of-people * p0)
  let all-p0-list shuffle([who] of turtles)
  let p0-list sublist all-p0-list 0 p0-length
  let np0-list sublist all-p0-list p0-length number-of-people

  foreach p0-list [ x -> ask turtle x [ set p0-agent true ] ]
  foreach np0-list [ x -> ask turtle x [ set p0-agent false ] ]

  ;; p1
  let p1-length floor(number-of-people * p1)
  let all-p1-list shuffle([who] of turtles)
  let p1-list sublist all-p1-list 0 p1-length
  let np1-list sublist all-p1-list p1-length number-of-people

  foreach p1-list [ x -> ask turtle x [ set p1-agent true ] ]
  foreach np1-list [ x -> ask turtle x [ set p1-agent false ] ]
end

to update-p-variants
  ;;------ Stage 0 ------
  ;; -> Determine change in p0
  ;; change_p0 = p0 * (1 - p0) * [(1 - alpha) * beta * (b_p0 - b_np0) + alpha (2 * p0 - 1)]
  ;; b_p0 - b_np0 = (1 - e) * (N * p1 * (1 - e) * \rho - C)

  let div-group-size floor ( number-of-people / (number-of-groups) )
  ;; |-> Since group sizes vary, the group size that is used is the one where
  ;;     everyone evenly distributes among the groups
  let nerr 1 - error-rate

  let payoff-diff nerr * ( div-group-size * p1 * nerr * punishee-cost - coop-cost)
  let normal-payoff-diff payoff-diff / abs( payoff-diff )
  let payoff-transmission (1 - alpha) * normal-payoff-diff
  let conformist-transmission alpha * (2 * p0 - 1)
  let change-p0 p0 * (1 - p0) * (payoff-transmission + conformist-transmission)

  ;; -> Change P-variants according to the new p0
  let p0-length floor(number-of-people * p0)
  let new-p0-length floor(number-of-people * (p0 + change-p0))
  let length-diff new-p0-length - p0-length

  if length-diff > 0 [
    let np-agents [who] of turtles with [p0-agent = false]
    let changed-np-agents n-of length-diff np-agents
    foreach changed-np-agents [ x -> ask turtle x [ set p0-agent true ] ]
  ]
  if length-diff < 0 [
    let p-agents [who] of turtles with [p0-agent = true]
    let changed-p-agents n-of abs(length-diff) p-agents
    foreach changed-p-agents [ x -> ask turtle x [ set p0-agent false ] ]
  ]

  ;;------ Stage 1 ------
  ;; -> Determine change in p1
  ;; change_p1 = p1 * (1 - p1) * [(1 - alpha) * beta * (b_p1 - b_np1) + alpha (2 * p1 - 1)]
  ;; b_p1 - b_np1 = - N * (1 - e) * \phi * (1 - (1 - e) * p0)

  set payoff-diff -1 * div-group-size * nerr * punisher-cost * (1 - nerr * p0)
  set normal-payoff-diff payoff-diff / abs( payoff-diff )
  set payoff-transmission (1 - alpha) * normal-payoff-diff
  set conformist-transmission alpha * (2 * p1 - 1)
  let change-p1 p1 * (1 - p1) * (payoff-transmission + conformist-transmission)

  ;; -> Change P-variants according to the new p1
  let p1-length floor(number-of-people * p1)
  let new-p1-length floor(number-of-people * (p1 + change-p1))
  set length-diff new-p1-length - p1-length

  if length-diff > 0 [
    let np-agents [who] of turtles with [p1-agent = false]
    let changed-np-agents n-of length-diff np-agents
    foreach changed-np-agents [ x -> ask turtle x [ set p1-agent true ] ]
  ]
  if length-diff < 0 [
    let p-agents [who] of turtles with [p1-agent = true]
    let changed-p-agents n-of abs(length-diff) p-agents
    foreach changed-p-agents [ x -> ask turtle x [ set p1-agent false ] ]
  ]

  ;;----- Update p0 and p1 ------
  set p0 p0 + change-p0
  set p1 p1 + change-p1
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; GO ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; remember current payoff
  ask turtles [ set last-payoff payoff ]
  ;; reset the color of potential partners back to default
  ask turtles [reset-color]
  ;; let all agent move to their sites
  ask turtles [ move-to my-neighborhood ]
  ;; decide what to do: stay in same group or move to another
  decide-action
  ;; count amount of agents in one group
  update-labels
  ;; Henrich/Boyd: update P-variants
  if model = "Henrich/Boyd" [
    update-p-variants
  ]

  ;; assign correct group to agent label and spread agents out
  ask turtles [
    set my-neighborhood patch-here
    spread-out-vertically
  ]

  ;; track the current average payoff
  set avg-payoff 0
  ask turtles [
    set avg-payoff avg-payoff + (payoff - last-payoff)
  ]
  set avg-payoff avg-payoff / (count turtles)

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; INTERACTIONS ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; decice whether agent should change neighborhood or stay in neighborhood
;; based on mobility rate
to decide-action
  ;; firstly, everybody is not a newcomer anymore
  ;; in their respective neighborhood
  ask turtles [ set newcomer? false ]
  ;; secondly, check who wants to change neighborhoods
  ask turtles [
    if (random-float 1.0) < mobility-rate [
      change-neighborhood
    ]
  ]
  ;; finally, after everyone has moved let everyone
  ;; who didn't change neighborhoods start interactions
  ifelse model = "Macy/Sato" [
    stay-in-neighborhood
  ] [
    stay-in-neighborhood-with-punishing
  ]
end

;; agent should change neighborhood it's currently in
to change-neighborhood
  display
  move-to one-of neighborhoods
  set newcomer? true
  if patch-here != my-neighborhood [ stop ]
  change-neighborhood
end

;;----------------- Macy & Sato ---------------------

;; if agent stays in same neighborhood, try to partner up
to stay-in-neighborhood
  ask turtles with [not newcomer?] [
    ;; pick a potential partner
    let potential-partner one-of other turtles-here
    ;; check whether there are partners left
    if potential-partner != nobody [
      ;; link with partner
      create-link-with potential-partner
      ask potential-partner [ set color green ]
      ;; perform interaction
      interact-with-partner
    ]
  ]
  clear-links
end

;; agent interacts with its partner
to interact-with-partner
    let partner one-of link-neighbors
    if partner != nobody [
      set number-interactions number-interactions + 1
      if newcomer? = true or [newcomer?] of partner = true [
        set interactions-newcomer interactions-newcomer + 1
      ]

      ;; update encountered agent list of both agents
      let my-id who
      let partner-id [who] of partner
      set encountered-agents lput partner-id encountered-agents
      ask partner [ set encountered-agents lput my-id encountered-agents ]
      ;; remove possible duplicates from both lists
      set encountered-agents remove-duplicates encountered-agents
      ask partner [ set encountered-agents remove-duplicates encountered-agents ]

      ;; determine whether the agent and its partner play or exit the prisoner's dilemma
      determine-play-or-exit partner
      ;; determine which strategy the agent and its partner use for the prisoner's dilemma
      determine-strategy partner
    ]
end

to determine-play-or-exit [ partner ]
  ;; ------ TRUST: PLAY OR EXIT -------
  ;; Check whether the agent wants to repeat its last action (play or exit)
  let play-action ""
  ifelse (random-float 1.0) < play-prob [
    ;; Yes -> repeat last action
    set play-action last-play-action
  ] [
    ;; No -> choose the other action
    if last-play-action = "play" [ set play-action "exit" ]
    if last-play-action = "exit" [ set play-action "play" ]
    set last-play-action play-action
  ]

  ;; Check whether the partner wants to repeat its last action (play or exit)
  let play-action-partner ""
  ifelse (random-float 1.0) < [play-prob] of partner [
    ;; Yes -> repeat last action
    set play-action-partner [last-play-action] of partner
  ] [
    ;; No -> choose the other action
    if [last-play-action] of partner = "play" [ set play-action-partner "exit" ]
    if [last-play-action] of partner = "exit" [ set play-action-partner "play" ]
    ask partner [ set last-play-action play-action-partner ]
  ]

  ;; If someone is a newcomer, the lower the mobility rate is,
  ;; the more likely it is someone exits the interaction
  if [newcomer?] of partner and (random-float 1.0) >= mobility-rate [
    set play-action "exit"
    set last-play-action "exit"
  ]
  if newcomer? and (random-float 1.0) >= [mobility-rate] of partner [
    set play-action-partner "exit"
    ask partner [ set last-play-action "exit" ]
  ]

  ;; Check for 50% chance of using the same decision as the role model
  ;; (agent in the neighborhood with highest cumulative payoff)
  let role-model max-one-of turtles-here [payoff]
  if who != [who] of role-model and (random-float 1.0) >= 0.5 [
    set play-action [last-play-action] of role-model
    set last-play-action [last-play-action] of role-model
  ]
  if [who] of partner != [who] of role-model and (random-float 1.0) >= 0.5 [
    set play-action-partner [last-play-action] of role-model
    ask partner [ set last-play-action [last-play-action] of role-model ]
  ]

  ;; Stop interacting if either the agent, its partner or both want to exit
  if play-action = "exit" or play-action-partner = "exit" [
    set interactions-exit interactions-exit + 1

    ;; determine new payoffs with exit payoff
    set payoff (payoff + payoff-exit)
    ask partner [ set payoff (payoff + payoff-exit) ]

    ;; update play probability for exiting
    update-play-prob payoff-exit
    ask partner [ update-play-prob payoff-exit ]

    ;; exit interaction
    stop
  ]
end

to determine-strategy [ partner ]
  ;; ---- TRUSTWORTHINESS: COOPERATE OR DEFECT ----
  ;; Check whether the agent wants to repeat its last coop action
  let strategy ""
  ifelse (random-float 1.0) < strategy-prob [
    ;; Yes -> repeat last coop action
    set strategy last-strategy
  ] [
    ;; No -> choose the other coop action
    if last-strategy = "cooperate" [ set strategy "defect" ]
    if last-strategy = "defect" [ set strategy "cooperate" ]
    set last-strategy strategy
  ]

  ;; Check whether the partner wants to repeat its last play action
  let partner-strategy ""
  ifelse (random-float 1.0) < [strategy-prob] of partner [
    ;; Yes -> repeat last play action
    set partner-strategy [last-strategy] of partner
  ] [
    ;; No -> choose the other play action
    if [last-strategy] of partner = "cooperate" [ set partner-strategy "defect" ]
    if [last-strategy] of partner = "defect" [ set partner-strategy "cooperate" ]
    ask partner [ set last-strategy partner-strategy ]
  ]

  ;; Check for 50% chance of using the same decision as the role model
  ;; (agent in the neighborhood with highest cumulative payoff)
  let role-model max-one-of turtles-here [payoff]
  if who != [who] of role-model and (random-float 1.0) >= 0.5 [
    set strategy [last-strategy] of role-model
    set last-strategy [last-strategy] of role-model
  ]
  if [who] of partner != [who] of role-model and (random-float 1.0) >= 0.5 [
    set partner-strategy [last-strategy] of role-model
    ask partner [ set last-strategy [last-strategy] of role-model ]
  ]

  ;; Update the interaction counters
  if strategy = "cooperate" and partner-strategy = "cooperate" [
    set interactions-full-coop interactions-full-coop + 1
    if newcomer? = true or [newcomer?] of partner = true [
      set interactions-full-coop-newcomer interactions-full-coop-newcomer + 1
    ]
  ]

  ;; calculate the payoffs based on the strategies of the agent and its partner
  ;; and the current opportunity cost
  let opportunity-cost 1 - ((count turtles-here - 1) / (count turtles - 1))
  let my-payoff calculate-payoff strategy partner-strategy opportunity-cost
  let partner-payoff calculate-payoff partner-strategy strategy opportunity-cost

  ;; update coop probabilities
  update-coop-prob my-payoff
  ask partner [ update-coop-prob partner-payoff ]

  ;; update payoffs of agents
  set payoff (payoff + my-payoff)
  ask partner [ set payoff (payoff + partner-payoff) ]
end

to update-play-prob [ new-payoff ]
  ifelse new-payoff >= 0 [
    set play-prob play-prob + (1 - play-prob) * new-payoff
  ] [
    set play-prob play-prob + play-prob * new-payoff
  ]
end

to update-coop-prob [ new-payoff ]
  ifelse new-payoff >= 0 [
    set strategy-prob strategy-prob + (1 - strategy-prob) * new-payoff
  ] [
    set strategy-prob strategy-prob + strategy-prob * new-payoff
  ]
end

;;---------------- Henrich & Boyd -------------------

;; if agent stays in same neighborhood, try to partner up
to stay-in-neighborhood-with-punishing
  set number-interactions number-interactions + 1
  ;; ------ Stage 0 ------
  ask turtles with [not newcomer?] [
    ;; pick a potential partner
    let potential-partner one-of other turtles-here
    ;; check whether there are partners left
    if potential-partner != nobody [
      ;; link with partner
      create-link-with potential-partner
      ask potential-partner [ set color green ]
      ;; perform interaction
      interact-p0
    ]
  ]
  clear-links
  ;; ------ Stage 1 ------
  ask turtles with [not newcomer? and p1-agent = true] [
    ;; determine defectors
    let defectors turtles-here with [last-action = "defect"]
    ;; pick a potential punishee
    let potential-punishee one-of other defectors
    ;; check whether there are punishee left
    if potential-punishee != nobody [
      ;; link with punishee
      create-link-with potential-punishee
      ask potential-punishee [ set color green ]
      ;; perform punishment
      punish-p1
    ]
  ]
  clear-links
end

;; agent interacts with its partner
to interact-p0
    let partner one-of link-neighbors
    if partner != nobody [
      set number-interactions number-interactions + 1
      if newcomer? = true or [newcomer?] of partner = true [
        set interactions-newcomer interactions-newcomer + 1
      ]

      ;; Determine which strategy the agent and its partner
      ifelse p0-agent = true [
        set last-action "cooperate"
        if (random-float 1.0) < error-rate [
          set last-action "defect"
        ]
      ] [
        set last-action "defect"
      ]

      ifelse [p0-agent] of partner = true [
        ask partner [ set last-action "cooperate" ]
        if (random-float 1.0) < error-rate [
          ask partner [ set last-action "defect" ]
        ]
      ] [
        ask partner [ set last-action "defect" ]
      ]

      if last-action = "cooperate" and [last-action] of partner = "cooperate" [
        set interactions-full-coop interactions-full-coop + 1
        if newcomer? = true or [newcomer?] of partner = true [
          set interactions-full-coop-newcomer interactions-full-coop-newcomer + 1
        ]
      ]

      ;; Calculate payoffs
      let my-payoff group-benefit / (count turtles-here)
      let partner-payoff group-benefit / (count turtles-here)
      if last-action = "cooperate" [ set my-payoff my-payoff - coop-cost ]
      if [last-action] of partner = "cooperate" [ set partner-payoff partner-payoff - coop-cost ]

      ;; Update payoffs
      set payoff payoff + my-payoff
      ask partner [ set payoff payoff + partner-payoff ]
    ]
end

;; agent punishes a defector
to punish-p1
  let punishee one-of link-neighbors
  if punishee != nobody [
    ;; Determine whether the punisher does indeed punish
    set last-action "punish"
    if (random-float 1.0) < error-rate [
      set last-action "not-punish"
    ]

    ;; Update payoffs if punishment happens
    if last-action = "punish" [
      set payoff payoff - punisher-cost
      ask punishee [ set payoff payoff - punishee-cost ]

      set interactions-punish interactions-punish + 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; PAYOFFS ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; calculate the pay-off from an interaction
to-report calculate-payoff [my-choice partner-choice opportunity-cost]
  if my-choice = "cooperate" and partner-choice = "cooperate" [
    ;; both cooperating (R)
    report 0.7 - 0.5 * opportunity-cost
  ]
  if my-choice = "defect" and partner-choice = "defect" [
    ;; both defecting (P)
    report -0.2
  ]
  if my-choice = "cooperate" and partner-choice = "defect" [
    ;; cooperating while partner defects (S)
    report -0.5
  ]
  if my-choice = "defect" and partner-choice = "cooperate" [
    ;; defecting while partner cooperates (T)
    report 1 - 0.5 * opportunity-cost
  ]
end

;; update the agent's payoff value
to update-payoffs [my-payoff]
  set payoff (payoff + my-payoff)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; EXTRAS ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; determine location of the groups (Based on Party model)
to-report neighborhood?  ;; patch procedure
  let middle-x min-pxcor + floor (world-width / 2)
  let top-y max-pycor - floor (world-height / 4)
  let group-interval floor (world-width / number-of-groups)
  report
    ;; groups are located on y-axis 0
    ((pycor = 0) and
    ;; x-coordination is less than 0
    (pxcor <= 0) and
    ;; there is an even interval between groups
    (pxcor mod group-interval = 0) and
    (floor ((- pxcor) / group-interval) < number-of-groups))
end

;; spread agents out vertically (Based on Party code)
to spread-out-vertically  ;; turtle procedure
  set heading 180
  fd 4                   ;; leave a gap
  while [any? other turtles-here] [
    if-else can-move? 2 [
      fd 1
    ]
    [ ;; else, if we reached the edge of the screen
      set xcor xcor - 1  ;; take a step to the left
      set ycor 0         ;; and move to the base a new stack
      fd 4
    ]
  ]
end

;; update group number based on agents in the group (Based on Party model)
to update-labels
  ask neighborhoods [ set plabel count turtles-here ]
end

;; reset the color of potential partners to default agent color
to reset-color
  ifelse (ethnicity = "American") [ set color red ] [ set color blue]
end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
430
10
798
507
-1
-1
4.4
1
14
1
1
1
0
1
0
1
-80
1
-55
55
1
1
1
ticks
30.0

BUTTON
65
50
133
83
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
216
50
284
83
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
134
50
215
83
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
10
10
161
43
number-of-people
number-of-people
100
1000
100.0
50
1
NIL
HORIZONTAL

SLIDER
175
10
326
43
number-of-groups
number-of-groups
5
20
5.0
1
1
NIL
HORIZONTAL

CHOOSER
10
90
148
135
ethnicity
ethnicity
"American" "Japanese"
0

PLOT
10
145
210
295
interactions vs exits
ticks
exit ratio
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot interactions-exit / number-interactions"

PLOT
10
305
210
455
interactions vs full cooperation
ticks
full coop ratio
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot interactions-full-coop / number-interactions"

MONITOR
810
180
902
225
avg play prob
mean [play-prob] of turtles
5
1
11

MONITOR
1010
180
1107
225
avg strat. prob
mean [strategy-prob] of turtles
5
1
11

MONITOR
1010
25
1142
70
nr. of exit interactions
interactions-exit
17
1
11

MONITOR
1010
75
1160
120
nr. of full coop interactions
interactions-full-coop
17
1
11

CHOOSER
165
90
303
135
model
model
"Macy/Sato" "Henrich/Boyd"
0

MONITOR
810
300
922
345
p-variants stage 0
count turtles with [p0-agent = true]
17
1
11

MONITOR
990
300
1102
345
p-variants stage 1
count turtles with [p1-agent = true]
17
1
11

PLOT
225
305
425
455
newcomer interact. vs full coop
ticks
full coop ratio
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot interactions-full-coop-newcomer / interactions-newcomer"

MONITOR
810
125
1042
170
nr. of full coop interactions (newcomer)
interactions-full-coop-newcomer
0
1
11

MONITOR
810
25
932
70
nr. of interactions
number-interactions
0
1
11

MONITOR
810
75
992
120
nr. of interactions (newcomer)
interactions-newcomer
0
1
11

PLOT
215
150
415
300
average payoff over time
ticks
avg. payoff
0.0
10.0
-2.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot avg-payoff"

MONITOR
810
355
962
400
nr. of punish interactions
interactions-punish
0
1
11

@#$#@#$#@
## WHAT IS IT?

## HOW IT WORKS

## HOW TO USE IT

## THINGS TO NOTICE

## THINGS TO TRY

## EXTENDING THE MODEL

## NETLOGO FEATURES

## RELATED MODELS

## CREDITS AND REFERENCES

## HOW TO CITE
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
setup
repeat 20 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
