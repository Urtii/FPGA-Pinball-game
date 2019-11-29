module rectangle(
    input wire [31:0] s_x,
    input wire [31:0] s_y,
    input wire [31:0] wi,
    input wire [31:0] he,
    input wire [31:0] x,
    input wire [31:0] y,
    output wire rect
    );
    assign rect =
        x >= s_x &
        x < s_x + wi &
        y >= s_y &
        y < s_y + he;
endmodule

module ssd_vga(
	 input wire CLK,
    input wire [31:0] s_x,     // top left position (x)
    input wire [31:0] s_y,     // top left position (y)
    input wire [3:0] number,   // number to show
    input wire [31:0] x,       // current x
    input wire [31:0] y,       // current y
    output wire digit          // output
    );
    
    reg [6:0] lines;
    
    always @ (posedge CLK)
	 begin
        case (number)
        4'd0: lines = 7'b0111111;
        4'd1: lines = 7'b0000110;
        4'd2: lines = 7'b1011011;
        4'd3: lines = 7'b1001111;
        4'd4: lines = 7'b1100110;
        4'd5: lines = 7'b1101101;
        4'd6: lines = 7'b1111101;
        4'd7: lines = 7'b0000111;
        4'd8: lines = 7'b1111111;
        4'd9: lines = 7'b1101111;
        endcase
    end
    
    wire [6:0] rectangle_vs;
    
    rectangle rectangle0(
        s_x + 10, s_y,
        30, 10, x, y, rectangle_vs[0]);
    
    rectangle rectangle6(
        s_x + 10, s_y + 40,
        30, 10, x, y, rectangle_vs[6]);
    
    rectangle rectangle3(
        s_x + 10, s_y + 80,
        30, 10, x, y, rectangle_vs[3]);
    
    rectangle rectangle5(
        s_x, s_y + 10,
        10, 30, x, y, rectangle_vs[5]);
    
    rectangle rectangle1(
        s_x + 40, s_y + 10,
        10, 30, x, y, rectangle_vs[1]);
    
    rectangle rectangle4(
        s_x, s_y + 50,
        10, 30, x, y, rectangle_vs[4]);
    
    rectangle rectangle2(
        s_x + 40, s_y + 50,
        10, 30, x, y, rectangle_vs[2]);
		  
	     assign digit = lines[0] & rectangle_vs[0] |
		  lines[1] & rectangle_vs[1] | lines[2] & rectangle_vs[2] | lines[3] & rectangle_vs[3] | 
		  lines[4] & rectangle_vs[4] | lines[5] & rectangle_vs[5] | lines[6] & rectangle_vs[6];	 
endmodule
