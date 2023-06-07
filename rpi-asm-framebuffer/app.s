	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32

	.equ GPIO_BASE,    0x3f200000
	.equ GPIO_GPFSEL0, 0x00
	.equ GPIO_GPLEV0,  0x34

	.globl main

main:
	// x0 contiene la direccion base del framebuffer
	mov x20, x0 // Guarda la dirección base del framebuffer en x20
	//---------------- CODE HERE ------------------------------------

	movz x10, 0xA0, lsl 16
	movk x10, 0xBFD4, lsl 00

	mov x3, 1

	mov x2, SCREEN_HEIGH         // Y Size
	sub x2, x2, 110
loop1:
	mov x1, SCREEN_WIDTH         // X Size
loop0:
	stur w10,[x0]  // Colorear el pixel N
	add x0,x0,4    // Siguiente pixel
	sub x1,x1,1    // Decrementar contador X
	cbnz x1,loop0  // Si no terminó la fila, salto
	sub x2,x2,1    // Decrementar contador Y
	bl Wait
	cbnz x2,loop1  // Si no es la última fila, salto
	cbz x3, endl0
	mov x3, 0
	movz x10, 0xFF, lsl 16
	movk x10, 0xFFFF, lsl 00
	mov x2, 110
endl0:
	cbnz x2,loop1


	// Ejemplo de uso de gpios
	mov x9, GPIO_BASE

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str wzr, [x9, GPIO_GPFSEL0]

	// Lee el estado de los GPIO 0 - 31
	ldr w10, [x9, GPIO_GPLEV0]

	// And bit a bit mantiene el resultado del bit 2 en w10 (notar 0b... es binario)
	// al inmediato se lo refiere como "máscara" en este caso:
	// - Al hacer AND revela el estado del bit 2
	// - Al hacer OR "setea" el bit 2 en 1
	// - Al hacer AND con el complemento "limpia" el bit 2 (setea el bit 2 en 0)
	and w11, w10, 0b00000010

	// si w11 es 0 entonces el GPIO 1 estaba liberado
	// de lo contrario será distinto de 0, (en este caso particular 2)
	// significando que el GPIO 1 fue presionado

	//---------------------------------------------------------------
	// Infinite Loop

	mov x0, x20                        		// map address
    movz x1, 187, lsl 00                       // center position x
    movz x2, 296, lsl 00                       // center position y
    movz x3, 77, lsl 00
	movz x10, 0, lsl 00
    bl Circle


    movz x2, 190, lsl 00                       // center position y
    movz x3, 46, lsl 00
	bl Circle

	movz x1, 187, lsl 00                       // center position x
    movz x2, 296, lsl 00                       // center position y
    movz x3, 53, lsl 00
	movz x10, 0x00FF, lsl 16
	movk x10, 0xFFFF, lsl 00
    bl Circle




InfLoop:
	b InfLoop

Wait:
	movz x7, 0x10, lsl 16

WLoop:
	sub x7, x7, 1
	cbnz x7, WLoop
	ret

/********************************************************/
/*                 drawing a circle                     */
/********************************************************/
/* x0 ->directon del framebuffer 	*/
/* x1 ->position X0  				*/
/* x2 ->position Y0				 	*/
/* x3 ->ratio						*/
/* x10->color						*/

Circle:
	mov x4, x3  	//x4 -> X
	mov x5, xzr  	//x5 -> Y
	mov x6, xzr		//x6 -> error
	mov x11, lr
	sub x3, x3, 1

CirLoop1:
	add x7, x1, x4	//x7 -> X0+X
	add x8, x2, x5	//x8 -> Y0+Y
	bl CirSetPoint
	add x7, x1, x5	//x7 -> X0+Y
	add x8, x2, x4	//x8 -> Y0+X
	bl CirSetPoint
	sub x7, x1, x5	//x7 -> X0-Y
	bl CirSetPoint
	sub x7, x1, x4	//x7 -> X0-X
	add x8, x2, x5	//x8 -> Y0+Y
	bl CirSetPoint
	sub x8, x2, x5	//x8 -> Y0-Y
	bl CirSetPoint
	sub x7, x1, x5	//x7 -> X0-Y
	sub x8, x2, x4	//x8 -> Y0-X
	bl CirSetPoint
	add x7, x1, x5	//x7 -> X0+Y
	bl CirSetPoint
	add x7, x1, x4	//x7 -> X0+X
	sub x8, x2, x5	//x8 -> Y0-Y
	bl CirSetPoint

	cmp x6, 1
	b.pl Cir2
	add x5, x5, 1
	lsl x7, x5, 02
	add x7, x7, 1
	add x6, x6, x7

Cir2:
	cmp x6, xzr
	b.mi Cir3
	sub x4, x4, 1
	lsl x7, x4, 02
	add x7, x7, 1
	sub x6, x6, x7

Cir3:
	cmp x4, x5
	b.pl CirLoop1
	mov lr, x11
	cbnz x3, Circle
	ret

CirSetPoint:
	add x7, x7, 1
	movz x9, 640, lsl 00
	mul x9, x9, x8
	add x9, x9, x7
	lsl x9, x9, 02
	add x9, x9, x0
	stur w10,[x9]

	sub x7, x7, 2
	movz x9, 640, lsl 00
	mul x9, x9, x8
	add x9, x9, x7
	lsl x9, x9, 02
	add x9, x9, x0
	stur w10,[x9]

	add x7, x7, 1
	add x8, x8, 1 
	movz x9, 640, lsl 00
	mul x9, x9, x8
	add x9, x9, x7
	lsl x9, x9, 02
	add x9, x9, x0
	stur w10,[x9]

	sub x8, x8, 2
	movz x9, 640, lsl 00
	mul x9, x9, x8
	add x9, x9, x7
	lsl x9, x9, 02
	add x9, x9, x0
	stur w10,[x9]
	ret

/********************************************************/
/*              drawing a triangle-rectangle            */
/********************************************************/
/* x0 ->directon del framebuffer 	*/
/* x1,x2 ->position P1(X,Y)  		*/
/* x3,x4 ->position P2(X,Y)		 	*/
/* x10->color						*/

TriangleRec:
	cmp x1, x3
	movz x5, 1, lsl 00
	b.mi tri0
	sub x5, 2
tri0:
	


