module lcd_final(lcd, led, col, lcd_rs, lcd_rw, lcd_en, row, clk, rst);
output reg [7:0] lcd; // Variable names are self-explanatory
output reg [4:0] led; // Should these be reg/ wire???
output reg [3:0] col;
output reg lcd_rs, lcd_rw, lcd_en;    
input [3:0] row;
input clk, rst;
reg [18:0] count; // Counter for 10 ms delay -> N = 4
reg [7:0] temp, lcd_dat; // temp = row-column combination of ‘the key’
reg [3:0] temp_row; // Stores row value before de-bouncing
reg [2:0] state; // FSM to send Commands and Data to LCD
reg [2:0] count_cmd; // Keeps count of commands sent to the LCD 
reg [1:0] state_debounce;// FSM for switch de-bouncing
reg [2:0] temp_state;
reg [1:0] temp_debounce;
// ... Declare an array to store the LCD commands
wire [7:0] lcd_cmd [4:0]; 
// ... Assign values to these array elements
//initial begin
 assign lcd_cmd[0] = 8'h38;
 assign lcd_cmd[1] = 8'h01;
 assign lcd_cmd[2] = 8'h0E;
 assign lcd_cmd[3] = 8'h80;
 assign lcd_cmd[4] = 8'h06;
 //end
// ... Define states for sending LCD commands and data
// We have used states S0 to S2 for sending commands,
// and S3 to S5 for sending data.

reg [2:0] S0,S1,S2,S3,S4,S5;
initial begin 
 S0 = 3'b000;
 S1 = 3'b001;
 S2 = 3'b010;
 S3 = 3'b011;
 S4 = 3'b100;
 S5 = 3'b101;
end
// ... Define states for switch de-bouncing
// We have named these states D0 to D2.
reg [1:0] D0,D1,D2;
initial begin 
 D0 = 2'b00;
 D1 = 2'b01;
 D2 = 2'b10;
end
parameter maxcount = 19'b1000000000000000000;     // max count allowed. 
reg temp_clk= 1'b0; 
//-------------------------------------------------------------------
// * Hardware = N bit Counter -> for generating 10 ms delay
always @(posedge clk)
begin
if (~rst)count =19'b0;
if(count==maxcount) begin count = 19'b0; temp_clk=~temp_clk; end
if (rst & count !=maxcount) count = count + 1;// Active high reset is to be used throughout
// ... Implement the count for the 10ms delay
end

// temp_clk -> new clk 100Hz. 

