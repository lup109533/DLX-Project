addi isr,r0,ISR_table # Just as a test

trap 1
j finish

finish:
j finish

ISR_table:
add r1,r0,12345
add r2,r0,23456
rfe