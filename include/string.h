#ifndef _OS_STRING_H_
#define _OS_STRING_H_

// p-pointer,i-int
PUBLIC void * memCpy( void* pDst, void* pSrc, int size );
PUBLIC void dispAChar( char ch );
PUBLIC void dispStr( char* pStr);

PUBLIC void memSet( void* pDstm, char ch, int size);
#endif