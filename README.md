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

Generic designs should be put in the __vhd\generics__ folder and named __DD-ComponentName.vhd__, where __DD__ is a two-digit decimal number, starting from 01.

Testbenches should be put in the __vhd\testbench__ folder and named __TB-ComponentName.vhd__.

# sim
### TODO

# syn
### TODO

# vhd
* 000-globals.vhd - Contains all the common constants and processes of the design.
* a - Full DLX Design
  * a.a - Processor L1 cache
  * a.b - Control Unit (CU), microprogrammed
  * a.c - Datapath, 5 stage pipeline
    * a.c.a - Fetch stage
    * a.c.b - Decode stage
    * a.c.c - Execute stage
    * a.c.d - Memory stage
    * a.c.e - Write back stage
* generics - Generic designs
  * 01 - Generic cache design, should support generic associativity and *write-back* write policy.
* testbench - Testbenches
