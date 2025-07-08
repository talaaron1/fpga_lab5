.data
.text
    # אתחול רגיסטרים עם ערכים בין 1–5
    li $t0, 1      # $t0 = 1
    li $t1, 2      # $t1 = 2
    li $t2, 3      # $t2 = 3
    li $t3, 4      # $t3 = 4
    li $t4, 5      # $t4 = 5

    #### Arithmetic Instructions ####

    # add: $s0 = $t0 + $t1 = 1 + 2 = 3
    add $s0, $t0, $t1

    # sub: $s1 = $t4 - $t2 = 5 - 3 = 2
    sub $s1, $t4, $t2

    # addi: $s2 = $t1 + 5 = 2 + 5 = 7
    addi $s2, $t1, 5
    
    # mul: $s3 = $t2 * $t3 = 3 * 4 = 12
    mul $s3, $t2, $t3
