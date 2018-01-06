module cmd_cfg(clk, rst_n, cmd_rdy, cmd, data, clr_cmd_rdy, resp, send_resp, d_ptch, d_roll, d_yaw, thrst, batt,
				strt_cal, inertial_cal, cal_done, motors_off, strt_cnv, cnv_cmplt); // YIPPEE KI YAW MOTHERCOPTERS

input clk, rst_n;
input cmd_rdy;
input logic[7:0] cmd;
input logic[15:0] data;
input logic[7:0] batt;
input cal_done;
input cnv_cmplt;

output logic clr_cmd_rdy;
output logic[7:0] resp;
output logic send_resp;
output logic[15:0] d_ptch, d_roll, d_yaw;
output logic[8:0] thrst;
output logic strt_cal;
output logic inertial_cal;
output logic motors_off;
output logic strt_cnv;

logic wptch, wroll, wyaw, wthrst;
logic mtrs_off, en_mtrs;
logic clr_tmr, tmr_full;
logic emergency;

localparam width = 9;

localparam REQ_BATT = 8'h01;
localparam SET_PTCH = 8'h02;
localparam SET_ROLL = 8'h03;
localparam SET_YAW = 8'h04;
localparam SET_THRST = 8'h05;
localparam EMER_LAND = 8'h07;
localparam MTRS_OFF = 8'h08;
localparam CALIBRATE = 8'h06;

logic[width:0] tmr;

typedef enum logic [2:0]{IDLE, SEND_ACK, BATT, CAL1, CAL2} state_t; 
state_t state, nxt_state; 

// set/clr d_ptch data
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		d_ptch <= 0;
	end
	else if (emergency) begin
		d_ptch <= 0;
	end
	else if (wptch) begin
		d_ptch <= data;
	end
end

// set/clr d_roll data
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		d_roll <= 0;
	end
	else if (emergency) begin
		d_roll <= 0;
	end
	else if (wroll) begin
		d_roll <= data;
	end
end

// set/clr d_yaw data
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		d_yaw <= 0;
	end
	else if (emergency) begin
		d_yaw <= 0;
	end
	else if (wyaw) begin
		d_yaw <= data;
	end
end

// set/clr thrst data
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		thrst <= 0;
	end
	else if (emergency) begin
		thrst <= 0;
	end
	else if (wthrst) begin
		thrst <= data[8:0];
	end
end

// increment tmr for every clk 
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		tmr <= 0;
	end
	else if (clr_tmr) begin
		tmr <= 0;
	end
	else begin
		tmr <= tmr + 1;
	end
end
// tmr is full after 2^width-1 clock cycles
assign tmr_full = &tmr;

// turn on/off motors
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		motors_off <= 1;
	end
	else if (en_mtrs) begin
		motors_off <= 0;
	end
	else if (mtrs_off) begin
		motors_off <= 1;
	end
end

// set state as next state for every posedge clock
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= IDLE; 
	else 
		state <= nxt_state; 
end

// state machine
always_comb begin
	// default values
	wptch = 0;
	wroll = 0;
	wyaw = 0;
	wthrst = 0;
	mtrs_off = 0;
	en_mtrs = 0;
	clr_cmd_rdy = 0;
	strt_cnv = 0;
	inertial_cal = 0;
	clr_tmr = 0;
	send_resp = 0;
	emergency = 0;
	strt_cal=0;
	resp = 0;
	nxt_state = IDLE;
	
	case (state)
		IDLE:
			if (!cmd_rdy) begin
				nxt_state = IDLE;
			end
			// perform the cmd when cmd_rdy is asserted
			else begin
				resp = 0;	// reset resp to 0
				case (cmd)
					REQ_BATT: begin
						strt_cnv = 1;
						clr_cmd_rdy = 1;
						nxt_state = BATT;
					end
					SET_PTCH: begin
						wptch = 1;
						clr_cmd_rdy = 1;
						nxt_state = SEND_ACK;
					end
					SET_ROLL: begin
						wroll = 1;
						clr_cmd_rdy = 1;
						nxt_state = SEND_ACK;
					end
					SET_YAW: begin
						wyaw = 1;
						clr_cmd_rdy = 1;
						nxt_state = SEND_ACK;
					end
					SET_THRST: begin
						wthrst = 1;
						clr_cmd_rdy = 1;
						nxt_state = SEND_ACK;
					end
					EMER_LAND: begin
						emergency = 1;
						clr_cmd_rdy = 1;
						nxt_state = SEND_ACK;
					end
					MTRS_OFF: begin
						mtrs_off = 1;
						clr_cmd_rdy = 1;
						nxt_state = SEND_ACK;
					end
					CALIBRATE: begin
						clr_tmr = 1;
						clr_cmd_rdy = 1;
						en_mtrs = 1;
						nxt_state = CAL1;
					end
				endcase
			end
		// set resp as the POS_ACK signal then return to IDLE
		SEND_ACK: begin
			resp = 8'hA5;
			send_resp = 1;
			nxt_state = IDLE;
		end
		// wait for cnv_cmplt is asserted then send battery response
		BATT:
			if (!cnv_cmplt) begin
				nxt_state = BATT;
			end
			else begin
				resp = batt;
				send_resp = 1;
				nxt_state = IDLE;
			end
		// assert motors on and wait until tmr runs out (tmr is cleared at transition to CAL1)
		CAL1:
			if (!tmr_full) begin
				nxt_state = CAL1;
				en_mtrs = 1;
			end
			else begin
				nxt_state = CAL2;
				strt_cal = 1;
				inertial_cal = 1;
			end
		// begin callibration until given the signal cal_done is asserted
		CAL2:
			if (!cal_done) begin
				nxt_state = CAL2;
				inertial_cal = 1;
			end
			else begin
				nxt_state = SEND_ACK;
			end
	endcase
end
	
endmodule 