onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 20 {Top-level signals}
add wave -noupdate -radix binary /TB/UUT/CLOCK_50_I
add wave -noupdate -radix binary /TB/UUT/resetn
add wave -noupdate /TB/UUT/top_state
add wave -noupdate -radix unsigned /TB/UUT/UART_timer

add wave -noupdate -divider -height 10 {SRAM signals}
add wave -noupdate -radix unsigned -childformat {{{/TB/UUT/SRAM_address[17]} -radix unsigned} {{/TB/UUT/SRAM_address[16]} -radix unsigned} {{/TB/UUT/SRAM_address[15]} -radix unsigned} {{/TB/UUT/SRAM_address[14]} -radix unsigned} {{/TB/UUT/SRAM_address[13]} -radix unsigned} {{/TB/UUT/SRAM_address[12]} -radix unsigned} {{/TB/UUT/SRAM_address[11]} -radix unsigned} {{/TB/UUT/SRAM_address[10]} -radix unsigned} {{/TB/UUT/SRAM_address[9]} -radix unsigned} {{/TB/UUT/SRAM_address[8]} -radix unsigned} {{/TB/UUT/SRAM_address[7]} -radix unsigned} {{/TB/UUT/SRAM_address[6]} -radix unsigned} {{/TB/UUT/SRAM_address[5]} -radix unsigned} {{/TB/UUT/SRAM_address[4]} -radix unsigned} {{/TB/UUT/SRAM_address[3]} -radix unsigned} {{/TB/UUT/SRAM_address[2]} -radix unsigned} {{/TB/UUT/SRAM_address[1]} -radix unsigned} {{/TB/UUT/SRAM_address[0]} -radix unsigned}} -subitemconfig {{/TB/UUT/SRAM_address[17]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[16]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[15]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[14]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[13]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[12]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[11]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[10]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[9]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[8]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[7]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[6]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[5]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[4]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[3]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[2]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[1]} {-height 15 -radix unsigned} {/TB/UUT/SRAM_address[0]} {-height 15 -radix unsigned}} /TB/UUT/SRAM_address
add wave -noupdate -radix hexadecimal /TB/UUT/SRAM_write_data
add wave -noupdate -radix binary /TB/UUT/SRAM_we_n
add wave -noupdate -radix hexadecimal /TB/UUT/SRAM_read_data

#add wave -noupdate -divider -height 10 {VGA signals}
#add wave -noupdate -radix binary /TB/UUT/VGA_unit/VGA_HSYNC_O
#add wave -noupdate -radix binary /TB/UUT/VGA_unit/VGA_VSYNC_O
#add wave -noupdate -radix unsigned /TB/UUT/VGA_unit/pixel_X_pos
#add wave -noupdate -radix unsigned /TB/UUT/VGA_unit/pixel_Y_pos
#add wave -noupdate -radix hexadecimal /TB/UUT/VGA_unit/VGA_red
#add wave -noupdate -radix hexadecimal /TB/UUT/VGA_unit/VGA_green
#add wave -noupdate -radix hexadecimal /TB/UUT/VGA_unit/VGA_blue
#add wave -noupdate -radix hexadecimal /TB/UUT/VGA_unit/SRAM_address
#add wave -noupdate -radix hexadecimal /TB/UUT/VGA_unit/SRAM_read_data
#add wave -noupdate -radix hexadecimal /TB/UUT/VGA_unit/SRAM_base_address
#add wave -noupdate -radix hexadecimal /TB/UUT/VGA_unit/VIEW_AREA_TOP


add wave -noupdate -divider -height 10 {milestone2 signals}
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/row_count
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/col_count
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/matrix_X
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/matrix_Y
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c0
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c1
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c2
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c3
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c4
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c5
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c6
add wave -noupdate -radix decimal /TB/UUT/m2_unit/c7
add wave -noupdate -radix binary /TB/UUT/m2_unit/state
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/w_row_count
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/w_col_count
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/w_matrix_X
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/w_matrix_Y
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/read_address
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/write_address
add wave -noupdate -radix decimal /TB/UUT/m2_unit/Sprime_buf
add wave -noupdate -radix decimal /TB/UUT/m2_unit/SprimeC_accum
add wave -noupdate -radix decimal /TB/UUT/m2_unit/S_accum
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/S_clipped
add wave -noupdate -radix decimal /TB/UUT/m2_unit/factor12
add wave -noupdate -radix decimal /TB/UUT/m2_unit/factor22
add wave -noupdate -radix decimal /TB/UUT/m2_unit/product1
add wave -noupdate -radix decimal /TB/UUT/m2_unit/product2
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/C_counter
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/Sprime_counter
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/T_counter

add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_addr_a
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_write_data_a
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_read_data_a
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_we_a

add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_addr_b
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_write_data_b
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_read_data_b
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp0_we_b

add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp1_addr_a
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp1_write_data_a
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp1_read_data_a
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp1_we_a

add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp1_addr_b
add wave -noupdate -radix hexadecimal /TB/UUT/m2_unit/dp1_write_data_b
add wave -noupdate -radix hexadecimal /TB/UUT/m2_unit/dp1_read_data_b
add wave -noupdate -radix unsigned /TB/UUT/m2_unit/dp1_we_b




#add wave -noupdate -divider -height 10 {milestone1 signals}
#add wave -noupdate -radix binary /TB/UUT/m1_unit/state
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/X_pos_counter
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/Y_read_buf
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/U_read_buf
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/V_read_buf
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/write_address
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/R_value_even
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/R_value_odd
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/G_value_even
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/G_value_odd
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/B_value_even
#add wave -noupdate -radix unsigned /TB/UUT/m1_unit/B_value_odd
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/R_sum
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/G_sum
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/B_sum
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/Uprime_even
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/Uprime_odd
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/Vprime_even
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/Vprime_odd
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/product1
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/product2
#add wave -noupdate -radix decimal /TB/UUT/m1_unit/product3
#add wave -noupdate /TB/UUT/VGA_enable
#add wave -noupdate -radix binary /TB/UUT/SRAM_base_address

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7340165600 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {346800 ps}
