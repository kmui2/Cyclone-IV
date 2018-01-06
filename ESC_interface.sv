module ESC_interface(clk, rst_n, SPEED, OFF, PWM);

input clk, rst_n;
input[10:0] SPEED; // speed of motors
input[9:0] OFF;	// added to correct variation

output logic PWM;

wire[11:0] compensated_speed;	// speed + offset
wire[15:0] compensated_speed_p;
wire[16:0] setting;
wire Rst, Set;

localparam PERIOD_WIDTH = 18;

logic[PERIOD_WIDTH-1:0] cnt;
logic[10:0] SPEED_FF;



assign compensated_speed = SPEED_FF + OFF;
assign compensated_speed_p = compensated_speed << 4;
assign setting = compensated_speed_p + 16'd50000;
assign Rst = cnt[16:0] >= setting;
assign Set = &cnt;


always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		SPEED_FF <= 0;
	else
		SPEED_FF <= SPEED;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		cnt <= 0;
	else
		cnt <= cnt + 1;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		PWM <= 1'b0;
	else if (Set)
		PWM <= 1'b1;
	else if (Rst)
		PWM <= 1'b0;
end 

endmodule 