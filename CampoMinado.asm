# Configurações do Display:
# - Unit Width/Height: 4x4 pixels
# - Display Width/Height: 512x256
# - Base Address: 0x10000000 (global data)
.data
nomes_pontos:
        .word 30,15, 29,16, 29,17, 30,18, 31,17, 30,19
        .word 29,21, 28,23, 28,24, 29,25, 31,25, 33,24
        .word 35,22, 35,23, 36,24, 37,24, 38,23, 38,22
        .word 39,23, 40,24, 42,22, 42,23, 43,24, 42,19
        .word 45,22, 46,22, 47,23, 46,24, 45,25, 44,26
        .word 45,27, 46,26, 28,24, 53,22, 52,23, 52,24
        .word 53,25, 54,25, 55,24, 55,22, 55,23, 56,25
        .word 58,22, 59,22, 60,23, 60,24, 61,25
        
        .word 30,38, 29,39, 30,41, 31,43, 32,44, 33,43
        .word 34,41, 35,39, 36,38, 38,39, 41,42, 40,43
        .word 41,44, 42,44, 43,43, 43,42, 44,44, 46,43
        .word 47,41, 48,39, 49,38, 48,37, 47,39, 47,41
        .word 47,43, 48,44, 51,43, 52,42, 53,42, 52,43
        .word 51,44, 53,45, 55,42, 55,43, 56,42, 57,43
        .word 57,44, 58,45, 60,39, 60,41, 60,43, 60,44
        .word 61,45, 59,41, 61,41
fim_nomes:

display_base:    .word 0x10000000    
screen_width:    .word 128            
screen_height:   .word 64             

grid_size:       .word 10             
cell_size:       .word 4              
grid_x_offset:   .word 44             
grid_y_offset:   .word 12             

color_hidden:    .word 0x00404040
color_open:      .word 0x00AAAAAA
color_borda:     .word 0x00000000
color_bomba:     .word 0x00FF0000
color_bandeira:  .word 0x000000FF

color_num1:      .word 0x000000FF    
color_num2:      .word 0x00008000    
color_num3:      .word 0x00FF0000    
color_num4:      .word 0x00000080    

game_grid_map:
    .byte  2,  0,  0,  0,  0,  0,  0, 11,  0,  0    
    .byte  9,  2,  0,  0,  0,  0,  0,  0,  2,  9    
    .byte  2,  2,  1,  1,  1,  2,  2,  2,  2,  2    
    .byte  0,  0,  2,  9,  2,  2,  9,  2,  1,  1    
    .byte  1,  1,  2,  2,  2,  1,  1,  2,  2,  2    
    .byte  0, 11,  0,  0,  0,  1,  1,  2,  9,  2    
    .byte  1,  1,  1,  0,  0,  1,  1,  1,  1,  1    
    .byte  0,  0,  0,  1,  1,  1,  1,  1,  1,  1    
    .byte  1,  1,  1,  0, 10,  0,  1,  1,  1,  1    
    .byte  1,  1,  1,  0,  0,  0,  1,  1,  1,  1    

.text
.globl main

main:
    lw $s0, display_base      
    lw $s4, screen_width      
    
    lui $t0, 0x00FF                
    ori $t0, $t0, 0xFFFF           
    li $t1, 0                      
    li $t2, 8192
limpar_intro:
    sw $t0, 0($s0)                 
    addi $s0, $s0, 4               
    addi $t1, $t1, 1               
    blt $t1, $t2, limpar_intro      
    
    lw $s0, display_base           
    la $s1, nomes_pontos           
    la $s2, fim_nomes              
    li $a2, 0x00000000             

desenhar_nomes_loop:
    beq $s1, $s2, iniciar_delay
    
    lw $a0, 0($s1)                 
    lw $a1, 4($s1)                 

    sll $t4, $a1, 7
    add $t4, $t4, $a0
    sll $t4, $t4, 2
    add $t5, $s0, $t4              
    sw $a2, 0($t5)                 

    addi $t6, $a0, 1
    sll $t4, $a1, 7
    add $t4, $t4, $t6
    sll $t4, $t4, 2
    add $t5, $s0, $t4
    sw $a2, 0($t5)

    addi $s1, $s1, 8               
    j desenhar_nomes_loop

iniciar_delay:
    li $v0, 32
    li $a0, 3000
    syscall

    lw $s0, display_base           
    li $t0, 0x00000000             
    li $t1, 0                      
    li $t2, 8192                   
limpar_jogo:
    sw $t0, 0($s0)                 
    addi $s0, $s0, 4               
    addi $t1, $t1, 1               
    blt $t1, $t2, limpar_jogo
    
    lw $s0, display_base      
    la $s1, game_grid_map     
    lw $s2, grid_size          
    lw $s3, cell_size          

    move $t0, $zero

row_loop:
    beq $t0, $s2, end_main     
    move $t1, $zero

col_loop:
    beq $t1, $s2, next_row     

    mult $t0, $s2              
    mflo $t2                   
    add $t2, $t2, $t1          
    add $t2, $t2, $s1          
    lbu $t3, 0($t2)            

    jal get_cell_color         

    move $a0, $t1              
    move $a1, $t0              
    move $a2, $v0              
    jal draw_game_cell         

    addi $t1, $t1, 1           
    j col_loop

next_row:
    addi $t0, $t0, 1           
    j row_loop

end_main:
    li $v0, 10                 
    syscall

get_cell_color:
    beq $t3, 0,  c_hidden     
    beq $t3, 1,  c_open       
    beq $t3, 2,  c_num1       
    beq $t3, 3,  c_num2       
    beq $t3, 4,  c_num3       
    beq $t3, 5,  c_num4       
    beq $t3, 9,  c_bomba      
    beq $t3, 10, c_bomba_exp  
    beq $t3, 11, c_bandeira   

    li $v0, 0x00FFFFFF        
    jr $ra

c_hidden:    
    lw $v0, color_hidden
    jr $ra
c_open:      
    lw $v0, color_open
    jr $ra
c_num1:      
    lw $v0, color_num1
    jr $ra
c_num2:      
    lw $v0, color_num2
    jr $ra
c_num3:      
    lw $v0, color_num3
    jr $ra
c_num4:      
    lw $v0, color_num4
    jr $ra
c_bomba:     
    lw $v0, color_bomba
    jr $ra
c_bomba_exp: 
    lw $v0, color_bomba
    jr $ra  
c_bandeira:  
    lw $v0, color_bandeira
    jr $ra

draw_game_cell:
    lw $t4, grid_x_offset     
    lw $t5, grid_y_offset     
    lw $t6, cell_size          

    mult $a0, $t6         
    mflo $t7
    add $t7, $t7, $t4          

    mult $a1, $t6         
    mflo $t8
    add $t8, $t8, $t5          

    move $t9, $zero
d_row_loop:
    beq $t9, $t6, d_end_cell  

    move $s7, $zero
d_col_loop:
    beq $s7, $t6, d_next_row  

    add $s5, $t7, $s7
    add $s6, $t8, $t9

    mult $s6, $s4
    mflo $t8                  
    
    add $t8, $t8, $s5
    sll $t8, $t8, 2
    add $t8, $t8, $s0

    sw $a2, 0($t8)             

    mult $a1, $t6         
    mflo $t8
    add $t8, $t8, $t5          

    addi $s7, $s7, 1          
    j d_col_loop

d_next_row:
    addi $t9, $t9, 1          
    j d_row_loop

d_end_cell:
    jr $ra