module QuadCopter_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;
wire SS_A2D_n,SCLK_A2D,MOSI_A2D,MISO_A2D;
wire RX,TX;
wire [7:0] resp;				// response from DUT
wire cmd_sent,resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd_to_copter;		// command to Copter via wireless link
reg [15:0] data;				// data associated with command
reg send_cmd;					// asserted to initiate sending of command (to your CommMaster)
reg clr_resp_rdy;				// asserted to knock down resp_rdy

/////// declare any localparams here /////


////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT),
                .frnt_ESC(frnt_ESC),.back_ESC(back_ESC),.left_ESC(left_ESC),
				.rght_ESC(rght_ESC));				  

///////////////////////////////////////////////////
// Instantiate Model of A2D for battery voltage //
/////////////////////////////////////////////////
ADC128S iA2D(.clk(clk),.rst_n(RST_n),.SS_n(SS_A2D_n),.SCLK(SCLK_A2D),
             .MISO(MISO_A2D),.MOSI(MOSI_A2D));			
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.LED(),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC),.SS_A2D_n(SS_A2D_n),.SCLK_A2D(SCLK_A2D),
				.MOSI_A2D(MOSI_A2D),.MISO_A2D(MISO_A2D));

//// Instantiate Master UART (used to send commands to Copter) //////
CommMaster iMSTR(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                 .cmd(cmd_to_copter), .data(data), .snd_cmd(send_cmd), .cmd_sent(cmd_sent),
		 .resp_rdy(resp_rdy), .resp(resp), .clr_resp_rdy(clr_resp_rdy));


//This is where you do the real work.
//  This section could be done as a bunch of calls to testing sub tasks contained in a separate file.
//  
//  You might want to consider having several versions of this file that test several different
//  smaller things instead of having one huge test that runs forever.

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
	initialize;
	
	@(posedge clk);
	@(negedge clk);
	
	//Begin Testing
	// CASE1: TEST CALIBRATE
	SendCmd(CALIBRATE, 16'h0000);
	
	@(posedge resp_rdy)
	// check acknowledge
	
	//ChkMotorOn;
	// ChkResp(POS_ACK);
	ChkResp(POS_ACK);
	//SendCmd(MTRS_OFF, 16'h0000);
	
	//@(posedge resp_rdy)
	// check acknowledge
	//ChkMotorOff;
	//ChkResp(POS_ACK);
	
	//SendCmd(EMER_LAND, 16'h0000);
	//@(posedge resp_rdy)
	// check acknowledge
	//ChkResp(POS_ACK);
	
	///SendCmd(SET_THRST, 16'hFFFF);
	//@(posedge resp_rdy)
	// check acknowledge
	//ChkResp(POS_ACK);
	
	//SendCmd(SET_YAW, 16'hFFFF);
	//@(posedge resp_rdy)
	// check acknowledge
	//ChkResp(POS_ACK);
	
	SendCmd(SET_YAW, 16'h0080);
	// check acknowledge
	$display("Done Cal"); 
	repeat(98) @(posedge frnt_ESC);
	$display("Value: #d", iQuad.roll_p); 
	////SendCmd(SET_PTCH, 16'hFFFF);
	////@(posedge resp_rdy)
	// check acknowledge
	//ChkResp(POS_ACK);
	
	/*SendCmd(REQ_BATT, 16'hFFFF);
	@(posedge resp_rdy)
	// check acknowledge
	$display("batt: %b", resp);
	*/
	$display("You passed QuadCopter_tb");
	$stop();
	
end

always
  #10 clk = ~clk;

`include "tb_tasks.v"	// maybe have a separate file with tasks to help with testing

endmodule	
