module A2D_intf(clk, rst_n, strt_cnv, chnnl, cnv_cmplt, res, MISO, SS_n, SCLK, MOSI);

input logic clk, rst_n;
input logic strt_cnv;
input logic[2:0] chnnl;
input logic MISO;

output logic cnv_cmplt;
output logic[11:0] res;
output logic SS_n, SCLK, MOSI;

logic wrt, done;
logic set, clr;
logic [15:0] rd_data;


typedef enum reg[1:0] {IDLE, CONV_MOSI, WAIT, CONV_MISO} state_t;
state_t state, nxt_state;


SPI_mstr16 iSPI(.clk(clk), .rst_n(rst_n), .wrt(wrt), .MISO(MISO), .cmd({2'b00,chnnl,11'h000}),
.SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .rd_data(rd_data));


assign res = rd_data[11:0];


always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
	end
	else begin
		state <= nxt_state;
	end
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cnv_cmplt <= 0;
	end
	else if (set) begin
		cnv_cmplt <= 1;
	end
	else if (clr) begin
		cnv_cmplt <= 0;
	end
end

always_comb begin
	wrt = 0;
	clr = 0;
	set = 0;
	nxt_state = IDLE;
	
	case (state)
		IDLE:
			if (!strt_cnv) begin
				nxt_state = IDLE;
			end
			else begin
				nxt_state = CONV_MOSI;
				wrt = 1;
				clr = 1;
			end

		CONV_MOSI:
			if (!done) begin
				nxt_state = CONV_MOSI;
			end
			else begin
				nxt_state = WAIT;
			end
	
		WAIT: begin
			nxt_state = CONV_MISO;
			wrt = 1;
		end
		
		CONV_MISO:
			if (!done) begin
				nxt_state = CONV_MISO;
			end
			else begin
				nxt_state = IDLE;
				set = 1;
			end
	endcase
end

endmodule 