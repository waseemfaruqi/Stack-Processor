#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "../../stack_app_wrapper_hw_platform_0/drivers/stack_ma_v1_0/src/stack_ma.h"
#include "xil_io.h"
#include "xil_types.h"


#define ADDR XPAR_STACK_MA_0_S00_AXI_BASEADDR
#define sc 0x01
#define sl 0x11
#define ss 0x21
#define sadd 0x31
#define ssub 0x41
#define sjlt 0x51
#define sjgt 0x61
#define sjeq 0x71
#define sjmp 0xE1
#define scmp 0xF1
#define smul 0x101
#define scall 0x81
#define srtn 0x91
#define salloc 0xA1
#define sdealloc 0xB1
#define slaa 0xC1
#define slla 0xD1
#define shalt 0xff
#define sma 0x111
#define scp 0xc01

#define main_len	16


// Registers/Ports Mapping
// =======================
//				run                 => slv_reg0(0),
//              reset               => slv_reg0(1),
//              bus2mem_en          => slv_reg0(2),
//              bus2mem_we          => slv_reg0(3),
//              ck                  => S_AXI_ACLK,
//              bus2mem_addr        => slv_reg1(9 downto 0),
//              bus2mem_data_in     => slv_reg2,
//              sp2bus_data_out     => slv_reg3,
//              done                => slv_reg4(0)
//-----------------------------------------------------
/* Machine Instructions
*  --------------------
constant sc ( x"00000001");
constant sl (x"00000011");
constant ss (x"00000021");
constant sadd (x"00000031");
*/

int main()
{
    init_platform();


    // slv_reg0 write = reset + bus2mem_en + bus2mem_we = 2+4+8 = 0xE
    STACK_MA_mWriteReg(ADDR, 0, 0x0000000E);

    // Lower Reset: slv_reg0 write = bus2mem_en + bus2mem_we = 4+8 = 0xC
    STACK_MA_mWriteReg(ADDR, 0, 0x0000000C);

    unsigned int prog[main_len] =
    {	sc, 100,
		sc, 50,
		ss,
		sc, 20,
		sc, 500,
		ss,
		sc, 100,
		sc, 20,
		scp,
		shalt
    };

    for (int j = 0; j < main_len; j++) {
    	STACK_MA_mWriteReg(ADDR, 4, j);
    	STACK_MA_mWriteReg(ADDR, 8, prog[j]);
    }

    // Lower bus2mem_en, bus2mem_we and run = slv_reg0(0) = 0x1
    STACK_MA_mWriteReg(ADDR, 0, 0x1);
    print("Hello World\n\r");
    // wait on done flag slv_reg4(0)
    while ((unsigned int)(STACK_MA_mReadReg(ADDR,16)&0x1)==0);
    //-----------------READ RESULTS---------------------------
    // enable bus2mem_en: slv_reg(2) = 0x4 run and bus2mem_we = 0
    STACK_MA_mWriteReg(ADDR, 0, 0x4);

    int addr = 20;
	STACK_MA_mWriteReg(ADDR, 4, addr);
	xil_printf("content of %d : %d \n \r", addr, (unsigned int)
				STACK_MA_mReadReg(ADDR,12));

	addr = 100;
	STACK_MA_mWriteReg(ADDR, 4, addr);
	xil_printf("content of %d : %d \n \r", addr, (unsigned int)
				STACK_MA_mReadReg(ADDR,12));

    cleanup_platform();
    return 0;
}
