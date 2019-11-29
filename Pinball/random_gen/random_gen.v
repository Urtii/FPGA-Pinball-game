module random_gen (
    input CLK,
    input reset,
    output rnd1,
    output rnd3,
    output rnd7,
    output rnd8,
    output rnd11
    );
 
wire feedback = random[7] ^ random[9] ^ random[11] ^ random[3]; 
 
reg [12:0] random, random_next, random_done;
reg [3:0] count, count_next; //to keep track of the shifts
 
always @ (posedge CLK)
begin
 if (reset)
 begin
  random <= 13'hF; //An LFSR cannot have an all 0 state, thus reset to FF
  count <= 0;
 end
  
 else
 begin
  random <= random_next;
  count <= count_next;
 end

 random_next = random; //default state stays the same
 count_next = count;
   
  random_next <= {random[11:0], feedback}; //shift left the xor'd every posedge clock
  count_next <= count + 1;
 
 if (count == 13)
 begin
  count <= 0;
  random_done <= random; //assign the random number to output after 13 shifts
 end
  
end
 
 
assign rnd1 = random_done[1];
assign rnd3 = random_done[3];
assign rnd7 = random_done[7];
assign rnd8 = random_done[8];
assign rnd11 = random_done[11];


endmodule
