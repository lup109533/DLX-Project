lhi r1,1
lhi r2,2

sw 0(r0),r1
sw 4(r0),r2
call subr
lw r3,8(r0)

finish:
j finish

subr:
lw r1,0(r0)
lw r2,4(r0)
add r3,r1,r2
sw 8(r0),r3
ret
