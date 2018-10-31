# Test jal, should continuously loop
xnor r1,r0,r0
jal  test1
nop

xnor r2,r0,r0
jalr r0
nop

test1:
ret