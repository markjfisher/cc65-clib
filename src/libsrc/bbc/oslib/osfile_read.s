
;	Dominic Beesley 2005
;	OSLib implementation for BBC/Master Target	
;
;	osfile_read
;

		.include "osfile.inc"
		.import osfile_alloc_block
		.import osfile_store_fn
		.import	osfile_callosfile
		.import osfile_ret_read_delete_load
		.import ldaxysp, addysp
		.importzp c_sp
		.export _osfile_read

;extern os_error *xosfile_read (char const *file_name,		2
;      fileswitch_object_type *obj_type,			1
;      bits32 *load_addr,					2
;      bits32 *exec_addr,					2
;      long *size,						2
;      fileswitch_attr *attr);					2
;extern fileswitch_object_type osfile_read (char const *file_name,	2 8
;      bits32 *load_addr,						2 6
;      bits32 *exec_addr,						2 4
;      long *size,							2 2
;      fileswitch_attr *attr);						2 0

		.proc _osfile_read
		
		jsr	osfile_alloc_block		; Allocates OSFILE block + filename buffer, sets up ptr2
		
		; Get filename pointer (offset by 18-byte OSFILE block + 128-byte filename buffer)  
		ldy	#18 + 128 + 9
		jsr	ldaxysp
		jsr	osfile_store_fn

		lda	#OSFile_Read
		jsr	osfile_callosfile

		; Clean up the 128-byte filename buffer
		lda	#128
		jsr	addysp

		ldy	#18 + 10
		jmp	osfile_ret_read_delete_load

		.endproc

