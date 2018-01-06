module cmd_cfg_tb(); // YIPPEE KI YAW MOTHERCOPTERS

	// inputs
	logic clk, rst_n;
	logic[7:0] cmd;
	logic[15:0] data;
	logic[7:0] batt;
	logic cnv_cmplt;
	logic cal_done;
	logic snd_cmd;

	// internal wires
	logic COMM_TX, UART_TX;
	logic cmd_rdy;
	logic clr_cmd_rdy;
	logic[7:0] resp;
	logic snd_resp;
	logic frm_snt;
	logic[7:0] UART_cmd;
	logic[15:0] UART_data;

	// outputs
	wire[15:0] d_ptch, d_roll, d_yaw;
	wire[8:0] thrst;
	wire strt_cal;
	wire inertial_cal;
	wire motors_off;
	wire strt_cnv;
	wire resp_rdy;
	wire[7:0] COMM_resp;

	// INSTANTIATE COMMMASTER
	CommMaster iMASTER(.clk(clk), .rst_n(rst_n), .cmd(cmd), .snd_cmd(snd_cmd), .data(data), .resp(COMM_resp), 
			   .resp_rdy(resp_rdy), .RX(UART_TX), .TX(COMM_TX), .frm_snt(frm_snt));

	// INSTANTIATE UART WRAPPER
	UART_wrapper iWRAP(.clr_cmd_rdy(clr_cmd_rdy), .cmd_rdy(cmd_rdy), .snd_resp(send_resp), 
			   .resp_sent(resp_sent), .cmd(UART_cmd), .data(UART_data), .resp(resp), .clk(clk), .rst_n(rst_n), .TX(UART_TX), .RX(COMM_TX));

	// INSTANTIATE CMD_CFG
	cmd_cfg	iCFG(.clk(clk), .rst_n(rst_n), .cmd(UART_cmd), .cmd_rdy(cmd_rdy), .data(UART_data), .batt(batt), .cnv_cmplt(cnv_cmplt), .clr_cmd_rdy(clr_cmd_rdy),
		     .resp(resp), .send_resp(send_resp), .d_ptch(d_ptch), .d_roll(d_roll), .d_yaw(d_yaw), .thrst(thrst), 
		     .strt_cal(strt_cal), .inertial_cal(inertial_cal), .motors_off(motors_off), .strt_cnv(strt_cnv), .cal_done(cal_done));

	localparam POS_ACK = 8'hA5;
	localparam REQ_BATT = 8'h01;
	localparam SET_PTCH = 8'h02;
	localparam SET_ROLL = 8'h03;
	localparam SET_YAW = 8'h04;
	localparam SET_THRST = 8'h05;
	localparam EMER_LAND = 8'h06;
	localparam MTRS_OFF = 8'h07;
	localparam CALIBRATE = 8'h08;
	
	
	initial begin
		clk = 0;
		rst_n = 0;
		snd_cmd = 0; 
		data = 0; 
		cnv_cmplt = 0;
		cal_done = 0;
		cmd = 0;
		
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;
		
		// test SET_PTCH
		task_send_cmd(SET_PTCH,16'h1234);
		// test if our response was POS_ACK
		wait_and_check_resp(POS_ACK);
		// test if d_ptch is the value we sent
		if (d_ptch!= 16'h1234) begin
			$display("You done goofed, case 1");
			$stop;
		end
		
		
		// test SET_ROLL
		task_send_cmd(SET_ROLL,16'h1235);
		// test if our response was POS_ACK
		wait_and_check_resp(POS_ACK);
		// test if d_roll is the value we sent
		if (d_roll!= 16'h1235) begin
			$display("You done goofed, case 2");
			$stop;
		end
		
		// test SET_YAW
		task_send_cmd(SET_YAW,16'h1236);
		// test if our response was POS_ACK
		wait_and_check_resp(POS_ACK);
		// test if d_yaw is the value we sent
		if (d_yaw!= 16'h1236) begin
			$display("You done goofed, case 3");
			$stop;
		end
		
		
		// test SET_THRST
		task_send_cmd(SET_THRST,16'h0037);
		// test if our response was POS_ACK
		wait_and_check_resp(POS_ACK);
		// test if d_thrst is the value we sent
		if (thrst != 16'h0037) begin
			$display("You done goofed, case 4");
			$stop;
		end
	
		
		// CASE 5: TEST EMERGENCY LAND
		task_send_cmd(EMER_LAND,16'h0000);
		// test if our response was POS_ACK
		wait_and_check_resp(POS_ACK);
		// check d_roll, d_yaw, d_ptch, d_thrst are zero
		if(d_ptch != 0 || d_yaw != 0 || d_roll != 0 || thrst != 0) begin
			$display("You done goofed, case 5");
			$stop();
		end

		// CASE 6: TEST MOTORS OFF
		task_send_cmd(MTRS_OFF, 16'h0000);
		// test if our response was POS_ACK
		wait_and_check_resp(POS_ACK);
		// test if motors are off
		if(!motors_off) begin
			$display("You done goofed, case 6");
			$stop();
		end
		
		
		// CASE 8: REQUEST VOLTAGE
		task_send_cmd(REQ_BATT,16'h0000);
		// assert cnv_cmplt to get a response for this test bench
		cnv_cmplt = 1;
		@(posedge resp_rdy)
		// test if resp is the battery reading
		if(resp != 8'hCA) begin
			$display("You done goofed, case 8");
			$stop();
		end
		
	

		// CASE 9: TEST CALIBRATE
		task_send_cmd(CALIBRATE, 16'h0000);
		// wait until it starts calibration
		@(posedge strt_cal);
		// assert cal_done to end calibration  
		cal_done = 1;
		@(posedge clk);
		// test if our response was POS_ACK
		wait_and_check_resp(POS_ACK);
		@(posedge clk);
		cal_done = 0;
		// test if motors are on
		if(motors_off) begin
			$display("You done goofed, case 9");
			$stop();
		end
		
		
		$display("YAHOO all tests passed!");
		$stop;


	end

	always
		#1 clk = ~clk;
		
	// update cmd and data with the desired cmd and data
	task task_send_cmd;
		input[7:0] cmd2;
		input [15:0] data2;
		
		begin
			cmd=cmd2;
			data=data2;
			snd_cmd=1;
			$display("sending cmd, data &h, %h", cmd, data);
			@(posedge clk);
			snd_cmd = 0;
			@(posedge clk);
		end
	endtask
	
	// wait for response and check for expected data
	task wait_and_check_resp;
		input [7:0] expected_data;
		begin
			@(posedge resp_rdy);
			if (resp != expected_data) begin
				$display("we expected data %h but got %h", expected_data, resp); 
			end
		end
	endtask
	

endmodule