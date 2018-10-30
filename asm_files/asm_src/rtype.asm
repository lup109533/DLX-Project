begin:
seq r1,r3,r4
sge r2,r5,r6
sle r3,r1,r2
slt r4,r1,r2
add r5,r1,r2
or  r6,r3,r5
sll r7,r6,r1
srl r8,r5,r2
sra r9,r4,r2
sub r10,r9,r8
not r11,r0,r0

addi r1,r2,1
subi r2,r4,2
slti r1,r2,0
bnez r1,begin

finish:
j finish
