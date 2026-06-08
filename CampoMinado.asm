#####################################################################
# CENÁRIO DE CAMPO MINADO (VISUAL) PARA MARS BITMAP DISPLAY
#
# Configurações do Display:
# - Unit Width/Height: 4x4 pixels
# - Display Width/Height: 512x256
# - Base Address: 0x10010000 (static data)
#####################################################################

.data
# --- Definições de Memória do Display ---
display_base:    .word 0x10010000    # Endereço base da memória de vídeo (estática)
screen_width:    .word 128            # Largura lógica em 'units' (512 / 4)
screen_height:   .word 64             # Altura lógica em 'units' (256 / 4)

# --- Definições do Jogo ---
grid_size:       .word 10             # Tamanho da matriz (10x10)
cell_size:       .word 4              # Tamanho de cada célula do jogo (4x4 'units')
grid_x_offset:   .word 44             # Centralização horizontal: (128 - 10*4) / 2
grid_y_offset:   .word 12             # Centralização vertical: (64 - 10*4) / 2

# --- Definições de Cores (Formato 0x00RRGGBB) ---
color_hidden:    .word 0x00404040    # Cinza Escuro (Célula fechada)
color_open:      .word 0x00AAAAAA    # Cinza Claro (Célula vazia aberta)
color_borda:     .word 0x00000000    # Preto (Linhas de grade)
color_bomba:     .word 0x00FF0000    # Vermelho (Bomba)
color_bandeira:  .word 0x000000FF    # Azul (Bandeira)

# Cores dos números (1 a 4)
color_num1:      .word 0x000000FF    # Azul
color_num2:      .word 0x00008000    # Verde
color_num3:      .word 0x00FF0000    # Vermelho
color_num4:      .word 0x00000080    # Azul Marinho

# --- Definição do Mapa do Cenário ---
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
.globl get_cell_color
.globl draw_game_cell

main:
    # --- Inicialização de Registradores de Base ---
    lw $s0, display_base      
    la $s1, game_grid_map     
    lw $s2, grid_size         
    lw $s3, cell_size         
    lw $s4, screen_width      

    # --- Inicialização dos Loops de Renderização ---
    move $t0, $zero           # $t0 = Contador de Linha (row)

row_loop:
    beq $t0, $s2, end_main    
    move $t1, $zero           # $t1 = Contador de Coluna (col)

col_loop:
    beq $t1, $s2, next_row    

    # 1. Calcular o endereço do valor na matriz 'game_grid_map'
    mult $t0, $s2             
    mflo $t2                  
    add $t2, $t2, $t1         
    add $t2, $t2, $s1         
    lbu $t3, 0($t2)           # $t3 guarda o valor da célula

    # 2. Calcular a cor com base no valor lido da matriz
    jal get_cell_color        

    # 3. Desenhar o quadrado na tela
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

# =====================================================================
# ROTINA: get_cell_color
# =====================================================================
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

# =====================================================================
# ROTINA: draw_game_cell
# =====================================================================
draw_game_cell:
    lw $t4, grid_x_offset     
    lw $t5, grid_y_offset     
    lw $t6, cell_size         

    # x_start = (col * cell_size) + x_offset
    mult $a0, $t6         
    mflo $t7
    add $t7, $t7, $t4         

    # y_start = (row * cell_size) + y_offset
    mult $a1, $t6         
    mflo $t8
    add $t8, $t8, $t5         

    # Loops internos do quadrado
    move $t9, $zero           # y_inner = 0
d_row_loop:
    beq $t9, $t6, d_end_cell  

    move $s7, $zero           # x_inner = 0
d_col_loop:
    beq $s7, $t6, d_next_row  

    # Coordenadas finais do pixel
    add $s5, $t7, $s7         # x_final
    add $s6, $t8, $t9         # y_final

    # --- MATEMÁTICA DO PIXEL ---
    mult $s6, $s4             # y_final * screen_width (128)
    mflo $t8                  
    
    add $t8, $t8, $s5         # + x_final
    sll $t8, $t8, 2           # * 4
    add $t8, $t8, $s0         # + Endereço Base ($s0)

    sw $a2, 0($t8)            # Escreve a cor na tela

    # Restaura o valor original de y_start para o próximo pixel
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