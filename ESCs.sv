module ESCs(clk, rst_n, frnt_spd, bck_spd, lft_spd, rght_spd, motors_off, frnt, bck, lft, rght);

input clk, rst_n;
input logic[10:0] frnt_spd, bck_spd, lft_spd, rght_spd;
input logic motors_off;

output logic frnt, bck, lft, rght;

logic[10:0] frnt_speed, bck_speed, lft_speed, rght_speed;
logic[9:0] frnt_off, bck_off, lft_off, rght_off;

localparam FRNT_OFF = 10'h220;
localparam BCK_OFF = 10'h220;
localparam LFT_OFF = 10'h220;
localparam RGHT_OFF = 10'h220;

ESC_interface front_ESC(.clk(clk), .rst_n(rst_n), .SPEED(frnt_speed), .OFF(frnt_off), .PWM(frnt));
ESC_interface back_ESC(.clk(clk), .rst_n(rst_n), .SPEED(bck_speed), .OFF(bck_off), .PWM(bck));
ESC_interface left_ESC(.clk(clk), .rst_n(rst_n), .SPEED(lft_speed), .OFF(lft_off), .PWM(lft));
ESC_interface right_ESC(.clk(clk), .rst_n(rst_n), .SPEED(rght_speed), .OFF(rght_off), .PWM(rght));

assign frnt_speed = !motors_off ? frnt_spd : 0;
assign bck_speed = !motors_off ? bck_spd : 0;
assign lft_speed = !motors_off ? lft_spd : 0;
assign rght_speed = !motors_off ? rght_spd : 0;

assign frnt_off = !motors_off ? FRNT_OFF: 0;
assign bck_off = !motors_off ? BCK_OFF: 0;
assign lft_off = !motors_off ? LFT_OFF: 0;
assign rght_off = !motors_off ? RGHT_OFF: 0;

endmodule