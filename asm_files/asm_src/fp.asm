addi r1,r0,3
addi r2,r0,3

mult r3,r1,r2
sub  r3,r0,r3

cvti2f f4,r3
addf f6,f4,f4
multf f5,f4,f4
cvtf2i r7,f6

eqf f4,f4
nef f4,f4
gef f4,f4
lef f4,f4
gtf f6,f4
ltf f4,f6

finish:
j finish