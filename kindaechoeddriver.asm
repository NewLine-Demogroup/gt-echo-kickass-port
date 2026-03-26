// Echo nmi by Geir Tjelta / Shape / MON - KickAss Port by D/V / NewLine
// This routine adapted for the Artillery 100% demo.
// ----------------------------------------------------------------
// This routine has been modified to work with GoatTracker 2 tunes.
// When composing, put whatever you want to echo in channel 3, and
// to minimise distortion, use pulse waves and noise when possible.
// Triangles and sawtooth will work, but with great distortion.
// 
// In order to use a GT tune with this echo routine, export it as a
// .bin file with the following options: 
// 		Buffered SID-writes		Yes
// 		Use zeropage ghostregs	Yes
// The start and zeropage address can be any address you like.
// Remember the start and zeropage addresses as we will need it.
// At the Packer/Relocator screen, select the format:
//		BIN - Raw binary format (no startaddress)
// Export your GT2 tune. You will now have a BIN file of the tune.
// In this assembly source file, edit base_zp and base_play to the
// start and zeropage addresses of the tune. Locate the line where
// the player data is imported. It should be "* = base_play".
// Once you are done, assemble the program as a PRG with 64tass.
// After this, you can test it in an emulator or convert it now.
// 
// To convert the resulting PRG into a SID, use the bundled tool
// "SIDEdit" to convert it. Load the PRG file into it, and edit:
//		Environment		PlaySID -> Real C64
// Edit name, author, released and the flags too if you wish.
// If you edit the flags, it is recommended that you pick:
//		Intended for SID chip type		6581
// Most players will acknowledge this and play it with the 6581.
// After editing, save it as a SID. The SID must be an RSID
// after you edit it. If you really want to double check, open it 
// in a hex editor of your choice, and look for RSID at the 
// beginning of the file.
//
// ! NOTE ! It will not work on JSIDPlay (last time I checked)
// and it will not work on sidplayfp without the BASIC and
// KERNAL ROMs! The routine relies on jumping to the KERNAL
// IRQ handler after running the song, and there is a BASIC stub
// to run the song at startup. Do note, sidplayfp can only play
// the PRG properly. I have no idea why it does not play the SID.
// Distribute your song in both PRG and SID format. If you can,
// recommend people use the PRG format over the SID format.
// I have included the ROMs for your convenience. If VICE can do it,
// why can I not? Put them in the same folder as sidplayfp.
// ----------------------------------------------------------------

.const base_zp		= $e5 // GT2 base ghost zp (set to whatever your song uses)
.const base_play	= $1000 // GT2 base player address (set to whatever your song uses)
.const play_d418	= base_zp+$18 // 19f8
.const irqzero		= $40

*= $0801 

BasicUpstart2(start)

*= $080d
start:
	sei
	lda #<irq
	sta $0314
	lda #>irq
	sta $0315
	lda #$1b
	sta $d011
	lda #0
	sta $d012
	lda #$7f
	sta $dc0d
	lda #1
	sta $d01a
	sta $d019
	lda #0
	jsr $1000
	cli

	jsr init_sid_nmi
	jsr set_sid_zp
hold:
	jmp hold

set_sid_zp:
	ldx #$17
copy:
	lda base_zp,x
	sta $d400,x
	dex
	bpl copy
	rts

init_sid_nmi:
	lda #$40
	sta $dd0c
	lda #<sid_nmi
	sta $0318
	lda #>sid_nmi
	sta $0319

	lda #0
	sta irqzero
	lda #$70
	sta irqzero+1
	
	lda $d012
	bne *-3
	sta $dd05
	sta $dd0e
	sta irqzero
	tay
	lda #$0d
memdel:
	sta (irqzero),y	//clear echo area
	iny
	bne memdel
	inc irqzero+1
	bpl memdel

	lda #0
	sta samp+1		//7000
	lda #$70
	sta samp+2

	lda #0
	sta samp2+1
	lda #$73 // echo delay ($70 = no echo, $71-$7f = echo)
	sta samp2+2

	lda #$c0 //c0
	sta $dd04
	lda #$00
	sta $dd05
	

	lda #$81
	sta $dd0d
	lda $dd0d
	lda #$11
	sta $dd0e
	
	rts

sid_nmi:
	sta areg+1
	lda $d41c
	and #$f0
	sta clickp+1
	lda $d41b
	lsr
	lsr
	lsr
	lsr
clickp:
	ora #0
	sta clickp2+1
clickp2:
	lda nmitable

samp:
	sta $f000
	sta $f000

samp2:	
	lda $f000
nmi_band:
	ora #$10  //resonance ONLY from player
	sta $d418

	lda #$70
	inc samp+1
	bne nmi_bne1
	inc samp+2
	bpl nmi_bne1
	sta samp+2
nmi_bne1:
	inc samp2+1
	bne nmi_bne2
	inc samp2+2
	bpl nmi_bne2
	sta samp2+2
nmi_bne2: 
areg:
	lda #0
	jmp $dd0c

irq:
	lda #1
	sta $d019
	lda #0
	jsr $1003
	lda play_d418
	and #$f0
	sta nmi_band+1
	jsr set_sid_zp
	jmp $ea31

//-----------------------------
	*= (*+$ff)&$ff00
//-----------------------------
nmitable:

	.byte $0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d  //00

	.byte $0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0c  //10

	.byte $0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0b  //20

	.byte $0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0a,$0d,$0b  //30

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$0a  //40

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$0a  //50

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$09  //60

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$09  //70

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$09  //80

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$09  //90

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$09  //a0

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$08  //b0

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$08  //c0

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$08  //d0

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$09  //e0

	.byte $0d,$0c,$0b,$0c,$0b,$0a,$09,$08,$09,$08,$09,$0a,$0b,$0c,$0a,$09  //f0
	
* = $1000
	// the SID to your song here! (must be exported in GT2)
	// the SID export must have ghost ZP address on!
	// set base_zp variable to where your SID ghost ZP addresses start
	.import binary ""
	
		