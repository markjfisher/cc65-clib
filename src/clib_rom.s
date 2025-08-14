	.include 	"clib_imports.inc"

	.segment 	"HEADER"

	.byte 		0,0,0		; language entry
	jmp clib_svc			; service
	.byte		$81		; dummy rom type
	.byte		<(clib_copyright)
	.byte		$01		; version
clib_rom_tite:
	.byte		"cc65 CLIB"
clib_vers_str:
	.byte		0,"0.01"
clib_copyright:
	.byte		0,"(C)"
	.byte		" Copyright Dossy 2020, fenrock 2025",0		

	.code
	.include	"clib_imports_jmp.inc"

clib_svc:
	rts