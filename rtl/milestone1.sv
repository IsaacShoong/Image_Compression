`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module milestone1 (
	input logic clock,
   input logic resetn,
	
	input logic start,
	output logic done,

   output logic [17:0] SRAM_address,
   input logic [15:0] SRAM_read_data,
	
	output logic [15:0] SRAM_write_data,
	
	output logic SRAM_we_n
);

milestone1_state_type state;

//New Registers we have to put
logic [7:0] Y_read_buf [1:0];
logic [7:0] U_read_buf [6:0];
logic [7:0] V_read_buf [6:0];
logic [7:0] R_value_even, R_value_odd, B_value_even, B_value_odd, G_value_even, G_value_odd;

logic [8:0] X_pos_counter;

logic [17:0] Y_address, U_address, V_address, write_address;

logic [31:0] R_sum, G_sum, B_sum;

logic [31:0] Uprime_even, Uprime_odd, Vprime_even, Vprime_odd;

			 // factor 1 and 2 of multiplier 1, factor 1 and 2 of multiplier 2, factor 1 and 2 of multiplier 3
logic [31:0] factor11, factor12, product1, factor21, factor22, product2, factor31, factor32, product3;
			 // 64 bit version of product, truncated later
logic [63:0] product1_long, product2_long, product3_long;

//multiplier 1
assign product1_long = factor11 * factor12;
assign product1 = product1_long[31:0];

//multiplier 2
assign product2_long = factor21 * factor22;
assign product2 = product2_long[31:0];

//multiplier 3
assign product3_long = factor31 * factor32;
assign product3 = product3_long[31:0];

always_ff @ (posedge clock or negedge resetn) begin
	if (resetn == 1'b0) begin
		state <= LI_M1_IDLE;
		
		SRAM_address <= 18'd0;
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		
		X_pos_counter <= 9'b0;
		
		R_value_even <= 8'd0;
		R_value_odd <= 8'd0;
		B_value_even <= 8'd0;
		B_value_odd <= 8'd0;
		G_value_even <= 8'd0;
		G_value_odd <= 8'd0;
		
		Y_read_buf[1] <= 8'd0;
		Y_read_buf[0] <= 8'd0;
		U_read_buf[6] <= 8'd0;
		U_read_buf[5] <= 8'd0;
		U_read_buf[4] <= 8'd0;
		U_read_buf[3] <= 8'd0;
		U_read_buf[2] <= 8'd0;
		U_read_buf[1] <= 8'd0;
		U_read_buf[0] <= 8'd0;
		V_read_buf[6] <= 8'd0;
		V_read_buf[5] <= 8'd0;
		V_read_buf[4] <= 8'd0;
		V_read_buf[3] <= 8'd0;
		V_read_buf[2] <= 8'd0;
		V_read_buf[1] <= 8'd0;
		V_read_buf[0] <= 8'd0;
		Y_address <= 18'd0;
		U_address <= 18'd38400;
		V_address <= 18'd57600;
		write_address <= 18'd146944;
		
		R_sum <= 32'd0;
		G_sum <= 32'd0;
		B_sum <= 32'd0;

		Uprime_even <= 32'd0;
		Uprime_odd <= 32'd0;
		Vprime_even <= 32'd0;
		Vprime_odd <= 32'd0;
		
	end else begin
		case (state)
		
/////////LEAD IN///////////////////////////////////////////////////////////////////////////
		
			LI_M1_IDLE: begin
				if (start != 1'b0) begin
					write_address <= 18'd146944;
					state <= LI_M1_0;
				end
			end
			
			LI_M1_0: begin
				SRAM_address <= Y_address;
				Y_address <= Y_address + 18'd1;
				
				state <= LI_M1_1;
			end
			
			LI_M1_1: begin
				SRAM_address <= U_address;
				U_address <= U_address + 18'd1;
				
				state <= LI_M1_2;
			end
			
			LI_M1_2: begin
				SRAM_address <= U_address;
				U_address <= U_address + 18'd1;
				
				state <= LI_M1_3;
			end
			
			LI_M1_3: begin
				SRAM_address <= V_address;
				V_address <= V_address + 18'd1;
				
				Y_read_buf[0] <= SRAM_read_data[15:8];
				Y_read_buf[1] <= SRAM_read_data[7:0];
				
				state <= LI_M1_4;
			end
			
			LI_M1_4: begin
				SRAM_address <= V_address;
				V_address <= V_address + 18'd1;
				
				U_read_buf[6] <= SRAM_read_data[15:8];//8'h8b;
				U_read_buf[5] <= SRAM_read_data[7:0];//8'h87;
				
				state <= LI_M1_5;
			end
			
			LI_M1_5: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[6];
				factor21 <= 32'sd52;
				factor22 <= U_read_buf[6];
				factor31 <= 32'sd159;
				factor32 <= U_read_buf[6];
				
				U_read_buf[4] <= SRAM_read_data[15:8];//8'h86;
				U_read_buf[3] <= SRAM_read_data[7:0];//8'h87;
				
				Uprime_even <= U_read_buf[6];
				
				state <= LI_M1_6;
			end
			
			LI_M1_6: begin
				factor11 <= 32'sd159;
				factor12 <= U_read_buf[5];
				factor21 <= 32'sd52;
				factor22 <= U_read_buf[4];
				factor31 <= 32'sd21;
				factor32 <= U_read_buf[3];
				
				V_read_buf[6] <= SRAM_read_data[15:8];//8'h84;
				V_read_buf[5] <= SRAM_read_data[7:0];//8'h83;
				
				Uprime_odd <= $signed(product1) - $signed(product2) + $signed(product3);
				
				state <= LI_M1_7;
			end
			
			LI_M1_7: begin
				factor11 <= 32'sd21;
				factor12 <= V_read_buf[6];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[6];
				factor31 <= 32'sd159;
				factor32 <= V_read_buf[6];
			
				V_read_buf[4] <= SRAM_read_data[15:8];//8'h84;
				V_read_buf[3] <= SRAM_read_data[7:0];//8'h85;
				
				Uprime_odd <= ($signed(Uprime_odd) + $signed(product1) - $signed(product2) + $signed(product3) + 32'sd128) >>> 8;
				
				Vprime_even <= V_read_buf[6];
				
				state <= LI_M1_8;
			end
			
			LI_M1_8: begin
				factor11 <= 32'sd159;
				factor12 <= V_read_buf[5];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[4];
				factor31 <= 32'sd21;
				factor32 <= V_read_buf[3];
	
				Vprime_odd <= $signed(product1) - $signed(product2) + $signed(product3);
				
				state <= LI_M1_9;
			end
			
			LI_M1_9: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[0] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= Vprime_even - 32'sd128;
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
				
				SRAM_address <= Y_address;
				Y_address <= Y_address + 18'd1;
				
				Vprime_odd <= ($signed(Vprime_odd) + $signed(product1) - $signed(product2) + $signed(product3) + 32'sd128) >>> 8;
				
				state <= LI_M1_10;
			end
			
			LI_M1_10: begin
				factor11 <= 32'sd132251;
				factor12 <= Uprime_even - 32'sd128;
				factor21 <= 32'sd53281;
				factor22 <= Vprime_even - 32'sd128;
				factor31 <= 32'sd76284;
				factor32 <= Y_read_buf[1] - 32'sd16;

				SRAM_address <= U_address;
				U_address <= U_address + 18'd1;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				state <= LI_M1_11;
			end
			
			LI_M1_11: begin
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
				
				SRAM_address <= V_address;
				V_address <= V_address + 18'd1;
				
				G_sum <= $signed(G_sum) - $signed(product2);
				B_sum <= $signed(B_sum) + $signed(product1);
				
				state <= LI_M1_12;
			end
			
			LI_M1_12: begin
				factor11 <= 32'sd104595;
				factor12 <= $signed(Vprime_odd) - 32'sd128;
				factor21 <= 32'sd25624;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				factor31 <= 32'sd132251;
				factor32 <= $signed(Uprime_odd) - 32'sd128;
				
				R_sum <= $signed(product3);
				G_sum <= $signed(product3);
				B_sum <= $signed(product3);
				
				Y_read_buf[1] <= SRAM_read_data[15:8];
				Y_read_buf[0] <= SRAM_read_data[7:0];
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
				
				state <= LI_M1_13;
			end
			
			LI_M1_13: begin
				factor11 <= 32'sd53281;
				factor12 <= $signed(Vprime_odd) - 32'sd128;
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
			
				U_read_buf[2] <= SRAM_read_data[15:8];
				U_read_buf[1] <= SRAM_read_data[7:0];
		
				R_sum <= $signed(R_sum) + $signed(product1);
				G_sum <= $signed(G_sum) - $signed(product2);
				B_sum <= $signed(B_sum) + $signed(product3);
				
				state <= LI_M1_14;
			end
			
			LI_M1_14: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[6];
				factor21 <= 32'sd52;
				factor22 <= U_read_buf[6];
				factor31 <= 32'sd159;
				factor32 <= U_read_buf[5];
				
				SRAM_we_n <= 1'b1;
			
				V_read_buf[2] <= SRAM_read_data[15:8];
				V_read_buf[1] <= SRAM_read_data[7:0];
				
				Uprime_even <= U_read_buf[5];
				Vprime_even <= V_read_buf[5];
			
				G_sum <= $signed(G_sum) - $signed(product1);
				
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
				
				state <= LI_M1_15;
			end
			
			LI_M1_15: begin
				factor11 <= 32'sd159;
				factor12 <= U_read_buf[4];
				factor21 <= 32'sd52;
				factor22 <= U_read_buf[3];
				factor31 <= 32'sd21;
				factor32 <= U_read_buf[2];
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
				
				Uprime_odd <= $signed(product1) - $signed(product2) + $signed(product3);
				
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				state <= LI_M1_16;
			end
			
			LI_M1_16: begin
				factor11 <= 32'sd21;
				factor12 <= V_read_buf[6];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[6];
				factor31 <= 32'sd159;
				factor32 <= V_read_buf[5];
				
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {G_value_odd, B_value_odd};
								
				Uprime_odd <= ($signed(Uprime_odd) + $signed(product1) - $signed(product2) + $signed(product3) + 32'sd128) >>> 8;
				
				state <= LI_M1_17;
			end
			
			LI_M1_17: begin
				factor11 <= 32'sd159;
				factor12 <= V_read_buf[4];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[3];
				factor31 <= 32'sd21;
				factor32 <= V_read_buf[2];
				
				SRAM_we_n <= 1'b1;
				
				SRAM_address <= Y_address;
				Y_address <= Y_address + 18'd1;
			
				Vprime_odd <= $signed(product1) - $signed(product2) + $signed(product3);
				
				state <= LI_M1_18;
			end
			
			LI_M1_18: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[1] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= Vprime_even - 32'sd128;
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
				
				Vprime_odd <= ($signed(Vprime_odd) + $signed(product1) - $signed(product2) + $signed(product3) + 32'sd128) >>> 8;
				
				state <= LI_M1_19;
			end
			
			LI_M1_19: begin
				factor11 <= 32'sd132251;
				factor12 <= Uprime_even - 32'sd128;
				factor21 <= 32'sd53281;
				factor22 <= Vprime_even - 32'sd128;
				factor31 <= 32'sd76284;
				factor32 <= Y_read_buf[0] - 32'sd16;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				state <= LI_M1_20;
			end
			
			LI_M1_20: begin
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
				
				Y_read_buf[1] <= SRAM_read_data[15:8];
				Y_read_buf[0] <= SRAM_read_data[7:0];
				
				G_sum <= $signed(G_sum) - $signed(product2);
				B_sum <= $signed(B_sum) + $signed(product1);
				
				state <= LI_M1_21;
			end
			
			LI_M1_21: begin
				factor11 <= 32'sd104595;
				factor12 <= $signed(Vprime_odd) - 32'sd128;
				factor21 <= 32'sd25624;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				factor31 <= 32'sd132251;
				factor32 <= $signed(Uprime_odd) - 32'sd128;
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
			
				R_sum <= product3;
				G_sum <= product3;
				B_sum <= product3;
				
				state <= LI_M1_22;
			end
			
			LI_M1_22: begin
				factor11 <= 32'sd53281;
				factor12 <= $signed(Vprime_odd) - 32'sd128;
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
				
				R_sum <= $signed(R_sum) + $signed(product1);
				G_sum <= $signed(G_sum) - $signed(product2);
				B_sum <= $signed(B_sum) + $signed(product3);
				
				state <= LI_M1_23;
			end
			
			LI_M1_23: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[6];
				factor21 <= 32'sd52;
				factor22 <= U_read_buf[5];
				factor31 <= 32'sd159;
				factor32 <= U_read_buf[4];
				
				Uprime_even <= U_read_buf[4];
				Vprime_even <= V_read_buf[4];
			
				SRAM_we_n <= 1'b1;
				
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
				
				G_sum <= $signed(G_sum) - $signed(product1);
				
				state <= LI_M1_24;
			end
			
			LI_M1_24: begin
				factor11 <= 32'sd159;
				factor12 <= U_read_buf[3];
				factor21 <= 32'sd52;
				factor22 <= U_read_buf[2];
				factor31 <= 32'sd21;
				factor32 <= U_read_buf[1];
				
				Uprime_odd <= product1 - product2 + product3;
			
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
				
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				state <= LI_M1_25;
			end
			
			LI_M1_25: begin
				factor11 <= 32'sd21;
				factor12 <= V_read_buf[6];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[5];
				factor31 <= 32'sd159;
				factor32 <= V_read_buf[4];
				
				Uprime_odd <= ($signed(Uprime_odd) + product1 - product2 + product3 + 32'sd128) >>> 8;
				
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {G_value_odd, B_value_odd};
			
				state <= LI_M1_26;
			end

			LI_M1_26: begin
				factor11 <= 32'sd159;
				factor12 <= V_read_buf[3];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[2];
				factor31 <= 32'sd21;
				factor32 <= V_read_buf[1];
				
				Vprime_odd <= product1 - product2 + product3;
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_address;
				Y_address <= Y_address + 18'd1;
			
				state <= LI_M1_27;
			end
			
			LI_M1_27: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[1] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= Vprime_even - 32'sd128;
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
			
				Vprime_odd <= ($signed(Vprime_odd) + product1 - product2 + product3 + 32'sd128) >>> 8;
				
				SRAM_address <= U_address;
				U_address <= U_address + 18'd1;
			
				state <= LI_M1_28;
			end
			
			LI_M1_28: begin
				factor11 <= 32'sd132251;
				factor12 <= Uprime_even - 32'sd128;
				factor21 <= 32'sd53281;
				factor22 <= Vprime_even - 32'sd128;
				factor31 <= 32'sd76284;
				factor32 <= Y_read_buf[0] - 32'sd16;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				SRAM_address <= V_address;
				V_address <= V_address + 18'd1;
			
				state <= LI_M1_29;
			end
			
			LI_M1_29: begin
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
				
				G_sum <= $signed(G_sum) - $signed(product2);
				B_sum <= $signed(B_sum) + $signed(product1);
				
				Y_read_buf[1] <= SRAM_read_data[15:8];
				Y_read_buf[0] <= SRAM_read_data[7:0];
			
				state <= LI_M1_30;
			end
			
			LI_M1_30: begin
				factor11 <= 32'sd104595;
				factor12 <= $signed(Vprime_odd) - 32'sd128;
				factor21 <= 32'sd25624;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				factor31 <= 32'sd132251;
				factor32 <= $signed(Uprime_odd) - 32'sd128;
				
				R_sum <= $signed(product3);
				G_sum <= $signed(product3);
				B_sum <= $signed(product3);
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
				
				U_read_buf[6] <= U_read_buf[5];
				U_read_buf[5] <= U_read_buf[4];
				U_read_buf[4] <= U_read_buf[3];
				U_read_buf[3] <= U_read_buf[2];
				U_read_buf[2] <= U_read_buf[1];
				U_read_buf[1] <= SRAM_read_data[15:8];
				U_read_buf[0] <= SRAM_read_data[7:0];
			
				state <= LI_M1_31;
			end
			
			LI_M1_31: begin
				factor11 <= 32'sd53281;
				factor12 <= $signed(Vprime_odd) - 32'sd128;
				
				R_sum <= $signed(R_sum) + $signed(product1);
				G_sum <= $signed(G_sum) - $signed(product2);
				B_sum <= $signed(B_sum) + $signed(product3);
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
				
				V_read_buf[6] <= V_read_buf[5];
				V_read_buf[5] <= V_read_buf[4];
				V_read_buf[4] <= V_read_buf[3];
				V_read_buf[3] <= V_read_buf[2];
				V_read_buf[2] <= V_read_buf[1];
				V_read_buf[1] <= SRAM_read_data[15:8];
				V_read_buf[0] <= SRAM_read_data[7:0];
			
				state <= LI_M1_32;
			end
			
			LI_M1_32: begin
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
				
				G_sum <= $signed(G_sum) - $signed(product1);
				
				SRAM_we_n <= 1'b1;
			
				state <= LI_M1_33;
			end
			
			LI_M1_33: begin
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
			
				X_pos_counter <= 9'd5; // at this point 5.33 pixel RGB values have been written
			
				state <= CC_S1;
			end
			
/////////COMMON CASE///////////////////////////////////////////////////////////////////////

			CC_S1: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[6];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[6];
				factor31 <= 32'sd76284;
				factor32 <= Y_read_buf[1] - 32'sd16;
				
				Uprime_even <= U_read_buf[4];
				Vprime_even <= V_read_buf[4];
				
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {G_value_odd, B_value_odd};
				
				X_pos_counter <= X_pos_counter + 9'd1;
			
				state <= CC_S2;
			end
			
			CC_S2: begin
				factor11 <= 32'sd52;
				factor12 <= U_read_buf[5];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[5];
				factor31 <= 32'sd104595;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= product3;
				G_sum <= product3;
				B_sum <= product3;
				
				Uprime_odd <= product1;
				Vprime_odd <= product2;
				
				SRAM_we_n <= 1'b1;
				
				state <= CC_S3;
			end
			
			CC_S3: begin
				factor11 <= 32'sd159;
				factor12 <= U_read_buf[4];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[4];
				factor31 <= 32'sd53281;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= $signed(R_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
			
				state <= CC_S4;
			end
			
			CC_S4: begin
				factor11 <= 32'sd159;
				factor12 <= U_read_buf[3];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[3];
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
			
				state <= CC_S5;
			end
			
			CC_S5: begin
				factor11 <= 32'sd52;
				factor12 <= U_read_buf[2];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[2];
				factor31 <= 32'sd132251;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
			
				state <= CC_S6;
			end
			
			CC_S6: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[1];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[1];
				
				B_sum <= $signed(B_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
				
				SRAM_address <= Y_address;
				Y_address <= Y_address + 18'd1;
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
				
				state <= CC_S7;
			end
			
			CC_S7: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[0] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= $signed((($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8)) - 32'sd128;
				factor31 <= 32'sd53281;
				factor32 <= $signed((($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8)) - 32'sd128;
				
				Uprime_odd <= ($signed(Uprime_odd) + $signed(product1) + 32'sd128) >>> 8;
				//Vprime_odd directly placed into multiplier
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
			
				state <= CC_S8;
			end
			
			CC_S8: begin
				factor11 <= 32'sd25624;
				factor12 <= $signed(Uprime_odd) - 32'sd128;
				factor21 <= 32'sd132251;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				SRAM_we_n <= 1'b1;
			
				state <= CC_S9;
			end
			
			CC_S9: begin
				Y_read_buf[1] <= SRAM_read_data[15:8];
				Y_read_buf[0] <= SRAM_read_data[7:0];
				
				G_sum <= $signed(G_sum) - $signed(product1);
				B_sum <= $signed(B_sum) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
			
				state <= CC_S10;
			end
			
			CC_S10: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[5];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[5];
				factor31 <= 32'sd76284;
				factor32 <= Y_read_buf[1] - 32'sd16;
				
				Uprime_even <= U_read_buf[3];
				Vprime_even <= V_read_buf[3];
				
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
				
				X_pos_counter <= X_pos_counter + 9'd1;
			
				state <= CC_S11;
			end
			
			CC_S11: begin
				factor11 <= 32'sd52;
				factor12 <= U_read_buf[4];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[4];
				factor31 <= 32'sd104595;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= product3;
				G_sum <= product3;
				B_sum <= product3;
				
				Uprime_odd <= product1;
				Vprime_odd <= product2;
				
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {G_value_odd, B_value_odd};
				
				X_pos_counter <= X_pos_counter + 9'd1;
			
				state <= CC_S12;
			end
			
			CC_S12: begin
				factor11 <= 32'sd159;
				factor12 <= U_read_buf[3];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[3];
				factor31 <= 32'sd53281;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= $signed(R_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
				
				SRAM_we_n <= 1'b1;
			
				state <= CC_S13;
			end
			
			CC_S13: begin
				factor11 <= 32'sd159;
				factor12 <= U_read_buf[2];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[2];
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
			
				state <= CC_S14;
			end
			
			CC_S14: begin
				factor11 <= 32'sd52;
				factor12 <= U_read_buf[1];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[1];
				factor31 <= 32'sd132251;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				SRAM_address <= Y_address;
				Y_address <= Y_address + 18'd1;
			
				state <= CC_S15;
			end
			
			CC_S15: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[0];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[0];
				
				B_sum <= $signed(B_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
				
				// don't increment U_address on last CC
				if (X_pos_counter < 9'd309) begin
					SRAM_address <= U_address;
					U_address <= U_address + 18'd1;
				end
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
			
				state <= CC_S16;
			end
			
			CC_S16: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[0] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= $signed((($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8)) - 32'sd128;
				factor31 <= 32'sd53281;
				factor32 <= $signed((($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8)) - 32'sd128;
				
				Uprime_odd <= ($signed(Uprime_odd) + $signed(product1) + 32'sd128) >>> 8;
				//Vprime_odd placed directly into multiplier
				
				// don't increment V_address on last CC
				if (X_pos_counter < 9'd309) begin
					SRAM_address <= V_address;
					V_address <= V_address + 18'd1;
				end
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
			
				state <= CC_S17;
			end
			
			CC_S17: begin
				factor11 <= 32'sd25624;
				factor12 <= $signed(Uprime_odd) - 32'sd128;
				factor21 <= 32'sd132251;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				Y_read_buf[1] <= SRAM_read_data[15:8];
				Y_read_buf[0] <= SRAM_read_data[7:0];
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
			
				state <= CC_S18;
			end
			
			CC_S18: begin
				G_sum <= $signed(G_sum) - $signed(product1);
				B_sum <= $signed(B_sum) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
				
				SRAM_we_n <= 1'b1;
				
				U_read_buf[6] <= U_read_buf[4];
				U_read_buf[5] <= U_read_buf[3];
				U_read_buf[4] <= U_read_buf[2];
				U_read_buf[3] <= U_read_buf[1];
				U_read_buf[2] <= U_read_buf[0];
				U_read_buf[1] <= SRAM_read_data[15:8];
				U_read_buf[0] <= SRAM_read_data[7:0];
				
				// don't need new U on last CC
				if (X_pos_counter >= 9'd309) begin
					U_read_buf[1] <= U_read_buf[0];
					U_read_buf[0] <= U_read_buf[0];
				end
				
				state <= CC_S19;
			end
			
			CC_S19: begin
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
				
				X_pos_counter <= X_pos_counter + 9'd1;
				
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
				
				V_read_buf[6] <= V_read_buf[4];
				V_read_buf[5] <= V_read_buf[3];
				V_read_buf[4] <= V_read_buf[2];
				V_read_buf[3] <= V_read_buf[1];
				V_read_buf[2] <= V_read_buf[0];
				V_read_buf[1] <= SRAM_read_data[15:8];
				V_read_buf[0] <= SRAM_read_data[7:0];
			
				if (X_pos_counter >= 9'd309) begin		
					// don't need new V on last CC
					V_read_buf[1] <= V_read_buf[0];
					V_read_buf[0] <= V_read_buf[0];
		
					state <= LO_CYC1_S1;
				end else begin
				
					state <= CC_S1;
				end
			end
			
/////////LEAD OUT//////////////////////////////////////////////////////////////////////////
			
			LO_CYC1_S1: begin				
				//Colourspace Conversion
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[6];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[6];
				factor31 <= 32'sd76284;
				factor32 <= $signed(Y_read_buf[1] - 32'sd16);
				
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {G_value_odd, B_value_odd};
				
				Uprime_even <= U_read_buf[4];
				Vprime_even <= V_read_buf[4];
				
				X_pos_counter <= 9'd0;
			
				state <= LO_CYC1_S2;
			end
			
			LO_CYC1_S2: begin
				factor11 <= 32'sd52;
				factor12	<= U_read_buf[5];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[5];
				factor31 <= 32'sd104595;
				factor32 <= $signed(Vprime_even - 32'sd128);
				
				R_sum <= $signed(product3);
				G_sum <= product3;
				B_sum <= product3;
				
				//Upscaling
				Uprime_odd <= product1;
				Vprime_odd <= product2;
				
				SRAM_we_n <= 1'b1;
				
				state <= LO_CYC1_S3;
			end
			
			LO_CYC1_S3: begin
				factor11 <= 32'sd159;
				factor12	<= U_read_buf[4];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[4];
				factor31 <= 32'sd53281;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= $signed(R_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
			
				state <= LO_CYC1_S4;
			end
			
			LO_CYC1_S4: begin
				factor11 <= 32'sd159;
				factor12	<= U_read_buf[3];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[3];
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
			
				state <= LO_CYC1_S5;
			end
			
			LO_CYC1_S5: begin
				//update SRAM_address to Y316,317?
				
				factor11 <= 32'sd52;
				factor12	<= U_read_buf[2];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[2];
				factor31 <= 32'sd132251;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);				
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				SRAM_address <= Y_address;
				Y_address <= Y_address + 18'd1;
				
				state <= LO_CYC1_S6;
			end
			
			LO_CYC1_S6: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[1];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[1];
				
				B_sum <= $signed(B_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
			
				state <= LO_CYC1_S7;
			end
			
			LO_CYC1_S7: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[0] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= ($signed($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8) - 32'sd128;
				factor31 <= 32'sd53281;
				factor32 <= ($signed($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8) - 32'sd128;
				
				Uprime_odd <= ($signed(Uprime_odd) + $signed(product1) + 32'sd128) >>> 8;
				//Vprime_odd placed directly into multiplier
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
				
				state <= LO_CYC1_S8;
			end
			
			LO_CYC1_S8: begin
				factor11 <= 32'sd25624;
				factor12 <= $signed(Uprime_odd) - 32'sd128;
				factor21 <= 32'sd132251;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				Y_read_buf[1] <= SRAM_read_data[15:8];	//Y[316]
				Y_read_buf[0] <= SRAM_read_data[7:0];	//Y[317]
				
				U_read_buf[6] <= U_read_buf[5];
				U_read_buf[5] <= U_read_buf[4];
				U_read_buf[4] <= U_read_buf[3];
				U_read_buf[3] <= U_read_buf[2];
				U_read_buf[2] <= U_read_buf[1];
				U_read_buf[1] <= U_read_buf[0];
				//no need to update read_buf[0] since filled with [159]
				
				V_read_buf[6] <= V_read_buf[5];
				V_read_buf[5] <= V_read_buf[4];
				V_read_buf[4] <= V_read_buf[3];
				V_read_buf[3] <= V_read_buf[2];
				V_read_buf[2] <= V_read_buf[1];
				V_read_buf[1] <= V_read_buf[0];
				//no need to update read_buf[0] since filled with [159]
				
				SRAM_we_n <= 1'b1;
				
				state <= LO_CYC2_S1;
			end
			
			LO_CYC2_S1: begin
				//Colourspace Conversion
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[6];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[6];
				factor31 <= 32'sd76284;
				factor32 <= Y_read_buf[1] - 32'sd16;
				
				G_sum <= $signed(G_sum) - $signed(product1);
				B_sum <= $signed(B_sum) + $signed(product2);
				
				Uprime_even <= U_read_buf[4];
				Vprime_even <= V_read_buf[4];
				
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
			
				state <= LO_CYC2_S2;
			end
			
			LO_CYC2_S2: begin
				factor11 <= 32'sd52;
				factor12	<= U_read_buf[5];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[5];
				factor31 <= 32'sd104595;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= product3;
				G_sum <= product3;
				B_sum <= product3;
				
				//Upscaling
				Uprime_odd <= product1;
				Vprime_odd <= product2;
				
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
				
				state <= LO_CYC2_S3;
			end
			
			LO_CYC2_S3: begin
				factor11 <= 32'sd159;
				factor12	<= U_read_buf[4];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[4];
				factor31 <= 32'sd53281;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= $signed(R_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);	
				
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {G_value_odd, B_value_odd};
				
				state <= LO_CYC2_S4;	
			end
			
			LO_CYC2_S4: begin
				factor11 <= 32'sd159;
				factor12	<= U_read_buf[3];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[3];
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
				
				SRAM_we_n <= 1'b1;
			
				state <= LO_CYC2_S5;
			end
			
			LO_CYC2_S5: begin
				factor11 <= 32'sd52;
				factor12	<= U_read_buf[2];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[2];
				factor31 <= 32'sd132251;
				factor32 <= $signed(Uprime_even) - 32'sd128;//change index of U_read_buf to correct one
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				
				SRAM_address <= Y_address;					//Request data for Y[318], Y[319]
				Y_address <= Y_address + 18'd1;
			
				state <= LO_CYC2_S6;
			end
			
			LO_CYC2_S6: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[1];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[1];
				
				B_sum <= $signed(B_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
				
				state <= LO_CYC2_S7;
			end
			
			LO_CYC2_S7: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[0] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= ($signed($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8) - 32'sd128;
				factor31 <= 32'sd53281;
				factor32 <= ($signed($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8) - 32'sd128;
				
				Uprime_odd <= ($signed(Uprime_odd) + $signed(product1) + 32'sd128) >>> 8;
				//Vprime_odd placed directly into multiplier
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
				
				state <= LO_CYC2_S8;
			end
			
			LO_CYC2_S8: begin
				factor11 <= 32'sd25624;
				factor12 <= $signed(Uprime_odd) - 32'sd128;
				factor21 <= 32'sd132251;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				Y_read_buf[1] <= SRAM_read_data[15:8];	//Y[318]
				Y_read_buf[0] <= SRAM_read_data[7:0];	//Y[319]
				
				U_read_buf[6] <= U_read_buf[5];
				U_read_buf[5] <= U_read_buf[4];
				U_read_buf[4] <= U_read_buf[3];
				U_read_buf[3] <= U_read_buf[2];
				U_read_buf[2] <= U_read_buf[1];
				U_read_buf[1] <= U_read_buf[0];
				//no need to update read_buf[0] since filled with [159]
				
				V_read_buf[6] <= V_read_buf[5];
				V_read_buf[5] <= V_read_buf[4];
				V_read_buf[4] <= V_read_buf[3];
				V_read_buf[3] <= V_read_buf[2];
				V_read_buf[2] <= V_read_buf[1];
				V_read_buf[1] <= V_read_buf[0];
				//no need to update read_buf[0] since filled with [159]
				
				SRAM_we_n <= 1'b1;
			
				state <= LO_CYC3_S1;
			end
			
			LO_CYC3_S1: begin
				//Colourspace Conversion
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[6];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[6];
				factor31 <= 32'sd76284;
				factor32 <= Y_read_buf[1] - 32'sd16;
				
				G_sum <= $signed(G_sum) - $signed(product1);
				B_sum <= $signed(B_sum) + $signed(product2);
				
				Uprime_even <= U_read_buf[4];
				Vprime_even <= V_read_buf[4];
				
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
			
				state <= LO_CYC3_S2;
			end
			
			LO_CYC3_S2: begin
				factor11 <= 32'sd52;
				factor12	<= U_read_buf[5];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[5];
				factor31 <= 32'sd104595;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= product3;
				G_sum <= product3;
				B_sum <= product3;
				
				//Upscaling
				Uprime_odd <= product1;
				Vprime_odd <= product2;
				
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
				
				state <= LO_CYC3_S3;
			end
			
			LO_CYC3_S3: begin
				factor11 <= 32'sd159;
				factor12	<= U_read_buf[4];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[4];
				factor31 <= 32'sd53281;
				factor32 <= Vprime_even - 32'sd128;
				
				R_sum <= $signed(R_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);	
	
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {G_value_odd, B_value_odd};
			
				state <= LO_CYC3_S4;
			end
			
			LO_CYC3_S4: begin
				factor11 <= 32'sd159;
				factor12	<= U_read_buf[3];
				factor21 <= 32'sd159;
				factor22 <= V_read_buf[3];
				factor31 <= 32'sd25624;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_even <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_even <= 8'd255;
					else R_value_even <= R_sum[23:16];
				end
				
				SRAM_we_n <= 1'b1;
			
				state <= LO_CYC3_S5;
			end
			
			LO_CYC3_S5: begin
				factor11 <= 32'sd52;
				factor12	<= U_read_buf[2];
				factor21 <= 32'sd52;
				factor22 <= V_read_buf[2];
				factor31 <= 32'sd132251;
				factor32 <= Uprime_even - 32'sd128;
				
				G_sum <= $signed(G_sum) - $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) + $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) + $signed(product2);
			
				state <= LO_CYC3_S6;
			end
			
			LO_CYC3_S6: begin
				factor11 <= 32'sd21;
				factor12 <= U_read_buf[1];
				factor21 <= 32'sd21;
				factor22 <= V_read_buf[1];
				
				B_sum <= $signed(B_sum) + $signed(product3);
				
				Uprime_odd <= $signed(Uprime_odd) - $signed(product1);
				Vprime_odd <= $signed(Vprime_odd) - $signed(product2);
				
				if (G_sum[31] == 1'b1) G_value_even <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_even <= 8'd255;
					else G_value_even <= G_sum[23:16];
				end
			
				state <= LO_CYC3_S7;
			end
			
			LO_CYC3_S7: begin
				factor11 <= 32'sd76284;
				factor12 <= Y_read_buf[0] - 32'sd16;
				factor21 <= 32'sd104595;
				factor22 <= ($signed($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8) - 32'sd128;
				factor31 <= 32'sd53281;
				factor32 <= ($signed($signed(Vprime_odd) + $signed(product2) + 32'sd128) >>> 8) - 32'sd128;
				
				Uprime_odd <= ($signed(Uprime_odd) + $signed(product1) + 32'sd128) >>> 8;
				//Vprime_odd placed directly into multiplier			
				
				if (B_sum[31] == 1'b1) B_value_even <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_even <= 8'd255;
					else B_value_even <= B_sum[23:16];
				end
					
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {R_value_even, G_value_even};
			
				state <= LO_CYC3_S8;
			end
			
			LO_CYC3_S8: begin
				factor11 <= 32'sd25624;
				factor12 <= $signed(Uprime_odd) - 32'sd128;
				factor21 <= 32'sd132251;
				factor22 <= $signed(Uprime_odd) - 32'sd128;
				
				R_sum <= $signed(product1) + $signed(product2);
				G_sum <= $signed(product1) - $signed(product3);
				B_sum <= product1;
				
				SRAM_we_n <= 1'b1;
			
				state <= LO_CYC3_S9;
			end
			
			LO_CYC3_S9: begin
				G_sum <= $signed(G_sum) - $signed(product1);
				B_sum <= $signed(B_sum) + $signed(product2);
				
				if (R_sum[31] == 1'b1) R_value_odd <= 8'd0;
				else begin
					if (|R_sum[30:24]) R_value_odd <= 8'd255;
					else R_value_odd <= R_sum[23:16];
				end
				
				state <= LO_CYC3_S10;
			end
			
			LO_CYC3_S10: begin
				if (G_sum[31] == 1'b1) G_value_odd <= 8'd0;
				else begin
					if (|G_sum[30:24]) G_value_odd <= 8'd255;
					else G_value_odd <= G_sum[23:16];
				end
				
				if (B_sum[31] == 1'b1) B_value_odd <= 8'd0;
				else begin
					if (|B_sum[30:24]) B_value_odd <= 8'd255;
					else B_value_odd <= B_sum[23:16];
				end
			
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
				
				SRAM_write_data <= {B_value_even, R_value_odd};
				
				state <= LO_CYC3_S11;
			end
			
			LO_CYC3_S11: begin
				SRAM_address <= write_address;
				write_address <= write_address + 18'd1;
			
				SRAM_write_data <= {G_value_odd, B_value_odd};
				
				state <= LO_CYC3_S12;
			end
			
			LO_CYC3_S12: begin
				SRAM_we_n <= 1'b1;
				
				Y_read_buf[1] <= 8'd0;
				Y_read_buf[0] <= 8'd0;
				U_read_buf[6] <= 8'd0;
				U_read_buf[5] <= 8'd0;
				U_read_buf[4] <= 8'd0;
				U_read_buf[3] <= 8'd0;
				U_read_buf[2] <= 8'd0;
				U_read_buf[1] <= 8'd0;
				U_read_buf[0] <= 8'd0;
				V_read_buf[6] <= 8'd0;
				V_read_buf[5] <= 8'd0;
				V_read_buf[4] <= 8'd0;
				V_read_buf[3] <= 8'd0;
				V_read_buf[2] <= 8'd0;
				V_read_buf[1] <= 8'd0;
				V_read_buf[0] <= 8'd0;
			
				if (Y_address != 18'd38400) state <= LI_M1_0;
				else done <= 1'b1;
			end
		endcase
	end
end
endmodule
		