module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
					roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);
				
parameter D_QUEUE_DEPTH = 14;		// delay for derivative term
				
input clk,rst_n;
input vld;									// tells when a new valid inertial reading ready
											// only update D_QUEUE on vld readings
input inertial_cal;							// need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw;	// desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw;			// actual pitch roll and yaw (from inertial interface)
input [8:0] thrst;							// thrust level from slider
output [10:0] frnt_spd;						// 11-bit unsigned speed at which to run front motor
output [10:0] bck_spd;						// 11-bit unsigned speed at which to back front motor
output [10:0] lft_spd;						// 11-bit unsigned speed at which to left front motor
output [10:0] rght_spd;						// 11-bit unsigned speed at which to right front motor

///////////////////////////////////////////////////
// Need integer for loop used to create D_QUEUE //
/////////////////////////////////////////////////
integer x;
//////////////////////////////
// Define needed registers //
////////////////////////////								
reg signed [9:0] prev_ptch_err[0:D_QUEUE_DEPTH-1];
reg signed [9:0] prev_roll_err[0:D_QUEUE_DEPTH-1];
reg signed [9:0] prev_yaw_err[0:D_QUEUE_DEPTH-1];	// need previous error terms for D of PD

//////////////////////////////////////////////////////
// You will need a bunch of interal wires declared //
// for intermediate math results...do that here   //
///////////////////////////////////////////////////

///////////////////////////////////////////////////////////////
// some Parameters to keep things more generic and flexible //
/////////////////////////////////////////////////////////////
  
localparam CAL_SPEED = 11'h1B0;		// speed to run motors at during inertial calibration
localparam MIN_RUN_SPEED = 13'h200;	// minimum speed while running  
localparam D_COEFF = 6'b00111;			// D coefficient in PID control = +7
  
  
/// OK...rest is up to you...good luck! ///


//////////////////////////////////////////////
// Calculate pterm for ptch, roll, and yaw //
////////////////////////////////////////////
logic signed [16:0] ptch_err;
logic signed [9:0] ptch_err_sat;
logic signed [9:0] ptch_pterm;
logic signed [9:0] ptch_err_sat_ff;
assign ptch_err = ptch-d_ptch;

assign ptch_err_sat_ff = (|ptch_err[15:9] & ~ptch_err[16]) ? 10'b0111111111 : 
						(~&ptch_err[15:9] & ptch_err[16]) ? 10'b1000000000 :
						ptch_err[9:0];

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		ptch_err_sat <= 0;
	else
		ptch_err_sat <= ptch_err_sat_ff;
end
						
assign ptch_pterm = (ptch_err_sat >>> 1) + (ptch_err_sat >>> 3);


logic signed [16:0] roll_err;
logic signed [9:0] roll_err_sat;
logic signed [9:0] roll_pterm;
logic signed [9:0] roll_err_sat_ff;

assign roll_err = roll-d_roll;

assign roll_err_sat_ff = 	(|roll_err[15:9] & ~roll_err[16]) ? 10'b0111111111 : 
						(~&roll_err[15:9] & roll_err[16]) ? 10'b1000000000 :
						roll_err[9:0];

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		roll_err_sat <= 0;
	else
		roll_err_sat <= roll_err_sat_ff;
end
						
assign roll_pterm = (roll_err_sat >>> 1) + (roll_err_sat >>> 3);


logic signed [16:0] yaw_err;
logic signed [9:0] yaw_err_sat;
logic signed [9:0] yaw_pterm;
logic signed [9:0] yaw_err_sat_ff;

assign yaw_err = yaw-d_yaw;

assign yaw_err_sat_ff = 	(|yaw_err[15:9] & ~yaw_err[16]) ? 10'b0111111111 : 
						(~&yaw_err[15:9] & yaw_err[16]) ? 10'b1000000000 :
						yaw_err[9:0];

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		yaw_err_sat <= 0;
	else
		yaw_err_sat <= yaw_err_sat_ff;
end
						
