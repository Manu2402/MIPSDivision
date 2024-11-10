# A program that calculates from scratch the division operation between two signed integer numbers 
# with exception handler and syscalls. I know there is a MIPS "pseudo-instruction" about the division, 
# but for didactical scopes i wanted to try to make one by myself using an exception handler.

# ABI (Application Binary Interface): 
# $a0 --> First Number
# $a1 --> Second Number
# $s0 --> Quotient
# $s1 --> Rest

.text # Starts from 0x00400000
main: # Entry Point
    la $a0, hello # Load address into $a0	
    li $v0, 4 # "print string" syscall ID
    syscall
#-----------------------------------------------------  
    la $a0, first
    li $v0, 4
    syscall
    
    li $v0, 5 # "read integer" syscall ID
    syscall
    move $t0, $v0 
#-----------------------------------------------------    
retry:
    la $a0, second
    li $v0, 4
    syscall
    
    li $v0, 5
    syscall
    move $t1, $v0
#-----------------------------------------------------
    beq $t1, $zero, exp_handler # Division by 0 --> IMPOSSIBLE! Throwing an exception!
#-----------------------------------------------------
    move $a0, $t0 # Args. Delay slot "trick". 
    move $a1, $t1
   
    jal division
    nop # Delay slot
    
    jal evaluate
    nop # Delay slot
#-----------------------------------------------------
    la $a0, quotient	
    li $v0, 4
    syscall
    
    move $a0, $s0  
    li $v0, 1 # "print integer" syscall ID
    syscall 
    
    la $a0, rest	
    li $v0, 4
    syscall
    
    move $a0, $s1 
    li $v0, 1
    syscall 
    
    li $a0, 0 
    li $v0, 17 # Exit with "exit code 0". 
    syscall
#-----------------------------------------------------
division: 
    slti $t0, $a0, 0
    slti $t1, $a1, 0   
    beqz $t0, skip_first_number
    nop # Delay slot
    mul $a0, $a0, -1
skip_first_number:
    beqz $t1, calc
    nop # Delay slot
    mul $a1, $a1, -1       
calc:
    sub $a0, $a0, $a1
    bgez $a0, calc  
    addi $s0, $s0, 1 # $s0++ --> Delay slot "trick". 
 
    subi $s0, $s0, 1
    add $t2, $a0, $a1
    move $s1, $t2
    jr $ra
    nop # Delay slot   
#-----------------------------------------------------
evaluate: # Evalutate about both number's signs.
    and $t3, $t0, $t1
    beqz $t3, skip_both_negative
    nop # Delay slot
    mul $s1, $s1, -1
    j end_evaluate
    nop # Delay slot
skip_both_negative:   
    beqz $t0, skip_first_negative
    nop # Delay slot
    mul $s0, $s0, -1
    mul $s1, $s1, -1
    j end_evaluate
    nop # Delay slot
skip_first_negative: 
    beqz $t1, end_evaluate
    nop # Delay slot
    mul $s0, $s0, -1
end_evaluate:
    jr $ra
    nop # Delay slot
#----------------------------------------------------
exp_handler:
    syscall # Generating a syscall in order to throw an exception. 
#----------------------------------------------------------------------------------------------------
.data #  Starts from 0x10010000
hello: .ascii "Hi! Welcome to my divisions calculator.\n\0" # Example with null-terminated character
first: .asciiz "\nInsert the first number: " 
second: .asciiz "Insert the second number: "
quotient: .asciiz "The quotient of the division is: "
rest: .asciiz "\nThe rest of the division is: "
exception: .asciiz "*DivideByZeroException*: is impossible to divide a number by zero!\n"  
#----------------------------------------------------------------------------------------------------  
.ktext 0x80000180 # Exception section starting address.

la $a0, exception	
li $v0, 4
syscall
 
mfc0 $t3, $14 # Move the address that threw the exception into $t3 in order to change it with the
              # "retry" label to let the user to insert a new number, possibly different by 0.           
la $t3, retry
mtc0 $t3, $14 
eret # Back to the program in "User Space".