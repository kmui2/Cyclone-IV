module UART_wrapper(clr_cmd_rdy, cmd_rdy, snd_resp, resp_sent, cmd, data, resp, clk, RX, TX, rst_n);

input clk, rst_n;
input RX;
input clr_cmd_rdy, snd_resp;
input [7:0] resp;

output logic cmd_rdy, resp_sent;
output logic TX;
output logic [7:0] cmd;
output logic [15:0] data;

logic high_byte_en;
logic mid_byte_en;
logic [7:0] high_byte;
logic [7:0] mid_byte;
logic rdy;
logic [7:0] rx_data;
logic clr_rdy, trmt, tx_done;
logic [7:0] tx_data;
logic set_cmd_rdy, clr_cmd_rdy_i;

assign resp_sent = tx_done;
assign tx_data = resp;
assign cmd = high_byte;
assign data = {mid_byte, rx_data};

UART iUART(.clk(clk), .RX(RX), .TX(TX), .rx_rdy(rdy), .rx_data(rx_data), 
				.clr_rx_rdy(clr_rdy), .trmt(snd_resp), .tx_done(tx_done), .tx_data(tx_data), 
				.rst_n(rst_n));

/////////////////////////////////////////////////////////
// assert and deassert cmd_rdy using set/clr flipflop //
//////////////////////////////////////////////////////				
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cmd_rdy <= 0;
	end
	else if (set_cmd_rdy) begin
		cmd_rdy <= 1;
	end
	else if (clr_cmd_rdy_i) begin
		cmd_rdy <= 0;
	end
	else if (clr_cmd_rdy) begin
		cmd_rdy <= 0;
	end
end			

/////////////////////////////////////////
// Store high byte when ready from SM //
///////////////////////////////////////	
always_ff@(posedge clk) begin
	if (high_byte_en)
		high_byte <= rx_data;
	else
		high_byte <= high_byte;
end

////////////////////////////////////////
// Store mid byte when ready from SM //	
//////////////////////////////////////			
always_ff@(posedge clk) begin
	if (mid_byte_en)
		mid_byte <= rx_data;
	else
		mid_byte <= mid_byte;
end

////////////////////////////////
// SM logic for UART Wrapper //
//////////////////////////////
typedef enum logic [1:0] {HIGH, MID, LOW } state_t;
state_t state, nxt_state;

 always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		state <= HIGH;
	end
	else begin
		state <= nxt_state;
	end
 end
 
 always_comb begin
	// default values
	clr_rdy = 0;
	high_byte_en = 0;
	mid_byte_en = 0;
	set_cmd_rdy = 0;
	clr_cmd_rdy_i = 0;
	nxt_state = HIGH;
	
	case (state) 
		HIGH: begin	// store high byte when rdy from UART
			if(!rdy) begin
				nxt_state = HIGH;
			end
			else begin
				clr_rdy = 1;
				high_byte_en = 1;
				clr_cmd_rdy_i = 1;
				nxt_state = MID;
			end
		end
		
		MID: begin	// store mid byte when rdy from UART
			if (!rdy) begin
				nxt_state = MID;
			end
			else begin
				clr_rdy = 1;
				mid_byte_en = 1;
				nxt_state = LOW;
			end
		end
		
		LOW: begin	// maintain low byte whe rdy from UART
			if(!rdy) begin
				nxt_state = LOW;
			end
			else begin
				clr_rdy = 1;
				set_cmd_rdy = 1;
				nxt_state = HIGH;
			end
		end
	endcase
 end

endmodule
