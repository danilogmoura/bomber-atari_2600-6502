    processor 6502
    
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Iniciar na posição $80 um segmento na memória RAM para a declaração das variáveis
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

JetXPos         byte        ; posição X do jogador 0
JetYPos         byte        ; posição Y do jogador 0
BomberXPos      byte        ; posição X do jogador 1
BomberYPos      byte        ; posição Y do jogador 1

JetSpritePtr    word        ; ponteiro para a sprite do jogador 0
JetColorPtr     word        ; ponteiro para a cor do jogador 0
BomberSpritePtr word        ; ponteiro para a sprite do jogador 1
BomberColorPtr  word        ; ponteiro para a cor do jogador 1

JetAnimOffset   byte        ; offset para a animação do jogador 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constantes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9              ; altura da sprite do jogador 0 (linhas na lookup table)
BOMBER_HEIGHT = 9           ; altura da sprite do jogador 1 (linhas na lookup table)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Iniciar nosso segmento de código na ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg code
    org $F000

Reset:
    CLEAN_START             ; Macro para limpar a memória e os registradores
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicialização das variaveis e dos resgistradores TIA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #10
    sta JetYPos             ; JetYPos = 10
    lda #60
    sta JetXPos             ; JetXPos = 60

    lda #83
    sta BomberYPos          ; BomberYPos = 83
    lda #54
    sta BomberXPos          ; BomberXPos = 54

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicialização das variaveis referentes as sprites (lookup table)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #<JetSprite         ; carrega o byte menos significativo do endereço da sprite do jogador 0
    sta JetSpritePtr        ; salva o endereço da sprite do jogador 0
    lda #>JetSprite         ; carrega o byte mais significativo do endereço da sprite do jogador 0
    sta JetSpritePtr+1      ; salva o endereço da sprite do jogador 0

    lda #<JetColor          ; carrega o byte menos significativo do endereço da cor do jogador 0
    sta JetColorPtr         ; salva o endereço da cor do jogador 0
    lda #>JetColor          ; carrega o byte mais significativo do endereço da cor do jogador 0
    sta JetColorPtr+1       ; salva o endereço da cor do jogador 0

    lda #<BomberSprite      ; carrega o byte menos significativo do endereço da sprite do jogador 1
    sta BomberSpritePtr     ; salva o endereço da sprite do jogador 1
    lda #>BomberSprite      ; carrega o byte mais significativo do endereço da sprite do jogador 1
    sta BomberSpritePtr+1   ; salva o endereço da sprite do jogador 1

    lda #<BomberColor       ; carrega o byte menos significativo do endereço da cor do jogador 1
    sta BomberColorPtr      ; salva o endereço da cor do jogador 1
    lda #>BomberColor       ; carrega o byte mais significativo do endereço da cor do jogador 1
    sta BomberColorPtr+1    ; salva o endereço da cor do jogador 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; iniciar o loop de exibição principal e a renderização do quadro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Processamento da entrada do joystick do jogador 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    lda #%00010000          ; jogador 1 pressionou o botão UP?
    bit SWCHA
    bne CheckP0Down         ; se sim, vai para o próximo teste
    inc JetYPos             ; se não, incrementa a posição Y do jogador 0
    lda #00                 ; carrega 0
    sta JetAnimOffset       ; offset para a animação do jogador 0 usando a primeira sprite

CheckP0Down:
    lda #%00100000          ; jogador 1 pressionou o botão DOWN?
    bit SWCHA
    bne CheckP0Left         ; se sim, vai para o próximo teste
    dec JetYPos             ; se não, decrementa a posição Y do jogador 0
    lda #00                 ; carrega 0
    sta JetAnimOffset       ; offset para a animação do jogador 0 usando a primeira sprite

CheckP0Left:
    lda #%01000000          ; jogador 1 pressionou o botão LEFT?
    bit SWCHA
    bne CheckP0Right        ; se sim, vai para o próximo teste
    dec JetXPos             ; se não, decrementa a posição X do jogador 0
    lda JET_HEIGHT          ; 9
    sta JetAnimOffset       ; offset para a animação do jogador 0 usando a segunda sprite

