# Implement FP multiplication by repeated additions
addi r1,r0,2 # Multiplicand
cvti2f f1,r1
addi r2,r0,3 # Multiplier

# Loop r2 times
multiply:
beqz r2,finish
addf f3,f3,f1
subi r2,r2,1
j multiply

finish:
j finish