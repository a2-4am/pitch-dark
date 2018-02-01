 0  IF  PEEK (104) = 8 THEN  POKE 104,96: POKE 24576,0: PRINT  CHR$ (4)"RUN MM4"
 1  GOSUB 990: REM  initialize weegui
 2  READ L: DIM DESC$(L): FOR I = 1 TO L: READ DESC$(I): NEXT I: REM  box blurb
 10  &  HOME 
 18  & WINDW(0,0,0,0,79,1,79,1): & SEL(0): & CURSR(0,0)
 19  INVERSE : &  PRINT ("Pitch Dark                                                                      "): NORMAL 
 20  GOSUB 1000: & BUTTN(14,1,2,12,800,B$): & STRW(1): REM  Previous
 25  GOSUB 1000: & BUTTN(15,65,2,13,900,B$): & STRW(1): REM   Next game
 40  GOSUB 1000: & BUTTN(1,34,10,13,200,B$): & STRW(1): REM  Play game
 41  GOSUB 1000: & BUTTN(2,66,7,11,300,B$): & STRW(1): REM  Clues
 42  GOSUB 1000: & BUTTN(3,66,9,11,400,B$): & STRW(1): REM  Box art
 43  GOSUB 1000: & BUTTN(4,66,11,11,500,B$): & STRW(1): REM  Options
 49  & WINDW(12,0,31,2,18,7,18,7)
 50  & CURSR(0,0): &  PRINT ("ZORK I: THE GREAT")
 51  & CURSR(0,1): &  PRINT ("UNDERGROUND EMPIRE")
 52  & CURSR(0,3): &  PRINT ("1980       Fantasy")
 53  & CURSR(0,5): &  PRINT ("Difficulty:  ")
 54  &  PRINT (64): &  PRINT (64): &  PRINT (64): &  PRINT (65): &  PRINT (65)
 90  & WINDW(13,2,1,15,77,8,77,17)
 93  & STACT(700)
 94  GOSUB 700
 99  & MOUSE(1)
 100  REM  run loop
 101  & PDACT
 102  &  GET (A%)
 103  IF A% = 10 THEN  & SEL(13): & SCRBY(0, - 1): GOSUB 700
 104  IF A% = 11 THEN  & SEL(13): & SCRBY(0,1): GOSUB 700
 105  IF A% = 9 THEN  & FOCN
 106  IF A% = 27 THEN 995
 107  IF A% = 13 THEN  & ACT
 109 B =  - 1
 111  IF A% = 80 OR A% = 112 THEN B = 1
 113  IF A% = 66 OR A% = 98 THEN B = 3
 125  IF A% = 78 OR A% = 110 THEN B = 15
 195  IF B < 0 THEN 100
 196  & SEL(B)
 197  & FOC
 198  & ACT
 199  GOTO 100
 200  REM  play
 205  GOSUB 997
 210  PRINT  CHR$ (4)"BLOAD INTERPP.SYSTEM,A$2000,TSYS"
 220 F$ = "ZORK1.Z3": POKE 8198, LEN (F$): FOR I = 1 TO  LEN (F$): POKE 8198 + I, ASC ( MID$ (F$,I,1)): NEXT I
 230  CALL 8192: REM  never returns
 300  REM  clues
 399  RETURN 
 400  REM  box art
 420  GOSUB 997
 430  PRINT  CHR$ (4)"BRUN ZORK1.PIC"
 440  RUN 
 500  REM  options
 700  REM  redraw box blurb
 701  & SEL(13)
 705  NORMAL 
 706  & ERASE(0)
 710  FOR I = 1 TO L: & CURSR(1,I): &  PRINT (DESC$(I)): NEXT I
 799  RETURN 
 800  REM  previous button
 899  RETURN 
 900  REM  next button
 910  GOSUB 997
 920  PRINT  CHR$ (4)"chain mm.zork.ii"
 930  RUN 
 990  REM  initialize and return
 991  PRINT  CHR$ (4)"BRUN WEEGUI"
 992  RETURN 
 995  REM  clean up and exit
 996  GOSUB 997: END 
 997  REM  clean up and return
 998  & MOUSE(0): & EXIT
 999  RETURN 
 1000  REM  build button title
 1010 B$ = "": READ L: FOR I = 1 TO L: READ C:B$ = B$ +  CHR$ (C): NEXT I
 1020  RETURN 
 9999  DATA  15
 10000  DATA  "Welcome to ZORK! You are about to experience a classic interactive fantasy,"
 10001  DATA  "set in a magical universe. The ZORK trilogy takes place in the ruins of an"
 10002  DATA  "ancient empire lying far underground. You, a dauntless treasure-hunter, are"
 10003  DATA  "venturing into this dangerous land in search of wealth and adventure."
 10004  DATA  "Because each part of the ZORK saga is a completely independent story, you"
 10005  DATA  "can explore them in any order. However, since ZORK I is the least difficult,"
 10006  DATA  "it is usually the best place to begin."
 10007  DATA  ""
 10008  DATA  "Many strange tales have been told of the fabulous treasures, exotic"
 10009  DATA  "creatures and diabolical puzzles in the Great Underground Empire. As an"
 10010  DATA  "aspiring adventurer you will undoubtedly want to locate the treasures and"
 10011  DATA  "deposit them in your trophy case. You'd better equip yourself with a source"
 10012  DATA  "of light (for the caverns are dark) and weapons (for some of the inhabitants"
 10013  DATA  "are unfriendly -- especially the thief, a skilled pickpocket and ruthless"
 10014  DATA  "opponent)."
 19000  REM   button titles (length byte + high ASCII characters) 
 19001  DATA    10,188,160,208,242,229,118,233,239,245,243 : REM    "< Previous" with inverse "v"
 19002  DATA  11, 14,229,248,244,160,231,225,237,229,160,190: REM  "Next game >" with inverse "N"
 19003  DATA  9,16,236,225,249,160,231,225,237,229: REM  "Play game" with inverse "P"
 19004  DATA  5,3,236,245,229,243: REM  "Clues" with inverse "C"
 19005  DATA  7,2,239,248,160,225,242,244: REM  "Box art" with inverse "B"
 19006  DATA  7,15,240,244,233,239,238,243: REM  "Options" with inverse "O"
