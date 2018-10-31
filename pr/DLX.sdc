###################################################################

# Created by write_sdc on Wed Oct 31 03:13:22 2018

###################################################################
set sdc_version 1.7

create_clock [get_ports CLK]  -period 1  -waveform {0 0.5}
set_max_delay 0  -from [list [get_ports CLK] [get_ports RST] [get_ports ENB] [get_ports        \
BRANCH_DELAY_EN] [get_ports {ICACHE_INSTR[31]}] [get_ports {ICACHE_INSTR[30]}] \
[get_ports {ICACHE_INSTR[29]}] [get_ports {ICACHE_INSTR[28]}] [get_ports       \
{ICACHE_INSTR[27]}] [get_ports {ICACHE_INSTR[26]}] [get_ports                  \
{ICACHE_INSTR[25]}] [get_ports {ICACHE_INSTR[24]}] [get_ports                  \
{ICACHE_INSTR[23]}] [get_ports {ICACHE_INSTR[22]}] [get_ports                  \
{ICACHE_INSTR[21]}] [get_ports {ICACHE_INSTR[20]}] [get_ports                  \
{ICACHE_INSTR[19]}] [get_ports {ICACHE_INSTR[18]}] [get_ports                  \
{ICACHE_INSTR[17]}] [get_ports {ICACHE_INSTR[16]}] [get_ports                  \
{ICACHE_INSTR[15]}] [get_ports {ICACHE_INSTR[14]}] [get_ports                  \
{ICACHE_INSTR[13]}] [get_ports {ICACHE_INSTR[12]}] [get_ports                  \
{ICACHE_INSTR[11]}] [get_ports {ICACHE_INSTR[10]}] [get_ports                  \
{ICACHE_INSTR[9]}] [get_ports {ICACHE_INSTR[8]}] [get_ports {ICACHE_INSTR[7]}] \
[get_ports {ICACHE_INSTR[6]}] [get_ports {ICACHE_INSTR[5]}] [get_ports         \
{ICACHE_INSTR[4]}] [get_ports {ICACHE_INSTR[3]}] [get_ports {ICACHE_INSTR[2]}] \
[get_ports {ICACHE_INSTR[1]}] [get_ports {ICACHE_INSTR[0]}] [get_ports         \
ICACHE_HIT] [get_ports {HEAP_ADDR[31]}] [get_ports {HEAP_ADDR[30]}] [get_ports \
{HEAP_ADDR[29]}] [get_ports {HEAP_ADDR[28]}] [get_ports {HEAP_ADDR[27]}]       \
[get_ports {HEAP_ADDR[26]}] [get_ports {HEAP_ADDR[25]}] [get_ports             \
{HEAP_ADDR[24]}] [get_ports {HEAP_ADDR[23]}] [get_ports {HEAP_ADDR[22]}]       \
[get_ports {HEAP_ADDR[21]}] [get_ports {HEAP_ADDR[20]}] [get_ports             \
{HEAP_ADDR[19]}] [get_ports {HEAP_ADDR[18]}] [get_ports {HEAP_ADDR[17]}]       \
[get_ports {HEAP_ADDR[16]}] [get_ports {HEAP_ADDR[15]}] [get_ports             \
{HEAP_ADDR[14]}] [get_ports {HEAP_ADDR[13]}] [get_ports {HEAP_ADDR[12]}]       \
[get_ports {HEAP_ADDR[11]}] [get_ports {HEAP_ADDR[10]}] [get_ports             \
{HEAP_ADDR[9]}] [get_ports {HEAP_ADDR[8]}] [get_ports {HEAP_ADDR[7]}]          \
[get_ports {HEAP_ADDR[6]}] [get_ports {HEAP_ADDR[5]}] [get_ports               \
{HEAP_ADDR[4]}] [get_ports {HEAP_ADDR[3]}] [get_ports {HEAP_ADDR[2]}]          \
[get_ports {HEAP_ADDR[1]}] [get_ports {HEAP_ADDR[0]}] [get_ports {MBUS[31]}]   \
[get_ports {MBUS[30]}] [get_ports {MBUS[29]}] [get_ports {MBUS[28]}]           \
[get_ports {MBUS[27]}] [get_ports {MBUS[26]}] [get_ports {MBUS[25]}]           \
[get_ports {MBUS[24]}] [get_ports {MBUS[23]}] [get_ports {MBUS[22]}]           \
[get_ports {MBUS[21]}] [get_ports {MBUS[20]}] [get_ports {MBUS[19]}]           \
[get_ports {MBUS[18]}] [get_ports {MBUS[17]}] [get_ports {MBUS[16]}]           \
[get_ports {MBUS[15]}] [get_ports {MBUS[14]}] [get_ports {MBUS[13]}]           \
[get_ports {MBUS[12]}] [get_ports {MBUS[11]}] [get_ports {MBUS[10]}]           \
[get_ports {MBUS[9]}] [get_ports {MBUS[8]}] [get_ports {MBUS[7]}] [get_ports   \
{MBUS[6]}] [get_ports {MBUS[5]}] [get_ports {MBUS[4]}] [get_ports {MBUS[3]}]   \
[get_ports {MBUS[2]}] [get_ports {MBUS[1]}] [get_ports {MBUS[0]}] [get_ports   \
RF_ACK] [get_ports {EXT_MEM_DOUT[31]}] [get_ports {EXT_MEM_DOUT[30]}]          \
[get_ports {EXT_MEM_DOUT[29]}] [get_ports {EXT_MEM_DOUT[28]}] [get_ports       \
{EXT_MEM_DOUT[27]}] [get_ports {EXT_MEM_DOUT[26]}] [get_ports                  \
{EXT_MEM_DOUT[25]}] [get_ports {EXT_MEM_DOUT[24]}] [get_ports                  \
{EXT_MEM_DOUT[23]}] [get_ports {EXT_MEM_DOUT[22]}] [get_ports                  \
{EXT_MEM_DOUT[21]}] [get_ports {EXT_MEM_DOUT[20]}] [get_ports                  \
{EXT_MEM_DOUT[19]}] [get_ports {EXT_MEM_DOUT[18]}] [get_ports                  \
{EXT_MEM_DOUT[17]}] [get_ports {EXT_MEM_DOUT[16]}] [get_ports                  \
{EXT_MEM_DOUT[15]}] [get_ports {EXT_MEM_DOUT[14]}] [get_ports                  \
{EXT_MEM_DOUT[13]}] [get_ports {EXT_MEM_DOUT[12]}] [get_ports                  \
{EXT_MEM_DOUT[11]}] [get_ports {EXT_MEM_DOUT[10]}] [get_ports                  \
{EXT_MEM_DOUT[9]}] [get_ports {EXT_MEM_DOUT[8]}] [get_ports {EXT_MEM_DOUT[7]}] \
[get_ports {EXT_MEM_DOUT[6]}] [get_ports {EXT_MEM_DOUT[5]}] [get_ports         \
{EXT_MEM_DOUT[4]}] [get_ports {EXT_MEM_DOUT[3]}] [get_ports {EXT_MEM_DOUT[2]}] \
[get_ports {EXT_MEM_DOUT[1]}] [get_ports {EXT_MEM_DOUT[0]}] [get_ports         \
EXT_MEM_BUSY]]  -to [list [get_ports {PC[31]}] [get_ports {PC[30]}] [get_ports {PC[29]}]      \
[get_ports {PC[28]}] [get_ports {PC[27]}] [get_ports {PC[26]}] [get_ports      \
{PC[25]}] [get_ports {PC[24]}] [get_ports {PC[23]}] [get_ports {PC[22]}]       \
[get_ports {PC[21]}] [get_ports {PC[20]}] [get_ports {PC[19]}] [get_ports      \
{PC[18]}] [get_ports {PC[17]}] [get_ports {PC[16]}] [get_ports {PC[15]}]       \
[get_ports {PC[14]}] [get_ports {PC[13]}] [get_ports {PC[12]}] [get_ports      \
{PC[11]}] [get_ports {PC[10]}] [get_ports {PC[9]}] [get_ports {PC[8]}]         \
[get_ports {PC[7]}] [get_ports {PC[6]}] [get_ports {PC[5]}] [get_ports         \
{PC[4]}] [get_ports {PC[3]}] [get_ports {PC[2]}] [get_ports {PC[1]}]           \
[get_ports {PC[0]}] [get_ports {RF_SWP[31]}] [get_ports {RF_SWP[30]}]          \
[get_ports {RF_SWP[29]}] [get_ports {RF_SWP[28]}] [get_ports {RF_SWP[27]}]     \
[get_ports {RF_SWP[26]}] [get_ports {RF_SWP[25]}] [get_ports {RF_SWP[24]}]     \
[get_ports {RF_SWP[23]}] [get_ports {RF_SWP[22]}] [get_ports {RF_SWP[21]}]     \
[get_ports {RF_SWP[20]}] [get_ports {RF_SWP[19]}] [get_ports {RF_SWP[18]}]     \
[get_ports {RF_SWP[17]}] [get_ports {RF_SWP[16]}] [get_ports {RF_SWP[15]}]     \
[get_ports {RF_SWP[14]}] [get_ports {RF_SWP[13]}] [get_ports {RF_SWP[12]}]     \
[get_ports {RF_SWP[11]}] [get_ports {RF_SWP[10]}] [get_ports {RF_SWP[9]}]      \
[get_ports {RF_SWP[8]}] [get_ports {RF_SWP[7]}] [get_ports {RF_SWP[6]}]        \
[get_ports {RF_SWP[5]}] [get_ports {RF_SWP[4]}] [get_ports {RF_SWP[3]}]        \
[get_ports {RF_SWP[2]}] [get_ports {RF_SWP[1]}] [get_ports {RF_SWP[0]}]        \
[get_ports {MBUS[31]}] [get_ports {MBUS[30]}] [get_ports {MBUS[29]}]           \
[get_ports {MBUS[28]}] [get_ports {MBUS[27]}] [get_ports {MBUS[26]}]           \
[get_ports {MBUS[25]}] [get_ports {MBUS[24]}] [get_ports {MBUS[23]}]           \
[get_ports {MBUS[22]}] [get_ports {MBUS[21]}] [get_ports {MBUS[20]}]           \
[get_ports {MBUS[19]}] [get_ports {MBUS[18]}] [get_ports {MBUS[17]}]           \
[get_ports {MBUS[16]}] [get_ports {MBUS[15]}] [get_ports {MBUS[14]}]           \
[get_ports {MBUS[13]}] [get_ports {MBUS[12]}] [get_ports {MBUS[11]}]           \
[get_ports {MBUS[10]}] [get_ports {MBUS[9]}] [get_ports {MBUS[8]}] [get_ports  \
{MBUS[7]}] [get_ports {MBUS[6]}] [get_ports {MBUS[5]}] [get_ports {MBUS[4]}]   \
[get_ports {MBUS[3]}] [get_ports {MBUS[2]}] [get_ports {MBUS[1]}] [get_ports   \
{MBUS[0]}] [get_ports {EXT_MEM_ADDR[31]}] [get_ports {EXT_MEM_ADDR[30]}]       \
[get_ports {EXT_MEM_ADDR[29]}] [get_ports {EXT_MEM_ADDR[28]}] [get_ports       \
{EXT_MEM_ADDR[27]}] [get_ports {EXT_MEM_ADDR[26]}] [get_ports                  \
{EXT_MEM_ADDR[25]}] [get_ports {EXT_MEM_ADDR[24]}] [get_ports                  \
{EXT_MEM_ADDR[23]}] [get_ports {EXT_MEM_ADDR[22]}] [get_ports                  \
{EXT_MEM_ADDR[21]}] [get_ports {EXT_MEM_ADDR[20]}] [get_ports                  \
{EXT_MEM_ADDR[19]}] [get_ports {EXT_MEM_ADDR[18]}] [get_ports                  \
{EXT_MEM_ADDR[17]}] [get_ports {EXT_MEM_ADDR[16]}] [get_ports                  \
{EXT_MEM_ADDR[15]}] [get_ports {EXT_MEM_ADDR[14]}] [get_ports                  \
{EXT_MEM_ADDR[13]}] [get_ports {EXT_MEM_ADDR[12]}] [get_ports                  \
{EXT_MEM_ADDR[11]}] [get_ports {EXT_MEM_ADDR[10]}] [get_ports                  \
{EXT_MEM_ADDR[9]}] [get_ports {EXT_MEM_ADDR[8]}] [get_ports {EXT_MEM_ADDR[7]}] \
[get_ports {EXT_MEM_ADDR[6]}] [get_ports {EXT_MEM_ADDR[5]}] [get_ports         \
{EXT_MEM_ADDR[4]}] [get_ports {EXT_MEM_ADDR[3]}] [get_ports {EXT_MEM_ADDR[2]}] \
[get_ports {EXT_MEM_ADDR[1]}] [get_ports {EXT_MEM_ADDR[0]}] [get_ports         \
{EXT_MEM_DIN[31]}] [get_ports {EXT_MEM_DIN[30]}] [get_ports {EXT_MEM_DIN[29]}] \
[get_ports {EXT_MEM_DIN[28]}] [get_ports {EXT_MEM_DIN[27]}] [get_ports         \
{EXT_MEM_DIN[26]}] [get_ports {EXT_MEM_DIN[25]}] [get_ports {EXT_MEM_DIN[24]}] \
[get_ports {EXT_MEM_DIN[23]}] [get_ports {EXT_MEM_DIN[22]}] [get_ports         \
{EXT_MEM_DIN[21]}] [get_ports {EXT_MEM_DIN[20]}] [get_ports {EXT_MEM_DIN[19]}] \
[get_ports {EXT_MEM_DIN[18]}] [get_ports {EXT_MEM_DIN[17]}] [get_ports         \
{EXT_MEM_DIN[16]}] [get_ports {EXT_MEM_DIN[15]}] [get_ports {EXT_MEM_DIN[14]}] \
[get_ports {EXT_MEM_DIN[13]}] [get_ports {EXT_MEM_DIN[12]}] [get_ports         \
{EXT_MEM_DIN[11]}] [get_ports {EXT_MEM_DIN[10]}] [get_ports {EXT_MEM_DIN[9]}]  \
[get_ports {EXT_MEM_DIN[8]}] [get_ports {EXT_MEM_DIN[7]}] [get_ports           \
{EXT_MEM_DIN[6]}] [get_ports {EXT_MEM_DIN[5]}] [get_ports {EXT_MEM_DIN[4]}]    \
[get_ports {EXT_MEM_DIN[3]}] [get_ports {EXT_MEM_DIN[2]}] [get_ports           \
{EXT_MEM_DIN[1]}] [get_ports {EXT_MEM_DIN[0]}] [get_ports EXT_MEM_RD]          \
[get_ports EXT_MEM_WR] [get_ports EXT_MEM_ENABLE]]