//-------------------------------------------------------------------
// * Hardware = Switch/ push button reading and de-bouncing mechanism
// * Should operate at 10 ms clk
always @ (posedge temp_clk or negedge rst)
// ... Decide the sensitivity list
begin
// ... Initialize State and column and LED values
if (~rst) begin col <= 4'b1000;end
else
case (state_debounce)
D0: // Wait until non-zero row value is detected
begin
if (row == 0)
begin
if(col==4'b0001)col<=4'b1000;
else col <= col >> 1;// ... Rotate the column and Decide the next state
state_debounce <=D0;
end
else
begin
// ... Store the row value and Decide the next state
temp_row<=row; state_debounce<= D1; 
end
end
D1: // Verify the row value (De-bounce)
begin
// ... If row values are equal, store the column-row
// combination in the variable ‘temp’
// and Decide the next state
//... If not equal, then Decide the next state
if(row==temp_row) begin temp<={temp_row,col}; state_debounce <= D2;end
else state_debounce<=D0; 
end
D2:
begin
//... Wait until key is released to avoid multiple

// detections and Decide the next state
//... When key is released, Decide the next state
if(row==temp_row) state_debounce<=D2;
else state_debounce<=D0;
end
default: // Why should you have a default case? Think.
begin
state_debounce <= D0; col<= 4'b1000;
end
endcase
end

//-------------------------------------------------------------------
// * Hardware = Decoder -> to compute the data to be sent to the LED/ LCD
// * operate at 10 ms and the value to decode is the row/ column data
always @ (posedge temp_clk )
// ... Decide the sensitivity list
begin
if(~rst)lcd_dat <= 8'h0;
else begin
case (temp)
// ... Depending on the unique row-column combination,
// decide value to be sent to the LED/LCD.
// For example: if key ‘1’ is pressed,
// led <= 5'h01;
// lcd_dat <= 8'h31; ... ASCII value of ‘1’
// and so on...
// Can only ASCII values be sent to LCD? Think.
8'b10001000 : begin lcd_dat <= 8'h31;led<=5'h01;end 
8'b10000100 : begin lcd_dat <= 8'h32;led<=5'h02;end
8'b10000010 : begin lcd_dat <= 8'h33;led<=5'h03;end
8'b10000001 : begin lcd_dat <= 8'h41;led<=5'h0A;end
8'b01001000 : begin lcd_dat <= 8'h34;led<=5'h04;end
8'b01000100 : begin lcd_dat <= 8'h35;led<=5'h05;end
8'b01000010 : begin lcd_dat <= 8'h36;led<=5'h06;end
8'b01000001 : begin lcd_dat <= 8'h42;led<=5'h0B;end
8'b00101000 : begin lcd_dat <= 8'h37;led<=5'h07;end
8'b00100100 : begin lcd_dat <= 8'h38;led<=5'h08;end
8'b00100010 : begin lcd_dat <= 8'h39;led<=5'h09;end
8'b00100001 : begin lcd_dat <= 8'h43;led<=5'h0C;end
8'b00011000 : begin lcd_dat <= 8'h2A;led<=5'h0E;end
8'b00010100 : begin lcd_dat <= 8'h30;led<=5'h00;end
8'b00010010 : begin lcd_dat <= 8'h23;led<=5'h0F;end
8'b00010001 : begin lcd_dat <= 8'h44;led<=5'h0D;end
default:
// What should your LED show when no key is pressed?
begin lcd_dat <= 8'h21; led<=5'h1F; end
endcase
end
end
//-------------------------------------------------------------------
// *Hardware = LCD Controller -> to send proper signals to the LCD
always @ (posedge temp_clk or negedge rst )
// ... Decide the sensitivity list
begin
if (~rst)
   begin
   state <= S0;
   count_cmd <= 3'b0; // Index to the LCD command array
   end
else
 begin
 case (state)
 S0: // S0 to S2: Send LCD commands
begin
 if (count_cmd < 3'b101)
  begin
  lcd <= lcd_cmd [count_cmd];
  lcd_rs <= 1'b0;
  lcd_rw <= 1'b0;
  lcd_en <= 1'b0;
  state <= S1;
  end
  // LCD requires 5 commands to be sent.
  // We send these commands and wait for valid LCD data
 else state <= S3;
end
S1:
 begin                                                //Is begin-end sequential?
 lcd <= lcd_cmd [count_cmd];                          // if yes then regs?
 lcd_rs <= 1'b0;
 lcd_rw <= 1'b0;
 lcd_en <= 1'b1;
 state <= S2;
 end
S2:
 begin
 lcd <= lcd_cmd [count_cmd];
 lcd_rs <= 1'b0;
 lcd_rw <= 1'b0;
 lcd_en <= 1'b0;
  count_cmd <= count_cmd + 1;
  state <= S0;
 end
S3: // S3 to S5: Send LCD data
 begin
 lcd <= lcd_dat;
 lcd_rs <= 1'b1;
 lcd_rw <= 1'b0;
 lcd_en <= 1'b0;
 state <= S4;
 end
S4:
 begin
 lcd <= lcd_dat;
 lcd_rs <= 1'b1;
 lcd_rw <= 1'b0;
 lcd_en <= 1'b1;
 state <= S5;
 end
S5:
 begin
 lcd <= lcd_dat;
 lcd_rs <= 1'b1;
 lcd_rw <= 1'b0;
 lcd_en <= 1'b0;
 // Monitor the state of de-bounce FSM to avoid displaying
 // the same character multiple times due to long key-press.
 if (state_debounce == D1) state <= S3;
 else state <= S5;
 end
default:
 begin
 state <= S0;
 count_cmd <= 3'b0;
 end
endcase
end
end
always @ (posedge temp_clk)
begin temp_state <= state; end
always @ (posedge temp_clk) begin
temp_debounce <= state_debounce; end

endmodule