`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module milestone2 (
	input logic clock,
   input logic resetn,
	
	input logic start,
	output logic done,

   output logic [17:0] SRAM_address,
   input logic [15:0] SRAM_read_data,
	
	output logic [15:0] SRAM_write_data,
	
	output logic SRAM_we_n
);

milestone2_state_type state;

//stores read Sprime elements
logic [15:0] Sprime_buf;

//SRAM read/write addresses and intermediate values
logic [17:0] addr_a, addr_b, read_address;
logic [17:0] addr_c, addr_d, write_address;

//coefficients currently being used
logic [31:0] c0, c1, c2, c3, c4, c5, c6, c7;

//sums S' * C products for each element
logic [31:0] SprimeC_accum;

//row and col within 8x8
logic [2:0] row_count;
logic [2:0] col_count;

//counts current matrix (0 =< X =< 39, 0 =< Y =< 29)
logic [5:0] matrix_X;
logic [4:0] matrix_Y;

logic [5:0] matrix_X_max;

//row and col within 8x8 (for writing)
logic [2:0] w_row_count;
logic [1:0] w_col_count;

//counts current matrix (for writing)
logic [5:0] w_matrix_X;
logic [4:0] w_matrix_Y;

logic [2:0] C_counter;
logic [2:0] Sprime_counter;
logic [1:0] T_counter;

//sums Ctrans * T products for each element
logic [31:0] S_accum;
//final S element to be written to memory (2 regs because writing 16 bits at a time)
logic [7:0] S_clipped [1:0];

//interface with dual-port RAM
logic [6:0] dp0_addr_a, dp0_addr_b, dp1_addr_a, dp1_addr_b;
logic [31:0] dp0_write_data_a, dp0_write_data_b, dp0_read_data_a, dp0_read_data_b, dp1_write_data_a, dp1_write_data_b, dp1_read_data_a, dp1_read_data_b;
logic dp0_we_a, dp0_we_b, dp1_we_a, dp1_we_b;

// instantiate RAM0
dual_port_RAM RAM0 (
	.address_a ( dp0_addr_a ),
	.address_b ( dp0_addr_b ),
	.clock ( clock ),
	.data_a ( dp0_write_data_a ),
	.data_b ( dp0_write_data_b ),
	.wren_a ( dp0_we_a ),
	.wren_b ( dp0_we_b ),
	.q_a ( dp0_read_data_a ),
	.q_b ( dp0_read_data_b )
);

// instantiate RAM1
dual_port_RAM RAM1 (
	.address_a ( dp1_addr_a ),
	.address_b ( dp1_addr_b ),
	.clock ( clock ),
	.data_a ( dp1_write_data_a ),
	.data_b ( dp1_write_data_b ),
	.wren_a ( dp1_we_a ),
	.wren_b ( dp1_we_b ),
	.q_a ( dp1_read_data_a ),
	.q_b ( dp1_read_data_b )
);

			 // factor 1 and 2 of multiplier 1, factor 1 and 2 of multiplier 2
logic [31:0] factor11, factor12, product1, factor21, factor22, product2;
			 // 64 bit version of product, truncated later
logic [63:0] product1_long, product2_long;

//multiplier 1
assign product1_long = factor11 * factor12;
assign product1 = product1_long[31:0];

//multiplier 2
assign product2_long = factor21 * factor22;
assign product2 = product2_long[31:0];

//decodes SRAM reading address
//assign addr_a = (matrix_Y << 11) + (matrix_Y << 9) + (matrix_X << 3);
//assign addr_b = (row_count << 8) + (row_count << 6) + col_count;
//assign read_address = 18'd76800 + addr_a + addr_b;

//decodes SRAM writing address
//assign addr_c = (w_matrix_Y << 10) + (w_matrix_Y << 8) + (w_matrix_X << 2);
//assign addr_d = (w_row_count << 7) + (w_row_count << 5) + w_col_count;
//assign write_address = addr_c + addr_d;

always_comb begin
	
	if (write_address >= 18'd38400) begin
		matrix_X_max <= 6'd19;
		
		addr_a = (matrix_Y << 10) + (matrix_Y << 8) + (matrix_X << 3);
		addr_b = (row_count << 5) + (row_count << 4) + col_count;
		read_address = 18'd76800 + addr_a + addr_b;
		
		addr_c = (w_matrix_Y << 10) + (w_matrix_Y << 8) + (w_matrix_X << 2);
		addr_d = (w_row_count << 7) + (w_row_count << 5) + w_col_count;
		write_address = addr_c + addr_d;
	end else begin
		matrix_X_max <= 6'd39;
		
		addr_a = (matrix_Y << 11) + (matrix_Y << 9) + (matrix_X << 3);
		addr_b = (row_count << 8) + (row_count << 6) + col_count;
		read_address = 18'd76800 + addr_a + addr_b;
		
		addr_c = (w_matrix_Y << 10) + (w_matrix_Y << 8) + (w_matrix_X << 2);
		addr_d = (w_row_count << 7) + (w_row_count << 5) + w_col_count;
		write_address = addr_c + addr_d;
	end
end

always_comb begin	// controls which values in matrix C are being used

	c0 <= 32'sd1448;

	case(C_counter)
		3'd0: begin
			c1 <= 32'sd2008;
			c2 <= 32'sd1892;
			c3 <= 32'sd1702;
			c4 <= 32'sd1448;
			c5 <= 32'sd1137;
			c6 <= 32'sd783;
			c7 <= 32'sd399;
		end
		3'd1: begin
			c1 <= 32'sd1702;
			c2 <= 32'sd783;
			c3 <= 32'hFFFFFE71;//-399
			c4 <= 32'hFFFFFA58;//-1448
			c5 <= 32'hFFFFF828;//-2008
			c6 <= 32'hFFFFF89C;//-1892
			c7 <= 32'hFFFFFB8F;//-1137
		end
		3'd2: begin
			c1 <= 32'sd1137;
			c2 <= 32'hFFFFFCF1;//-783
			c3 <= 32'hFFFFF828;//-2008
			c4 <= 32'hFFFFFA58;//-1448
			c5 <= 32'sd399;
			c6 <= 32'sd1892;
			c7 <= 32'sd1702;
		end
		3'd3: begin
			c1 <= 32'sd399;
			c2 <= 32'hFFFFF89C;//-1892
			c3 <= 32'hFFFFFB8F;//-1137
			c4 <= 32'sd1448;
			c5 <= 32'sd1702;
			c6 <= 32'hFFFFFCF1;//-783
			c7 <= 32'hFFFFF828;//-2008
		end
		3'd4: begin
			c1 <= 32'hFFFFFE71;//-399
			c2 <= 32'hFFFFF89C;//-1892
			c3 <= 32'sd1137;
			c4 <= 32'sd1448;
			c5 <= 32'hFFFFF95A;//-1702
			c6 <= 32'hFFFFFCF1;//-783
			c7 <= 32'sd2008;
		end
		3'd5: begin
			c1 <= 32'hFFFFFB8F;//-1137
			c2 <= 32'hFFFFFCF1;//-783
			c3 <= 32'sd2008;
			c4 <= 32'hFFFFFA58;//-1448
			c5 <= 32'hFFFFFE71;//-399
			c6 <= 32'sd1892;
			c7 <= 32'hFFFFF95A;//-1702
		end
		3'd6: begin
			c1 <= 32'hFFFFF95A;//-1702
			c2 <= 32'sd783;
			c3 <= 32'sd399;
			c4 <= 32'hFFFFFA58;//-1448
			c5 <= 32'sd2008;
			c6 <= 32'hFFFFF89C;//-1892
			c7 <= 32'sd1137;
		end
		3'd7: begin
			c1 <= 32'hFFFFF828;//-2008
			c2 <= 32'sd1892;
			c3 <= 32'hFFFFF95A;//-1702
			c4 <= 32'sd1448;
			c5 <= 32'hFFFFFB8F;//-1137
			c6 <= 32'sd783;
			c7 <= 32'hFFFFFE71;//-399
		end
	endcase

end

always_ff @ (posedge clock or negedge resetn) begin
	if (resetn == 1'b0) begin
		SRAM_address <= 18'd0;
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
	
		C_counter <= 3'd0;
		Sprime_counter <= 3'd0;
		T_counter <= 2'd0;
		
		row_count <= 3'd0;
		col_count <= 3'd0;
		matrix_X <= 6'd0;
		matrix_Y <= 5'd0;
		
		w_row_count <= 3'd0;
		w_col_count <= 2'd0;
		w_matrix_X <= 6'd0;
		w_matrix_Y <= 5'd0;
		
		Sprime_buf <= 16'd0;
		SprimeC_accum <= 32'd0;
		S_accum <= 32'd0;
		
		S_clipped[1] <= 8'd0;
		S_clipped[0] <= 8'd0;
		
		dp0_we_a <= 1'b0;
		dp0_addr_a <= 7'd0;
		dp0_write_data_a <= 32'd0;
		
		dp0_we_b <= 1'd0;
		dp0_addr_b <= 7'd0;
		dp0_write_data_b <= 32'd0;
		
		dp1_we_a <= 1'b0;
		dp1_addr_a <= 7'd0;
		dp1_write_data_a <= 32'd0;
		
		dp1_we_b <= 1'd0;
		dp1_addr_b <= 7'd0;
		dp1_write_data_b <= 32'd0;
		
		done <= 1'b0;
		
		state <= S_M2_IDLE;
		
	end else begin
		case (state)
			S_M2_IDLE: begin
				if (start != 1'b0) begin
					state <= S_FS_1;
				end
			end
			
			S_FS_1: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				state <= S_FS_2;
			end
			
			S_FS_2: begin 
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				state <= S_FS_3;
			end
			
			S_FS_3: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				state <= S_FS_4;
			end
			
			S_FS_4: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				Sprime_buf <= SRAM_read_data;
				
				state <= S_FS_5;
			end
			
			S_FS_5: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_we_b <= 1'b1;
				
				if (row_count == 3'd0) begin
					dp0_addr_b <= 7'd0;
				end else begin
					dp0_addr_b <= dp0_addr_b + 7'd1;
				end
				
				state <= S_FS_6;
			end
			
			S_FS_6: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				Sprime_buf <= SRAM_read_data;
				
				dp0_we_b <= 1'b0;
				
				state <= S_FS_7;
			end
			
			S_FS_7: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_addr_b <= dp0_addr_b + 7'd1;
				dp0_we_b <= 1'b1;
				
				state <= S_FS_8;
			end
			
			S_FS_8: begin
				SRAM_address <= read_address;
				row_count <= row_count + 3'd1;
				col_count <= col_count + 3'd1;
				
				Sprime_buf <= SRAM_read_data;
				
				dp0_we_b <= 1'b0;
				
				state <= S_FS_9;
			end
			
			S_FS_9: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_addr_b <= dp0_addr_b + 7'd1;
				dp0_we_b <= 1'b1;
				
				state <= S_FS_10;
			end
			
			S_FS_10: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				Sprime_buf <= SRAM_read_data;
				
				dp0_we_b <= 1'b0;
				
				state <= S_FS_11;
			end
			
			S_FS_11: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_addr_b <= dp0_addr_b + 7'd1;
				dp0_we_b <= 1'b1;
				
				state <= S_FS_12;
			end
			
			S_FS_12: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				Sprime_buf <= SRAM_read_data;
				
				dp0_we_b <= 1'b0;
				
				if (row_count == 3'd7) begin
					state <= S_FS_13;
				end else begin
					state <= S_FS_5;
				end
			end
			
			S_FS_13: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_addr_b <= dp0_addr_b + 7'd1;
				dp0_we_b <= 1'b1;
				
				state <= S_FS_14;
			end
			
			S_FS_14: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				Sprime_buf <= SRAM_read_data;
				
				dp0_we_b <= 1'b0;
				
				state <= S_FS_15;
			end
			
			S_FS_15: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_addr_b <= dp0_addr_b + 7'd1;
				dp0_we_b <= 1'b1;
				
				state <= S_FS_16;
			end
			
			S_FS_16: begin
				SRAM_address <= read_address;
				col_count <= col_count + 3'd1;
				row_count <= row_count + 3'd1;
				
				Sprime_buf <= SRAM_read_data;
				
				dp0_we_b <= 1'b0;
				
				state <= S_FS_17;
			end
			
			S_FS_17: begin
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_addr_b <= dp0_addr_b + 7'd1;
				dp0_we_b <= 1'b1;
				
				matrix_X <= matrix_X + 6'd1;
				
				state <= S_FS_18;
			end
			
			S_FS_18: begin
				Sprime_buf <= SRAM_read_data;
				
				dp0_addr_a <= 1'b0;
				dp0_we_b <= 1'b0;
				
				state <= S_FS_19;
			end
			
			S_FS_19: begin
				dp0_write_data_b <= {Sprime_buf, SRAM_read_data};
				dp0_addr_b <= dp0_addr_b + 7'd1;
				dp0_we_b <= 1'b1;
				
				dp0_addr_a <= dp0_addr_a + 7'd1;
				
				state <= S_CT_1;
			end
			
			S_CT_1: begin
				if ((Sprime_counter != 3'd0) || (C_counter != 3'd0)) begin
					dp0_write_data_b <= ($signed(SprimeC_accum) + $signed(product1) + $signed(product2)) >>> 8;
					dp0_we_b <= 1'b1;
				end else begin
					dp0_we_b <= 1'b0;
				end
				
				if ((Sprime_counter == 3'd0) && (C_counter == 3'd1)) begin
					dp0_addr_b <= 7'd64;
				end else begin
					dp0_addr_b <= dp0_addr_b + 7'd1;
				end
				
				dp0_addr_a <= dp0_addr_a + 7'd1;

				factor11 <= c0;
				factor12 <= $signed(dp0_read_data_a[31:16]);
				factor21 <= c1;
				factor22 <= $signed(dp0_read_data_a[15:0]);
				
				state <= S_CT_2;
			end
			
			S_CT_2: begin
				dp0_we_b <= 1'b0;
				dp0_addr_a <= dp0_addr_a + 7'd1;
				
				factor11 <= c2;
				factor12 <= $signed(dp0_read_data_a[31:16]);
				factor21 <= c3;
				factor22 <= $signed(dp0_read_data_a[15:0]);
				
				SprimeC_accum <= $signed(product1) + $signed(product2);
				
				state <= S_CT_3;
			end
			
			S_CT_3: begin
				if (C_counter == 3'd7) begin
					dp0_addr_a <= dp0_addr_a + 7'd1;
				end else begin
					dp0_addr_a <= dp0_addr_a - 7'd3;
				end
				
				factor11 <= c4;
				factor12 <= $signed(dp0_read_data_a[31:16]);
				factor21 <= c5;
				factor22 <= $signed(dp0_read_data_a[15:0]);
				
				SprimeC_accum <= $signed(SprimeC_accum) + $signed(product1) + $signed(product2);
				
				state <= S_CT_4;
			end
			
			S_CT_4: begin

				dp0_addr_a <= dp0_addr_a + 7'd1;

				factor11 <= c6;
				factor12 <= $signed(dp0_read_data_a[31:16]);
				factor21 <= c7;
				factor22 <= $signed(dp0_read_data_a[15:0]);
				
				SprimeC_accum <= $signed(SprimeC_accum) + $signed(product1) + $signed(product2);
				
				C_counter <= C_counter + 3'd1;
				if (C_counter == 3'd7) begin
					Sprime_counter <= Sprime_counter + 3'd1;
				end
				
				if ((Sprime_counter == 3'd7) && (C_counter == 3'd7)) begin
					state <= S_CT_5;
				end else begin
					state <= S_CT_1;
				end
			end
			
			S_CT_5: begin
				dp0_write_data_b <= ($signed(SprimeC_accum) + $signed(product1) + $signed(product2)) >>> 8;
				dp0_addr_b <= dp0_addr_b + 7'd1;
				
				state <= S_CT_6;
			end
			
			S_CT_6: begin
				dp0_addr_a <= 7'd64;
				dp0_addr_b <= 7'd72;
				
				state <= S_CT_7;
			end
			
			S_CT_7: begin
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				state <= S_CSFS_1;
			end
			
/////////CSFS////////////////////////////////////////////////////////////////
			
			S_CSFS_1: begin
				factor11 <= c0;
				factor12 <= dp0_read_data_a;
				factor21 <= c1;
				factor22 <= dp0_read_data_b;

				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				if ((col_count != 3'd0) || (row_count != 3'd0)) begin
					dp1_addr_b <= dp1_addr_b + 7'd1;
					dp1_write_data_b <= {Sprime_buf, SRAM_read_data};
				end
				
				if ((C_counter != 3'd0) || (T_counter != 2'd0)) begin
					S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				end
				
				SRAM_address <= read_address;
				
				col_count <= col_count + 3'd1;
				
				state <= S_CSFS_2;
			end
			
			S_CSFS_2: begin
				factor11 <= c2;
				factor12 <= dp0_read_data_a;
				factor21 <= c3;
				factor22 <= dp0_read_data_b;
					
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				SRAM_address <= read_address;
				
				S_accum <= $signed(product1) + $signed(product2);
				
				col_count <= col_count + 3'd1;
				
				if (S_accum[31] == 1'b1) S_clipped[0] <= 8'd0;
				else begin
					if (|S_accum[30:24]) S_clipped[0] <= 8'd255;
					else S_clipped[0] <= S_accum[23:16];
				end
				
				if ((col_count != 3'd0) && (row_count != 3'd0)) begin
					Sprime_buf <= SRAM_read_data;
				end
				
				state <= S_CSFS_3;
			end
			
			S_CSFS_3: begin
				factor11 <= c4;
				factor12 <= dp0_read_data_a;
				factor21 <= c5;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a - 7'd47;
				dp0_addr_b <= dp0_addr_b - 7'd47;
				
				SRAM_address <= read_address;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				if ((col_count != 3'd0) && (row_count != 3'd0)) begin
					dp1_addr_b <= dp1_addr_b + 7'd1;
					dp1_write_data_b <= {Sprime_buf, SRAM_read_data};
				end
				
				if ((C_counter != 3'd0) || (T_counter != 2'd0)) begin
					if ((C_counter == 3'd0) && (T_counter == 2'd1)) begin
						dp1_addr_a <= 7'd64;
					end else begin
						dp1_addr_a <= dp1_addr_a + 7'd1;
					end
					dp1_we_a <= 1'b1;
					dp1_write_data_a <= {S_clipped[1], S_clipped[0], 16'd0};
				end
				
				
				col_count <= col_count + 3'd1;
				
				state <= S_CSFS_4;
			end
			
			S_CSFS_4: begin
				factor11 <= c6;
				factor12 <= dp0_read_data_a;
				factor21 <= c7;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				dp1_we_a <= 1'b0;
				
				SRAM_address <= read_address;
				Sprime_buf <= SRAM_read_data;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				col_count <= col_count + 3'd1;
				
				state <= S_CSFS_5;
			end
			
			S_CSFS_5: begin
				factor11 <= c0;
				factor12 <= dp0_read_data_a;
				factor21 <= c1;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				SRAM_address <= read_address;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				if ((col_count != 3'd0) && (row_count != 3'd0)) begin
					dp1_addr_b <= dp1_addr_b + 7'd1;
				end else begin
					dp1_addr_b <= 7'd0;
					dp1_we_b <= 1'b1;
				end
				dp1_write_data_b <= {Sprime_buf, SRAM_read_data};
				
				col_count <= col_count + 3'd1;
				
				state <= S_CSFS_6;
			end
			
			S_CSFS_6: begin
				factor11 <= c2;
				factor12 <= dp0_read_data_a;
				factor21 <= c3;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				SRAM_address <= read_address;
				Sprime_buf <= SRAM_read_data;
				
				S_accum <= $signed(product1) + $signed(product2);
				
				if (S_accum[31] == 1'b1) S_clipped[1] <= 8'd0;
				else begin
					if (|S_accum[30:24]) S_clipped[1] <= 8'd255;
					else S_clipped[1] <= S_accum[23:16];
				end
				
				col_count <= col_count + 3'd1;
				
				state <= S_CSFS_7;
			end
			
			S_CSFS_7: begin
				factor11 <= c4;
				factor12 <= dp0_read_data_a;
				factor21 <= c5;
				factor22 <= dp0_read_data_b;
				
				if (T_counter == 2'd3) begin
					dp0_addr_a <= 7'd64;
					dp0_addr_b <= 7'd72;
				end else begin
					dp0_addr_a <= dp0_addr_a - 7'd47;
					dp0_addr_b <= dp0_addr_b - 7'd47;
				end
				
				SRAM_address <= read_address;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				dp1_addr_b <= dp1_addr_b + 7'd1;
				dp1_write_data_b <= {Sprime_buf, SRAM_read_data};
				
				col_count <= col_count + 3'd1;
				
				state <= S_CSFS_8;
			end
			
			S_CSFS_8: begin
				factor11 <= c6;
				factor12 <= dp0_read_data_a;
				factor21 <= c7;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				SRAM_address <= read_address;
				Sprime_buf <= SRAM_read_data;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				T_counter <= T_counter + 2'd1;
				if (T_counter == 2'd3) begin
					C_counter <= C_counter + 3'd1;
				end
				
				col_count <= col_count + 3'd1;
				if (col_count == 3'd7) begin
					row_count <= row_count + 3'd1;
				end
				if (row_count == 3'd7) begin
					
					if (matrix_X == matrix_X_max) begin
						matrix_X <= 6'd0;
						matrix_Y <= matrix_Y + 5'd1;
					end else begin
						matrix_X <= matrix_X + 6'd1;
					end
					
					state <= S_CSFS_9;
				end else begin
					state <= S_CSFS_1;
				end
			end
			
			S_CSFS_9: begin
				factor11 <= c0;
				factor12 <= dp0_read_data_a;
				factor21 <= c1;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				if ((C_counter == 3'd2) && (T_counter == 2'd0)) begin
					dp1_addr_b <= dp1_addr_b + 7'd1;
					dp1_write_data_b <= {Sprime_buf, SRAM_read_data};
				end
				
				state <= S_CSFS_10;
			end
			
			S_CSFS_10: begin
				factor11 <= c2;
				factor12 <= dp0_read_data_a;
				factor21 <= c3;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				S_accum <= $signed(product1) + $signed(product2);
			
				if ((C_counter == 3'd2) && (T_counter == 2'd0)) begin
					Sprime_buf <= SRAM_read_data;
				end
				
				if (S_accum[31] == 1'b1) S_clipped[0] <= 8'd0;
				else begin
					if (|S_accum[30:24]) S_clipped[0] <= 8'd255;
					else S_clipped[0] <= S_accum[23:16];
				end
			
				state <= S_CSFS_11;
			end
			
			S_CSFS_11: begin
				factor11 <= c4;
				factor12 <= dp0_read_data_a;
				factor21 <= c5;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a - 7'd47;
				dp0_addr_b <= dp0_addr_b - 7'd47;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
			
				if ((C_counter == 3'd2) && (T_counter == 2'd0)) begin
					dp1_addr_b <= dp1_addr_b + 7'd1;
					dp1_write_data_b <= {Sprime_buf, SRAM_read_data};
				end
				
				dp1_we_a <= 1'b1;
				dp1_addr_a <= dp1_addr_a + 7'd1;
				dp1_write_data_a <= {S_clipped[1], S_clipped[0], 16'd0};
				
				state <= S_CSFS_12;
			end
			
			S_CSFS_12: begin
				factor11 <= c6;
				factor12 <= dp0_read_data_a;
				factor21 <= c7;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				dp1_we_a <= 1'd0;
				
				state <= S_CSFS_13;
			end
			
			S_CSFS_13: begin
				factor11 <= c0;
				factor12 <= dp0_read_data_a;
				factor21 <= c1;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				state <= S_CSFS_14;
			end
			
			S_CSFS_14: begin
				factor11 <= c2;
				factor12 <= dp0_read_data_a;
				factor21 <= c3;
				factor22 <= dp0_read_data_b;
				
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				S_accum <= $signed(product1) + $signed(product2);
				
				if (S_accum[31] == 1'b1) S_clipped[1] <= 8'd0;
				else begin
					if (|S_accum[30:24]) S_clipped[1] <= 8'd255;
					else S_clipped[1] <= S_accum[23:16];
				end
				
				state <= S_CSFS_15;
			end
			
			S_CSFS_15: begin
				factor11 <= c4;
				factor12 <= dp0_read_data_a;
				factor21 <= c5;
				factor22 <= dp0_read_data_b;
				
				if (T_counter == 2'd3) begin
					dp0_addr_a <= 7'd64;
					dp0_addr_b <= 7'd72;
				end else begin
					dp0_addr_a <= dp0_addr_a - 7'd47;
					dp0_addr_b <= dp0_addr_b - 7'd47;
				end
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				state <= S_CSFS_16;
			end
			
			S_CSFS_16: begin
				factor11 <= c6;
				factor12 <= dp0_read_data_a;
				factor21 <= c7;
				factor22 <= dp0_read_data_b;
				
				if ((C_counter != 3'd7) || (T_counter != 2'd3)) begin
					dp0_addr_a <= dp0_addr_a + 7'd16;
					dp0_addr_b <= dp0_addr_b + 7'd16;
				end
				
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				T_counter <= T_counter + 2'd1;
				
				
				if (T_counter == 2'd3) begin
					C_counter <= C_counter + 3'd1;
				end
				
				if ((C_counter == 3'd7) && (T_counter == 2'd3)) begin
					state <= S_CSFS_17;
				end else begin
					state <= S_CSFS_9;
				end
			end
			
			S_CSFS_17: begin
				S_accum <= $signed(S_accum) + $signed(product1) + $signed(product2);
				
				state <= S_CSFS_18;
			end
			
			S_CSFS_18: begin
				
				if (S_accum[31] == 1'b1) S_clipped[0] <= 8'd0;
				else begin
					if (|S_accum[30:24]) S_clipped[0] <= 8'd255;
					else S_clipped[0] <= S_accum[23:16];
				end
				
				state <= S_CSFS_19;
			end
			
			S_CSFS_19: begin
				dp1_addr_a <= dp1_addr_a + 7'd1;
				dp1_write_data_a <= {S_clipped[1], S_clipped[0], 16'd0};
				dp1_we_a <= 1'd1;
				
				state <= S_CSFS_20;
			end
			
			S_CSFS_20: begin
				dp1_addr_b <= 7'd64;
				dp1_we_b <= 1'b0;
				
				dp1_addr_a <= 7'd0;
				dp1_we_a <= 1'b0;
				
				
				state <= S_CSFS_21;
			end
			
			S_CSFS_21: begin
				dp1_addr_a = dp1_addr_a + 7'd1;
				dp1_addr_b <= dp1_addr_b + 7'd1;
			
				state <= S_WSCT_1;
			end
			
/////////WSCT///////////////////////////////////////////////////////////////////////
			
			S_WSCT_1: begin
				if ((C_counter != 3'd0) || (Sprime_counter != 3'd0)) begin
					dp0_write_data_b <= ($signed(SprimeC_accum) + $signed(product1) + $signed(product2)) >>> 8; 
					dp0_we_b <= 1'b1;
					
					if ((C_counter == 3'd1) && (Sprime_counter == 3'd0)) begin
						dp0_addr_b <= 7'd64; 
					end else begin
						dp0_addr_b <= dp0_addr_b + 7'd1;
					end
				end
				
				w_col_count <= w_col_count + 2'd1;
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				SRAM_write_data <= dp1_read_data_b[31:16];
				
				dp1_addr_b <= dp1_addr_b + 7'd1;
				dp1_addr_a <= dp1_addr_a + 7'd1;

				factor11 <= c0;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c1;
				factor22 <= $signed(dp1_read_data_a[15:0]);
			
				state <= S_WSCT_2;
			end
			
			S_WSCT_2: begin
				w_col_count <= w_col_count + 2'd1;
		
				SRAM_address <= write_address;
				SRAM_write_data <= dp1_read_data_b[31:16];
				
				dp1_addr_b <= dp1_addr_b + 7'd1;
				
				dp0_we_b <= 1'b0;
				
				dp1_addr_a = dp1_addr_a + 7'd1;
				
				factor11 <= c2;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c3;
				factor22 <= $signed(dp1_read_data_a[15:0]);
				
				SprimeC_accum <= $signed(product1) + $signed(product2);
				
				state <= S_WSCT_3;
			end
			
			S_WSCT_3: begin		
				w_col_count <= w_col_count + 2'd1;
				
				dp1_addr_b <= dp1_addr_b + 7'd1;
				
				SRAM_address <= write_address;
				SRAM_write_data <= dp1_read_data_b[31:16];
				
				if (C_counter == 3'd7) begin
					dp1_addr_a <= dp1_addr_a + 7'd1;
				end else begin
					dp1_addr_a <= dp1_addr_a - 7'd3;
				end
				
				factor11 <= c4;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c5;
				factor22 <= $signed(dp1_read_data_a[15:0]);
				
				SprimeC_accum <= $signed(SprimeC_accum) + $signed(product1) + $signed(product2);
			
				state <= S_WSCT_4;
			end
			
			S_WSCT_4: begin
				w_row_count <= w_row_count + 3'd1; 			
				w_col_count <= w_col_count + 2'd1;
			
				if (w_row_count == 3'd7) begin
					w_matrix_X <= w_matrix_X + 6'd1;
					
					if (w_matrix_X == 6'd39) begin
						w_matrix_X <= 6'd0;
						w_matrix_Y <= w_matrix_Y + 5'd1;
					end
				end
				
				
				SRAM_address <= write_address;
				SRAM_write_data <= dp1_read_data_b[31:16];
				
				dp1_addr_b <= dp1_addr_b + 7'b1;
				dp1_addr_a = dp1_addr_a + 7'd1;
				
				factor11 <= c6;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c7;
				factor22 <= $signed(dp1_read_data_a[15:0]);
				
				SprimeC_accum <= $signed(SprimeC_accum) + $signed(product1) + $signed(product2);
				
				C_counter <= C_counter + 3'd1;
				
				if (C_counter == 3'd7) begin 
					Sprime_counter <= Sprime_counter + 3'd1;
					state <= S_WSCT_5;
				end else begin
					state <= S_WSCT_1;
				end
			end
			
			S_WSCT_5: begin
				dp0_write_data_b <= ($signed(SprimeC_accum) + $signed(product1) + $signed(product2)) >>> 8; 
				dp0_addr_b <= dp0_addr_b + 7'd1; 
				dp0_we_b <= 1'b1;
				
				dp1_addr_a = dp1_addr_a + 7'd1;
			
				factor11 <= c0;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c1;
				factor22 <= $signed(dp1_read_data_a[15:0]);
				
				SRAM_we_n <= 1'b1;
			
				state <= S_WSCT_6;
			end
			
			S_WSCT_6: begin
				factor11 <= c2;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c3;
				factor22 <= $signed(dp1_read_data_a[15:0]);
				
				dp1_addr_a = dp1_addr_a + 7'd1;
				
				dp0_we_b <= 1'b0;
				
				SprimeC_accum <= $signed(product1) + $signed(product2);
			
				state <= S_WSCT_7;
			end
			
			S_WSCT_7: begin
				factor11 <= c4;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c5;
				factor22 <= $signed(dp1_read_data_a[15:0]);
				
				if (C_counter == 3'd7) begin
					dp1_addr_a <= dp1_addr_a + 7'd1;
				end else begin
					dp1_addr_a <= dp1_addr_a - 7'd3;
				end
				
				SprimeC_accum <= $signed(SprimeC_accum) + $signed(product1) + $signed(product2);
			
				state <= S_WSCT_8;
			end
			
			S_WSCT_8: begin
				factor11 <= c6;
				factor12 <= $signed(dp1_read_data_a[31:16]);
				factor21 <= c7;
				factor22 <= $signed(dp1_read_data_a[15:0]);
				
				dp1_addr_a = dp1_addr_a + 7'd1;
				
				SprimeC_accum <= $signed(SprimeC_accum) + $signed(product1) + $signed(product2);
				
				C_counter <= C_counter + 3'd1;
				
				if (C_counter == 3'd7) begin
					Sprime_counter <= Sprime_counter + 3'd1;
				end
				
				if ((Sprime_counter == 3'd7) && (C_counter == 3'd7)) begin
					state <= S_WSCT_9;
				end else begin
					state <= S_WSCT_5;
				end
			end
			
			S_WSCT_9: begin
				dp0_write_data_b <= ($signed(SprimeC_accum) + $signed(product1) + $signed(product2)) >>> 8; 
				dp0_addr_b <= dp0_addr_b + 7'd1; 
				dp0_we_b <= 1'b1;
				
				state <= S_WSCT_10;
			end
			
			S_WSCT_10: begin
				dp0_addr_a <= 7'd64;
				dp0_addr_b <= 7'd72;
				
				dp0_we_b <= 1'b0;
			
				state <= S_WSCT_11;
			end
			
			S_WSCT_11: begin
				dp0_addr_a <= dp0_addr_a + 7'd16;
				dp0_addr_b <= dp0_addr_b + 7'd16;
				
				state <= S_CSFS_1;
			end
			
			
		endcase
		
	end
end

endmodule
		
		
	