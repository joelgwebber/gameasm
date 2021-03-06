processor 6502

;Default 2600 Constants set up by dissasembler..
VSYNC   =  $00
VBLANK  =  $01
WSYNC   =  $02
RSYNC   =  $03
NUSIZ0  =  $04
NUSIZ1  =  $05
COLUP0  =  $06
COLUP1  =  $07
COLUPF  =  $08
COLUBK  =  $09
CTRLPF  =  $0A
PF0     =  $0D
PF1     =  $0E
PF2     =  $0F
RESP0   =  $10
AUDC0   =  $15
AUDF0   =  $17
AUDV0   =  $19
AUDV1   =  $1A
GRP0    =  $1B
GRP1    =  $1C
ENAM0   =  $1D
ENAM1   =  $1E
ENABL   =  $1F
HMP0    =  $20
VDEL01  =  $26
HMOVE   =  $2A
HMCLR   =  $2B
CXCLR   =  $2C
CXP0FB  =  $32
CXP1FB  =  $33
CXM0FB  =  $34
CXM1FB  =  $35
CXBLPF  =  $36
CXPPMM  =  $37
INPT4   =  $3C
SWCHA   =  $0280
SWCHB   =  $0282
INTIM   =  $0284
TIM64T  =  $0296

       ORG $F000

START:
       JMP    StartGame           ;Jump To Start Game

;Alternate Start
      .byte $78,$D8,$4C,$06,$F3  ;Setup for 6507, Start with no Variable Initialisation.

;Print Display
PrintDisplay:
       STA    HMCLR               ;Clear horzontal motion.
       LDA    $86                 ;Position Player00 Sprite To
       LDX    #$00                ;      the X Coordinate of Object1.
       JSR    PosSpriteX

       LDA    $88                 ;Position Player01 Sprite to
       LDX    #$01                ;      the X Coordinate of Object2.
       JSR    PosSpriteX

       LDA    $8B                 ;Position Ball Strite to
       LDX    #$04                ;      the X Coordinate of the Man.
       JSR    PosSpriteX

       STA    WSYNC               ;Wait for horizontal Blank.
       STA    HMOVE               ;Apply Horizontal Motion.
       STA    CXCLR               ;Clear Collision Latches.

       LDA    $8C                 ;Get the Y Coordinate of the Man.
       SEC
       SBC    #$04                ;And Adjust it (By Four Scan Lines)
       STA    $8D                 ;      for printing (so Y Coordinate Specifies Middle)

PrintDisplay_1:
	 LDA    INTIM               ;Wait for end of the
       BNE    PrintDisplay_1      ;      current fame.

       LDA    #$00
       STA    $90                 ;Set Player00 definition index.
       STA    $91                 ;Set Player01 definition index.
       STA    $8F                 ;Set room definition index.
       STA    GRP1                ;Clear any graphics for Player01.
       LDA    #$01
       STA    VDEL01              ;vertically delay Player 01
       LDA    #$68
       STA    $8E                 ;Set Scan Lind Count.

;Print top line of Room.
       LDY    $8F                 ;Get room definition index.
       LDA    ($80),Y             ;Get first room definition byte.
       STA    PF0                 ;      and display.
       INY
       LDA    ($80),Y             ;Get Next room definition byte.
       STA    PF1                 ;      and display.
       INY
       LDA    ($80),Y             ;Get Last room defintion byte.
       STA    PF2                 ;      and display.
       INY
       STY    $8F                 ;Save for Next Time.

       STA    WSYNC               ;Wait for Horizontal Blank.
       LDA    #$00
       STA    VBLANK              ;Clear any Vertical Blank.
       JMP    PrintPlayer00


;Print Player01 (Object 02)
PrintPlayer01:
       LDA    $8E                 ;Get Current Scan Line.
       SEC                        ;Have we reached Object2's
       SBC    $89                 ;      Y Coordinate?
       STA    WSYNC               ;      Wait for Horzonal Blank.
       BPL    PrintPlayer00       ;If Not, Branch.

       LDY    $91                 ;Get the Player01 definition index.
       LDA    ($84),Y             ;Get the Next Player01 Definition byte
       STA    GRP1                ;      and display.
       BEQ    PrintPlayer00       ;If Zero then Definition finished.

       INC    $91                 ;Goto next Player01 definition byte.

;Print Player00 (Object01), Ball (Man) and Room.
PrintPlayer00:
	 LDX    #$00
       LDA    $8E                 ;Get the Current Scan Line.
       SEC                        ;Have we reached the Object1's
       SBC    $87                 ;      Y coordinate?
       BPL    PrintPlayer00_1     ;If not then Branch.

       LDY    $90                 ;Get Player00 definition index.
       LDA    ($82),Y             ;Get the Next Player00 definition byte.
       TAX
       BEQ    PrintPlayer00_1     ;If Zero then Definition finished.

       INC    $90                 ;Go to Next Player00 definition byte.

PrintPlayer00_1:
	 LDY    #$00                ;Disable Ball Graphic.
       LDA    $8E                 ;Get Scan line count.
       SEC                        ;Have we reached the Man's
       SBC    $8D                 ;      Y Coordinate?
       AND    #$FC                ;Mask value to four either side (getting depth of 8)
       BNE    PrintPlayer00_2     ;If Not, Branch.

       LDY    #$02                ;Enable Ball Graphic.

PrintPlayer00_2:
       LDA    $8E                 ;Get Scan Line Count.
       AND    #$0F                ;Have we reached a sixteenth scan line.
       BNE    PrintPlayer00_4     ;If not, Branch.

       STA    WSYNC               ;Wait for Horzontal Blank.
       STY    ENABL               ;Enable Ball (If Wanted)
       STX    GRP0                ;Display Player 00 definition byte (if wanted)

       LDY    $8F                 ;Get room definition index.
       LDA    ($80),Y             ;Get first room definition byte,
       STA    PF0                 ;      and display.
       INY
       LDA    ($80),Y             ;Get next room definition byte,
       STA    PF1                 ;      and display.
       INY
       LDA    ($80),Y             ;Get next room definition byte,
       STA    PF2                 ;      and display.
       INY
       STY    $8F                 ;Save for Next Time.

PrintPlayer00_3:
       DEC    $8E                 ;Goto next scan line.
       LDA    $8E                 ;Get the scan line.
       CMP    #$08                ;Have we reached to within 8 scanlines of the bottom?
       BPL    PrintPlayer01       ;If not, Branch.

       STA    VBLANK              ;Turn on VBLANK
       JMP    TidyUp

;Print Player00 (Object 01) and Ball (Man)
PrintPlayer00_4:
       STA    WSYNC               ;Wait for Horzontal blank.
       STY    ENABL               ;Enable Ball (If Wanted.)
       STX    GRP0                ;Display Player00 definition byte (if Wanted).
       JMP    PrintPlayer00_3

;Tidy Up
TidyUp:
       LDA    #$00
       STA    GRP1                ;Clear any graphics for Player01
       STA    GRP0                ;Clear any graphics for Player00
       LDA    #$20
       STA    TIM64T              ;Stat Timing this frame using
       RTS                        ;      the 64 bit counter.


;Position Sprite X horizontally.
PosSpriteX:
       LDY    #$02                ;Start with 10 clock cycles (to avoid HBLANK)
       SEC                        ;Divide the Coordinate.
PosSpriteX_1:
       INY                        ;      Wanted by Fifteen I.E.
       SBC    #$0F                ;      Get Course Horizontal
       BCS    PosSpriteX_1        ;      Value (In Multiples of 5 Clock Cycles
                                  ;      (Therefore giving 15 Color Cycles)
       EOR    #$FF                ;Flip remanter to positive value (inverted).
       SBC    #$06                ;Convert to left or right of current position.
       ASL
       ASL                        ;Move to high nybble for TIA
       ASL                        ;      horizontal motion.
       ASL
       STY    WSYNC               ;Wait for horozontal blank.

PosSpriteX_2:
       DEY                        ;Count down the color
       BPL    PosSpriteX_2        ;      cycles (these are 5 machine/15 color cycles).

       STA    RESP0,X             ;Reset the sprite, thus positioning it coursely.
       STA    HMP0,X              ;Set horizontal (fine) motion of sprite.
       RTS


;Preform VSYNC
DoVSYNC:
       LDA    INTIM               ;Get Timer Output
       BNE    DoVSYNC             ;Wait for Time-Out
       LDA    #$02
       STA    WSYNC               ;Wait for horizonal blank.
       STA    VBLANK              ;Start Vertical Blanking.
       STA    WSYNC               ;Wait for horizonal blank.
       STA    WSYNC               ;Wait for horizonal blank.
       STA    WSYNC               ;Wait for horizonal blank.
       STA    VSYNC               ;Start verticle sync.
       STA    WSYNC               ;Wait for horizonal blank.
       STA    WSYNC               ;Wait for horizonal blank.
       LDA    #$00
       STA    WSYNC               ;Wait for horizonal blank.
       STA    VSYNC               ;End Vertical sync.
       LDA    #$2A                ;Set clock interval to
       STA    TIM64T              ;Countdown next frame.
       RTS

;Setup a room for print.
SetupRoomPrint:
       LDA    $8A                 ;Get current room number.
       JSR    RoomNumToAddress    ;Convert it to an address.
       LDY    #$00
       LDA    ($93),Y             ;Get low pointer to room
       STA    $80                 ;      Graphics
       LDY    #$01
       LDA    ($93),Y             ;Get high pointer to room
       STA    $81                 ;      Graphics

;Check B&W Switch for foom graphics.
       LDA    SWCHB               ;Get console switches.
       AND    #$08                ;Check black and white switch
       BEQ    UseBW               ;Branch if B&W.

;Use Color
       LDY    #$02
       LDA    ($93),Y             ;Get room color
       JSR    ChangeColor         ;Change if necessary
       STA    COLUPF              ;Put in Playfiled color register.
       JMP    UseColor

;Use B&W
UseBW:
       LDY    #$03
       LDA    ($93),Y             ;Get B&W Color
       JSR    ChangeColor         ;Change if necessary
       STA    COLUPF              ;Put in the Playfield color register.

;Color Background.
UseColor:
       LDA    #$08                ;Get light grey background
       JSR    ChangeColor         ;Change if necessary
       STA    COLUBK              ;Put it in the Background color register.

;Playfield Control.
       LDY    #$04
       LDA    ($93),Y             ;Get the playfield control value.
       STA    CTRLPF              ;And put in the playfield control register.
       AND    #$C0                ;Get the "this wall" flag.
       LSR
       LSR
       LSR                        ;Get the first bit into position.
       LSR
       LSR
       STA    ENAM1               ;Enable right hand thin wall. (if wanted - missile01)
       LSR
       STA    ENAM0               ;Enable left hand thin wall (if wanted - missle00)

;Get objects to display.
       JSR    CacheObjects        ;Get next two objects to display.

;Sort out their order.
       LDA    $95                 ;If the object1 is the
       CMP    #$00                ;Invisible surround
       BEQ    SwapPrintObjects    ;Then branch to swap (we want it as player01)

       CMP    #$5A                ;If the first object is the bridge then
       BNE    SetupObjectPrint    ;Swap the objects (we want it as player01)

       LDA    $96                 ;If the object2 is the
       CMP    #$00                ;Invisble surround then branch to leave
       BEQ    SetupObjectPrint    ;it (we want it as player01)

SwapPrintObjects:
       LDA    $95
       STA    $D8
       LDA    $96
       STA    $95                 ;Swap the objects to print.
       LDA    $D8
       STA    $96

;Setup Object1 to print.
SetupObjectPrint:
       LDX    $95                 ;Get Object1
       LDA    Store1,X             ;Get low pointer to it's dynamic information.
       STA    $93
       LDA    Store2,X             ;Get high pointer to it's dynamic informtion.
       STA    $94

       LDY    #$01
       LDA    ($93),Y             ;Get Object1's X coordinate
       STA    $86                 ;and Store for print.
       LDY    #$02
       LDA    ($93),Y             ;Get Object1's Y coordinate
       STA    $87                 ;and Store for print.

       LDA    Store3,X             ;Get low pointer to state value.
       STA    $93
       LDA    Store4,X             ;Get high pointer to state value.
       STA    $94
       LDY    #$00
       LDA    ($93),Y             ;Retrieve Object1's current state.
       STA    $DC

       LDA    Store5,X             ;Get low pointer to state information.
       STA    $93
       LDA    Store6,X             ;Get high pointer to state information.
       STA    $94
       JSR    GetObjectState      ;Find current state in the state information.

       INY                        ;Index to the state's corresponding graphic pointer.
       LDA    ($93),Y             ;Get Object1's low graphic address
       STA    $82                 ;and store for print.
       INY
       LDA    ($93),Y             ;Get Object1's high graphic address
       STA    $83                 ;and store for print.

;Check B&W for object01
       LDA    SWCHB               ;Get console switches
       AND    #$08                ;Check B&W switches.
       BEQ    MakeObjectBW        ;Branch if B&W.

;Colour
       LDA    Store7,X             ;Get Object1's Color.
       JSR    ChangeColor         ;Change if necessary.
       STA    COLUP0              ;And set color luminance00.
       JMP    ResizeObject

;B&W
MakeObjectBW:
       LDA    Store8,X             ;Get Object's B&W Color.
       JSR    ChangeColor         ;Change if necessary.
       STA    COLUP0              ;Set color luminance00.

;Object1 Size
ResizeObject:
       LDA    Store9,X             ;Get Object1's Size
       ORA    #$10                ;And set to larger size if necessary.
       STA    NUSIZ0              ;(Used by bridge and invisible surround)

;Setup Object 2 to Print.
       LDX    $96                 ;Get Object 2
       LDA    Store1,X
       STA    $93                 ;Get low pointer to it's dynamic information.
       LDA    Store2,X
       STA    $94                 ;Get high pointer to it's dynamic information.
       LDY    #$01
       LDA    ($93),Y             ;Get Object2's X coordinate
       STA    $88                 ;and store for print.
       LDY    #$02
       LDA    ($93),Y             ;Get Object2's Y coordinate
       STA    $89                 ;and store for print.
       LDA    Store3,X             ;Get low pointer to state value.
       STA    $93
       LDA    Store4,X             ;Get high pointer to state value.
       STA    $94


       LDY    #$00
       LDA    ($93),Y             ;Retrieve Object2's current state.
       STA    $DC
       LDA    Store5,X             ;Get low pointer to state information.
       STA    $93
       LDA    Store6,X             ;Get high pointer to state information.
       STA    $94
       JSR    GetObjectState      ;Find the current state in the state information.

       INY                        ;Index to the state's corresponding graphic pointer.
       LDA    ($93),Y
       STA    $84                 ;Get Object2's low graphic address.
       INY
       LDA    ($93),Y             ;Get Object2's high graphic address.
       STA    $85

;Check B&W for Object2
       LDA    SWCHB               ;Get Console Switches
       AND    #$08                ;Check B&W Switch.
       BEQ    MakeObject2BW       ;If B&W then Branch.

;Color
       LDA    Store7,X             ;Get Object2;s Color
       JSR    ChangeColor         ;Change if Necessary.
       STA    COLUP1              ;and set color luminance01.
       JMP    ResizeObject2

;B&W
MakeObject2BW:
       LDA    Store8,X             ;Get Object's B&W Color.
       JSR    ChangeColor         ;Change if Necessary.
       STA    COLUP1              ;and set color luminance01.

;Object2 Size
ResizeObject2:
       LDA    Store9,X             ;Get Object2's Size
       ORA    #$10                ;And set to larger size if necessary.
       STA    NUSIZ1              ;(Used by bridge and invisible surround)
       RTS

;Fill cache with two objects in this room.
CacheObjects:
       LDY    $9C                 ;Get Last Object
       LDA    #$A2                ;Set cache to
       STA    $95                 ;      no-ojects.
       STA    $96
MoveNextObject:
       TYA
       CLC                        ;Goto the next object to
       ADC    #$09                ;check (add nine).
       CMP    #$A2                ;Check if over maximum.
       BCC    GetObjectsInfo
       LDA    #$00                ;If so, wrap to zero.
GetObjectsInfo:
       TAY
       LDA    Store1,Y             ;Get low byte of object info.
       STA    $93
       LDA    Store2,Y             ;Get high byte of object info.
       STA    $94
       LDX    #$00
       LDA    ($93,X)             ;Get objects current room.
       CMP    $8A                 ;Is it in this room?
       BNE    CheckForMoreObjects ;If not lets try next object (branch)

       LDA    $95                 ;Check first slot.
       CMP    #$A2                ;If not default (no-object)
       BNE    StoreObjectToPrint  ;then branch.

       STY    $95                 ;Store this object's number to print
       JMP    CheckForMoreObjects ;      and try for more.

StoreObjectToPrint:
       STY    $96                 ;Store this object's number to print.
       JMP    StoreCount          ;      and then give up - no slots free.

CheckForMoreObjects:
       CPY    $9C                 ;Have we done all the objets?
       BNE    MoveNextObject      ;If not, continue.

StoreCount:
       STY    $9C                 ;If so, store current count
       RTS                        ;      for next time.

;Convert room number to address.
RoomNumToAddress:
       STA    $D8                 ;Strore room number wanted.
       STA    $93
       LDA    #$00                ;Zero the high byte of the
       STA    $94                 ;      offset.
       CLC
       ROL    $93
       ROL    $94                 ;Multiply room number by eight.
       ROL    $93
       ROL    $94
       ROL    $93
       ROL    $94

       LDA    $D8                 ;Get the original room number.
       CLC
       ADC    $93
       STA    $93                 ;And add it to the offset.
       LDA    #$00
       ADC    $94                 ;In effect the room number is
       STA    $94                 ;      multiplied by nine.

       LDA    #<RoomDataTable
       CLC
       ADC    $93                 ;Add the room data base address
       STA    $93                 ;to the offset therefore getting
       LDA    #>RoomDataTable     ;      the final room data address.
       ADC    $94
       STA    $94
       RTS

;Get pointer to current state.
GetObjectState:
       LDY    #$00
       LDA    $DC                 ;Get the current object state.
GetObjectState_1:
       CMP    ($93),Y             ;Have we found it in the list of states.
       BCC    GetObjectState_2    ;If nearing it then found it and return
       BEQ    GetObjectState_2    ;If found it then return.

       INY
       INY                        ;Goto next state in list of states.
       INY
       JMP    GetObjectState_1
GetObjectState_2:
       RTS

;Check for input.
CheckInput:
	 INC    $E5                 ;Increment low count.
       BNE    GetJoystick

       INC    $E6                 ;Increment hight count if
       BNE    GetJoystick         ;      needed.

       LDA    #$80                ;Wrap the high count (indicating
       STA    $E6                 ;      timeout) if needed.

