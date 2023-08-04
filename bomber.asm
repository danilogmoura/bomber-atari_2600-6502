    processor 6502
    
    include "../dasm/machines/atari2600/vcs.h"
    include "../dasm/machines/atari2600/macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Iniciar na posição $80 um segmento na memória RAM para a declaração das variáveis
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

JetXPox         byte        ; posição X do jogador 0
JetYPox         byte        ; posição Y do jogador 0

BomberXPos      byte        ; posição X do jogador 1
BomberYPos      byte        ; posição Y do jogador 1

JetSpritePtr    word        ; ponteiro para a sprite do jogador 0
JetColorPtr     word        ; ponteiro para a cor do jogador 0

BomberSpritePtr word        ; ponteiro para a sprite do jogador 1
BomberColorPtr  word        ; ponteiro para a cor do jogador 1

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
    sta JetYPox             ; JetYPos = 10
    lda #60
    sta JetXPox             ; JetXPos = 60

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
;; Exibe as 192 scanlines visíveis
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

    ldx #192                ; contador X para o restante das scanlines
.GameLineVisible:
    sta WSYNC               ; espera o inicio da próxima scanline
    dex                     ; decrementa o contador
    bne .GameLineVisible    ; se X != 0, repete o loop

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