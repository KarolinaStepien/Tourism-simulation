turtles-own[
  goal
  budget
  time
  to-visit
  waiter
  in-hurry
  hotel
]

patches-own[

  popularity
  price
  visitors
  curent-visitors
  max-visitors
  visit-time

]

globals[buildings sums clock]

to setup
  set clock 9
  clear-all
  reset-ticks
  set buildings(list)
  set sums(list)
  import-drawing "mapa.png"
  ask patches[
    set pcolor green
    set popularity 1
    set price 0
    set visitors 0
  ]
  create-buildings
  create-people walker-count false
end

to create-buildings
  ; obliczenie ticków potrzebnych na zwiedzenie z proporcji: 50 ticków to około 20 minut czasu realnego
  ask patch(23)(59)[become-building 10 50 200] ;Okno papieski - 20 min 0 zł
  ask patch(27)(103)[become-building 5 25 200] ;Plac Szczepański - 10 min 0zł
  ask patch(90)(105)[become-building 30 300 50] ;Teatr słowackiego - 2godz 30zł
  ask patch(12)(24)[become-building 5 70 200]  ;Bulwary wislane - 28min 0zł
  ask patch(51)(111)[become-building 15 150 100] ;Czartoryscy - 1godz 15zł
  ask patch(97)(47)[become-building 10 150 40] ;Lodowisko - 1godz 10zł
  ask patch(82)(14)[become-building 30 150 10] ;Escape room - 1godz 20zł
  ask patch(19)(81)[become-building 10 20 200] ;UJ - 8min 0zł
  ask patch(6)(101)[become-building 25 150 50]  ;Teatr Bagatela - 1godz 25zł
  ask patch(44)(52)[become-building 10 50 200] ;Plac Wszystkich Świętych - 20min 0zł
  ask patch(48)(18)[become-building 18 225 200] ;Wawel - 90 min 18 zł
  ask patch(64)(118)[become-building 15 50 200] ;Barbakan - 20 min 8 zł
  ask patch(50)(88)[become-building 10 75 200] ;Mariacki - 30 min 10 zł
  ask patch(39)(73)[become-building 100 150 30] ;Wierzynek - 60 min 100 zł
  ask patch(34)(82)[become-building 19 450 200]  ;Sukiennice muzeum - 180 min 19 zł
  set buildings sublist buildings 0 building-count
end

to create-people [counter from-hotel]
  create-turtles counter[
    if not from-hotel [
      set xcor random-xcor
      set ycor random-ycor
    ]
    if from-hotel[
      set xcor one-of [100 0]
      set ycor random-ycor
    ]
    set goal one-of patches
    set color black
    set size 3
    set budget random 500
    set time 300 + random 1200           ;Mają minimum dwie godzinki, maks 10
    set shape "person"
    set to-visit buildings
    set waiter 0
    set hotel one-of patches with[ pxcor = 100 or pycor = 130 ]
    ifelse time > 600[
      set in-hurry false
    ]
    [
      set in-hurry true
    ]
  ]
end

to go       ; co się dzieje w pętli co tick
  ; zaczynamy od 9

  move-walkers
  if ticks mod 37 = 0 and ticks < 2700[
    create-people 10 true
  ]

  if ticks = 1050 or ticks = 1800 [
    create-people 50 true
  ]
  decay-popularity
  if not any? turtles or ticks = 24 * 150 [
     stop
  ]
  if ticks mod 75 = 0 [
    set clock clock + 0.5
    if clock = 15[
      set clock -9
    ]
  ]
  tick
end

to become-building [ entry-price v-time max-vis ]      ; konstruktor budynku
  set pcolor red
  set buildings(fput self buildings)
  set price entry-price
  set max-visitors max-vis
  set visit-time v-time
end

to decay-popularity       ; z czasem popoularność patchy się zmniejsza
  ask patches with[pcolor != red][
    if popularity > 1 and not any? turtles-here[set popularity popularity * (100 - 0.7)/ 100]
    ifelse pcolor = green[
      if popularity < 1[
        set popularity 1
      ]
    ]
    [
      if popularity < 1[
        set popularity 1
        set pcolor green
      ]
    ]
  ]
end


to become-more-popular
  set popularity popularity + popularity-per-step
  if popularity > minimum-route-popularity[
    set pcolor gray
  ]
end


to move-walkers     ; funkcja, która minusuje energie i ogarnia kolejne cele
  ask turtles[
    set time time - 1
    if patch-here = hotel[
      die
    ]

    ifelse time < 0 or length to-visit = 0[
      ifelse length to-visit = 0[
        set to-visit (fput hotel to-visit)
      ]
      [
        set goal hotel
        walk-towards-goal
      ]
    ]
    [
      ifelse patch-here = goal[
        let turtles-number count turtles-here
        ifelse max-visitors >= turtles-number[
          set to-visit remove patch-here to-visit
          ifelse budget >= price and (visit-time < 150 or (visit-time >= 150 and not in-hurry))[
            ifelse waiter >= visit-time[
              set budget budget - price
              if length to-visit = 0 [
                set to-visit (fput hotel to-visit)
              ]
              set goal one-of to-visit
              ask patch-here[set visitors visitors + 1]
              set waiter 0
              walk-towards-goal
            ]
            [
              set waiter waiter + 1
            ]
          ]
          [
            if length to-visit > 0[
            set goal one-of to-visit
            ]
            walk-towards-goal
          ]
        ]
        [
          if length to-visit > 0[
            set goal one-of to-visit
          ]
          walk-towards-goal
        ]
      ]
      [
        walk-towards-goal
      ]
    ]
  ]
end



