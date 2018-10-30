addi r1,r0,28 # Dividend/Quotient
addi r2,r0,-9  # Divisor
xor  r3,r3,r3 # Remainder

# Check if divisor zero
seq  r10,r2,r0
bnez r10,finish

# Check sign of dividend and divisor to choose between addition and subtraction
slt r4,r1,r0
slt r5,r2,r0
seq r6,r4,r5

divide:

# Check if end of division according to signs of dividend and divisor
beqz r6,check_different_sign
sgt  r10,r2,r1
bnez r10,finish
j division_proper

# Different signs and negative dividend
check_different_sign:
beqz r4,negative_divisor
sub  r9,r0,r1
sgt  r10,r2,r9
bnez r10,finish
j division_proper

# Different signs and negative divisor
negative_divisor:
sub  r9,r0,r2
sgt  r10,r9,r1
bnez r10,finish

division_proper:
beqz r6,addition
# Same sign, subtract
sub  r1,r1,r2
j inc_quotient
# Different sign, add
addition:
add  r1,r1,r2

inc_quotient:
addi r3,r3,1
j divide

finish:
j finish