GetJoystick:
	 LDA    SWCHA               ;Get joystick values.
       CMP    #$FF                ;If any movement then branch.
       BNE    GetJoystick_2

       LDA    SWCHB               ;Get the consol switches
       AND    #$03                ;Mast for the reset/select switchs.
       CMP    #$03                ;Have either of them been used?
       BEQ    GetJoystick_3       ;If not branch.

GetJoystick_2:
	 LDA    #$00                ;Zero the high count of the
       STA    $E6                 ;      switches or joystick have been used.
GetJoystick_3:
	 RTS

;Change color if necessary.
ChangeColor:
	 LSR                        ;If bit 0 of the color is set
       BCC    ChangeColor_2       ;      then the room is to flash.

       TAY                        ;Use color as an index (usually E5- the low counter).
       LDA.wy $0080,Y             ;Get flash color (usually the low counter.)

ChangeColor_2:
       LDY    $E6                 ;Get the input counter.
       BPL    ChangeColor_3       ;If console/joystick moved reciently then branch.

       EOR    $E6                 ;Merge the high counter with the color wanted.
       AND    #$FB                ;Keep this color bug merge down the luminance.

ChangeColor_3:
       ASL                        ;And restore original color if necessary.
       RTS

;Get the address of the dynamic information for an object.
GetObjectAddress:
       LDA    Store1,X
       STA    $93                 ;Get and store the low address.
       LDA    Store2,X
       STA    $94                 ;Get and store the high address.
       RTS

;Game Start
StartGame:
	 SEI                        ;Set Interupts Off
       CLD
       LDX    #$28                ;Clear TIA Registers
       LDA    #$00                ;&04-&2C i.e. blank
ResetAll:
       STA    NUSIZ0,X            ;Everything And Turn.
       DEX                        ;Everything Off.
       BPL    ResetAll
       TXS                        ;Reset Stack
SetupVars:
       STA    VSYNC,X             ;Clear &80 to &FF User Vars.
       DEX
       BMI    SetupVars
       JSR    ThinWalls           ;Position the thin walls (missiles)
       JSR    SetupRoomObjects    ;Setup objects rooms and positions.
MainGameLoop:
       JSR    CheckGameStart      ;Check for Game Start
       JSR    MakeSound           ;Make noise if necessary
       JSR    CheckInput          ;Check for input.
       LDA    $DE                 ;Is The Game Active?
       BNE    NonActiveLoop       ;If Not Branch..
       LDA    $B9                 ;Get the room the Chalise is in.
       CMP    #$12                ;Is it in the yellow castle?
       BNE    MainGameLoop_2      ;If Not Branch..
       LDA    #$FF
       STA    $DF                 ;Set the note count to maximum.
       STA    $DE                 ;Set the game to inactive.
       LDA    #$00                ;Set the noise type to end-noise.
       STA    $E0
MainGameLoop_2:
	 LDY    #$00                ;Allow joystick read - all movement.
       JSR    BallMovement        ;Check ball collisions and move ball.
       JSR    MoveCarriedObject   ;Move the Carried Object
       JSR    DoVSYNC             ;Wait for VSYNC
       JSR    SetupRoomPrint      ;Setup the room and objects for display.
       JSR    PrintDisplay        ;Display the room and objects.
       JSR    PickupPutdown       ;Deal with object pickup and putdown.
       LDY    #$01                ;Dissalow joystick read - move vertically only.
       JSR    BallMovement        ;Check ball collisions and move ball.
       JSR    Surround            ;Deal With Invisible Surround Moving.
       JSR    DoVSYNC             ;Wait for VSYNC
       JSR    MoveBat             ;Move and deal with bat.
       JSR    Portals             ;Move and deal with portcullises.
       JSR    PrintDisplay        ;Display the room and objects.
       JSR    MoveGreenDragon     ;Move and deal with the green dragon.
       JSR    MoveYellowDragon    ;Move and deal with the yellow dragon.
       JSR    DoVSYNC             ;Wait for VSYNC.
       LDY    #$02                ;Dissalow joystic read/bridge check - move horrizonally only.
       JSR    BallMovement        ;Check ball collisions and move ball.
       JSR    MoveRedDragon       ;Move and deal with red dragon.
       JSR    Mag_1               ;Deal with the magnet.
       JSR    PrintDisplay        ;Display the room and objects.
       JMP    MainGameLoop

;Non Active Game Loop.
NonActiveLoop:
	 JSR    DoVSYNC             ;Wait for VSYNC
       JSR    PrintDisplay        ;Display the room and objects.
       JSR    SetupRoomPrint      ;Set up room and objects for display.
       JMP    MainGameLoop

;Position missiles to "thin wall" areas.
ThinWalls:
       LDA    #$0D                ;Position missile 00 to
       LDX    #$02                ;(0D,00) - left thin wall.
       JSR    PosSpriteX
       LDA    #$96                ;Position missile 01 to
       LDX    #$03                ;(96,00) - right thin wall.
       JSR    PosSpriteX
       STA    WSYNC                     ;Wait for horizonal blank.
       STA    HMOVE                     ;Apply the horizonal move.
       RTS

CheckGameStart:
       LDA    SWCHB               ;Get the console switches.
       EOR    #$FF                ;Flip (as reset active low).
       AND    $92                       ;Compare with what was before
       AND    #$01                      ;And check only the reset switch
       BEQ    CheckReset          ;If no reset then branch.
       LDA    $DE                 ;Has the Game Started?
       CMP    #$FF                ;If not then branch.
       BEQ    SetupRoomObjects
       LDA    #$11                ;Get the yellow castle room.
       STA    $8A                       ;Make it the current room.
       STA    $E2                       ;Make it the previous room.
       LDA    #$50                ;Get the X coordinate.
       STA    $8B                       ;Make it the current ball X coordinate.
       STA    $E3                       ;Make it the previous ball X coordinate.
       LDA    #$20                ;Get the Y coordinate.
       STA    $8C                       ;Make it the current ball Y coordinate.
       STA    $E4                       ;Make it the previous ball Y coordinate.
       LDA    #$00
       STA    $A8                 ;Set the red dragon's state to OK.
       STA    $AD                 ;Set the yellow dragon's state to OK.
       STA    $B2                 ;Set the green dragon's state to OK.
       STA    $DF                 ;Set the note count to zero.. (ops!??)
       LDA    #$A2
       STA    $9D                 ;Set no object being carried.
CheckReset:
       LDA    SWCHB               ;Get the console switches.
       EOR    #$FF                ;Flip (as select active low)
       AND    $92                 ;Compare with what was before.
       AND    #$02                ;And check only the select switch.
       BEQ    StoreSwitches       ;Branch if select not being used.
       LDA    $8A                 ;Get the Current Room.
       CMP    #$00                ;Is it the "Number" room?
       BNE    SetupRoomObjects    ;Branch if not.
       LDA    $DD                 ;Increment the level.
       CLC                        ;Number (by two).
       ADC    #$02
       CMP    #$06                ;Have we reached the maximum?
       BCC    ResetSetup
       LDA    #$00                ;If yep then set back to zero.
ResetSetup:
       STA    $DD                 ;Store the new level number.