to walk-towards-goal         ; funkcja, która kieruje zółwika w dobrą stronę i dodaje popularność do patcha, na który pójdzie, a potem jeśli są w zasięgu szare to idź na najlepszy jak nie to idx w kierunku goal
  let last-distance distance goal
  let best-route-tile route-on-the-way-to goal last-distance
  if pcolor = green[
    ask patch-here[become-more-popular]
  ]
  ifelse best-route-tile = nobody[
    face goal
  ]
  [
    face best-route-tile
  ]
  fd 1
end

to-report route-on-the-way-to[l current-distance]      ; funkcja zwracająca najbliższy punkt, który jest popularny, który ma mniejszy dystans do celu niż my obecnie i który jest w zasięgu wzroku.
  let routes-on-the-way-to-goal(patches in-radius walker-vision-dist with[
      pcolor = gray and distance l < current-distance
    ])
  report min-one-of routes-on-the-way-to-goal[distance self]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
622
563
-1
-1
4.0
1
10
1
1
1
0
1
1
1
0
100
0
135
1
1
1
ticks
60.0

BUTTON
106
148
179
181
NIL
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
105
210
168
243
NIL
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

SLIDER
1088
189
1282
222
popularity-per-step
popularity-per-step
0
20
9.0
1
1
NIL
HORIZONTAL

SLIDER
1086
121
1319
154
minimum-route-popularity
minimum-route-popularity
0
80
29.0
1
1
NIL
HORIZONTAL

SLIDER
1094
256
1266
289
walker-count
walker-count
0
200
102.0
1
1
NIL
HORIZONTAL

SLIDER
1091
354
1270
387
walker-vision-dist
walker-vision-dist
0
10
1.0
1
1
NIL
HORIZONTAL

MONITOR
711
68
873
113
Sukiennice visitors
[visitors] of patches at-points [[34 82]]
17
1
11

MONITOR
707
168
868
213
Mariacki church visitors
[visitors] of patches at-points [[50 88]]
17
1
11

MONITOR
706
222
867
267
Barbakan visitors
[visitors] of patches at-points [[64 118]]
17
1
11

MONITOR
709
118
873
163
Wierzynek
[visitors] of patches at-points [[39 73]]
17
1
11

MONITOR
883
172
973
217
Mariacki Price
[price] of patches at-points [[50 88]]
17
1
11

MONITOR
882
115
972
160
Wierzynek Price
[price] of patches at-points [[39 73]]
17
1
11

MONITOR
882
68
971
113
Barbakan Price
[price] of patches at-points [[34 82]]
17
1
11

MONITOR
884
222
973
267
Barbakan price
[price] of patches at-points [[64 118]]
17
1
11

SLIDER
1056
511
1228
544
building-count
building-count
0
15
6.0
1
1
NIL
HORIZONTAL

MONITOR
768
10
960
55
Krakow Income
sum([visitors * price] of patches at-points [[23 59] [27 103] [90 105] [12 24] [51 111] [97 47] [82 14] [19 81] [6 101] [ 44 52] [48 18] [64 118] [50 88] [39 73] [34 82]])
17
1
11

MONITOR
705
273
867
318
Wawel
[visitors] of patches at-points [[48 18]]
17
1
11

MONITOR
883
273
973
318
Wawel price
[price] of patches at-points [[48 18]]
17
1
11

MONITOR
884
326
974
371
All saint's square price
[price] of patches at-points [[ 44 52]]
17
1
11

MONITOR
708
323
867
368
All saints sq
[visitors] of patches at-points [[ 44 52]]
17
1
11

MONITOR
708
373
867
418
Bagatela Theater
[visitors] of patches at-points [[6 101]]
17
1
11

MONITOR
882
374
974
419
Bagatela price
[price] of patches at-points [[6 101]]
17
1
11

MONITOR
709
422
868
467
Jagiellonian University
[visitors] of patches at-points [[19 81]]
17
1
11

MONITOR
882
421
975
466
University price
[price] of patches at-points [[19 81]]
17
1
11

MONITOR
710
471
868
516
Escape room
[visitors] of patches at-points [[82 14]]
17
1
11

MONITOR
881
472
976
517
Escape room price
[price] of patches at-points [[82 14]]
17
1
11

MONITOR
882
520
976
565
Ice ring price
[price] of patches at-points [[97 47]]
17
1
11

MONITOR
711
520
869
565
Ice ring
[visitors] of patches at-points [[97 47]]
17
1
11

MONITOR
710
569
867
614
Czartoryscy museum
[visitors] of patches at-points [[51 111]]
17
1
11

MONITOR
882
569
977
614
Czartoryscy price
[price] of patches at-points [[51 111]]
17
1
11

MONITOR
710
618
867
663
Boulevards
[visitors] of patches at-points [[12 24]]
17
1
11

MONITOR
881
618
978
663
Boulvards price
[price] of patches at-points [[12 24]]
17
1
11

MONITOR
711
667
867
712
Słowacki theatre
[visitors] of patches at-points  [[90 105]]
17
1
11

MONITOR
882
667
978
712
Słowacki price
[price] of patches at-points  [[90 105]]
17
1
11

MONITOR
712
716
866
761
Szczepanski sq
[visitors] of patches at-points [[27 103]]
17
1
11

MONITOR
883
717
979
762
Szczepański price
[price] of patches at-points [[27 103]]
17
1
11

MONITOR
713
766
866
811
Pope's window
[visitors] of patches at-points [[23 59]]
17
1
11

MONITOR
882
767
980
812
Pope's window
[price] of patches at-points [[23 59]]
17
1
11

MONITOR
1081
32
1138
77
Time
clock + 9
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
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
0
@#$#@#$#@