CheckP0Right:
    lda #%10000000          ; jogador 1 pressionou o botão RIGHT?
    bit SWCHA
    bne EndInputCheck       ; se sim, vai para o próximo teste
    inc JetXPos             ; se não, incrementa a posição X do jogador 0
    lda JET_HEIGHT          ; 9
    sta JetAnimOffset       ; offset para a animação do jogador 0 usando a segunda sprite

EndInputCheck:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cálculos para atualizar a posição do proximo frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateBomberPosition:
    lda BomberYPos          ; carrega a posição Y do jogador 1
    clc                     ; limpa o bit de carry
    cmp #00                 ; compara a posicao Y do jogador 1 com 0
    bmi .ResetBomberPosition; se o resultado for menor que 0, reseta a posição Y do jogador 1
    dec BomberYPos          ; se não, decrementa a posição Y do jogador 1
    jmp EndPositionUpdate   ; vai para o final do loop
.ResetBomberPosition
    lda #96
    sta BomberYPos          ; reseta a posição Y do jogador 1 para 96

EndPositionUpdate:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cálculos e tarefas realizadas no pré-VBlank
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda JetXPos             ; carrega a posição X do jogador 0
    ldy #00
    jsr SetObjetctXPos      ; chama a subrotina para mover o jogador 0 na posição X

    lda BomberXPos          ; carrega a posição X do jogador 1
    ldy #01
    jsr SetObjetctXPos      ; chama a subrotina para mover o jogador 1 na posição X

    sta WSYNC               ; espera pela scanline
    sta HMOVE               ; move os objetos na posição X - Aplica o deslocamento FINO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicia o VSYNC e o VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #02
    sta VBLANK              ; ativa o VBLANK
    sta VSYNC               ; ativa o VSYNC

    REPEAT 3
        sta WSYNC
    REPEND

    lda #00
    sta VSYNC               ; desativa o VSYNC
    REPEAT 37
        sta WSYNC           ; gerar 37 scanlines de VBLANK recomendas pelo TIA
    REPEND
    sta VBLANK              ; desativa o VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exibe as 96 scanlines visíveis
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLine:
    lda #$84                ; seta a cor azul para o background
    sta COLUBK              ; seta a cor do background

    lda #$C2                ; seta a cor verde para o playfild/grama (PF0, PF1, PF2)
    sta COLUPF              ; seta a cor do playfield

    lda #%00000001
    sta CTRLPF              ; seta o bit 0 do registrador CTRLPF para habilitar o playfield (Refletir)

    lda #$F0
    sta PF0                 ; configuração padrão de bits para o playfield 0
    
    lda #$FC
    sta PF1                 ; configuração padrão de bits para o playfield 1

    lda #0
    sta PF2                 ; configuração padrão de bits para o playfield 2

    ldx #96                 ; contador X para o restante das scanlines
.GameLineVisible:
.AreWeInsideJetSprite:
    txa                     ; carrega o contador X
    sec                     ; seta o bit de carry
    sbc JetYPos             ; subtrai a posição Y do jogador 0 do contador X
    cmp JET_HEIGHT          ; compara o resultado com a altura da sprite do jogador 0
    bcc .DrawSrpiteP0       ; se o resultado for menor que a altura da sprite do jogador 0, desenha a sprite
    lda #00                 ; se não, carrega 0

.DrawSrpiteP0:
    clc                    ; limpa o bit de carry
    adc JetAnimOffset      ; adiciona o offset da animação do jogador 0

    tay                     ; carrega o contador Y
    lda (JetSpritePtr),y    ; carrega o byte da sprite do jogador 0
    sta WSYNC               ; espera pela scanline
    sta GRP0                ; desenha a sprite do jogador 0
    lda (JetColorPtr),y     ; carrega o byte da cor do jogador 0
    sta COLUP0              ; seta a cor do jogador 0

