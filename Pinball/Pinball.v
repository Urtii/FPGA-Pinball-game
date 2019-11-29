module Pinball(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire RST_BTN,         // reset button
	 input wire plunger_BTN,		  // plunger button
	 input wire flipper_left,	  // left flipper button
	 input wire flipper_right,	  // left flipper button
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output wire [7:0] VGA_R,    // 4-bit VGA red output
    output wire [7:0] VGA_G,    // 4-bit VGA green output
    output wire [7:0] VGA_B,     // 4-bit VGA blue output
    output wire clk_25MHz 
	 );

	 
	 wire digit_count = ~RST_BTN;
    wire rst = ~RST_BTN;    // reset is active low on Arty & Nexys Video
    // wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)

	 assign clk_25MHz = pix_stb;
	 
    wire [9:0] x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0] y;  // current pixel y position:  9-bit value: 0-511
    wire animate;  // high when we're ready to animate at end of drawing

    // generate a 25 MHz pixel strobe
    reg [15:0] cnt = 0;
    reg pix_stb = 0;
    always @(posedge CLK)
        {pix_stb, cnt} <= cnt + 16'h8000;  // divide by 2: (2^16)/2 = 0x8000

    vga640x480 display (
        .i_clk(CLK),
        .i_pix_stb(pix_stb),
        .i_rst(rst),
        .o_hs(VGA_HS_O), 
        .o_vs(VGA_VS_O), 
        .o_x(x), 
        .o_y(y),
        .o_animate(animate)
    );
	

	
	 //***********Time Display***************************************************************************
	 
	 integer counter_time;
	 integer s0;	//first digit of second
	 integer s1;	//second digit of second
	 integer m0;	//first digit of minute
	 integer m1; 	//second digit of minute

	 always @ (posedge CLK)
	 begin	
		if (rst)
		begin
			 counter_time <=0;
			 s0 <= 0;
			 s1 <= 0;
			 m0 <= 0;
			 m1 <= 0; 
		end
		if ((counter_time == 49_999_999)&(s0 == 9)&(s1 == 5)&(m0 == 9))
		begin
			counter_time <= 0;
			s0 <= 0;
			s1 <= 0;
			m0 <= 0;
			m1 <= m1+1;
		end
		
		else if ((counter_time == 49_999_999)&(s0 == 9)&(s1 == 5))
		begin
			counter_time <= 0;
			s0 <= 0;
			s1 <= 0;
			m0 <= m0+1;
		end
		else if ((counter_time == 49_999_999)&(s0 == 9))
		begin
			counter_time <= 0;
			s0 <= 0;
			s1 <= s1+1;
		end
		else if (counter_time == 49_999_999)
		begin
			counter_time <= 0;
			s0 <= s0+1;
		end
		else
			counter_time <= counter_time +1;
	 end	 
	 
		 ssd_vga time3 (
				CLK, 350, 100, m1, x, y, t3);
		 ssd_vga time2 (
				CLK, 410, 100, m0, x, y, t2);
		 ssd_vga time1 (
				CLK, 500, 100, s1, x, y, t1);
		 ssd_vga time0 (
				CLK, 560, 100, s0, x, y, t0);
		

		 ssd_vga pt3 (
			CLK, 365, 300, point3, x, y, p3);
		 ssd_vga pt2 (
			CLK, 425, 300, point2, x, y, p2);
		 ssd_vga pt1 (
			CLK, 485, 300, point1, x, y, p1);
		 ssd_vga pt0 (
			CLK, 545, 300, point0*5, x, y, p0);

	 //***********Time Flags***************************************************************************
	 //Each process done in a certain time between each frame
	 
	 integer timecounter;
	 
	 wire flag_collision;		//if 1 run collision process
	 wire flag_velocityset;		//if 1 set new velocity
	 wire flag_move;			//if 1 move ball according to velocity
	 wire flag_point;			//if 1 callculate new point
	 
	 assign flag_collision = timecounter == 100_000;
	 assign flag_velocityset = timecounter == 150_000;
	 assign flag_move = timecounter == 200_000;
	 assign flag_point = timecounter == 300_000;

	 
	 always @ (posedge CLK)
	 begin
		if (animate)
			timecounter <= 0;		//reset timecounter at the start of each frame
		else
			timecounter <= timecounter +1;
		end
	 
	 //borders**********************************************************************************************
	 
	 // play area borders
	 integer max_x=640;  //maximum x value
	 integer max_y=480; //maximum y value
	 
	 integer top_edge_in = 10;
	 integer left_edge_in = 10;
	 integer left_edge_bottom = 370;
	 integer right_edge_in = 270;
	 integer right_edge_out = 280;
	 integer right_edge_bottom = 370;
	 
	 integer left_parallel_top = 369;
	 integer left_parallel_bottom = 431;
	 integer right_parallel_top = 369;
	 integer right_parallel_bottom = 431;
	 
	 wire border;
	 wire top_edge;
	 wire left_edge;
	 wire right_edge;
	 wire left_parallel;
	 wire right_parallel;
	 
	 //border display	 
	 assign top_edge = ((x > 0)&(x <= right_edge_out) & (y > 0)&(y < top_edge_in));
	 assign left_edge = ((x > 0)&(x < left_edge_in) & (y > 0)&(y < left_edge_bottom));
	 assign right_edge = ((x > right_edge_in)&(x <= right_edge_out) & (y > 0)&(y < right_edge_bottom));
	 assign left_parallel= ((y-x >= 361)&(y-x <= 370) & (y > left_parallel_top)&(y < left_parallel_bottom));
	 assign right_parallel= ((x+y >= 641)&(x+y <= 650) & (y > right_parallel_top)&(y < right_parallel_bottom));
	 
    assign border =
	 ((top_edge|left_edge|right_edge|left_parallel|right_parallel)&(x>0)&(x<640)&(y>0)&(y<480));	//boundary conditions

	 
	 //left flipper
	 wire flipper_left_vga;
	 integer counter_8_left;
	 reg trigger_left;
	 integer flipper_left_state;
	 initial 
	 begin
		counter_8_left <= 0;
		flipper_left_state <= 0;
	 end
	 always @(posedge CLK)
	 begin	
		if ((flipper_left==1'b0) || trigger_left == 1)
		begin
			trigger_left <=1;
			if (counter_8_left == 6_250_000)
			begin
				flipper_left_state <= flipper_left_state + 1;
				counter_8_left <=0;								
			end		
			else
				counter_8_left <= counter_8_left+1;		
		end
		if (flipper_left_state == 16)
		begin
			flipper_left_state <= 2'd0;
			trigger_left <= 1'b0;
		end
 
	 end
	 assign flipper_left_vga = ((((x-65)*(x-65))+((y-431)*(y-431)) < 3601)&
		 (((y-x >= 361)&(y-x <= 371) & (y >= 431) &((flipper_left_state == 0)|(flipper_left_state == 16))) |				//8-8
		 ((3*y-2*x >= 1153)&(y-x <= 371) & (y >= 431) & ((flipper_left_state == 1)|(flipper_left_state == 15))) |		//9-6
		 ((5*y-2*x >= 2015)&(3*y-2*x <= 1173) & (y >= 431) &((flipper_left_state == 2)|(flipper_left_state == 14))) |	//10-4
		 ((5*y-x >= 2085)&(5*y-2*x <= 2035) & (y >= 431) &((flipper_left_state == 3)|(flipper_left_state == 13))) |		//10-2
		 ((y >= 431) & (5*y-x <= 2095) &((flipper_left_state == 4)|(flipper_left_state == 12))) |								//10-0	 
		 ((5*y+x >= 2215) & (y <= 431) &((flipper_left_state == 5)|(flipper_left_state == 11))) |								//2-10
		 ((5*y+2*x >= 2275)&(5*y+x <= 2225) & (y <= 431) &((flipper_left_state == 6)|(flipper_left_state == 10))) |		//4-10
		 ((3*y+2*x >= 1413)&(5*y+2*x <= 2295) & (y <= 431) &((flipper_left_state == 7)|(flipper_left_state == 9))) |	//6-9
		 ((y+x >= 491)&(3*y+2*x <= 1433) & (y <= 431) &(flipper_left_state == 8))));												//8-8
	 
		 
	 
	 
	 //right flipper
	 wire flipper_right_vga;
	 integer counter_8_right;
	 reg trigger_right;
	 integer flipper_right_state;
	 initial 
	 begin
		counter_8_right <= 0;
		flipper_right_state <= 0;
	 end
	 always @(posedge CLK)
	 begin	
		if ((flipper_right==1'b0) || trigger_right == 1)
		begin
			trigger_right <=1;
			if (counter_8_right == 6_250_000)
			begin
				flipper_right_state <= flipper_right_state + 1;
				counter_8_right <=0;								
			end		
			else
				counter_8_right <= counter_8_right+1;		
		end
		if (flipper_right_state == 16)
		begin
			flipper_right_state <= 2'd0;
			trigger_right <= 1'b0;
		end
 
	 end
	 assign flipper_right_vga = ((((x-215)*(x-215))+((y-431)*(y-431)) < 3601)&
		 (((y+x >= 641)&(y+x <= 650) & (y >= 431) &((flipper_right_state == 0)|(flipper_right_state == 16))) |				//8-8
		 ((3*y+2*x >= 1713)&(y+x <= 650) & (y >= 431) & ((flipper_right_state == 1)|(flipper_right_state == 15))) |		//9-6
		 ((5*y+2*x >= 2575)&(3*y+2*x <= 1731) & (y >= 431) &((flipper_right_state == 2)|(flipper_right_state == 14))) |	//10-4
		 ((5*y+x >= 2365)&(5*y+2*x <= 2593) & (y >= 431) &((flipper_right_state == 3)|(flipper_right_state == 13))) |		//10-2
		 ((y >= 431) & (5*y+x <= 2374) &((flipper_right_state == 4)|(flipper_right_state == 12))) |								//10-0	 
		 ((5*y-x >= 1936) & (y <= 431) &((flipper_right_state == 5)|(flipper_right_state == 11))) |								//2-10
		 ((5*y-2*x >= 1717)&(5*y-x <= 1945) & (y <= 431) &((flipper_right_state == 6)|(flipper_right_state == 10))) |		//4-10
		 ((3*y-2*x >= 855)&(5*y-2*x <= 1735) & (y <= 431) &((flipper_right_state == 7)|(flipper_right_state == 9))) |	//6-9
		 ((y-x >= 212)&(3*y-2*x <= 873) & (y <= 431) &(flipper_right_state == 8))));												//8-8
	 
	 //ball
	 localparam ball_r=7;
	 integer ball_x;
	 integer ball_y;
	 integer ball_x_f;
	 integer ball_y_f; 
	 initial
	 begin
		 ball_x=20;
		 ball_y=370;
		 ball_x_f=2560;
		 ball_y_f=47360;
	 end
	 
	 wire [19:0] distance_ball;
	 assign distance_ball = (x-ball_x)*(x-ball_x)+(y-ball_y)*(y-ball_y);
	 wire ball;
	 assign ball = distance_ball < (ball_r*ball_r);
	 
	 
	 
	 localparam circular_r=12;  //circular radius
	 //circular 1
	 localparam circular1_x=96;
	 localparam circular1_y=180;
	 wire [19:0] distance_c1;
	 assign distance_c1 = (x-circular1_x)*(x-circular1_x)+(y-circular1_y)*(y-circular1_y);
	 wire circular1;
	 assign circular1 = distance_c1 < (circular_r*circular_r);
	 
	 
	 
	 //circular 2
	 localparam circular2_x=184;
	 localparam circular2_y=180;
	 wire [19:0] distance_c2;
	 assign distance_c2 = (x-circular2_x)*(x-circular2_x)+(y-circular2_y)*(y-circular2_y);
	 wire circular2;
	 assign circular2 = distance_c2 < (circular_r*circular_r);
	 
	 
	 localparam  penalty_r=10;  //penalty radius
	 //penalty 1
	 localparam penalty1_x=70;
	 localparam penalty1_y=120;
	 wire [19:0] distance_p1;
	 assign distance_p1 = (x-penalty1_x)*(x-penalty1_x)+(y-penalty1_y)*(y-penalty1_y);
	 wire penalty1;
	 assign penalty1 = distance_p1 < (penalty_r*penalty_r);
	 
	 //penalty 2
	 localparam penalty2_x=210;
	 localparam penalty2_y=120;
	 wire [19:0] distance_p2;
	 assign distance_p2 = (x-penalty2_x)*(x-penalty2_x)+(y-penalty2_y)*(y-penalty2_y);
	 wire penalty2;
	 assign penalty2 = distance_p2 < (penalty_r*penalty_r);
	 
	 integer hex_r = 20;
	 //hexagon 1	 
	 integer hex1_x = 85;
	 integer hex1_y = 280;
	 
	 assign hexagon1 = ((((x==66)|(x==105))&(y<282)&(y>279))|(((x==67)|(x==104))&(y<284)&(y>277))|
	 (((x==68)|(x==103))&(y<286)&(y>275))|(((x==69)|(x==102))&(y<288)&(y>273))|(((x==70)|(x==101))&(y<290)&(y>271))|
	 (((x==71)|(x==100))&(y<292)&(y>269))|(((x==72)|(x==99))&(y<294)&(y>267))|(((x==73)|(x==98))&(y<296)&(y>265))|
	 (((x==74)|(x==97))&(y<298)&(y>263))|(((x==75)|(x==96))&(y<300)&(y>261))|((x<96)&(x>75)&(y<302)&(y>259)));
	 
	 //hexagon 2
	 integer hex2_x = 215;
	 integer hex2_y = 280;
	 
	 assign hexagon2 = ((((x==234)|(x==195))&(y<282)&(y>279))|(((x==233)|(x==196))&(y<284)&(y>277))|
	 (((x==232)|(x==197))&(y<286)&(y>275))|(((x==231)|(x==198))&(y<288)&(y>273))|(((x==230)|(x==199))&(y<290)&(y>271))|
	 (((x==229)|(x==200))&(y<292)&(y>269))|(((x==228)|(x==201))&(y<294)&(y>267))|(((x==227)|(x==202))&(y<296)&(y>265))|
	 (((x==226)|(x==203))&(y<298)&(y>263))|(((x==225)|(x==204))&(y<300)&(y>261))|((x<225)&(x>204)&(y<302)&(y>259)));
	 
	 //plunger
	 
	 assign plunger = 
	 ((x >= 30)&(x < 33) & (y > 357)&(y < 393)) | 	//right
	 ((x > 0)&(x < 33) & (y >357)&(y <= 360)); 		//top
	 
	 //*******************************Collision Parameters**************************************************************************************	 
	 integer collision_state;				//set a state if there is a collision state 13 no collision
	 integer velocity_x_temp;
	 integer velocity_y_temp;
	 integer timer_left_parallel;			//timers for disable a collision to repeat
	 integer timer_right_parallel;			//after a collision happened to prevent repeat 
	 integer timer_left_flipper;
	 integer timer_right_flipper;
	 integer timer_c1;
	 integer timer_c2;
	 integer timer_p1;
	 integer timer_p2;
	 integer timer_h1;
	 integer timer_h2;
	 integer disable_collision_frames = 59; //disables collision for # of frames
	 
	 reg point_c;							//1 when a point change happened
	 reg point_p;
	 reg point_h;
		 
	 initial
	 begin
		 collision_state <= 13;
		 timer_left_parallel <= 0;
		 timer_right_parallel <= 0;
		 timer_left_flipper <= 0;
		 timer_right_flipper <= 0;
		 timer_c1 <= 0;
		 timer_c2 <= 0;
		 timer_p1 <= 0;
		 timer_p2 <= 0;
		 timer_h1 <= 0;
		 timer_h2 <= 0;
		 point_c <= 0;
		 point_p <= 0;
		 point_h <= 0;
	 end
	 
	 //*********************Movement Parameters***********************************************************************************
	 
	 
	 
	 integer velocity_x;
	 integer velocity_y;
	 integer counter_collision_frame;
	 
	 reg velocity_x_direction;
	 reg velocity_y_direction;
	 reg plunger_state;
	 
	 wire random_direction [2:0];
	 
	 	random_gen hexa1 (
	CLK,
	rst,
	random_direction0,
	random_direction1,
	random_direction2,
	random_directionx,
	random_directiony);
	
	assign random_direction[0] = random_direction0;
	assign random_direction[1] = random_direction1;
	assign random_direction[2] = random_direction2;
	
	 
	 
	 initial
	 begin										//velocity
		 velocity_x<=0;
		 velocity_y<=0;
		 velocity_x_direction <= 1;
		 velocity_y_direction <= 0;
		 counter_collision_frame <= 0;
		 plunger_state <= 1;
	 end
	
	 //***********Point Display Parameters ***************************************************************************
	 integer point;
	 integer point0;
	 integer point1;
	 integer point2;
	 integer point3;

	 
	 always @ (posedge CLK)
	 begin
	//reset*********************************************
	if(rst)
	begin
		 ball_x<=20;
		 ball_y<=370;
		 ball_x_f<=2560;
		 ball_y_f<=47360;
		 collision_state <= 13;
		 timer_left_parallel <= 0;
		 timer_right_parallel <= 0;
		 timer_left_flipper <= 0;
		 timer_right_flipper <= 0;
		 timer_c1 <= 0;
		 timer_c2 <= 0;
		 timer_p1 <= 0;
		 timer_p2 <= 0;
		 timer_h1 <= 0;
		 timer_h2 <= 0;
		 velocity_x<=0;
		 velocity_y<=0;
		 velocity_x_direction <= 1;
		 velocity_y_direction <= 0;
		 counter_collision_frame <= 0;
		 plunger_state <= 1;			//becomes 0 after game started
		 point0 <= 0;
		 point1 <= 0;
		 point2 <= 0;
		 point3 <= 0;
	end
	//*************************************************collision detection******************************
		if (flag_collision)
		begin
			if (ball_y <= 10+ball_r) //top edge
			begin
				collision_state <= 0;
			end
		 
			else if (ball_x <= 10 + ball_r ) //left edge
			begin
				collision_state <= 1;
			end
		 
			else if (ball_x >= 270 - ball_r) //right edge
			begin
				collision_state <= 2;
			end
		 
			else if ((ball_y - ball_x >= 356)&(ball_y<=430)&(ball_x>=10)&(ball_y>369)&(ball_x<80)&(timer_left_parallel==0)) //left parallel
			begin
				collision_state <= 3;
				timer_left_parallel <= disable_collision_frames;
			end
		 
			else if ((ball_x + ball_y >= 636)&(ball_y<=430)&(ball_y > 369)&(ball_x<=270)&(ball_x > 60)&(timer_right_parallel==0)) //right parallel
			begin
				collision_state <= 4;
				timer_right_parallel <= disable_collision_frames;
			end
		 
			else if (ball & flipper_left_vga) //left flipper
			begin
				collision_state <= 5;
				timer_right_parallel <= disable_collision_frames;
			end
		 
			else if (ball & flipper_right_vga ) //right flipper
			begin
				collision_state <= 6;
				timer_right_parallel <= disable_collision_frames;
			end
		 
			else if ((((ball_x-circular1_x)*(ball_x-circular1_x)+(ball_y-circular1_y)*(ball_y-circular1_y))<=(ball_r+circular_r)*(ball_r+circular_r))&(timer_c1==0)) //circular1
			begin
				collision_state <= 7;
				timer_c1 <= disable_collision_frames;
				point_c <= 1;
			end
		 
			else if ((((ball_x-circular2_x)*(ball_x-circular2_x)+(ball_y-circular2_y)*(ball_y-circular2_y))<=(ball_r+circular_r)*(ball_r+circular_r))&(timer_c2==0)) //circular2
			begin
				collision_state <= 8;
				timer_c2 <= disable_collision_frames;
				point_c <= 1;
			end
		 
			else if ((((ball_x-penalty1_x)*(ball_x-penalty1_x)+(ball_y-penalty1_y)*(ball_y-penalty1_y))<=(ball_r+penalty_r)*(ball_r+penalty_r))&(timer_p1==0)) //penalty1
			begin
				collision_state <= 9;
				timer_p1 <= disable_collision_frames;
				point_p <= 1;
			end
		 
			else if (((((ball_x-penalty2_x)*(ball_x-penalty2_x)+(ball_y-penalty2_y)*(ball_y-penalty2_y))<=(ball_r+penalty_r)*(ball_r+penalty_r)))&(timer_p2==0)) //penalty2
			begin
				collision_state <= 10;
				timer_p2 <= disable_collision_frames;
				point_p <= 1;
			end
		 
			else if (((((ball_x-hex1_x)*(ball_x-hex1_x)+(ball_y-hex1_y)*(ball_y-hex1_y))<=(ball_r+hex_r)*(ball_r+hex_r))&(timer_h1==0))|
						((((ball_x-hex2_x)*(ball_x-hex2_x)+(ball_y-hex2_y)*(ball_y-hex2_y))<=(ball_r+hex_r)*(ball_r+hex_r))&(timer_h2==0)))//hexagon1&2
			begin
				collision_state <= 11;
				timer_h1 <= disable_collision_frames;
				timer_h2 <= disable_collision_frames;
				point_h <= 1;
			end
		 
			else if (ball_y > 415) //bottom side
			begin
				collision_state <= 12;
				timer_h2 <= disable_collision_frames;
			end
			else
				collision_state <= 13;
	 //*************************************************collision timer******************************
	 
			if (timer_left_parallel > 0)
				timer_left_parallel <= timer_left_parallel -1;
				
			if (timer_right_parallel > 0)
				timer_right_parallel <= timer_right_parallel -1;
				
			if (timer_left_flipper > 0)
				timer_left_flipper <= timer_left_flipper -1;
				
			if (timer_right_flipper > 0)
				timer_right_flipper <= timer_right_flipper -1;
			
			if (timer_c1 > 0)
				timer_c1 <= timer_c1 -1;
			
			if (timer_c2 > 0)
				timer_c2 <= timer_c2 -1;
			
			if (timer_p1 > 0)
				timer_p1 <= timer_p1 -1;
			
			if (timer_p2 > 0)
				timer_p2 <= timer_p2 -1;
			
			if (timer_h1 > 0)
				timer_h1 <= timer_h1 -1;
			
			if (timer_h2 > 0)
				timer_h2 <= timer_h2 -1;
		end
		
		if ((plunger_BTN==0)&plunger_state)	//start game
		begin
		 velocity_x<=100;
		 velocity_y<=150;
		 plunger_state <= 0;
		end
		
		velocity_x_temp = velocity_x;
		velocity_y_temp = velocity_y;

//******************** Velocity Set **********************************************************
		
		if (flag_velocityset&(plunger_state == 0))
		begin
			case (collision_state)					// set velocity direction according to collision happened if 13(no collision) do nothing
				0:	velocity_y_direction <= 1;
				1:	velocity_x_direction <= 1;
				2:	velocity_x_direction <= 0;
				3: begin
					velocity_x <= 200;
					velocity_y <= 100;
					velocity_x_direction <= 1;
					velocity_x_direction <= 1;
				end
				4: begin
					velocity_x <= 200;
					velocity_y <= 100;
					velocity_x_direction <= 1;
					velocity_x_direction <= 1;						
				end
//				5:begin
//					case(flipper_left_state)
//						0:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						1:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						2:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						3:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						4:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						5:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						6:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						7:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						8:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						8:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						9:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						10:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						11:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						12:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						13:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						14:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						15:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//						16:begin
//							velocity_x_direction <= ;
//							velocity_y_direction <= ;
//							velocity_x;
//							velocity_y;
//						end
//				end
//				6:begin
//				
//				end
				7:begin
					velocity_x_direction <= ~velocity_x_direction;
					velocity_y_direction <= ~velocity_y_direction;
				end
				8:begin
					velocity_x_direction <= ~velocity_x_direction;
					velocity_y_direction <= ~velocity_y_direction;
				end
				9:begin
					velocity_x_direction <= ~velocity_x_direction;
					velocity_y_direction <= ~velocity_y_direction;
				end
				10:begin
					velocity_x_direction <= ~velocity_x_direction;
					velocity_y_direction <= ~velocity_y_direction;
				end
				11:begin
					velocity_x_direction <= random_directionx;
					velocity_y_direction <= random_directiony;
					case ({random_direction[0],random_direction[1],random_direction[2]})
						0:begin
							velocity_x <=120;
							velocity_y <=120;
						end
						1:begin
							velocity_x <=135;
							velocity_y <=90;
						end
						2:begin
							velocity_x <=150;
							velocity_y <=30;
						end
						3:begin
							velocity_x <=150;
							velocity_y <=15;
						end
						4:begin
							velocity_x <=150;
							velocity_y <=0;
						end
						5:begin
							velocity_x <=15;
							velocity_y <=150;
						end
						6:begin
							velocity_x <=30;
							velocity_y <=150;
						end
						7:begin
							velocity_x <=90;
							velocity_y <=135;
						end
					endcase
				end
				12: velocity_y_direction <= 0;
				//12: plunger_state <= 1;
			endcase
		end
		

//******************** Move ***************************************************
		if (flag_move&(plunger_state == 0))
		begin
			/*if (velocity_x < 30)
				velocity_x <= velocity_x +1;
			else if (velocity_x > 120)
				velocity_x <= velocity_x -1;*/
				
			if (velocity_x_direction)					//x location
				ball_x_f <= ball_x_f + velocity_x;
			else
				ball_x_f <= ball_x_f - velocity_x;
			
			if (velocity_y_direction)					//y location
			begin
				ball_y_f <= ball_y_f + velocity_y;
				if (velocity_y < 250)
					velocity_y <= velocity_y +1;		// change velocity of y according to gravity
			end
			else
			begin
				ball_y_f <= ball_y_f - velocity_y;
				if (velocity_y > 100)
					velocity_y <= velocity_y -1;		// change velocity of y according to gravity
			end
				
			ball_x <= ball_x_f[15:7];
			ball_y <= ball_y_f[15:7];							
		end		
	
	 
	 
	 

//******************** Point **************************************************
		if (flag_point)
		begin
			if (point_c)
			begin
				point <= point +2;
				point_c <= 0;
			end
			
			if (point_p)
			begin
//				if ((point > 3)&((point3>0)|(point2>0)|(point1>1)|((point1==1)&(point0==1))))
//				begin
					point <= point - 3;
					point_p <= 0;
//				end
//				else
//				begin
//					point <= 0;
//					point_p <= 0;
//				end
			end
				
			if (point_h)
			begin
				point <= point + 4;
				point_h <= 0;
			end
				
			if (point > 0)
			begin
				point <= point -1;
				if ((point0 == 1 )&(point1 == 9)&(point2	== 9))
				begin
					point0 <= 0;
					point1 <= 0;
					point2 <= 0;
					point3 <= point3 + 1;
				end
				
				else if ((point0 == 1 )&(point1 == 9))
				begin
					point0 <= 0;
					point1 <= 0;
					point2 <= point2 + 1;
				end
				else if ((point0 == 1 ))
				begin
					point0 <= 0;
					point1 <= point1 + 1;
				end
				else
					point0 <= point0 + 1;
			end
			
			if (point < 0)
			begin
				point <= point + 1;
//				if (~(point0|point1|point2|point3))
//				begin
//					point0 <= 0;
//					point1 <= 0;
//					point2 <= 0;
//					point3 <= 0;
//				end
//				else 
				if ((point0 == 0 )&(point1 == 0)&(point2	== 0))
				begin
					point0 <= 1;
					point1 <= 9;
					point2 <= 9;
					point3 <= point3 - 1;
				end
				
				else if ((point0 == 0 )&(point1 == 0))
				begin
					point0 <= 1;
					point1 <= 9;
					point2 <= point2 - 1;
				end
				else if (point0 == 0 )
				begin
					point0 <= 1;
					point1 <= point1 - 1;
				end
				else
					point0 <= point0 - 1;
			end
		end
	 end
	   
	 //VGA***********************************************************************************
	 
    assign VGA_R = {8{((border)|circular1|circular2|flipper_left_vga|flipper_right_vga|ball|(t3&(timer_c1>0))|(t2&(timer_c2>0))|(t1&(timer_h1>0))|(t0&(timer_h2>0))|p3|p2|(p1&(timer_p1>0))|(p0&(timer_p2>0)))}};	//red areas
    assign VGA_G = {8{((border)|penalty1|penalty2|ball|plunger|t3|t2|t1|t0|p3|p2|p1|p0)}};													//green areas
    assign VGA_B = {8{((border)|hexagon1|hexagon2|plunger|t3|t2|t1|t0|p3|p2|p1|p0)}};  																				//blue areas
endmodule
