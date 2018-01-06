module inert_intf(clk, rst_n, vld, strt_cal, INT, cal_done, ptch, roll, yaw, SS_n, SCLK, MOSI, MISO);
	// INPUTS
	input clk, rst_n, strt_cal, INT;
	input MISO;

	// INTERNAL WIRES
	logic wrt;
	logic[15:0] cmd;
	logic done;
	logic [15:0] data;
	logic[7:0] rd_data;
	logic signed [15:0] ptch_rt, roll_rt, yaw_rt, ax, ay;
	logic[16:0] tmr;
	logic en_ptchL, en_ptchH, en_rollL, en_rollH, en_yawL, en_yawH, en_axL, en_axH, en_ayL, en_ayH;
	logic[7:0] ptchL, ptchH, rollL, rollH, yawL, yawH, axL, axH, ayL, ayH;

	// OUTPUTS
	output logic vld;
	output cal_done;
	output[15:0] ptch, roll, yaw;
	output SS_n, SCLK, MOSI;

	// ADDRESSES
	localparam ptchLAddr = 16'hA200;
	localparam ptchHAddr = 16'hA300;
	localparam rollLAddr = 16'hA400;
	localparam rollHAddr = 16'hA500;
	localparam yawLAddr = 16'hA600;
	localparam yawHAddr = 16'hA700;
	localparam AXLAddr = 16'hA800;
	localparam AXHAddr = 16'hA900;
	localparam AYLAddr = 16'hAA00;
	localparam AYHAddr = 16'hAB00;
	
	localparam en_int = 16'h0D02;
	localparam set_accel = 16'h1062;
	localparam set_gyro = 16'h1162;
	localparam turn_round = 16'h1460;
	
	reg INT_ff1, INT_ff2;


	typedef enum logic[3:0]{INIT1, INIT2, INIT3, INIT4, WAIT, DATA_RDY, PITCHL, PITCHH, ROLLL, ROLLH, YAWL, YAWH, AXL, AXH, AYL, AYH} state_t;
	state_t state, nxt_state;
	
	// INSTANTIATE MODULEs
	SPI_mstr16 iSPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .cmd(cmd), 
			.done(done), .rd_data(data));

	inertial_integrator #(3) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done), .vld(vld), .ptch_rt(ptch_rt),
				.roll_rt(roll_rt), .yaw_rt(yaw_rt), .ax(ax), .ay(ay), .ptch(ptch), .roll(roll), .yaw(yaw));
	
	///////////////////////////////////////////////
	// Turns out meta-stability is a real thing //
	/////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n)
	  if (!rst_n) begin
	    INT_ff1 <= 1'b0;
		INT_ff2 <= 1'b0;
	  end else begin
	    INT_ff1 <= INT;
		INT_ff2 <= INT_ff1;
	  end
	
	assign rd_data = data[7:0];
	
	// TIMER
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			tmr <= 0;
		else
			tmr <= tmr + 1;
	end

	// state flip-flop
	always_ff @(posedge clk, negedge rst_n) begin
    		if (!rst_n)
	   		state <= INIT1;
		 else
			state <= nxt_state;
	end

	// PITCH LOW
	always @(posedge clk) begin
		if(!rst_n)
			ptchL <= 0;
		else if(en_ptchL)
			ptchL <= rd_data;
		else
			ptchL <= ptchL;
	end

	// PITCH HIGH
	always @(posedge clk) begin
		if(!rst_n)
			ptchH <= 0;
		else if(en_ptchH)
			ptchH <= rd_data;
		else
			ptchH <= ptchH;
	end

	// ROLL LOW
	always @(posedge clk) begin
		if(!rst_n)
			rollL <= 0;
		else if(en_rollL)
			rollL <= rd_data;
		else
			rollL <= rollL;
	end

	// ROLL HIGH
	always @(posedge clk) begin
		if(!rst_n)
			rollH <= 0;
		else if(en_rollH)
			rollH <= rd_data;
		else
			rollH <= rollH;
	end

	// YAW LOW
	always @(posedge clk) begin
		if(!rst_n)
			yawL <= 0;
		else if(en_yawL)
			yawL <= rd_data;
		else
			yawL <= yawL;
	end
	
	// YAW HIGH
	always @(posedge clk) begin
		if(!rst_n)
			yawH <= 0;
		else if(en_yawH)
			yawH <= rd_data;
		else
			yawH <= yawH;
	end

	// AX LOW
	always @(posedge clk) begin
		if(!rst_n)
			axL <= 0;
		else if(en_axL)
			axL <= rd_data;
		else
			axL <= axL;
	end

	// AX HIGH
	always @(posedge clk) begin
		if(!rst_n)
			axH <= 0;
		else if(en_axH)
			axH <= rd_data;
		else
			axH <= axH;
	end

	// AY LOW
	always @(posedge clk) begin
		if(!rst_n)
			ayL <= 0;
		else if(en_ayL)
			ayL <= rd_data;
		else
			ayL <= ayL;
	end

	// AY HIGH
	always @(posedge clk) begin
		if(!rst_n)
			ayH <= 0;
		else if(en_ayH)
			ayH <= rd_data;
		else
			ayH <= ayH;
	end


	assign ptch_rt = {ptchH, ptchL};
	assign yaw_rt = {yawH, yawL};
	assign roll_rt = {rollH, rollL};
	assign ax = {axH, axL};
	assign ay = {ayH, ayL};

	always_comb begin

	// Default outputs //
	wrt = 0;
	cmd = 0;
	vld = 0;
	en_ptchL = 0;
	en_ptchH = 0;
	en_rollL = 0;
	en_rollH = 0;
	en_yawL = 0;
	en_yawH = 0;
	en_axL = 0;
	en_axH = 0;
	en_ayL = 0;
	en_ayH = 0;
   nxt_state = INIT1;
	//nxt_state = state;

	case (state)
	INIT1 : begin
		if(tmr == 16'hFFFF) begin
			cmd = en_int;
			wrt = 1;
			nxt_state = INIT2;
		end	
	end
	
	INIT2 : begin
		if(tmr == 16'hFFFF) begin
			cmd = set_accel;
			wrt = 1;
			nxt_state = INIT3;
		end else
		  nxt_state = INIT2;

	end

	INIT3 : begin
		if(tmr == 16'hFFFF) begin
			cmd = set_gyro;
			wrt = 1;
			nxt_state = INIT4;
		end else
		  nxt_state = INIT3;

	end
	
	INIT4 : begin
		if(tmr == 16'hFFFF) begin
			cmd = turn_round;
			wrt = 1;
			nxt_state = WAIT;
		end else
		  nxt_state = INIT4;

	end
	
	WAIT: begin
		if(done) begin
			nxt_state = DATA_RDY;
		end else
		  nxt_state = WAIT;
        end

	DATA_RDY: begin
		
		if(INT_ff2) begin
			nxt_state = PITCHL;
			wrt = 1;
			cmd = ptchLAddr;
		end else
		  nxt_state = DATA_RDY;

	end

	PITCHL : begin
		if(done) begin
			nxt_state = PITCHH;
			en_ptchL = 1;
			cmd = ptchHAddr;
			wrt = 1;
		end else
		  nxt_state = PITCHL;
	end
	
	PITCHH : begin
		if(done) begin
			nxt_state = ROLLL;
			en_ptchH = 1;
			cmd = rollLAddr;
			wrt = 1;
		end else
		  nxt_state = PITCHH;
	end

	ROLLL : begin
		if(done) begin
			nxt_state = ROLLH;
			en_rollL = 1;
			cmd = rollHAddr;
			wrt = 1;
		end else
		  nxt_state = ROLLL;

	end
	
	ROLLH : begin
		if(done) begin
			nxt_state = YAWL;
			en_rollH = 1;
			cmd = yawLAddr;
			wrt = 1;
		end else
		  nxt_state = ROLLH;

	end

	YAWL : begin
		
		if(done) begin
			nxt_state = YAWH;
			en_yawL = 1;
			cmd = yawHAddr;
			wrt = 1;
		end else
		  nxt_state = YAWL;

	end
	
	YAWH : begin
		
		if(done) begin
			nxt_state = AXL;
			en_yawH = 1;
			cmd = AXLAddr;
			wrt = 1;
		end else
		  nxt_state = YAWH;

	end

	AXL : begin
		
		if(done) begin
			nxt_state = AXH;
			en_axL = 1;
			cmd = AXHAddr;
			wrt = 1;
			
		end else
		  nxt_state = AXL;

	end
	
	AXH : begin
		
		if(done) begin
			nxt_state = AYL;
			en_axH = 1;
			cmd = AYLAddr;
			wrt = 1;
		end else
		  nxt_state = AXH;
	end

	AYL : begin
		
		if(done) begin
			nxt_state = AYH;
			en_ayL = 1;
			cmd = AYHAddr;
			wrt = 1;
		end else
		  nxt_state = AYL;
	end
	
	AYH : begin
		if(done) begin
			nxt_state = DATA_RDY;
			en_ayH = 1;
			vld = 1;
		end else
		  nxt_state = AYH;

	end
	
	default : begin
		nxt_state = INIT1;

	end
		
	endcase
	 
  end
  

endmodule

	
