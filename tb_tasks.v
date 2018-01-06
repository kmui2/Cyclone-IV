	task initialize;
	clk = 0;
	RST_n = 0;
	cmd_to_copter = 0;		// command to Copter via wireless link
	data = 0;				// data associated with command
	send_cmd = 0;					// asserted to initiate sending of command (to your CommMaster)
	clr_resp_rdy = 0;	
	@(posedge clk);
	@(negedge clk);
	RST_n = 1;
	endtask
	
	task SendCmd(input reg[7:0] cmd, input reg[15:0] dt);
		cmd_to_copter = cmd;
		data = dt;
		@(negedge clk);
		send_cmd = 1;
		@(negedge clk);
		send_cmd = 0;
	endtask
	
	task ChkResp(input reg[7:0] response);
		if(resp != response) begin
			$display("You done goofed");
			$stop();
		end
		@(negedge clk);
		clr_resp_rdy = 1;
		@(negedge clk);
		clr_resp_rdy = 0;
		
	endtask
	
	task ChkMotorOff;
		if (frnt_ESC != 0) begin
			$display("Test failed");
			$stop();
		end
		if (back_ESC != 0) begin
			$display("Test failed");
			$stop();
		end
		if (left_ESC != 0) begin
			$display("Test failed");
			$stop();
		end
		if (rght_ESC != 0) begin
			$display("Test failed");
			$stop();
		end
	endtask
	
	task ChkMotorOn;
		if (frnt_ESC == 0 && back_ESC == 0 && left_ESC == 0 && rght_ESC == 0) begin
			$display("Test failed");
			$stop();
		end

	endtask
	
	task ChkPosAck(input signal);
		if (signal) begin
			$display("Test passed!");
		end
		else begin
			$display("Error");
			$stop;
		end
	endtask
