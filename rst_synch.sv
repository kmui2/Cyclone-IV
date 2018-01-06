module rst_synch(RST_n, clk, rst_n);

input RST_n;
input clk;
output logic rst_n;
logic middle;

always_ff@(negedge clk, negedge RST_n) begin

if (!RST_n) begin
    middle <= 1'b0;
    rst_n <= 1'b0;
end

else begin
    middle <= 1'b1;
    rst_n <= middle;
end

end


endmodule