assign yaw_pterm = (yaw_err_sat >>> 1) + (yaw_err_sat >>> 3);
	
	
////////////////////////////////////////////////////////////////////////
// Create D queueing flip flops for storing prev ptch, roll, and yaw //
//////////////////////////////////////////////////////////////////////
always_ff@ (posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			for (x = 0; x < D_QUEUE_DEPTH-1; x = x + 1) begin
				prev_ptch_err[x] <= 0;
				prev_roll_err[x] <= 0;
				prev_yaw_err[x] <= 0;
			end
		end
		else if (vld) begin
			for (x = 0; x < D_QUEUE_DEPTH-1; x = x + 1) begin
				prev_ptch_err[x] <= prev_ptch_err[x+1];
				prev_roll_err[x] <= prev_roll_err[x+1];
				prev_yaw_err[x] <= prev_yaw_err[x+1];
			end
			
			prev_ptch_err[D_QUEUE_DEPTH-1] <= ptch_err_sat;
			prev_roll_err[D_QUEUE_DEPTH-1] <= roll_err_sat;
			prev_yaw_err[D_QUEUE_DEPTH-1] <= yaw_err_sat;
		end
end


///////////////////////////////////////////////////////////
// Calculate D_diff staturated for ptch, roll, and yaw //
/////////////////////////////////////////////////////////
logic signed [9:0] ptch_D_diff;
assign ptch_D_diff = ptch_err_sat - prev_ptch_err[0];

logic signed [9:0] roll_D_diff;
assign roll_D_diff = roll_err_sat - prev_roll_err[0];

logic signed [9:0] yaw_D_diff;
assign yaw_D_diff = yaw_err_sat - prev_yaw_err[0];

logic signed [5:0] ptch_D_diff_sat;
logic signed [5:0] roll_D_diff_sat;
logic signed [5:0] yaw_D_diff_sat;
assign ptch_D_diff_sat = 	(|ptch_D_diff[8:5] & ~ptch_D_diff[9]) ? 6'b011111 : 
							(~&ptch_D_diff[8:5] & ptch_D_diff[9]) ? 6'b100000 :
							ptch_D_diff[5:0];

assign roll_D_diff_sat = 	(|roll_D_diff[8:5] & ~roll_D_diff[9]) ? 6'b011111 : 
							(~&roll_D_diff[8:5] & roll_D_diff[9]) ? 6'b100000 :
							roll_D_diff[5:0];

assign yaw_D_diff_sat = 	(|yaw_D_diff[8:5] & ~yaw_D_diff[9]) ? 6'b011111 : 
							(~&yaw_D_diff[8:5] & yaw_D_diff[9]) ? 6'b100000 :
							yaw_D_diff[5:0];

							
/////////////////////////////////////////////////////////////////////
// Calculate dterm using D_diff saturated for ptch, roll, and yaw //
///////////////////////////////////////////////////////////////////
logic signed [11:0] ptch_dterm;
logic signed [11:0] roll_dterm;
logic signed [11:0] yaw_dterm;

assign ptch_dterm = ptch_D_diff_sat * $signed(D_COEFF);
assign roll_dterm = roll_D_diff_sat * $signed(D_COEFF);
assign yaw_dterm = yaw_D_diff_sat * $signed(D_COEFF);
	

////////////////////////////////////////////////////////////////
// Sign extend all calculation terms for ptch, roll, and yaw //
//////////////////////////////////////////////////////////////
logic signed [12:0] frnt_calc;
logic signed [12:0] bck_calc;
logic signed [12:0] lft_calc;
logic signed [12:0] rght_calc;

logic [12:0] thrst_SE; 
logic signed [12:0] ptch_pterm_SE;
logic signed [12:0] ptch_dterm_SE;
logic signed [12:0] yaw_pterm_SE;
logic signed [12:0] yaw_dterm_SE;
logic signed [12:0] roll_pterm_SE;
logic signed [12:0] roll_dterm_SE;

assign thrst_SE = {{4'b0000},thrst[8:0]};
assign ptch_pterm_SE = {{3{ptch_pterm[9]}},ptch_pterm[9:0]};
assign ptch_dterm_SE = {{1{ptch_dterm[11]}},ptch_dterm[11:0]};
assign roll_pterm_SE = {{3{roll_pterm[9]}},roll_pterm[9:0]};
assign roll_dterm_SE = {{1{roll_dterm[11]}},roll_dterm[11:0]};
assign yaw_pterm_SE = {{3{yaw_pterm[9]}},yaw_pterm[9:0]};
assign yaw_dterm_SE = {{1{yaw_dterm[11]}},yaw_dterm[11:0]};


//////////////////////////////////////////////////////////////////////////////////
// Begin calculating saturated intermmediate frnt, bck, lft, rght speed values //
////////////////////////////////////////////////////////////////////////////////
	
assign frnt_calc = thrst_SE+$signed(MIN_RUN_SPEED)-ptch_pterm_SE-ptch_dterm_SE-yaw_pterm_SE-yaw_dterm_SE;
assign bck_calc = thrst_SE+$signed(MIN_RUN_SPEED)+ptch_pterm_SE+ptch_dterm_SE-yaw_pterm_SE-yaw_dterm_SE;
assign lft_calc = thrst_SE+$signed(MIN_RUN_SPEED)+roll_pterm_SE-roll_dterm_SE+yaw_pterm_SE+yaw_dterm_SE;
assign rght_calc = thrst_SE+$signed(MIN_RUN_SPEED)+roll_pterm_SE+roll_dterm_SE+yaw_pterm_SE+yaw_dterm_SE;

logic signed [11:0] frnt_calc_sat;
logic signed [11:0] bck_calc_sat;
logic signed [11:0] lft_calc_sat;
logic signed [11:0] rght_calc_sat;

assign frnt_calc_sat = (|frnt_calc[12:11]) ? 11'b11111111111 : frnt_calc[10:0];
assign bck_calc_sat = (|bck_calc[12:11]) ? 11'b11111111111 : bck_calc[10:0];
assign lft_calc_sat = (|lft_calc[12:11]) ? 11'b11111111111 : lft_calc[10:0];
assign rght_calc_sat = (|rght_calc[12:11]) ? 11'b11111111111 : rght_calc[10:0];


////////////////////////////////////////////////////////////////////////
// Calculate frnt, bck, lft, and rght speeds for ptch, roll, and yaw //
//////////////////////////////////////////////////////////////////////			
				
assign frnt_spd = inertial_cal ? CAL_SPEED : frnt_calc_sat;
assign bck_spd = inertial_cal ? CAL_SPEED : bck_calc_sat;
assign lft_spd = inertial_cal ? CAL_SPEED : lft_calc_sat;
assign rght_spd = inertial_cal ? CAL_SPEED : rght_calc_sat;
	
	
	
  
endmodule 
