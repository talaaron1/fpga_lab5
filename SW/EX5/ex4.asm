.data
a: .word 0       # Allocate a word at label 'a'

.text
main:
    li $t1, 32        # $t1 = 32
    la $t0, a         # $t0 = address of 'a'
    sw $t1, 0($t0)    # Store 32 into 'a'
    lw $t2, 0($t0)    # Load from 'a' into $t2