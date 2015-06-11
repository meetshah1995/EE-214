module four_bit_multiplier( clk, multstart, a, b, result, done );
input clk, multstart; input [3:0] a, b;
output done; output [7:0] result;
reg [3:0] multd;
wire [7:0] result;                                      
wire ctr_load, ctr_enable, update_result;              // Control/Access Variables
wire [7:0] next_result;
wire [3:0] count;
always @( posedge clk ) if ( multstart ) multd <= a ;      // Temp register to store Multiplicand A
down_counter_4_bit i0 ( .clk( clk ), .load( ctr_load ), .din( b ), .enable ( ctr_enable ), .q( count ) );
assign ctr_load = multstart;
assign ctr_enable = | count;
assign next_result = result + multd;
parallel_register_4_bit i1 ( .clk ( clk ), .clear ( multstart ),.load ( update_result ), .din( next_result ), .q( result ) );
assign update_result = | count ;
assign done = ~ ( count[3] | count[2] | count[1] | count[0] );
endmodule

module down_counter_4_bit ( clk, load, din, enable, q );
input clk, load, enable; input [3:0] din; output [3:0] q;
wire [3:0] din; reg [3:0] q;
always @( posedge clk ) begin
if ( load ) q <= din; else if ( enable ) q <= q - 1;
end
endmodule

module parallel_register_4_bit ( clk, clear, load, din , q );
input clk, clear, load; input [7:0] din; output [7:0] q;
wire [7:0] din; reg [7:0] q;
always @( posedge clk ) if ( clear ) q <= 0; else if ( load ) q <= din;
endmodule

module test ;
reg clk, multstart; reg [3:0] a, b;
wire [3:0] result;
Exp7_v2 i0 ( clk, multstart, a, b, result, done );
endmodule