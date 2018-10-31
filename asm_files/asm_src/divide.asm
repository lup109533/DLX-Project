# Implement signed integer division by repeated subtractions
addi r1,r0,28 # Dividend/Quotient
addi r2,r0,-9  # Divisor
xor  r3,r3,r3 # Remainder

# Check if divisor zero
seq  r10,r2,r0
bnez r10,finish

# Check sign of dividend and divisor to choose sign of output
slt r4,r1,r0
slt r5,r2,r0
seq r6,r4,r5

# Make divisor or divident positive if necessary
check_dividend:
beqz r4,check_divisor
sub  r1,r0,r1

check_divisor:
beqz r5,divide
sub  r2,r0,r2

divide:
slt  r10,r1,r2
bnez r10,output_sign
sub  r1,r1,r2
addi r3,r3,1
j divide

# Invert quotient if necessary
output_sign:
bnez r6,finish
sub  r1,r0,r1

finish:
j finish
