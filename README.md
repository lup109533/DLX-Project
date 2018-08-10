# DLX-Project

Overleaf TeX URL: https://www.overleaf.com/18196542nddgrggtchyj

# Naming guidelines
Objects within the project should follow the following naming style:
> Base.Sub0.Sub1.Sub2...SubN-ComponentName.ext

Where __Base__ is the base level (presently only *a*), __Sub\*__ is a sublevel, marked by a lowercase letter, __ComponentName__ is the name of the component (which should also be the name of the VHDL entity), preferably in UPPERCASE, and __ext__ is the extension.\
Objects may be binary files (.txt, .vhd etc.) or directories (in which case the extension should be .core). If the object is a directory, there should also be a corresponding file with the same name of the folder (other than the __ext__), used to assemble all subcomponents.
For example:
> a.b-CU.vhd\
> a.c.a-FETCH.vhd\
> a.c.c.a-ALU.vhd\
> a.c-DATAPATH.core\
> a.c-DATAPATH.vhd

Generic designs should be put in the __vhd\generics__ folder and named __ComponentName.vhd__. If the generic component is to be implemented in several files, they should all be put in a significantly named folder and named __DD-ComponentName.vhd__, where __DD__ is a two-digit decimal number, such that the names are representative of the required order of compilation, e.g.
> In folder __generics/ADDERS/RCA/__ we have:\
> __00__-HA.vhd  (Half-adder)\
> __01__-FA.vhd  (Full-adder, requires HA.vhd)\
> __02__-RCA.vhd (Ripple Carry Adder, requires FA.vhd)

Testbenches should be put in the __vhd\testbench__ folder and named __TB-ComponentName.vhd__.

# sim
### TODO

# syn
### TODO

# vhd
* 000-globals.vhd - Contains all the common constants and procedures of the design, as well as useful functions such as __log2__.
* a - Full DLX Design
  * a.a - Processor L1 cache
  * a.b - Control Unit (CU), microprogrammed
  * a.c - Datapath, 5 stage pipeline
    * a.c.a - Fetch stage
    * a.c.b - Decode stage
    * a.c.c - Execute stage
      * a.c.c.a - ALU, Arithmetic and Logic Unit, performs additions/subtractions, shifts and logic operations.
        * a.c.c.a.a - LU_CTRL, a package containing helper constants for the LU.
        * a.c.c.a.b - LU, Logic Unit, implements all logic functions on two operands.
        * a.c.c.a.c - Adder/Subtractor, implemented using a radix-2 Sparse Tree Carry Lookahead Adder. 
      * a.c.c.b - FPU, Floating Point Unit, for now only performs multiplication.
    * a.c.d - Memory stage
    * a.c.e - Write back stage
* generics - Generic designs
  * GENERIC_CACHE - Generic cache design, should support generic associativity and *write-back* write policy.
  * ADDERS - Folder containing generic adder implementations.
    * RCA - Folder containing all files required to implement a generic N-bit Ripple Carry Adder.
    * CLA - Folder containing all files required to implement a generic N-bit Sparse Tree Carry Lookahead Adder with arbitrary radix.
* testbench - Testbenches