SetupRoomObjects:
       LDA    #$00                ;Set the current room to the
       STA    $8A                 ;"Number" room.
       STA    $E2                 ;And the previous room.
       LDA    #$00                ;Set the ball's Y coordinate to zero.
       STA    $8C                 ;And the previous Y coordinate.
       STA    $E4                 ;(So can't be seen.)
       LDY    $DD                 ;Get the level number.
       LDA    Loc_4,Y              ;Get the low pointer to object locations.
       STA    $93
       LDA    Loc_5,Y             ;Get the high pointer to object locations.
       STA    $94
       LDY    #$30                ;Copy all the objects dynamic information.
SetupRoomObjects_2:
       LDA    ($93),Y             ;(the rooms and positions) into
       STA.wy $00A1,Y             ;the working area.
       DEY
       BPL    SetupRoomObjects_2
       LDA    $DD                 ;Get the level number.
       CMP    #$04                ;Branch if level one.
       BCC    SignalGameStart     ;Or two (Where all objects are in defined areas.)
       JSR    RandomizeLevel3     ;Put some objects in random rooms.
       JSR    DoVSYNC             ;Wait for VSYNC
       JSR    PrintDisplay        ;Display rooms and objects.
SignalGameStart:
       LDA    #$00                ;Signal that the game has started.
       STA    $DE
       LDA    #$A2                ;Set no object being carried.
       STA    $9D
StoreSwitches:
       LDA    SWCHB               ;Store the current console switches
       STA    $92
       RTS

;Put objects in random rooms for level 3.
RandomizeLevel3:
       LDY    #$1E                ;For each of the eleven objects..
RandomizeLevel3_2:
       LDA    $E5                 ;Get the low input counter as seed.
       LSR
       LSR
       LSR                        ;Generate a psudo-random
       LSR                        ;room number.
       LSR
       SEC
       ADC    $E5                 ;Store the low input counter.
       STA    $E5
       AND    #$1F                ;Trim so represents a room value.
       CMP    Loc_2,Y             ;If it is less than the
       BCC    RandomizeLevel3_2   ;lower bound for object then get another.
       CMP    Loc_3,Y             ;If it equals or is
       BEQ    RandomizeLevel3_3   ;Less than the higher bound for object
       BCS    RandomizeLevel3_2   ;Then continue (branch if higher)
RandomizeLevel3_3:
       LDX    Loc_1,Y             ;Get the dynamic data index for this object
       STA    VSYNC,X             ;Store the new room value.
       DEY
       DEY                        ;Goto the next object.
       DEY
       BPL    RandomizeLevel3_2   ;Untill all done
       RTS

;Room Bounds Data.
;Ex. the chalise at location &B9 can only exist in rooms 13-1A for
;     level 3.
Loc_1:
       .byte $B9                    ;
Loc_2:
       .byte $13                    ;Chalise
Loc_3:
       .byte $1A                    ;
       .byte $A4,$01,$1D            ;Red Dragon
       .byte $A9,$01,$1D            ;Yellow Dragon
       .byte $AE,$01,$1D            ;Green Dragon
       .byte $B6,$01,$1D            ;Sword
       .byte $BC,$01,$1D            ;Bridge
       .byte $BF,$01,$1D            ;Yellow Key
       .byte $C2,$01,$16            ;White Key
       .byte $C5,$01,$12            ;Black Key
       .byte $CB,$01,$1D            ;Bat
       .byte $B3,$01,$1D            ;Magnet

Loc_4:
       .byte <Game1Objects                    ;Pointer to object locations for game 01.
Loc_5:
       .byte >Game1Objects                    ;      --continued.
       .byte <Game2Objects,>Game2Objects                ;Pointer to object locations for game 02.
       .byte <Game2Objects,>Game2Objects                ;Pointer to object locations for game 03.

;Object locations (room and coordinate) for game 01.
Game1Objects:
       .byte $15,$51,$12            ;Black dot (Room, X, Y)
       .byte $0E,$50,$20,$00,$00    ;Red Dragon (Room, X, Y, Movement, State)
       .byte $01,$50,$20,$00,$00    ;Yellow Dragon (Room, X, Y, Movement, State)
       .byte $1D,$50,$20,$00,$00    ;Green Dragon (Room, X, Y, Movement, State)
       .byte $1B,$80,$20            ;Magnet (Room,X,Y)
       .byte $12,$20,$20            ;Sword (Room,X,Y)
       .byte $1C,$30,$20            ;Challise (Room,X,Y)
       .byte $04,$29,$37            ;Bridge (Room,X,Y)
       .byte $11,$20,$40            ;Yellow Key (Room,X,Y)
       .byte $0E,$20,$40            ;White Key (Room,X,Y)
       .byte $1D,$20,$40            ;Black Key (Room,X,Y)
       .byte $1C                    ;Portcullis State
       .byte $1C                    ;Portcullis State
       .byte $1C                    ;Portcullis State
       .byte $1A,$20,$20,$00,$00    ;Bat (Room, X, Y, Movement, State)
       .byte $78,$00                ;Bat (Carrying, Fed-Up)

;Object locations (room and coordinate) for Games 02 and 03.
Game2Objects:
       .byte $15,$51,$12            ;Black Dot (Room,X,Y)
       .byte $14,$50,$20,$A0,$00    ;Red Dragon (Room,X,Y,Movement,State)
       .byte $19,$50,$20,$A0,$00    ;Yellow Dragon (Room,X,Y,Movement,State)
       .byte $04,$50,$20,$A0,$00    ;Green Dragon (Room,X,Y,Movement,State)
       .byte $0E,$80,$20            ;Magnet (Room,X,Y)
       .byte $11,$20,$20            ;Sword (Room,X,Y)
       .byte $14,$30,$20            ;Chalise (Room,X,Y)
       .byte $0B,$40,$40            ;Bridge (Room,X,Y)
       .byte $09,$20,$40            ;Yellow Key (Room,X,Y)
       .byte $06,$20,$40            ;White Key (Room,X,Y)
       .byte $19,$20,$40            ;Black Key (Room,X,Y)
       .byte $1C                    ;Portcullis State
       .byte $1C                    ;Portcullis State
       .byte $1C                    ;Portcullis State
       .byte $02,$20,$20,$90,$00    ;Bat (Room,X,Y,Movement,State)
       .byte $78,$00                ;Bat (Carrying, Fed-Up)

;Check ball collisions and move ball.
BallMovement:
       LDA    CXBLPF
       AND    #$80                ;Get ball-playfield collision
       BNE    PlayerCollision     ;Branch if collision (Player-Wall)

       LDA    CXM0FB
       AND    #$40                ;Get ball-missile00 collision.
       BNE    PlayerCollision     ;Branch if collision. (Player-Left Thin)

       LDA    CXM1FB
       AND    #$40                ;Get ball-missile01 collision.
       BEQ    BallMovement_2      ;Branch if no collision.

       LDA    $96                 ;If object2 (to print) is
       CMP    #$87                ;      not the black dot then collide.
       BNE    PlayerCollision
BallMovement_2:
       LDA    CXP0FB
       AND    #$40                ;Get ball-player00 collision.
       BEQ    BallMovement_3      ;If no collision then branch.

       LDA    $95                 ;If object1 (to print) is
       CMP    #$00                ;      not the invisible surround then
       BNE    PlayerCollision     ;      branch (collision)

BallMovement_3:
       LDA    CXP1FB
       AND    #$40                ;Get ball-player01 collision.
       BEQ    NoCollision         ;If no collision then branch.

       LDA    $96                 ;If player01 to print is
       CMP    #$00                ;      not the invisible surround then
       BNE    PlayerCollision     ;      branch (collision)

       JMP    NoCollision         ;No collision - branch.

;Player collided (with something)
PlayerCollision:
       CPY    #$02                ;Are we checking for the bridge?
       BNE    ReadStick           ;If not, branch.

       LDA    $9D                 ;Get the object being carried.
       CMP    #$5A                ;      Branch if it is the bridge.
       BEQ    ReadStick

       LDA    $8A                 ;Get the current room.
       CMP    $BC                 ;Is the bridge in this room.
       BNE    ReadStick           ;If not branch.

;Check going through the bridge.
       LDA    $8B                 ;Get the ball's X coordinate.
       SEC
       SBC    $BD                 ;Subtract the bridge's X coordinate.
       CMP    #$0A                ;If less than &0A then forget it.
       BCC    ReadStick

       CMP    #$17                ;If more than &17 then forget it.
       BCS    ReadStick

       LDA    $BE                 ;Get the bridge's Y coordinate.
       SEC
       SBC    $8C                 ;Subtrac the ball's Y coordinate.
       CMP    #$FC
       BCS    NoCollision         ;If more than &FC then going through bridge.

       CMP    #$19                ;If more than &19 then forget it.
       BCS    ReadStick

;No collision (and going through bridge)
NoCollision:
       LDA    #$FF                ;Reset the joystick input.
       STA    $99
       LDA    $8A                 ;Get the current room.
       STA    $E2                 ;      and store temporarily.
       LDA    $8B                 ;Get the ball's X coordinate.
       STA    $E3                 ;      and store temporarily.
       LDA    $8C                 ;Get the ball's Y coordinate.
       STA    $E4                 ;And Store Temporarily.

;Read Sticks
ReadStick:
       CPY    #$00                ;???Is game in first phase?
       BNE    ReadStick_2         ;If not, don't bother with joystick read.

       LDA    SWCHA               ;Read joysticks.
       STA    $99                 ;      and store value.

ReadStick_2:
       LDA    $E2                 ;Get Temporary room.
       STA    $8A                 ;      and make it the current room.
       LDA    $E3                 ;Get temporary X coordinate
       STA    $8B                 ;      and make it the man's X coordinate.
       LDA    $E4                 ;Get temporary Y coordinate
       STA    $8C                 ;      and make it the man's Y coordinate.

       LDA    $99                 ;Get the Joystick position.
       ORA    ReadStick_3,Y             ;Merge out movement not allowed in this phase.
       STA    $9B                 ;And store cooked movement.

       LDY    #$03                ;Set the delta for the ball.
       LDX    #$8A                ;Point to ball's coordiates.
       JSR    MoveGroundObject     ;Move the ball
       RTS

;Joystick Merge Values
ReadStick_3:
       .byte $00,$C0,$30            ;No change, No horizontal, No vertical.

;Deal with object pickup and putdown.
PickupPutdown:
       ROL    INPT4               ;Get joystick trigger.
       ROR    $D7                 ;Merget into joystick record.
       LDA    $D7                 ;Get joystick record.
       AND    #$C0                ;Merget out previous presses.
       CMP    #$40                ;Was it previously pressed?
       BNE    PickupPutdown_2     ;If not branch.

       LDA    #$A2
       CMP    $9D                 ;If nothing is being carried
       BEQ    PickupPutdown_2     ;      then branch.

       STA    $9D                 ;Drop object.
       LDA    #$04                ;Set noise type to four.
       STA    $E0
       LDA    #$04                ;Set noise count to four.
       STA    $DF

PickupPutdown_2:
       LDA    #$FF                ;????
       STA    $98

;Check for collision.
       LDA    CXP0FB
       AND    #$40                ;Get Ball-Player00 collision.
       BEQ    PickupPutdown_3     ;If nothing occured then branch.

;With Player00
       LDA    $95                 ;Get type of Player00
       STA    $97                 ;And Store.
       JMP    CollisionDetected   ;Deal with collision.

PickupPutdown_3:
       LDA    CXP1FB
       AND    #$40                ;Get Ball-Player01 collision.
       BEQ    PickupPutdown_4     ;If nothing has happened, branch.

       LDA    $96                 ;Get type of Player01
       STA    $97                 ;      and store.
       JMP    CollisionDetected   ;Deal with collision.

PickupPutdown_4:
       JMP    NoObject            ;Deal with no collision (return).

;Collision occured.
CollisionDetected:
       LDX    $97                 ;Get the object collided with.
       JSR    GetObjectAddress    ;Get it's dynamic information.
       LDA    $97                 ;Get the object collided with.
       CMP    #$51                ;Is it carriable?
       BCC    NoObject            ;If not, branch.

       LDY    #$00
       LDA    ($93),Y             ;Get the object's room.
       CMP    $8A                 ;Is it in the current room?
       BNE    NoObject            ;If not, branch.

       LDA    $97                 ;Get the object collided with.
       CMP    $9D                 ;Is it the object being carried?
       BEQ    PickupObject        ;If so, branch (and actually pick it up.)

       LDA    #$05                ;Set noise type to five.
       STA    $E0
       LDA    #$04                ;Set noise type to four.
       STA    $DF

PickupObject:
       LDA    $97                 ;Set the object as being
       STA    $9D                 ;      carried.

       LDX    $93                 ;Get the dynamice address low byte.
       LDY    #$06
       LDA    $99                 ;????
       JSR    MoveObjectDelta     ;????

       LDY    #$01
       LDA    ($93),Y             ;Get the object's X coordinate.
       SEC
       SBC    $8B                 ;Subtract the ball's X coordinate.
       STA    $9E                 ;      and store the difference.
       LDY    #$02
       LDA    ($93),Y             ;Get the object's Y coordinate.
       SEC
       SBC    $8C                 ;Subtract the Ball's Y coordinate.
       STA    $9F                 ;      and store the difference.

;No collision
NoObject:
       RTS


;Move the carried object
MoveCarriedObject:
       LDX    $9D                 ;Get the object being carried.
       CPX    #$A2                ;If nothing then branch (return)
       BEQ    MoveCarriedObject_2

       JSR    GetObjectAddress    ;Get it's dynamic information.
       LDY    #$00

       LDA    $8A                 ;Get the current room.
       STA    ($93),Y             ;      and stroe the object's current room.
       LDY    #$01

       LDA    $8B                 ;Get the ball's X coordinate.
       CLC
       ADC    $9E                 ;Add the X difference.
       STA    ($93),Y             ;      and store as the object's X coordinate.
       LDY    #$02
       LDA    $8C                 ;Get the ball's Y coordinate.
       CLC
       ADC    $9F                 ;Add the Y difference.
       STA    ($93),Y             ;      and store as the object's Y coordinate.

       LDY    #$00                ;Set no delta.
       LDA    #$FF                ;Set no movement.
       LDX    $93                 ;Get the object's dynamic address.
       JSR    MoveGroundObject     ;Move the object.
MoveCarriedObject_2:
       RTS

;Move the object.
MoveGroundObject:
       JSR    MoveObjectDelta     ;Move the object by delta.
       LDY    #$02                ;Set to do the three
MoveGroundObject_2:
       STY    $9A                 ;      portcullises.
       LDA.wy $00C8,Y             ;Get the portal state.
       CMP    #$1C                ;Is it in a closed state?
       BEQ    GetPortal           ;If not, next portal.

;Deal with object moving out of a castle.
       LDY    $9A                 ;Get port number.
       LDA    VSYNC,X             ;Get object's room number.
       CMP    EntryRoomOffsets,Y  ;Is it in a castle entry room.
       BNE    GetPortal           ;If not, next portal.

       LDA    WSYNC,X             ;Get the object's Y coordinate.
       CMP    #$0D                ;Is it above &OD i.e at the bottom.
       BPL    GetPortal           ;If so then branch.

       LDA    CastleRoomOffsets,Y ;Get the castle room.
       STA    VSYNC,X             ;And put the object in the castle room.
       LDA    #$50
       STA    VBLANK,X            ;Set the object's new X coordinate.
       LDA    #$2C
       STA    WSYNC,X             ;Set the new object's Y coordinate.
       LDA    #$01
       STA.wy $00C8,Y             ;Set the portcullis state to 01.
       RTS

GetPortal:
       LDY    $9A                 ;Get the portcullis number.
       DEY                        ;      goto next,
       BPL    MoveGroundObject_2   ;      and continue.

;Check and Deal with Up.
       LDA    WSYNC,X             ;Get the object's Y coordinate.
       CMP    #$6A                ;Has it reched above the top.
       BMI    DealWithLeft        ;If not, branch.

       LDA    #$0D                ;Set new Y coordinate to bottom.
       STA    WSYNC,X
       LDY    #$05                ;Get the direction wanted.
       JMP    GetNewRoom          ;Go and get new room.

;Check and Deal with Left.
DealWithLeft:
       LDA    VBLANK,X            ;Get the object's X coordinate.
       CMP    #$03                ;Is it Three or less?
       BCC    DealWithLeft_2      ;IF so, branch.  (off to left)

       CMP    #$F0                ;Is it's &F0 or more.
       BCS    DealWithLeft_2      ;If so, branch.  (off to right)

       JMP    DealWithDown

DealWithLeft_2:
       CPX    #$8A                ;Are we dealling with the ball?
       BEQ    DealWithLeft_3      ;If so Branch.

       LDA    #$9A                ;Set new X coordinate for the others.
       JMP    DealWithLeft_4

DealWithLeft_3:
       LDA    #$9E                ;Set new X coordinate for the ball.

DealWithLeft_4:
       STA    VBLANK,X            ;Store the next X coordinate.
       LDY    #$08                ;And get the direction wanted.
       JMP    GetNewRoom          ;Go and get new room.

;Check and Deal with Down.
DealWithDown:
       LDA    WSYNC,X             ;Get object's Y coordinate.
       CMP    #$0D                ;If it's greater than &0D then
       BCS    DealWithRight       ;Branch.

       LDA    #$69                ;Set new Y coordinate.
       STA    WSYNC,X
       LDY    #$07                ;Get the direction wanted.
       JMP    GetNewRoom          ;Go and get new room.

;Check and Deal with Right.
DealWithRight:
       LDA    VBLANK,X            ;Get the object's X coordinate.
       CPX    #$8A                ;Are we dealing with the ball.
       BNE    DealWithRight_2     ;Branch if not.

       CMP    #$9F                ;Has the object reached the right?
       BCC    MovementReturn      ;Branch if not.

       LDA    VSYNC,X             ;Get the Ball's Room.
       CMP    #$03                ;Is it room #3 (Right to secret room)
       BNE    DealWithRight_3     ;Branch if not.

       LDA    $A1                 ;Check the room of the black dot.
       CMP    #$15                ;Is it in the hidden room area?
       BEQ    DealWithRight_3     ;If so, Branch.

;Manually change to secret room.
       LDA    #$1E                ;Set room to secret room.
       STA    VSYNC,X             ;And make it current.
       LDA    #$03                ;Set the X coordinate.
       STA    VBLANK,X
       JMP    MovementReturn      ;And Exit.

DealWithRight_2:
       CMP    #$9B                ;Has the object reached the right of the screen?
       BCC    MovementReturn      ;Branch if not (no room change)

DealWithRight_3:
       LDA    #$03                ;Set the next X coordinate.
       STA    VBLANK,X
       LDY    #$06                ;And get the direction wanted.
       JMP    GetNewRoom          ;Get the new room.

;Get new room
GetNewRoom:
       LDA    VSYNC,X             ;Get the object's room.
       JSR    RoomNumToAddress    ;Convert it to an address.
       LDA    ($93),Y             ;Get the adjacent room.
       JSR    AdjustRoomLevel     ;Deal with the level differences.
       STA    VSYNC,X             ;      and store as new object's room.

MovementReturn:
       RTS

;Move the object in direction by delta.
MoveObjectDelta:
       STA    $9B                 ;Stored direction wanted.
MoveObjectDelta_2:
       DEY                        ;Count down the delta.
       BMI    MoveObjectDelta_7

       LDA    $9B                 ;Get direction wanted.
       AND    #$80                ;Check for right move.
       BNE    MoveObjectDelta_3   ;If no move right then branch.

       INC    VBLANK,X            ;Increment the X coordinate.

MoveObjectDelta_3:
       LDA    $9B                 ;Get the direction wanted.
       AND    #$40                ;Check for left move.
       BNE    MoveObjectDelta_4   ;If no move left then branch.

       DEC    VBLANK,X            ;Decrement the X coordinate.

MoveObjectDelta_4:
       LDA    $9B                 ;Get the direction wanted.
       AND    #$10                ;Check for move up.
       BNE    MoveObjectDelta_5   ;If no move up then branch.
       INC    WSYNC,X

MoveObjectDelta_5:
       LDA    $9B                 ;Get direction wanted.
       AND    #$20                ;Check for move down.
       BNE    MoveObjectDelta_6   ;If no move down the branch.

       DEC    WSYNC,X             ;Decrement the Y coordinate.

MoveObjectDelta_6:
       JMP    MoveObjectDelta_2   ;Keep going until delta finished.
MoveObjectDelta_7:
       RTS


;Adjust room for different levels.
AdjustRoomLevel:
       CMP    #$80                ;Is the room number
       BCC    AdjustRoomLevel_2   ;      above &80?

       SEC
       SBC    #$80                ;Remove the &80 flag and
       STA    $D8                 ;      store the room number.
       LDA    $DD                 ;Get the level number.
       LSR                        ;Devide it by two.
       CLC
       ADC    $D8                 ;Add to the original room.
       TAY
       LDA    RoomDiffs,Y             ;Use as an offset to get the next room.
AdjustRoomLevel_2:
       RTS


;Get player-ball collision.
PBCollision:
       CMP    $95                 ;Is it the rist object?
       BEQ    PBCollision_2       ;YES - Then Branch.

       CMP    $96                 ;Is it the second object?
       BEQ    PBCollision_3       ;YES - Then Branch.

       LDA    #$00                ;Otherewise nothing.
       RTS

PBCollision_2:
       LDA    CXP0FB              ;Get player00-ball collision.
       AND    #$40
       RTS
PBCollision_3:
       LDA    CXP1FB              ;Get player01-ball collision.
       AND    #$40
       RTS


;Find which object has hit object wanted.
FindObjHit:
       LDA    CXPPMM              ;Get Player00-Player01
       AND    #$80                ;      collision.
       BEQ    FindObjHit_2        ;If nothing, Branch.

       CPX    $95                 ;Is object 1 the one being hit?
       BEQ    FindObjHit_3        ;If so, Branch.

       CPX    $96                 ;Is object 2 the one being hit?
       BEQ    FindObjHit_4        ;If so, Branch.
FindObjHit_2:
       LDA    #$A2                ;Therefore select the other.
       RTS
FindObjHit_3:
       LDA    $96                 ;Therefore select the other.
       RTS
FindObjHit_4:
       LDA    $95                 ;Therefore select the other.
       RTS


;Move object.
MoveGameObject:
       JSR    GetLinkedObject     ;Get liked object and movement.
       LDX    $D5                 ;Get dynamic data address.
       LDA    $9B                 ;Get Movement.
       BNE    MoveGameObject_2    ;If movement then branch.

       LDA    RSYNC,X             ;Use old movement.

MoveGameObject_2:
       STA    RSYNC,X             ;Stoe the new movement.
       LDY    $D4                 ;Get the object's Delta.
       JSR    MoveGroundObject     ;Move the object.
       RTS


;Find liked object and get movement.
GetLinkedObject:
       LDA    #$00                ;Set index to zero.
       STA    $E1
GetLinkedObject_2:
       LDY    $E1                 ;Get index.
       LDA    ($D2),Y             ;Get first object.
       TAX
       INY
       LDA    ($D2),Y             ;Get second object.
       TAY
       LDA    VSYNC,X             ;Get object1;s room.
       CMP.wy $0000,Y             ;Combare with object2's room.
       BNE    GetLinkedObject_3   ;If not the same room then branch.

       CPY    $D6                 ;Have we matched the second object
       BEQ    GetLinkedObject_3   ;      for difficulty (if so, carry on).

       CPX    $D6                 ;Have we matched the first object
       BEQ    GetLinkedObject_3   ;      for difficulty (if so, carry on).

       JSR    GetLinkedObject_4   ;Get object's movement.
       RTS
GetLinkedObject_3:
       INC    $E1                 ;Increment the index.
       INC    $E1
       LDY    $E1                 ;Get the index number.
       LDA    ($D2),Y             ;Check for end of sequence.
       BNE    GetLinkedObject_2   ;If not branch.

       LDA    #$00                ;Set no move if no
       STA    $9B                 ;      liked object is found.
       RTS


;Work out object's movement.
GetLinkedObject_4:
       LDA    #$FF                ;Set object movement to none.
       STA    $9B

       LDA.wy $0000,Y             ;Get oject2's room.
       CMP    VSYNC,X             ;Compare it with object's room.
       BNE    GetLinkedObject_8   ;If not the same, forget it.

       LDA.wy $0001,Y             ;Get Object2's X coordinate.
       CMP    VBLANK,X            ;Get Object1;s X coordinate.
       BCC    GetLinkedObject_5   ;If Object2 to left of Object1 then Branch.
       BEQ    GetLinkedObject_6   ;If Object2 on Object1 then Branch.

       LDA    $9B                 ;Get Object Movement.
       AND    #$7F                ;Signal a move right.
       STA    $9B
       JMP    GetLinkedObject_6   ;Now try Vertical.
GetLinkedObject_5:
       LDA    $9B                 ;Get object movent.
       AND    #$BF                ;Signal a move left.
       STA    $9B

GetLinkedObject_6:
       LDA.wy $0002,Y             ;Get Object2's Y Coordinate.
       CMP    WSYNC,X             ;Get Object1's X Coordinate.
       BCC    GetLinkedObject_7   ;If Object2 Below Object1 Then Branch.
       BEQ    GetLinkedObject_8   ;If Object2 on Object1 Then Branch.

       LDA    $9B                 ;Get Object Movement.
       AND    #$EF                ;Signal a move up.
       STA    $9B
       JMP    GetLinkedObject_8   ;Jump to Finish.

GetLinkedObject_7:
       LDA    $9B                 ;Get Object Movement.
       AND    #$DF                ;Signal a move down.
       STA    $9B

GetLinkedObject_8:
       LDA    $9B                 ;Get the Move.
       RTS


;Move the Red Dragon
MoveRedDragon:
       LDA    #<RedDragMatrix
       STA    $D2                 ;Set the Low address of Object Store.
       LDA    #>RedDragMatrix
       STA    $D3                 ;Set the High address of Object Store.
       LDA    #$03
       STA    $D4                 ;Set the Dragon's Delta
       LDX    #$36                ;Select Dragon #1 : Red
       JSR    MoveDragon
       RTS

;Red Dragon Object Matrix
RedDragMatrix:
       .byte $B6,$A4                  ;Sword, Red Dragon
       .byte $A4,$8A                  ;Red Dragon, Ball
       .byte $A4,$B9                  ;Red Dragon, Chalise
       .byte $A4,$C2                  ;Red Dragon, White Key
       .byte $00

;Move the Yellow Dragon.
MoveYellowDragon:
       LDA    #<YelDragMatrix
       STA    $D2                 ;Set the Low Address of Object Store.
       LDA    #>YelDragMatrix
       STA    $D3                 ;Set the High Address of Object Store.
       LDA    #$02
       STA    $D4                 ;Set the Yellow Dragon's Delta.
       LDX    #$3F
       JSR    MoveDragon          ;Select Dragon #2 : Yellow.
       RTS

;Yellow Dragon's Object Matrix
YelDragMatrix:
	 .byte $B6,$A9                  ;Sword, Yellow Dragon
       .byte $BF,$A9                  ;Yellow Key, Yellow Dragon
       .byte $A9,$8A                  ;Yellow Dragon, Ball
       .byte $A9,$B9                  ;Yellow Dragon, Chalise
       .byte $00


;Move the Green Dragon
MoveGreenDragon:
       LDA    #<GreenDragonMatrix
       STA    $D2                 ;Set Low Address of Object Store.
       LDA    #>GreenDragonMatrix
       STA    $D3                 ;Set High Address of Object Store.
       LDA    #$02
       STA    $D4                 ;Set the Green Dragon's Delta.
       LDX    #$48                ;Select Dragon #3 : Green
       JSR    MoveDragon
       RTS

;Green Dragon's Object Matrix
GreenDragonMatrix:
       .byte $B6,$AE                  ;Sword, Green Dragon
       .byte $AE,$8A                  ;Green Dragon, Ball
       .byte $AE,$B9                  ;Green Dragon Chalise
       .byte $AE,$BC                  ;Green Dragon, Bridge
       .byte $AE,$B3                  ;Green Dragon, Magnet
       .byte $AE,$C5                  ;Green Dragon, Black Key
       .byte $00


;Move A Dragon
MoveDragon:
       STX    $A0                 ;Save Object were dealing with.
       LDA    Store1,X             ;Get the Object's Dynamic Data.
       TAX
       LDA    NUSIZ0,X            ;Get the Object's State.
       CMP    #$00                ;Is it in State 00 (Normal #1)
       BNE    MoveDragon_6        ;Branch if not.

;Dragon Normal (State 1)
       LDA    SWCHB               ;Read console switches.
       AND    #$80                ;Check for P1 difficulty.
       BEQ    MoveDragon_2        ;If Amateur Branch.

       LDA    #$00                ;Set Hard - Ignore Nothing
       JMP    MoveDragon_3

MoveDragon_2:
       LDA    #$B6                ;Set Easy - Ignore Sword.

MoveDragon_3:
       STA    $D6                 ;Store Difficulty
       STX    $D5                 ;Store Dynamic Data Address.
       JSR    MoveGameObject

       LDA    $A0                 ;Get Object
       JSR    PBCollision         ;      And get the Player-Ball collision.
       BEQ    MoveDragon_4        ;If None Then Branch.

       LDA    SWCHB               ;Get Console Switched.
       ROL                        ;Move P0 difficulty to
       ROL                        ;      bit 01 position.
       ROL
       AND    #$01                ;Mask it out.
       ORA    $DD                 ;Merget in the Level Number.
       TAY                        ;Create Lookup.
       LDA    DragonDiff,Y             ;Get New State.
       STA    NUSIZ0,X            ;Store as Dragon's State (Open Mouthed).
       LDA    $E3
       STA    VBLANK,X            ;Get Temp Ball X Coord and Store as Dragon's.
       LDA    $E4
       STA    WSYNC,X             ;Get Temp Ball Y Coord and Store as Dragon's
       LDA    #$01
       STA    $E0                 ;Set Noise Type to 01
       LDA    #$10
       STA    $DF                 ;Set Noise Count to 10 i.e. make roar noise.

MoveDragon_4:
       STX    $9A                 ;Store Object's Dynamic Data Address.
       LDX    $A0                 ;Get the Object Number.
       JSR    FindObjHit          ;See if anoher object has hit the dragon.
       LDX    $9A                 ;Get the Object Address.
       CMP    #$51                ;Has the Sword hit the Dragon?
       BNE    MoveDragon_5        ;If Not, Branch.

       LDA    #$01                ;Set the State to 01 (Dead)
       STA    NUSIZ0,X
       LDA    #$03                ;Set Sound Three.
       STA    $E0
       LDA    #$10                ;Set a Noise count of &10.
       STA    $DF

MoveDragon_5:
       JMP    MoveDragon_9        ;Jump to Finish.

MoveDragon_6:
       CMP    #$01                ;Is it in State 01 (Dead)
       BEQ    MoveDragon_9        ;Branch if So (Return)

       CMP    #$02                ;Is it int State 02 (Normal #2)
       BNE    MoveDragon_7        ;Branch if Not.

;Normal Dragon State 2 (Eaten Ball)
       LDA    VSYNC,X             ;Get the Dragon's Current Room.
       STA    $8A                 ;Store as the Ball's Current Room
       STA    $E2                 ;      and Previous Room.
       LDA    VBLANK,X            ;Get the Dragon's X Coordinate.
       CLC
       ADC    #$03                ;Adjust
       STA    $8B                 ;      and store as the ball's X coordinate.
       STA    $E3                 ;      and previous X coordinate.
       LDA    WSYNC,X             ;Get the Dragon's Y coordinate.
       SEC
       SBC    #$0A                ;Adjust
       STA    $8C                 ;      and store as the ball's Y coordinate.
       STA    $E4                 ;      and the previous Y coordinate.
       JMP    MoveDragon_9


;Dragon Roaring.
MoveDragon_7:
       INC    NUSIZ0,X            ;Increment the Dragon's State.
       LDA    NUSIZ0,X            ;Get it's State.
       CMP    #$FC                ;Is it near the end?
       BCC    MoveDragon_9        ;If Not, Branch.

       LDA    $A0                 ;Get the Dragon's Number.
       JSR    PBCollision         ;Check if the Ball is colliding.
       BEQ    MoveDragon_9        ;If not, Branch.

       LDA    #$02                ;Set the State to State 02 : Eaten
       STA    NUSIZ0,X
       LDA    #$02                ;Set noise two.
       STA    $E0
       LDA    #$10                ;Set the Count of Noise to &10.
       STA    $DF
       LDA    #$9B                ;Get the Maximum X Coordinate.
       CMP    VBLANK,X            ;Compare with the Dragon's X Coordinate.
       BEQ    MoveDragon_8
       BCS    MoveDragon_8

       STA    VBLANK,X            ;If too large then Use It.

MoveDragon_8:
       LDA    #$17                ;Set Minimum Y Coordinate.
       CMP    WSYNC,X             ;Compare with the Dragon's Y Coordinate.
       BCC    MoveDragon_9

       STA    WSYNC,X             ;If Too Small, set as Dragon's Y coordinate.
MoveDragon_9:
       RTS

;Dragon Difficulty
DragonDiff:
       .byte $D0,$E8                  ;Level 1 : Am, Pro
       .byte $F0,$F6                  ;Level 2 : Am, Pro
       .byte $F0,$F6                  ;Level 3 : Am, Pro

;Move Bat
MoveBat:
       INC    $CF                 ;Put Bat in the Next State.
       LDA    $CF                 ;Get the Bat State.
       CMP    #$08                ;Has it Reached the Maximum?
       BNE    MoveBat_2

       LDA    #$00                ;If So, Reset the Bat State.
       STA    $CF
MoveBat_2:
       LDA    $D1                 ;Get the Bat Fed-Up Value.
       BEQ    MoveBat_3           ;If Bat Fed-Up then Branch.

       INC    $D1                 ;Increment its value for next time.
       LDA    $CE                 ;Get the Bat's Movement.
       LDX    #$CB                ;Position to Bat.
       LDY    #$03                ;Get the Bat's Deltas.
       JSR    MoveGroundObject    ;Move the Bat.
       JMP    MoveBat_4           ;Update the Bat's Object.

;Bat Fed-Up
MoveBat_3:
       LDA    #$CB                ;Store the Bat's Dynamic Data Address
       STA    $D5
       LDA    #$03                ;Set the Bat's Delta.
       STA    $D4
       LDA    #<BatMatrix         ;Set the Low Address of Object Store.
       STA    $D2
       LDA    #>BatMatrix         ;Set the High Address of Object Store.
       STA    $D3
       LDA    $D0                 ;Get Object being Carried by Bat,
       STA    $D6                 ;      And Copy.
       JSR    MoveGameObject      ;Move the Bat.

       LDY    $E1                 ;Get Object Liked Index.
       LDA    ($D2),Y             ;Look up the Object Found in the Table.
       BEQ    MoveBat_4           ;If nothing found then Forget it.

       INY
       LDA    ($D2),Y             ;Get the Object Wanted.
       TAX
       LDA    VSYNC,X             ;Get the Object's Room.
       CMP    $CB                 ;Is it the Same as the Bats?
       BNE    MoveBat_4           ;If not Forget it.

;See if Bat Can pick up Object.
       LDA    VBLANK,X            ;Get the Object's X Coordinate.
       SEC
       SBC    $CC                 ;Find the differenct with the Bat's
       CLC                        ;X coordinate.
       ADC    #$04                ;Adjust so Bat in middle of object.
       AND    #$F8                ;Is Bat within Seven Pixels?
       BNE    MoveBat_4           ;If not, no pickup possible.

       LDA    WSYNC,X             ;Get the Object's Y Coordinate.
       SEC
       SBC    $CD                 ;Find the Difference with the Bat's
       CLC                        ;      Y Coordinate.
       ADC    #$04                ;Adjust.
       AND    #$F8                ;Is the Bat within Seven Pixels?
       BNE    MoveBat_4           ;If not, No Pickup Possible.

;Get Object
       STX    $D0                 ;Store Object as Being Carried.
       LDA    #$10                ;Reset the Bat Fed Up Time.
       STA    $D1

;Move Object Being Carried by Bat.
MoveBat_4:
       LDX    $D0                 ;Get Object Being Carried by Bat.
       LDA    $CB                 ;Get the Bat's Room.
       STA    VSYNC,X             ;Store this as the Object's Room.
       LDA    $CC                 ;Get the Bat's X coordinate.
       CLC
       ADC    #$08                ;Adjust to the Right.
       STA    VBLANK,X            ;Make it the Object's X coordinate.
       LDA    $CD                 ;Get the Bat's Y Coordinate.
       STA    WSYNC,X             ;Store it as the Object's Y Coordinate.
       LDA    $D0                 ;Get the Object Being Carried by the Bat.
       LDY    $9D                 ;Get the Object Being Carried by the Ball.
       CMP    Store1,Y             ;Are the the Same?
       BNE    MoveBat_5           ;If not Branch.

       LDA    #$A2                ;Set Nothing Being
       STA    $9D                 ;      Carried.
MoveBat_5:
       RTS


;Bat Object Matrix.
BatMatrix:
       .byte $CB,$B9                  ;Bat,Chalise
       .byte $CB,$B6                  ;Bat,Sword
       .byte $CB,$BC                  ;Bat,Bridge
       .byte $CB,$BF                  ;Bat,Yellow Key
       .byte $CB,$C2                  ;Bat,White Key
       .byte $CB,$C5                  ;Bat,Black Key
       .byte $CB,$A4                  ;Bat,Red Dragon
       .byte $CB,$A9                  ;Bat,Yellow Dragon
       .byte $CB,$AE                  ;Bat,Green Dragon
       .byte $CB,$B3                  ;Bat,Magnet
       .byte $00


;Deal with Portcullis and Collisions.
Portals:
       LDY    #$02                ;For Each Portcullis.
Portals_2:
       LDX    PortOffsets,Y             ;Get the Portcullises offset number.
       JSR    FindObjHit          ;See if an Object Collided with it.
       STA    $97                 ;      Store that Object.
       CMP    KeyOffsets,Y             ;Is it the Associated Key?
       BNE    Portals_3           ;If not then Branch.

       TYA                        ;Get the Portcullis Number
       TAX
       INC    $C8,X               ;Change it's state to open it.
Portals_3:
       TYA                        ;Get the Porcullis number.
       TAX
       LDA    $C8,X               ;Get the State.
       CMP    #$1C                ;Is it Closed?
       BEQ    Portals_7           ;Yes - then Branch.

       LDA    PortOffsets,Y             ;Get Portcullis number.
       JSR    PBCollision         ;Get the Player-Ball Collision.
       BEQ    Portals_4           ;If Not Then Branch.

       LDA    #$01                ;Set the Portcullis to Closed.
       STA    $C8,X
       LDX    #$8A                ;Set to the Castle.
       JMP    Portals_6           ;Put the Ball in the Castle.

Portals_4:
       LDA    $97                 ;Get the Object that hit the Portcullis.
       CMP    #$A2                ;Is it nothing?
       BEQ    Portals_5           ;If so, Branch.

       LDX    $97                 ;Get Object.
       STY    $9A                 ;Save Y
       JSR    GetObjectAddress    ;And find it's Dynamic Address.
       LDY    $9A                 ;Retrieve Y
       LDX    $93                 ;Get Object's Address.
       JMP    Portals_6           ;Put Object In the Castle.

Portals_5:
       JMP    Portals_7

Portals_6:
       LDA    EntryRoomOffsets,Y ;Look up Castle endry room for this port.
       STA    VSYNC,X       ;Make it the object's Room.
       LDA    #$10          ;Give the Object a new Y coordinate.
       STA    WSYNC,X
Portals_7:
       TYA                  ;Get the Portcullis number.
       TAX
       LDA    $C8,X         ;Get its State.
       CMP    #$01          ;Is it Open?
       BEQ    Portals_8     ;Yes - Then Branch.

       CMP    #$1C          ;Is it Closed?
       BEQ    Portals_8     ;Yes - Then Branch.

       INC    $C8,X         ;Increment it's State.
       LDA    $C8,X         ;Get the State.
       CMP    #$38          ;Has it reached the maximum state.
       BNE    Portals_8     ;If not, Branch.

       LDA    #$01          ;Set to Closed
       STA    $C8,X         ;      State.

Portals_8:
       DEY                  ;Goto the next portcullis.
       BMI    Portals_9     ;Branch if Finished.
       JMP    Portals_2     ;Do next Protcullis.
Portals_9:
       RTS




;Portcullis #1, #2, #3
PortOffsets:
	 .byte $09,$12,$1B

;Keys #1, #2, #3  (Yellow, White, Black)
KeyOffsets:
	 .byte $63,$6C,$75

;Castle Entry Rooms (Yellow, White, Black)
EntryRoomOffsets:
	 .byte $12,$1A,$1B

;Castle Rooms (Yellow, White, Black)
CastleRoomOffsets:
	 .byte $11,$0F,$10


;Deal With Magnet.
Mag_1:
	 LDA    $B5                 ;Get Magnet's Y Coordinate.
       SEC
       SBC    #$08                ;Adjust to it's "Poles".
       STA    $B5
       LDA    #$00                ;Con Difficulty!
       STA    $D6
       LDA    #<MagnetMatrix                ;Set Low Address of Object Store.
       STA    $D2
       LDA    #>MagnetMatrix                ;Set High Address of Object Store.
       STA    $D3
       JSR    GetLinkedObject     ;Get Liked Object and Set Movement.
       LDA    $9B                 ;Get Movement.
       BEQ    Mag_2               ;If None, then Forget It.

       LDY    #$01                ;Set Delta to One.
       JSR    MoveGroundObject     ;Move Object.

Mag_2:
	 LDA    $B5                 ;Reset the Magnet's
       CLC                        ;      Y Coordinate.
       ADC    #$08
       STA    $B5
       RTS

;Magnet Object Matrix.
MagnetMatrix:
       .byte $BF,$B3                  ;Yellow Key, Magnet
       .byte $C2,$B3                  ;White Key, Magnet
       .byte $C5,$B3                  ;Black Key, Magnet
       .byte $B6,$B3                  ;Sword, Magnet
       .byte $BC,$B3                  ;Bridge, Magnet
       .byte $B9,$B3                  ;Chalise, Magnet
       .byte $00



;Deal with Invisible Surround Moving.
Surround:
	 LDA    $8A                 ;Get the Current Room.
       JSR    RoomNumToAddress    ;Convert it to an Address.
       LDY    #$02
       LDA    ($93),Y             ;Get the Room's Color.
       CMP    #$08                ;Is it Invisible?
       BEQ    Surround_2          ;If So Branch.

       LDA    #$00                ;If not, signal the
       STA    $DB                 ;      Invisible surround not
       JMP    Surround_4          ;      Wanted.

Surround_2:
       LDA    $8A                 ;Get the Current Room.
       STA    $D9                 ;And store as the Invisible Surrounds.
       LDA    $8B                 ;Get the Ball's X Coordinate.
       SEC
       SBC    #$0E                ;Adjust for Surround,
       STA    $DA                 ;      and store as surround's X coordinate.
       LDA    $8C                 ;Get the Ball's Y Coordinate.
       CLC
       ADC    #$0E                ;Adjust for Surround.
       STA    $DB                 ;      and store as surround's Y coordinate.
       LDA    $DA                 ;Get the Surround's X cordinate.
       CMP    #$F0                ;Is it close to the right edge?
       BCC    Surround_3          ;Branch if not.

       LDA    #$01                ;Flick surround to the
       STA    $DA                 ;      otherside of the screen.
       JMP    Surround_4

Surround_3:
       CMP    #$82                ;???
       BCC    Surround_4          ;???

       LDA    #$81                ;???
       STA    $DA                 ;???
Surround_4:
       RTS


;Make A Noise.
MakeSound:
	 LDA    $DF                 ;Check Not Count.
       BNE    MakeSound_2         ;Branch if Noise to be made.

       STA    AUDV0               ;Turn off the Volume.
       STA    AUDV1
       RTS

MakeSound_2:
       DEC    $DF                 ;Goto the Next Note.
       LDA    $E0                 ;Get the Noise Type.
       BEQ    NoiseGameOver       ;Game Over

       CMP    #$01                ;Roar
       BEQ    NoiseRoar

       CMP    #$02                ;Man Eaten.
       BEQ    EatenNoise

       CMP    #$03                ;Dying Dragon.
       BEQ    DragDieNoise

       CMP    #$04                ;Dropping Object.
       BEQ    NoiseDropObject

       CMP    #$05                ;Picking up Object.
       BEQ    NoiseGetObject

       RTS


;Noise 0 : Game Over
NoiseGameOver:
       LDA    $DF
       STA    COLUPF              ;Color-Luminance Playfield.
       STA    AUDC0               ;Audio-Control 00
       LSR
       STA    AUDV0               ;Audio-Volume 00
       LSR
       LSR
       STA    AUDF0               ;Audio-Frequency 00
       RTS

;Noise 1 : Roar
NoiseRoar:
       LDA    $DF                 ;Get noise count.
       LSR
       LDA    #$03                ;If it was even then
       BCS    SetVolume           ;Branch.

       LDA    #$08                ;Get a differnt audio control value.

SetVolume:
       STA    AUDC0               ;Set Audio Control 00.
       LDA    $DF                 ;Set the Volume to the Noise Count.
       STA    AUDV0
       LSR                        ;Divide by Four.
       LSR
       CLC
       ADC    #$1C                ;Set the Frequency.
       STA    AUDF0
       RTS


;Noise 2 : Man Eaten
EatenNoise:
       LDA    #$06
       STA    AUDC0               ;Audio-Control 00
       LDA    $DF
       EOR    #$0F
       STA    AUDF0               ;Audio-Frequency 00
       LDA    $DF
       LSR
       CLC
       ADC    #$08
       STA    AUDV0               ;Audio-Volume 00
       RTS


;Noise 3 : Dying Dragon
DragDieNoise:
       LDA    #$04                ;Set the Audio Control
       STA    AUDC0
       LDA    $DF                 ;Put the Note Count In
       STA    AUDV0               ;      the Volume.
       EOR    #$1F
       STA    AUDF0               ;Flip the Count as store
       RTS                        ;      as the frequency.


;Noise 4 : Dropping Object.
NoiseDropObject:
       LDA    $DF                 ;Get Not Count
       EOR    #$03                ;Reverse it as noise does up.
NoiseDropObject_2:
       STA    AUDF0               ;Store in Frequency for Channel 00.
       LDA    #$05
       STA    AUDV0               ;Set Volume on Channel 00.
       LDA    #$06
       STA    AUDC0               ;Set a Noise on Channel 00.
       RTS


;Noise 5 : Picking up an Object.
NoiseGetObject:
       LDA    $DF                 ;Get Not Count.
       JMP    NoiseDropObject_2   ;      and Make Same noise as Drop.


;[[image-1-3]]
;Left of Name Room
LeftOfName:
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRRRRRR
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00

;[[image-1-3]]
;Below Yellow Castle
BelowYellowCastle:
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRRRRRR   **Line Shared With Above Room ----^
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRRRRRR

;[[image-1-3]]
;Side Corridor
SideCorridor:
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $00,$00,$00
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR


;[[image-1-3]]
;Number Room Definition
NumberRoom:
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR
;[[]]

;Object #1 States (Portcullis)
PortStates:
       .byte $04,<GfxPort07,>GfxPort07          ;State 04 at FB24 -Open
       .byte $08,<GfxPort06,>GfxPort06          ;State 08 at FB22
       .byte $0C,<GfxPort05,>GfxPort05          ;State 0C at FB20
       .byte $10,<GfxPort04,>GfxPort04          ;State 10 at FB1E
       .byte $14,<GfxPort03,>GfxPort03          ;State 14 at FB1C
       .byte $18,<GfxPort02,>GfxPort02          ;State 18 at FB1A
LFB03: .byte $1C,<GfxPort01,>GfxPort01          ;State 1C at FB18 -Closed
       .byte $20,<GfxPort02,>GfxPort02          ;State 20 at FB1A
       .byte $24,<GfxPort03,>GfxPort03          ;State 24 at FB1C
       .byte $28,<GfxPort04,>GfxPort04          ;State 28 at FB1E
       .byte $2C,<GfxPort05,>GfxPort05          ;State 2C at FB20
       .byte $30,<GfxPort06,>GfxPort06          ;State 30 at FB22
LFB15: .byte $FF,<GfxPort07,>GfxPort07          ;State FF at FB24 -Open


;[[image-1-1]]
;Object #1 States 940FF (Graphic)
GfxPort01:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort02:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort03:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort04:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort05:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort06:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort07:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort08:
       .byte $FE                  ;XXXXXXX
       .byte $AA                  ;X X X X
GfxPort09:
       .byte $00

;[[image-1-3]]
;Two Exit Room
TwoExitRoom:
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR


;[[image-1-3]]
;Top of Blue Maze
BlueMazeTop:
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $00,$0C,$0C          ;        XX    XX        RR    RR
       .byte $F0,$0C,$3C          ;XXXX    XX    XXXX    RRRR    RR    RRRR
       .byte $F0,$0C,$00          ;XXXX    XX                    RR    RRRR
       .byte $F0,$FF,$3F          ;XXXXXXXXXXXXXXXXXX    RRRRRRRRRRRRRRRRRR
       .byte $00,$30,$30          ;      XX        XX    RR        RR
       .byte $F0,$33,$3F          ;XXXX  XX  XXXXXXXX    RRRRRRRR  RR  RRRR

;[[image-1-3]]
;Blue Maze #1
BlueMaze1:
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR
       .byte $00,$00,$00          ;
       .byte $F0,$FC,$FF          ;XXXXXXXXXX  XXXXXXXXRRRRRRRR  RRRRRRRRRR
       .byte $F0,$00,$C0          ;XXXX              XXRR              RRRR
       .byte $F0,$3F,$CF          ;XXXX  XXXXXXXXXX  XXRR  RRRRRRRRRR  RRRR
       .byte $00,$30,$CC          ;      XX      XX  XXRR  RR      RR
       .byte $F0,$F3,$CC          ;XXXXXXXX  XX  XX  XXRR  RR  RR  RRRRRRRR

;[[image-1-3]]
;Bottom of Blue Maze
BlueMazeBottom:
       .byte $F0,$F3,$0C          ;XXXXXXXX  XX  XX        RR  RR  RRRRRRRR
       .byte $00,$30,$0C          ;      XX      XX        RR      RR
       .byte $F0,$3F,$0F          ;XXXX  XXXXXXXXXX        RRRRRRRRRR  RRRR
       .byte $F0,$00,$00          ;XXXX                                RRRR
       .byte $F0,$F0,$00          ;XXXXXXXX                        RRRRRRRR
       .byte $00,$30,$00          ;      XX                        RR
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR

;[[image-1-3]]
;Center of Blue Maze
BlueMazeCenter:
       .byte $F0,$33,$3F          ;XXXX  XX  XXXXXXXX    RRRRRRRR  RR  RRRR
       .byte $00,$30,$3C          ;      XX      XXXX    RRRR      RR
       .byte $F0,$FF,$3C          ;XXXXXXXXXXXX  XXXX    RRRR  RRRRRRRRRRRR
       .byte $00,$03,$3C          ;          XX  XXXX    RRRR  RR
       .byte $F0,$33,$3C          ;XXXX  XX  XX  XXXX    RRRR  RR  RR  RRRR
       .byte $00,$33,$0C          ;      XX  XX  XX        RR  RR  RR
       .byte $F0,$F3,$0C          ;XXXXXXXX  XX  XX        RR  RR  RRRRRRRR

;[[image-1-3]]
;Blue Maze Entry
BlueMazeEntry:
       .byte $F0,$F3,$CC          ;XXXXXXXX  XX  XX  XXRR  RR  RR  RRRRRRRR
       .byte $00,$33,$0C          ;      XX  XX  XX        RR  RR  RR
       .byte $F0,$33,$FC          ;XXXX  XX  XX  XXXXXXRRRRRR  RR  RR  RRRR
       .byte $00,$33,$00          ;      XX  XX                RR  RR
       .byte $F0,$F3,$FF          ;XXXXXXXX  XXXXXXXXXXRRRRRRRRRR  RRRRRRRR
       .byte $00,$00,$00          ;
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR

;[[image-1-3]]
;Maze Middle
MazeMiddle:
       .byte $F0,$FF,$CC          ;XXXXXXXXXXXX  XX  XXRR  RR  RRRRRRRRRRRR
       .byte $00,$00,$CC          ;              XX  XXRR  RR
       .byte $F0,$03,$CF          ;XXXX      XXXXXX  XXRR  RRRRRR      RRRR
       .byte $00,$03,$00          ;          XX                RR
       .byte $F0,$F3,$FC          ;XXXXXXXX  XX  XXXXXXRRRRRR  RR  RRRRRRRR
       .byte $00,$33,$0C          ;      XX  XX  XX        RR  RR  RR

;[[image-1-3]]
;Maze Side
MazeSide:
       .byte $F0,$33,$CC          ;XXXX  XX  XX  XX  XXRR  RR  RR  RR  RRRR     **Line Shared With Above Room ----^
       .byte $00,$30,$CC          ;      XX      XX  XXRR  RR      RR
       .byte $00,$3F,$CF          ;      XXXXXX  XX  XXRR  RR  RRRRRR
       .byte $00,$00,$C0          ;                  XXRR
       .byte $00,$3F,$C3          ;      XXXXXXXX    XXRR    RRRRRRRR
       .byte $00,$30,$C0          ;      XX          XXRR          RR
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR

;[[image-1-3]]
;Maze Entry
MazeEntry:
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $00,$30,$00          ;      XX                        RR
       .byte $F0,$30,$FF          ;XXXX  XX    XXXXXXXXRRRRRRRRR   RR  RRRR
       .byte $00,$30,$C0          ;      XX          XXRR          RR
       .byte $F0,$F3,$C0          ;XXXXXXXX  XX      XXRR      RR  RRRRRRRR
       .byte $00,$03,$C0          ;          XX      XXRR      RR
       .byte $F0,$FF,$CC          ;XXXXXXXXXXXX  XX  XXRR  RR  RRRRRRRRRRRR

;[[image-1-3]]
;Castle Definition
CastleDef:
       .byte $F0,$FE,$15          ;XXXXXXXXXXX X X X      R R R RRRRRRRRRRR
       .byte $30,$03,$1F          ;XX        XXXXXXX      RRRRRRR        RR
       .byte $30,$03,$FF          ;XX        XXXXXXXXXXRRRRRRRRRR        RR
       .byte $30,$00,$FF          ;XX          XXXXXXXXRRRRRRRR          RR
       .byte $30,$00,$3F          ;XX          XXXXXX    RRRRRR          RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXX            RRRRRRRRRRRRRR
;[[]]

;Object Data
;Offset 0 : Room number of object.
;Offset 1 : X Coordinate of object.
;Offset 2 : Y Coordinate of object.

;Object #1 : Portcullis
PortInfo1:
       .byte $11,$4D,$31          ;Room 11, (4D, 31)
;Object #2 : Portcullis
PortInfo2:
       .byte $0F,$4D,$31          ;Room 0F, (4D, 31)
;Object #3 : Portcullis
PortInfo3:
       .byte $10,$4D,$31          ;Room 10, (4D, 31

;Object #0 : State
SurroundCurr:
       .byte $00

;Object #1 : State List
SurroundStates:
       .byte $FF,<GfxSurround,>GfxSurround          ;State FF as FC05

;[[image-1-1]]
;Object #1 : Graphic
GfxSurround:
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $FF                  ;XXXXXXXX
       .byte $00

;[[image-1-3]]
;Red Maze #1
RedMaze1:
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR
       .byte $00,$00,$00          ;
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $00,$00,$0C          ;                  XX        RR
       .byte $F0,$FF,$0C          ;XXXXXXXXXXXX  XX        RR  RRRRRRRRRRRR
       .byte $F0,$03,$CC          ;XXXX      XX  XX  XXRR  RR  RR      RRRR

;[[image-1-3]]
;Bottom of Red Maze
RedMazeBottom:
       .byte $F0,$33,$CF          ;XXXX  XX  XXXXXX  XXRR  RRRRRR  RR  RRRR     **Line Shared With Above Room ----^
       .byte $F0,$30,$00          ;XXXX  XX                        RR  RRRR
       .byte $F0,$33,$FF          ;XXXX  XX  XXXXXXXXXXRRRRRRRRRR  RR  RRRR
       .byte $00,$33,$00          ;      XX  XX                RR  RR  RRRR
       .byte $F0,$FF,$00          ;XXXXXXXXXXXX                RRRRRRRRRRRR
       .byte $00,$00,$00          ;
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR

;[[image-1-3]]
;Top of Red Maze
RedMazeTop:
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR
       .byte $00,$00,$C0          ;                  XXRR
       .byte $F0,$FF,$CF          ;XXXXXXXXXXXXXXXX  XXRR  RRRRRRRRRRRRRRRR
       .byte $00,$00,$CC          ;              XX  XXRR  RR
       .byte $F0,$33,$FF          ;XXXX  XX  XXXXXXXXXXRRRRRRRRRR  RR  RRRR
       .byte $F0,$33,$00          ;XXXX  XX  XX                RR  RR  RRRR

;[[image-1-3]]
;White Castle Entry
WhiteCastleEntry:
       .byte $F0,$3F,$0C          ;XXXX  XXXXXX  XX        RR  RRRRRR  RRRR     **Line Shared With Above Room ----^
       .byte $F0,$00,$0C          ;XXXX          XX        RR          RRRR
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $00,$30,$00          ;      XX                        RR
       .byte $F0,$30,$00          ;XXXX  XX                        RR  RRRR
       .byte $00,$30,$00          ;      XX                        RR
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR

;[[image-1-3]]
;Top Entry Room
TopEntryRoom:
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $30,$00,$00          ;XX                                    RR
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXRRRRRRRRRRRRRRRRRRRR

;[[image-1-3]]
;Black Maze #1
BlackMaze1:
       .byte $F0,$F0,$FF          ;XXXXXXXX    XXXXXXXXRRRRRRRR    RRRRRRRR
       .byte $00,$00,$03          ;            XX            RR
       .byte $F0,$FF,$03          ;XXXXXXXXXXXXXX            RRRRRRRRRRRRRR
       .byte $00,$00,$00          ;
       .byte $30,$3F,$FF          ;XX    XXXXXXXXXXXXXXRRRRRRRRRRRRRR    RR
       .byte $00,$30,$00          ;      XX                        RR

;[[image-1-3]]
;Black Maze #3
BlackMaze3:
       .byte $F0,$F0,$FF          ;XXXXXXXX    XXXXXXXXRRRRRRRR    RRRRRRRR    **Line Shared With Above Room ----^ (Mirrored Not Reversed)
       .byte $30,$00,$00          ;XX                  MM
       .byte $30,$3F,$FF          ;XX    XXXXXXXXXXXXXXMM    MMMMMMMMMMMMMM
       .byte $00,$30,$00          ;      XX                  MM
       .byte $F0,$F0,$FF          ;XXXXXXXX    XXXXXXXXMMMMMMMM    MMMMMMMM
       .byte $30,$00,$03          ;XX          XX      MM          MM
       .byte $F0,$F0,$FF          ;XXXXXXXX    XXXXXXXXMMMMMMMM    MMMMMMMM

;[[image-1-3]]
;Black Maze #2
BlackMaze2:
       .byte $F0,$FF,$FF          ;XXXXXXXXXXXXXXXXXXXXMMMMMMMMMMMMMMMMMMMM
       .byte $00,$00,$C0          ;                  XX                  MM
       .byte $F0,$FF,$CF          ;XXXXXXXXXXXXXXXX  XXMMMMMMMMMMMMMMMM  MM
       .byte $00,$00,$0C          ;                  XX                  MM
       .byte $F0,$0F,$FF          ;XXXX    XXXXXXXXXXXXMMMM    MMMMMMMMMMMM
       .byte $00,$0F,$C0          ;        XXXX      XX        MMMM      MM

;[[image-1-3]]
;Black Maze Entry
BlackMazeEntry:
       .byte $30,$CF,$CC          ;XX  XX  XXXX  XX  XXMM  MM  MMMM  MM  MM  **Line Shared With Above Room ----^ (Reversed Not Mirrored)
       .byte $00,$C0,$CC          ;        XX        XX  XXRR  RR        RR
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $00,$00,$00          ;
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
       .byte $00,$00,$00          ;
       .byte $F0,$FF,$0F          ;XXXXXXXXXXXXXXXX        RRRRRRRRRRRRRRRR
;[[]]

;Objtect #0A : State
BridgeCurr:
       .byte $00

;Object #0A : List of States
BridgeStates:
       .byte $FF,<GfxBridge,>GfxBridge          ;State FF at &FCDB

;[[image-1-1]]
;Object #0A : State FF : Graphic
GfxBridge:
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $42                  ; X    X
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $00

;[[image-1-1]]
;Object #5 State #1 Graphic :'1'
GfxNum1:
       .byte $04                  ; X
       .byte $0C                  ;XX
       .byte $04                  ; X
       .byte $04                  ; X
       .byte $04                  ; X
       .byte $04                  ; X
       .byte $0E                  ;XXX
       .byte $00
;[[]]

;Object #0B : State
KeyCurr:
       .byte $00

;Object #0B : List of States
KeyStates:
       .byte $FF,<GfxKey,>GfxKey

;[[image-1-1]]
;Object #0B : State FF : Graphic
GfxKey:
       .byte $07                  ;     XXX
       .byte $FD                  ;XXXXXX X
       .byte $A7                  ;X X  XXX
       .byte $00

;[[image-1-1]]
;Object #5 State #2 Grphic : '2'
GfxNum2:
       .byte $0E                  ; XXX
       .byte $11                  ;X   X
       .byte $01                  ;    X
       .byte $02                  ;   X
       .byte $04                  ;  X
       .byte $08                  ; X
       .byte $1F                  ;XXXXX
       .byte $00

;[[image-1-1]]
;Object #5 State #3 Graphic :'3'
GfxNum3:
       .byte $0E                  ; XXX
       .byte $11                  ;X   X
       .byte $01                  ;    X
       .byte $06                  ;  XX
       .byte $01                  ;    X
       .byte $11                  ;X   X
       .byte $0E                  ; XXX
       .byte $00
;[[]]

;Object #0E : List of States
BatStates:
       .byte $03,<GfxBat1,>GfxBat1          ;State 03 at &FD1A
LFD17: .byte $FF,<GfxBat2,>GfxBat2          ;State FF as &FD22

;[[image-1-1]]
;Object #0E : State 03 : Graphic
GfxBat1:
       .byte $81                  ;X      X
       .byte $81                  ;X      X
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $FF                  ;XXXXXXXX
       .byte $5A                  ; X XX X
       .byte $66                  ; XX  XX
       .byte $00

;[[image-1-1]]
;Object #0E : State FF : Graphic
GfxBat2:
       .byte $01                  ;       X
       .byte $80                  ;X
       .byte $01                  ;       X
       .byte $80                  ;X
       .byte $3C                  ;  XXXX
       .byte $5A                  ; X XX X
       .byte $66                  ; XX  XX
       .byte $C3                  ;XX    XX
       .byte $81                  ;X      X
       .byte $81                  ;X      X
       .byte $81                  ;X      X
       .byte $00
;[[]]

;Object #6 : States
DragonStates:
       .byte $00,<GfxDrag0,>GfxDrag0          ;State 00 at &FD3A
LFD31: .byte $01,<GfxDrag2,>GfxDrag2          ;State 01 at &FD66
LFD34: .byte $02,<GfxDrag0,>GfxDrag0          ;State 02 at &FD3A
LFD37: .byte $FF,<GfxDrag1,>GfxDrag1          ;State FF at &FD4F

;[[image-1-1]]
;Object #6 : State #00 : Graphic
GfxDrag0:
       .byte $06                  ;     XX
       .byte $0F                  ;    XXXX
       .byte $F3                  ;XXXX  XX
       .byte $FE                  ;XXXXXXX
       .byte $0E                  ;    XXX
       .byte $04                  ;     X
       .byte $04                  ;     X
       .byte $1E                  ;   XXXX
       .byte $3F                  ;  XXXXXX
       .byte $7F                  ; XXXXXXX
       .byte $E3                  ;XXX   XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C7                  ;XX   XXX
       .byte $FF                  ;XXXXXXXX
       .byte $3C                  ;  XXXX
       .byte $08                  ;    X
       .byte $8F                  ;X   XXXX
       .byte $E1                  ;XXX    X
       .byte $3F                  ;  XXXXXX
       .byte $00

;[[image-1-1]]
;Object 6 : State FF : Graphic
GfxDrag1:
       .byte $80                  ;X
       .byte $40                  ; X
       .byte $26                  ;  X  XX
       .byte $1F                  ;   XXXXX
       .byte $0B                  ;    X XX
       .byte $0E                  ;    XXX
       .byte $1E                  ;   XXXX
       .byte $24                  ;  X  X
       .byte $44                  ; X   X
       .byte $8E                  ;X   XXX
       .byte $1E                  ;   XXXX
       .byte $3F                  ;  XXXXXX
       .byte $7F                  ; XXXXXXX
       .byte $7F                  ; XXXXXXX
       .byte $7F                  ; XXXXXXX
       .byte $7F                  ; XXXXXXX
       .byte $3E                  ;  XXXXX
       .byte $1C                  ;   XXX
       .byte $08                  ;    X
       .byte $F8                  ;XXXXX
       .byte $80                  ;X
       .byte $E0                  ;XXX
       .byte $00

;[[image-1-1]]
;Object 6 : State 02 : Graphic
GfxDrag2:
       .byte $0C                  ;    XX
       .byte $0C                  ;    XX
       .byte $0C                  ;    XX
       .byte $0E                  ;    XXX
       .byte $1B                  ;   XX X
       .byte $7F                  ; XXXXXXX
       .byte $CE                  ;XX  XXX
       .byte $80                  ;X
       .byte $FC                  ;XXXXXX
       .byte $FE                  ;XXXXXXX
       .byte $FE                  ;XXXXXXX
       .byte $7E                  ; XXXXXX
       .byte $78                  ; XXXX
       .byte $20                  ;  X
       .byte $6E                  ; XX XXX
       .byte $42                  ; X    X
       .byte $7E                  ; XXXXXX
       .byte $00
;[[]]

;Object #9 : Current State
SwordCurr:
       .byte $00

;Object #9 : List of States
SwordStates:
       .byte $FF,<GfxSword,>GfxSword          ;State FF at &FD7C

;[[image-1-1]]
;Object #9 : State FF : Graphics
GfxSword:
       .byte $20                  ;  X
       .byte $40                  ; X
       .byte $FF                  ;XXXXXXXX
       .byte $40                  ; X
       .byte $20                  ;  X
       .byte $00
;[[]]

;Object #0F : State
DotCurr:
       .byte $00

;Object #0F : List of States
DotStates:
       .byte $FF,<GfxDot,>GfxDot          ;State FF at FD86

;[[image-1-1]]
;Object #0F : State FF : Graphic
GfxDot:
       .byte $80                  ;X
       .byte $00

;[[image-1-1]]
;Object #4 : State FF : Graphic
GfxAuthor:
       .byte $F0                  ;XXXX
       .byte $80                  ;X
       .byte $80                  ;X
       .byte $80                  ;X
       .byte $F4                  ;XXXX X
       .byte $04                  ;     X
       .byte $87                  ;X    XXX
       .byte $E5                  ;XXX  X X
       .byte $87                  ;X    XXX
       .byte $80                  ;X
       .byte $05                  ;     X X
       .byte $E5                  ;XXX  X X
       .byte $A7                  ;X X  XXX
       .byte $E1                  ;XXX    X
       .byte $87                  ;X    XXX
       .byte $E0                  ;XXX
       .byte $01                  ;       X
       .byte $E0                  ;XXX
       .byte $A0                  ;X X
       .byte $F0                  ;XXXX
       .byte $01                  ;       X
       .byte $40                  ; X
       .byte $E0                  ;XXX
       .byte $40                  ; X
       .byte $40                  ; X
       .byte $40                  ; X
       .byte $01                  ;       X
       .byte $E0                  ;XXX
       .byte $A0                  ;X X
       .byte $E0                  ;XXX
       .byte $80                  ;X
       .byte $E0                  ;XXX
       .byte $01                  ;       X
       .byte $20                  ;  X
       .byte $20                  ;  X
       .byte $E0                  ;XXX
       .byte $A0                  ;X X
       .byte $E0                  ;XXX
       .byte $01                  ;       X
       .byte $01                  ;       X
       .byte $01                  ;       X
       .byte $88                  ;   X   X
       .byte $A8                  ;X X X
       .byte $A8                  ;X X X
       .byte $A8                  ;X X X
       .byte $F8                  ;XXXXX
       .byte $01                  ;       X
       .byte $E0                  ;XXX
       .byte $A0                  ;X X
       .byte $F0                  ;XXXX
       .byte $01                  ;       X
       .byte $80                  ;X
       .byte $E0                  ;XXX
       .byte $8F                  ;X   XXXX
       .byte $89                  ;X   X  X
       .byte $0F                  ;    XXXX
       .byte $8A                  ;X   X X
       .byte $E9                  ;XXX X  X
       .byte $80                  ;X
       .byte $8E                  ;X   XXX
       .byte $0A                  ;    X X
       .byte $EE                  ;XXX XXX
       .byte $A0                  ;X X
       .byte $E8                  ;XXX X
       .byte $88                  ;X   X
       .byte $EE                  ;XXX XXX
       .byte $0A                  ;    X X
       .byte $8E                  ;X   XXX
       .byte $E0                  ;XXX
       .byte $A4                  ;X X  X
       .byte $A4                  ;X X  X
       .byte $04                  ;     X
       .byte $80                  ;X
       .byte $08                  ;    X
       .byte $0E                  ;    XXX
       .byte $0A                  ;    X X
       .byte $0A                  ;    X X
       .byte $80                  ;X
       .byte $0E                  ;    XXX
       .byte $0A                  ;    X X
       .byte $0E                  ;    XXX
       .byte $08                  ;    X
       .byte $0E                  ;    XXX
       .byte $80                  ;X
       .byte $04                  ;     X
       .byte $0E                  ;    XXX
       .byte $04                  ;     X
       .byte $04                  ;     X
       .byte $04                  ;     X
       .byte $80                  ;X
       .byte $04                  ;     X
       .byte $0E                  ;    XXX
       .byte $04                  ;     X
       .byte $04                  ;     X
       .byte $04                  ;     X
       .byte $00
;[[]]

;Object $4 : Author's Name
AuthorInfo:
       .byte $1E,$50,$69          ;Room 1E, (50, 69)

;Object #4 : Current State
AuthorCurr:
       .byte $00

;Object #4 : States
AuthorStates:
       .byte $FF,<GfxAuthor,>GfxAuthor          ;State FF at &FD88

;Object #10 : State
ChalliseCurr:
       .byte $00

;Object #10 : List of States
ChalliseStates:
       .byte $FF,<GfxChallise,>GfxChallise          ;State FF at &FDF3

;[[image-1-1]]
;Object #10 : State FF : Graphic
GfxChallise:
       .byte $81                  ;X      X
       .byte $81                  ;X      X
       .byte $C3                  ;XX    XX
       .byte $7E                  ; XXXXXX
       .byte $7E                  ; XXXXXX
       .byte $3C                  ;  XXXX
       .byte $18                  ;   XX
       .byte $18                  ;   XX
       .byte $7E                  ; XXXXXX
       .byte $00
;[[]]

;Object #12 : State
NullCurr:
       .byte $00

;Object #12 : List of States
NullStates:
       .byte $FF,<GfxNull,>GfxNull

;Object #12 " State FF : Graphic
GfxNull:
       .byte $00

;Object #5 Number.
NumberInfo:
       .byte $00,$50,$40          ;#5 Number: Room 00, (50,40)

;Object #5 States.
NumberStates:
       .byte $01,<GfxNum1,>GfxNum1          ;State 1 as FCF4
LFE08: .byte $03,<GfxNum2,>GfxNum2          ;State 3 as FD04
LFE0B: .byte $FF,<GfxNum3,>GfxNum3          ;State FF as FD0C

;Object #11 : State
MagnetCurr:
       .byte $00

;Object #11 : List of States
MagnetStates:
       .byte $FF,<GfxMagnet,>GfxMagnet          ;State FF at FE12

;[[image-1-1]]
;Object #11 : State FF : Graphic
GfxMagnet:
       .byte $3C                  ;  XXXX
       .byte $7E                  ; XXXXXX
       .byte $E7                  ;XXX  XXX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $C3                  ;XX    XX
       .byte $00
;[[]]


;Room Data
;Offset 0 : Low byte foom graphics data.
;Offset 1 : High byte room graphics data
;Offset 2 : Color
;Offset 3 : B&W Color
;Offset 4 : Bits 5-0 : Playfield Control
;            Bit 6 : True if right thin wall wanted.
;            Bit 7 : True if left thin wall wanted.
;Offset 5 : Room Above
;Offset 6 : Room Left
;Offset 7 : Room Down
;Offset 8 : Room Right

RoomDataTable:
LFE1B:  .byte <NumberRoom,>NumberRoom,                $66,$0A,$21,$00,$00,$00,$00      ;00; 'Number Room.                          Purple
LFE24:  .byte <BelowYellowCastle,>BelowYellowCastle,  $D8,$0A,$A1,$08,$02,$80,$03      ;01; (Top Acess) Reflected/8 Clock Ball
LFE2D:  .byte <BelowYellowCastle,>BelowYellowCastle,  $C8,$0A,$21,$11,$03,$83,$01      ;02; (Top Access)                         Green
LFE36:  .byte <LeftOfName,>LeftOfName,                $E8,$0A,$61,$06,$01,$86,$02      ;03; Left of Name
LFE3F:  .byte <BlueMazeTop,>BlueMazeTop,              $86,$0A,$21,$10,$05,$07,$06      ;04; Top of Blue Maze                         Blue
LFE48:  .byte <BlueMaze1,>BlueMaze1,                  $86,$0A,$21,$1D,$06,$08,$04      ;05; Blue Maze #1                                Blue
LFE51:  .byte <BlueMazeBottom,>BlueMazeBottom,        $86,$0A,$21,$07,$04,$03,$05      ;06; Bottom of Blue Maze                  Blue
LFE5A:  .byte <BlueMazeCenter,>BlueMazeCenter,        $86,$0A,$21,$04,$08,$06,$08      ;07; Center of Blue Maze                  Blue
LFE63:  .byte <BlueMazeEntry,>BlueMazeEntry,          $86,$0A,$21,$05,$07,$01,$07      ;08; Blue Maze Entry                        Blue
LFE6C:  .byte <MazeMiddle,>MazeMiddle,                $08,$08,$25,$0A,$0A,$0B,$0A      ;09; Maze Middle                               Invisible
LFE75:  .byte <MazeEntry,>MazeEntry,                  $08,$08,$25,$03,$09,$09,$09      ;0A; Maze Entry                              Invisible
LFE7E:  .byte <MazeSide,>MazeSide,                    $08,$08,$25,$09,$0C,$1C,$0D      ;0B; Maze Side                              Invisible      Re
LFE87:  .byte <SideCorridor,>SideCorridor,            $98,$0A,$61,$1C,$0D,$1D,$0B      ;0C; (Side Corridor)
LFE90:  .byte <SideCorridor,>SideCorridor,            $B8,$0A,$A1,$0F,$0B,$0E,$0C      ;0D; (Side Corridor)
LFE99:  .byte <TopEntryRoom,>TopEntryRoom,            $A8,$0A,$21,$0D,$10,$0F,$10      ;0E; (Top Entry Room)
LFEA2:  .byte <CastleDef,>CastleDef,                  $0C,$0C,$21,$0E,$0F,$0D,$0F      ;0F; White Castle                              White
LFEAB:  .byte <CastleDef,>CastleDef,                  $00,$02,$21,$01,$1C,$04,$1C      ;10; Black Castle                              Black
LFEB4:  .byte <CastleDef,>CastleDef,                  $1A,$0A,$21,$06,$03,$02,$01      ;11; Yellow Castle                        Yellow
LFEBD:  .byte <NumberRoom,>NumberRoom,                $1A,$0A,$21,$12,$12,$12,$12      ;12; Yellow Castle Entry                   Yellow
LFEC6:  .byte <BlackMaze1,>BlackMaze1,                $08,$08,$25,$15,$14,$15,$16      ;13; Black Maze #1                          Invisible      Re
LFECF:  .byte <BlackMaze2,>BlackMaze2,                $08,$08,$24,$16,$15,$16,$13      ;14; Black Maze #2                        Invisible      Dupl
LFED8:  .byte <BlackMaze3,>BlackMaze3,                $08,$08,$24,$13,$16,$13,$14      ;15; Black Maze #3                        Invisible      Dupl
LFEE1:  .byte <BlackMazeEntry,>BlackMazeEntry,        $08,$08,$25,$14,$13,$1B,$15      ;16; Black Maze Entry                        Invisible      R
LFEEA:  .byte <RedMaze1,>RedMaze1,                    $36,$0A,$21,$19,$18,$19,$18      ;17; Red Maze #1                              Red
LFEF3:  .byte <RedMazeTop,>RedMazeTop,                $36,$0A,$21,$1A,$17,$1A,$17      ;18; Top of Red Maze                        Red
LFEFC:  .byte <RedMazeBottom,>RedMazeBottom,          $36,$0A,$21,$17,$1A,$17,$1A      ;19; Bottom of Red Maze                        Red
LFF05:  .byte <WhiteCastleEntry,>WhiteCastleEntry,    $36,$0A,$21,$18,$19,$18,$19      ;1A; White Castle Entry                        Red
LFF0E:  .byte <TwoExitRoom,>TwoExitRoom,              $36,$0A,$21,$89,$89,$89,$89      ;1B; Black Castle Entry                        Red
LFF17:  .byte <NumberRoom,>NumberRoom,                $66,$0A,$21,$1D,$07,$8C,$08      ;1C; Other Purple Room                         Purple
LFF20:  .byte <TopEntryRoom,>TopEntryRoom,            $36,$0A,$21,$8F,$01,$10,$03      ;1D; (Top Entry Room)                        Red
LFF29:  .byte <BelowYellowCastle,>BelowYellowCastle,  $66,$0A,$21,$06,$01,$06,$03      ;1E; Name Room                              Purple


;Room differences for different levels (level 1,2,3)
RoomDiffs:
LFF32: .byte $10,$0F,$0F            ;Down from Room 01
LFF35: .byte $05,$11,$11            ;Down from Room 02
LFF38: .byte $1D,$0A,$0A            ;Down from Room 03
LFF3B: .byte $1C,$16,$16            ;U/L/R/D from Room 1B (Black Castle Room)
LFF3E: .byte $1B,$0C,$0C            ;Down from Room 1C
LFF41: .byte $03,$0C,$0C            ;Up from Room 1D (Top Entry Room)

;Objects
;Offset 0 : Low byte object information (moveable stuff)
;Offset 1 : High byte object information (moveable stuff)
;Offset 2 : Low byte to object's current state
;Offset 3 : High byte to object's current state
;Offset 4 : Low byte list of states
;Offset 5 : High byte list of states
;Offset 6 : Colour
;Offset 7 : Colour in B&W.
;Offset 8 : Size of object

Store1:
       .byte $D9                        ;0      ;#0 Invisible Surround Offsets..      00
Store2:
       .byte $00
Store3:
       .byte <SurroundCurr
Store4:
       .byte >SurroundCurr
Store5:
       .byte <SurroundStates
Store6:
       .byte >SurroundStates
Store7:
       .byte $28
Store8:
       .byte $0C
Store9:
       .byte $07

LFF4D:       .byte <PortInfo1,>PortInfo1,    $C8,$00,                      <PortStates,>PortStates,          $00,$00,$00      ;#1 Portcullis #1       Black            09
LFF56:       .byte <PortInfo2,>PortInfo2,    $C9,$00,                      <PortStates,>PortStates,          $00,$00,$00      ;#2 Portcullis #2       Black            12
LFF5F:       .byte <PortInfo3,>PortInfo3,    $CA,$00,                      <PortStates,>PortStates,          $00,$00,$00      ;#3 Portcullis #3       Black            1B
LFF68:       .byte <AuthorInfo,>AuthorInfo,  <AuthorCurr,>AuthorCurr,      <AuthorStates,>AuthorStates,      $CB,$00,$00      ;#4 Name                Flash            24
LFF71:       .byte <NumberInfo,>NumberInfo,  $DD,$00,                      <NumberStates,>NumberStates,      $C8,$00,$00      ;#5 Number              Green            2D
LFF7A:       .byte $A4,$00,                  $A8,$00,                      <DragonStates,>DragonStates,      $36,$0E,$00      ;#6 Dragon #1           Red              36
LFF83:       .byte $A9,$00,                  $AD,$00,                      <DragonStates,>DragonStates,      $1A,$06,$00      ;#7 Dragon #2           Yellow           3F
LFF8C:       .byte $AE,$00,                  $B2,$00,                      <DragonStates,>DragonStates,      $C8,$00,$00      ;#8 Dragon #3           Green            48
LFF95:       .byte $B6,$00,                  <SwordCurr,>SwordCurr,        <SwordStates,>SwordStates,        $1A,$06,$00      ;#9 Sword               Yellow           51
LFF9E:       .byte $BC,$00,                  <BridgeCurr,>BridgeCurr,      <BridgeStates,>BridgeStates,      $66,$02,$07      ;#0A Bridge             Purple           5A
LFFA7:       .byte $BF,$00,                  <KeyCurr,>KeyCurr,            <KeyStates,>KeyStates,            $1A,$06,$00      ;#0B Key #01            Yellow           63
LFFB0:       .byte $C2,$00,                  <KeyCurr,>KeyCurr,            <KeyStates,>KeyStates,            $0E,$0E,$00      ;#0C Key #02            White            6C
LFFB9:       .byte $C5,$00,                  <KeyCurr,>KeyCurr,            <KeyStates,>KeyStates,            $00,$00,$00      ;#0D Key #03            Black            75
LFFC2:       .byte $CB,$00,                  $CF,$00,                      <BatStates,>BatStates,            $00,$00,$00      ;#0E Bat                Black            7E
LFFCB:       .byte $A1,$00,                  <DotCurr,>DotCurr,            <DotStates,>DotStates,            $08,$08,$00      ;#0F Black Dot          Light Gray       87
LFFD4:       .byte $B9,$00,                  <ChalliseCurr,>ChalliseCurr,  <ChalliseStates,>ChalliseStates,  $CB,$06,$00      ;#10 Challise           Flash            90
LFFDD:       .byte $B3,$00,                  <MagnetCurr,>MagnetCurr,      <MagnetStates,>MagnetStates,      $00,$06,$00      ;#11 Magnet             Black            99
LFFE6:       .byte $BC,$00,                  <NullCurr,>NullCurr,          <NullStates,>NullStates,          $00,$00,$00      ;#12 Null               Black            A2

;Not Used
LFFEF: .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;6502 Vectors (Not Used??
LFFFA:  .byte $00,$F0
LFFFC:  .byte $00,$F0
LFFFE:  .byte $00,$F0
