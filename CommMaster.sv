module CommMaster(clk, rst_n, cmd, snd_cmd, cmd_sent, data, resp, resp_rdy, RX, TX, clr_resp_rdy); // DAVID YU & NATE CISKE
	// inputs
	input clk, rst_n;
	input[7:0] cmd;
	input snd_cmd;
	input[15:0] data;
	input RX;
	input clr_resp_rdy; 

	// outputs
	output logic resp_rdy;
	output logic cmd_sent; 
	output logic [7:0] resp;
	output logic TX;
	
	//reg[7:0] rx_data;
	reg[7:0] tx_data;
	reg[1:0] sel;
	reg[7:0] dataM;
	reg[7:0] dataL;
	typedef enum logic [1:0]{IDLE, WaitH, WaitM, WaitL} state_t; 
	state_t state, nxt_state;

	logic trmt;
	logic snd_frm;
	logic set_cmplt, clr_cmplt;

	// Instantiate UART
	/*UART UART_Tranceiver(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_resp_rdy), .rx_data(rx_data), 
			  .trmt(trmt), .tx_data(resp), .tx_done(tx_done));*/
	
	UART UART_Tranceiver(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_resp_rdy), .rx_data(resp), 
			  .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));

	// set response as the mid, low, or cmd byte based on select
	/*assign resp = 	(sel == 2'b01) ? 	dataM :
					(sel == 2'b00) ? 	dataL :
										cmd; */
	assign tx_data = 	(sel == 2'b01) ? 	dataM :
					(sel == 2'b00) ? 	dataL :
										cmd;

	assign snd_frm = snd_cmd;

	// split the data into the mid and low byte if snd_cmd is asserted
	always @(posedge clk) begin
		if(snd_cmd) begin
			dataM <= data[15:8];
			dataL <= data[7:0];
		end else begin
			dataM <= dataM;
			dataL <= dataL;
		end
	end

	// set/clr frm_snt based on output from state machine
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cmd_sent <= 0;
		else if(clr_cmplt)
			cmd_sent <= 0;
		else if(set_cmplt)
			cmd_sent <= 1;
		else
			cmd_sent <= cmd_sent;
	end

	// set state to next state after every posedge clock
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE; 
		else 
			state <= nxt_state; 
	end
	
	// state machine for waiting for high, mid, and low bytes
	always_comb begin
		// default values
		trmt = 0;
		clr_cmplt = 0;
		set_cmplt = 0;
		sel = 2'b10;

		case(state)
			IDLE: begin
				// begin transmitting high byte when send is asserted
				if(snd_frm) begin	
					trmt = 1;
					clr_cmplt = 1;
					nxt_state = WaitH;
				end else
					nxt_state = IDLE;
				end
			WaitH: begin
				// begin transmitting mid byte when done transmitting high byte
				if(tx_done) begin
					sel = 2'b01;
					trmt = 1;
					nxt_state = WaitM;
				end else
					nxt_state = WaitH;
				end
			WaitM: begin
				// begin transmitting low byte when done transmitting mid byte
				if(tx_done) begin
					sel = 2'b00;
					trmt = 1;
					nxt_state = WaitL;
				end else
					nxt_state = WaitM;
				end
			WaitL: begin
				// return to idle when done transmitting mid byte
				if(tx_done) begin
					set_cmplt = 1;
					nxt_state = IDLE;
				end else
					nxt_state = WaitL;
				end
			default: nxt_state = IDLE;
		endcase
	end
				
endmodule
