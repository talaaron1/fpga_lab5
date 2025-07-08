.data
.text
    #### Initialize Registers ####
    li $t0, 15    # $t0 = 15
    li $t1, 240    # $t1 = 240
    li $t2, 1    # $t2 = 1
    li $t3, 4             # shift amount = 4

    #### Logical and Shift Instructions ####

    # sll: $s0 = $t2 << 4 = 1 << 4 = 16
    sll $s0, $t2, 4
    
    jal main

main:
    # srl: $s1 = $t1 >> 4 = 240 >> 4 = 15
    srl $s1, $t1, 4

    # ori: $s2 = $t0 | 0xF0 = 0x0F | 0xF0 = 0xFF = 255
    ori $s2, $t0, 0xF0

    # xor: $s3 = $t0 ^ $t1 = 0x0F ^ 0xF0 = 0xFF
    xor $s3, $t0, $t1

    # and: $s4 = $t0 & $t1 = 0x0F & 0xF0 = 0x00
    and $s4, $t0, $t1