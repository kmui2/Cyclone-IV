/**
Author: Chang Won Choi
Course: ECE 551
*/
module SPI_mstr16(clk, rst_n, wrt, MISO, cmd, SS_n, SCLK, MOSI, done, rd_data);

input clk, rst_n, wrt, MISO;
input logic[15:0] cmd;

output logic SS_n, SCLK, MOSI, done;
output logic[15:0] rd_data;

logic[4:0] bit_cnt;
logic[15:0] shft_reg;
logic[4:0] sclk_div;
logic MISO_smpl;
logic rst_cnt;
logic smpl;
logic shft;
logic set;
logic clr;

typedef enum reg[1:0] {IDLE, FRNT, TRANS, BCK} state_t;
state_t state, nxt_state;

assign rd_data = shft_reg;

always_ff @(posedge clk) begin
	if (rst_cnt) begin
		bit_cnt <= 0;
	end
	else if (smpl) begin
		bit_cnt <= bit_cnt + 1;
	end
end
//counts how many bit has been sampled

always_ff @(posedge clk) begin
	if (rst_cnt) begin
		sclk_div <= 5'b10111;
	end
	else begin
		sclk_div <= sclk_div + 1;
	end
end
//SCLK counter

assign SCLK = sclk_div[4];

always_ff @(posedge clk) begin
	if (smpl) begin
		MISO_smpl <= MISO;
	end
end
//MISO

always_ff @(posedge clk) begin
	if (wrt) begin
		shft_reg <= cmd;
	end
	else if (shft) begin
		shft_reg <= {shft_reg[14:0], MISO_smpl};
	end
end

assign MOSI = shft_reg[15];
//MOSI

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		done <= 0;
	end
	else if (set) begin
		done <= 1;
	end
	else if (clr) begin
		done <= 0;
	end
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		SS_n <= 1;
	end
	else if (set) begin
		SS_n <= 1;
	end
	else if (clr) begin
		SS_n <= 0;
	end
end
//done and SS_n behave the same except when rst_n is deasserted so you can use same set and clr

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
	end
	else begin
		state <= nxt_state;
	end
end

always_comb begin
	set = 0;
	clr = 0;
	rst_cnt = 0;
	smpl = 0;
	shft = 0;
	nxt_state = IDLE;
	//default values
	
	case (state)
		IDLE:
			if (!wrt) begin
				rst_cnt = 1;
				nxt_state = IDLE;
				
			end //Makes sure that the SCLK stays 1
			else begin
				rst_cnt = 1;
				nxt_state = FRNT;
				clr = 1;
			end
		FRNT:
			if (sclk_div == 5'b01111) begin
				smpl = 1;
				nxt_state = TRANS;
			end
			else begin
				nxt_state = FRNT;
			end
		TRANS:
			if (sclk_div == 5'b01111 && bit_cnt == 15) begin
				smpl = 1;
				nxt_state = BCK;
			end //exit at bit_cnt == 15 because we assert smpl
			else if (sclk_div == 5'b01111) begin
				smpl = 1;
				nxt_state = TRANS;
			end
			else if (sclk_div == 5'b11111) begin
				shft = 1;
				nxt_state = TRANS;
			end
			else begin
				nxt_state = TRANS;
			end
		BCK:
			if (sclk_div == 5'b11111) begin
				set = 1;
				shft = 1;
				rst_cnt = 1;
				nxt_state = IDLE;
			end
			else begin
				nxt_state = BCK;
			end
	endcase		
end
endmodule 
			
		
