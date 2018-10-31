# Test some I-type instructions
seq r1,r0,r0
seqi r2,r0,0
snei r3,r0,1
nop
sne r4,r1,r0
xnori r5,r2,1
andni r6,r0,3

finish:
j finish
