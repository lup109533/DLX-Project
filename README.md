# DLX-Project

Overleaf TeX URL: https://www.overleaf.com/18196542nddgrggtchyj

# Naming guidelines
Objects within the project should follow the following naming style:
> Base.Sub0.Sub1.Sub2...SubN-ComponentName.ext

Where __Base__ is the base level (presently only *a*), __Sub\*__ is a sublevel, marked by a lowercase letter, __ComponentName__ is the name of the component, preferably in UPPERCASE, and __ext__ is the extension.\
Objects may be binary files (.txt, .vhd etc.) or directories (in which case the extension should be .core). If the object is a directory, it should also contain a file named __000-ComponentName.ext__, used to assemble all subcomponents.
For example:
> a.b-CU.vhd\
> a.c.a-FETCH.vhd\
> a.c.c.a-ALU.vhd\
> a.c-DATAPATH\\000-DATAPATH.vhd

# sim
### TODO

# syn
### TODO

# vhd
* 00\* - Generic designs
  * 0 - Global constants and processes
  * 1 - Generic cache design, should support generic associativity and *write-back* write policy.
* a - Full DLX Design
  * a.a - Processor L1 cache
  * a.b - Control Unit (CU), microprogrammed
  * a.c - Datapath, 5 stage pipeline
    * a.c.a - Fetch stage
    * a.c.b - Decode stage
    * a.c.c - Execute stage
    * a.c.d - Memory stage
    * a.c.e - Write back stage