.AreWeInsideBomberSprite:
    txa                     ; carrega o contador X
    sec                     ; seta o bit de carry
    sbc BomberYPos          ; subtrai a posição Y do jogador 1 do contador X
    cmp BOMBER_HEIGHT       ; compara o resultado com a altura da sprite do jogador 1
    bcc .DrawSrpiteP1       ; se o resultado for menor que a altura da sprite do jogador 1, desenha a sprite
    lda #00                 ; se não, carrega 1

.DrawSrpiteP1:
    tay                     ; carrega o contador Y

    lda #%00000101
    sta NUSIZ1              ; seta o tamanho da sprite do jogador 1

    lda (BomberSpritePtr),y ; carrega o byte da sprite do jogador 1
    sta WSYNC               ; espera pela scanline
    sta GRP1                ; desenha a sprite do jogador 1
    lda (BomberColorPtr),y  ; carrega o byte da cor do jogador 1
    sta COLUP1              ; seta a cor do jogador 1

    dex                     ; decrementa o contador
    bne .GameLineVisible    ; se X != 0, repete o loop

    lda #00
    sta JetAnimOffset       ; reseta o offset da animação do jogador 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Gera as 30 scanlines do overscan (VBLANK), recomendado
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Overscan:
    lda #02
    sta VBLANK              ; ativa o VBLANK
    REPEAT 30
        sta WSYNC           ; Gera as 30 scanlines do overscan (VBLANK)
    REPEND

    lda #00
    sta VBLANK              ; desativa o VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop principal do jogo, volta para o inicio do loop de exibição principal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame          ; vai para o proximo frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subrotina para mover os objetos na posicao horizontal com deslocamento FINO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A é a posição alvo da coordenada X em pixels do nosso objeto
;; Y é o tipo de objeto (0 = Jet, 1 = Bomber, 2 = missile0, 3 = missile1, 4 = ball)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjetctXPos subroutine
    sta WSYNC               ; espera pela scanline
    sec                     ; certifique-se que o bit de carry esteja definido antes da subtração    
.Div15Loop
    sbc #15                 ; subtrai 15 da posição alvo
    bcs .Div15Loop          ; se o resultado for maior que 15, repete o loop
    eor #07                 ; inverte os 3 bits menos significativos
    asl
    asl
    asl
    asl                     ; 4 shift left para multiplicar por 16
    sta HMP0,Y              ; salva o resultado no registrador HMxx
    sta RESP0,Y             ; corrija a posição do objeto em incrementos de 15 etapas
    rts                     ; retorna da subrotina

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define o array de bytes para a sprite
;; IMPORTANTE!!! 
;; Devem estar sempre nos endereços finais da ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JetSprite:
    .byte #%00000000        ;
    .byte #%00010100        ;   # #
    .byte #%01111111        ; #######
    .byte #%00111110        ;  #####
    .byte #%00011100        ;   ###
    .byte #%00011100        ;   ###
    .byte #%00001000        ;    #
    .byte #%00001000        ;    #
    .byte #%00001000        ;    #

JetSpriteTurn:
    .byte #%00000000        ;
    .byte #%00001000        ;    #
    .byte #%00111110        ;  #####
    .byte #%00011100        ;   ###
    .byte #%00011100        ;   ###
    .byte #%00011100        ;   ###
    .byte #%00001000        ;    #
    .byte #%00001000        ;    #
    .byte #%00001000        ;    #

BomberSprite:
    .byte #%00000000        ;
    .byte #%00001000        ;    #
    .byte #%00001000        ;    #
    .byte #%00101010        ;  # # #
    .byte #%00111110        ;  #####
    .byte #%01111111        ; #######
    .byte #%00101010        ;  # # #
    .byte #%00001000        ;    #
    .byte #%00011100        ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completa a ROM com 4KB, exigência do 6502
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC               ; move para a posicão $FFFC
    .word Reset             ; Endereço de reset $FFFC (o 6502 inicia a execução do programa nesse endereço)
    .word Reset             ; Endereço de IRQ (interrupção) $FFFE