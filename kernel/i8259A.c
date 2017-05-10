#include "const.h"
#include "port.h"
#include "string.h"
#include "lib.h"
#include "global.h"
#include "i8259A.h"
/*
*　FIEL NAME ：i8259.c
* 中断处理
* 
*/

PUBLIC void init8259A()
{
	/*
	* 对于ICW的设置要遵循如下规范，
	* 1,按照ICW1,ICW2,ICW3,ICW4的顺序设置
	* 2,ICW1为偶地址端口，ICW2,ICW3,ICW4均为奇地址端口。其中是否需要设置ICW3,ICW4，需要根据ICW1控制字的内容
	* 3,只有控制字的顺序有要求，而主从片的设置顺序并没有要求
	* 4,x86计算机中的8258A的电路形成了定式，主片端口位20h,21h,从片的端口为A0h,A1h。
	* 5,16/32位系统才需要设置ICW４.级联时才需要设置ICW3。
	*/


	/* Set ICW1
	* ICW1主要用于设置工作模式，包括端口号，中断触发方式，中断向量类型，是否级联，是否使用ICW4
	* D7~D5: 在16位和32位系统中无定义，可以为0，也可以为1。也有资料上说，PC系统必须位０．？
	* D4: １－ICW1,0－OCW2或OCW3,这是因为这三个锁存器使用同一端口所致的。该位便是用于区分写入的锁存器的
	* D3: 设置触发中断的信号方式。0:上升沿触发，如果是1，则为电平触发，要求中断得到响应后，及时撤出高电平，
	* 	  如果在进入中断处理过程，且开放中断前未去掉高电平，可能引起第二次中断。
	* E2: 中断向量的长度，１为4字节中断向量，0为８字节中断向量。
	* D1: 用于指示该片是否级联，1为单片，级联时主从片均为0．
	* D0: 是否使用ICW4,在16/32位系统中必须使用ICW4,所以必须为１．
	*/
	writePort( INTE_MASTER_EVEN, 0x11 ); // 主片
	writePort( INTE_SLAVE_EVEN,  0x11 ); // 从片

	/* Set ICW2
	* 设置中断向量号和中断输入口的对应关系
	* 中断的向量号的高５位由输入数字的高五位确定，低三位由引入中断请求的输入口IR确定，组合成８位的中断向量号
	* 如20h,21h,25h设置出的中断向量号一样，因为低三位并不是由设置字决定。
	*/
	writePort( INTE_MASTER_ADD, INTE_VECTOR_IRQ0 ); // 主片
	writePort( INTE_SLAVE_ADD,  INTE_VECTOR_IRQ8 ); // 从片

	/* Set ICW3
	* 标识主从片,只有级联时8259A才有意义。只有ICW1:D1=0时才设置ICW3.而ICW3的格式与该片是主片还是从片有关。
	* 主片：
	* D7~D0: 与IR7~IR0对应，如果某引脚连接的从片，则ICW3对应的位应设置为１，否则设置为0．
	* 
	* 从片：
	* D7~D3: 不用,为了向以后的产品兼容，设置为0.
	* D2~D1: 从片输出段INT连接到主片的哪个引脚。如连接到IR5上，则D2~D0应设置为101.
	*/
	writePort( INTE_MASTER_ADD, 0x4 ); // 主片
	writePort( INTE_SLAVE_ADD,  0x2 ); // 从片

	/* Set ICW4
	* 中断触发，嵌套，结束方式
	* D7~D5:　均为0,用来做ICW4的标识
	* D4: 1-特殊全嵌套方式
	* D3~D2: D3=1-缓冲方式，在多片系统中常采用缓冲方式。此时，D2=1表示本片位主片，D2=0表示本片为从片。
	* 		D3=0,非缓冲方式，此时D2不起作用。
	* D1: 中断结束方式，１－中断自动结束。０－需设置标识位结束。
	* D0: 1-当前系统为非８位系统
	*/
	writePort( INTE_MASTER_ADD, 1 ); // 主片
	writePort( INTE_SLAVE_ADD,  1 ); // 从片



	/*
	* OCW称为操作控制字，一共有三个。操作命令字是在应用程序中设置的，设置次序没有要求。
	* 1,OCW1必须写入奇地址端口，OCW2,OCW3必须写入偶地址
	* 这里先关闭键盘中断，打开时钟中断。
	*/
	writePort( INTE_MASTER_ADD, 0xFF ); // 屏蔽主片所有中断
	writePort( INTE_SLAVE_ADD,  0xFF ); // 屏蔽从片中断

	for(int i = 0; i < NUM_IRQ; ++i){
        irqHandler[i] = printIRQ;
    }
}

// 打印中断请求号
PUBLIC void printIRQ(int irq)
{
    dispStr("\nInterrupt Request Number: ");
    dispInt(irq);
    dispStr("\n");
}

PUBLIC void setIRQHandler(int IRQ, IRQHandler hanler){
    disableIRQ(IRQ);
    irqHandler[IRQ] = hanler;
}