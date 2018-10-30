addi r1,r0,2
cvti2f f1,r1
addi r2,r0,3

multiply:
beqz r2,finish
addf f3,f3,f1
subi r2,r2,1
j multiply

finish:
j finish