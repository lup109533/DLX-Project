# Test forwarding of both registers by using R-type instructions
sge r1,r0,r0
add r2,r1,r1
sub r3,r2,r1
xor r4,r3,r1
# Clear pipeline
nop
nop
nop
nop
# Test forwarding with stalling
lw  r1,8(r0)
add r2,r1,r1