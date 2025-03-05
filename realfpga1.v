module fpga1(    
    input clk,
    input rst,
    input wire echo0,
	input wire echo1,
    //input wire mode, 
    output wire trig0,
	output wire trig1,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
	output [15:0] led 
);
    
        wire [19:0] distance0, distance1;
        reg [3:0] BCD0, BCD1, BCD2, BCD3;
        wire clk_13;

        div clk1 (clk ,clk_13);

        LED7SEG led7seg_00 (.led(led), .clk(clk), .distance1(distance1), .distance0(distance0));

		sonic_top A(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo0), 
        .Trig(trig0),
        .distance(distance0)
        );
		
        sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo1), 
        .Trig(trig1),
        .distance(distance1)
        );

        always @(posedge clk or posedge rst)begin
            if (rst) begin
                BCD0 <= 0;
                BCD1 <= 0;
                BCD2 <= 0;
                BCD3 <= 0;
            end
            else begin
                BCD0 <= distance1 % 10;
                BCD1 <= (distance1 / 10) % 10;
                BCD2 <= (distance1 / 100) % 10;
                BCD3 <= 0;
                //end
            end
        end
        SevenSegment sg00(.clk(clk), .rst(rst), .nums({BCD3, BCD2, BCD1, BCD0}), .display(DISPLAY), .digit(DIGIT));
		//if distance > k, then output


endmodule

module LED7SEG (output reg [15:0] led, input clk, input [19:0] distance1, input [19:0] distance0);
always@(posedge clk)begin
    if(distance0 > 20'd10 && distance1 > 20'd10)begin
        led <= 16'b1111_1111_1111_1111;
    end else if(distance0 > 20'd10 && distance1 <= 20'd10) begin
        led <= 16'b1111_1111_0000_0000;
    end else if(distance0 <= 20'd10 && distance1 > 20'd10) begin
        led <= 16'b0000_0000_1111_1111;
    end else begin
        led <= 16'b0000000000000000;
    end
end

/*reg [3:0] value;

	always @(posedge clk) begin	
		case(DIGIT) 
			4'b0111: begin
			    value = BCD2; //百位數
				DIGIT <= 4'b1011;
			end
			4'b1011: begin
			    value = BCD1; //十位數
				DIGIT <= 4'b1101;
			end
			4'b1101: begin
				value = BCD0; //個位數
				DIGIT <= 4'b1110;
			end
			4'b1110: begin
				value = BCD3;
				DIGIT <= 4'b0111;
			end
			default begin
				DIGIT <= 4'b1110;
			end
		endcase	
	end

	assign DISPLAY  =   (value == 4'd0) ? 7'b100_0000:
					    (value == 4'd1) ? 7'b111_1001 :
						(value == 4'd2) ? 7'b010_0100 :
						(value == 4'd3) ? 7'b011_0000 :
						(value == 4'd4) ? 7'b001_1001 :
						(value == 4'd5) ? 7'b001_0010 :
						(value == 4'd6) ? 7'b000_0010 :
						(value == 4'd7) ? 7'b111_1000:
						(value == 4'd8) ? 7'b000_0000: 
						(value == 4'd9) ? 7'b001_0000:
						(value == 4'd10) ? 7'b1111110 :    // j
						(value == 4'd11) ? 7'b1100011 :    // u
						(value == 4'd12) ? 7'b0111011 :    // i
						(value == 4'd13) ? 7'b1110010 :    // c
						(value == 4'd14) ? 7'b0111000 :    // f
						(value == 4'd15) ? 7'b1111111 :    // e
                 						   7'b1111111;*/
endmodule

module sonic_top (input clk, input rst, input Echo, output Trig, output [19:0] distance);

	wire [19:0] dis;
    wire clk1M;
	wire clk_2_17;

    assign distance = dis;

    div clk1 (clk ,clk1M);
	TrigSignal u1 (.clk(clk), .rst(rst), .trig(Trig));
	PosCounter u2 (.clk(clk1M), .rst(rst), .echo(Echo), .distance_count(dis));
 
endmodule

// send trigger signal to sensor
module TrigSignal(input clk, input rst, output reg trig);

    reg next_trig;
    reg [23:0] count, next_count;
    parameter us_10 = 1000 - 1;
    parameter ms_100 = 10000000 - 1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            trig <= 0;
        end
        else begin
            count <= next_count;
            trig <= next_trig;
        end
    end
    
    // count 10us to set <trig> high and wait for 100ms, then set <trig> back to low
    // TODO: set <next_trig> and <next_count> to let the sensor work properly
    always @(*) begin
        if (count == ms_100) begin
            next_trig = 0;
            next_count = 0;
        end
        else if (count == us_10) begin
            next_trig = 1;
            next_count = count + 1; //數
        end
        else begin
            next_trig = trig;
            next_count = count + 1;
        end
        
    end
endmodule

// clock divider for T = 1us clock
module div(input clk, output reg out_clk);

    reg [6:0] cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 0;
            out_clk <= 1'b1;
        end
    end
endmodule

module PosCounter (input clk, input rst, input echo, output wire [19:0] distance_count);

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg [1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg [19:0] count, distance_register;

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register  <= 0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            case(curr_state)
                S0:begin
                    if (start) curr_state <= next_state; // S1
                    else count <= 0;
                end
                S1:begin
                    if (finish) curr_state <= next_state; // S2
                    else count <= count + 1;
                end
                S2:begin
                    distance_register <= count;
                    count <= 0;
                    curr_state <= next_state; // S0
                end
            endcase
        end
    end
    
    always @(*) begin
        case(curr_state)
            S0: next_state = S1;
            S1: next_state = S2;
            S2: next_state = S0;
            default: next_state = S0;
        endcase
    end

    assign start = echo_reg1 & ~echo_reg2;  
    assign finish = ~echo_reg1 & echo_reg2;
    
    // TODO: trace the code and calculate the distance, output it to <distance_count>
    assign distance_count = (distance_register / 2) * 340 / 10000;
    
endmodule

//revised
module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire[15:0] nums, //5, 5, 5, 5
	input wire rst,
	input wire clk
    );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= nums[11:8]; 
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12]; 
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0]; 
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= 4'd10; 
						digit <= 4'b1110;
					end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001                                                
			2 : display = 7'b0100100;   //0010                                                
			3 : display = 7'b0110000;   //0011                                             
			4 : display = 7'b0011001;   //0100                                               
			5 : display = 7'b0010010;   //0101                                               
			6 : display = 7'b0000010;   //0110
			7 : display = 7'b1111000;   //0111
			8 : display = 7'b0000000;   //1000
			9 : display = 7'b0010000;	//1001
			10: display = 7'b011_1111;//DASH
			default : display = 7'b1111111; //should not happen
    	endcase
    end
    
endmodule

