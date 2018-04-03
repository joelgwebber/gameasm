PrintDisplay:
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
