//fpga 2 controls the motor and the speaker
// candy selection,  7segment display to show the candy selected, and play the corresponding music
//curcandy = 0: 天龍, 1: 博客來
//馬達: 天龍: IA, IB; 博客來: IIA, IIB

`define llc   ((32'd262 >> 1) >> 1)   // C2
`define llcP   ((32'd277 >> 1) >> 1)  // C2#
`define lld   ((32'd294 >> 1) >> 1)   // D2
`define lleM   ((32'd311 >> 1) >> 1)   // E2b
`define lle   ((32'd330 >> 1) >> 1)   // E2
`define llf   ((32'd349 >> 1) >> 1)   // F2
`define llfP   ((32'd370 >> 1) >> 1)   // F2#
`define llg   ((32'd392 >> 1) >> 1)   // G2
`define llgP   ((32'd415 >> 1) >> 1)   // G2#
`define lla   ((32'd440 >> 1) >> 1)   // A2
`define llbM   ((32'd466 >> 1) >> 1)   // B2b
`define llb   ((32'd494 >> 1) >> 1)   // B2

`define lc   (32'd262 >> 1)   // C3
`define lcP   (32'd277 >> 1)  // C3#
`define ld   (32'd294 >> 1)   // D3
`define leM   (32'd311 >> 1)   // E3b
`define le   (32'd330 >> 1)   // E3
`define lf   (32'd349 >> 1)   // F3
`define lfP   (32'd370 >> 1)   // F3#
`define lg   (32'd392 >> 1)   // G3
`define lgP   (32'd415 >> 1)   // G3#
`define la   (32'd440 >> 1)   // A3
`define lbM   (32'd466 >> 1)   // B3b
`define lb   (32'd494 >> 1)   // B3

`define c   32'd262   // C4
`define cP   32'd277   // C4#
`define d   32'd294   // D4
`define eM   32'd311   // E4b
`define e   32'd330   // E4
`define f   32'd349   // F4
`define fP   32'd370   // F4#
`define g   32'd392   // G4
`define gP   32'd415   // G4#
`define a   32'd440   // A4
`define bM   32'd466   // B4b
`define b   32'd494   // B4

`define hc   32'd524   // C5
`define hcP   32'd554   // C5#
`define hd   32'd588   // D5
`define heM   32'd622   // E5b
`define he   32'd660   // E5
`define hf   32'd698   // F5
`define hfP   32'd740   // F5#
`define hg   32'd784   // G5
`define hgP   32'd830   // G5#
`define ha   32'd880   // A5
`define hbM   32'd932   // B5b
`define hb   32'd988   // B5

`define hhc   32'd1048  // C6
`define hhcP   32'd1108   // C6#
`define hhd   32'd1176   // D6
`define hheM   32'd1244   // E6b
`define hhe   32'd1320   // E6
`define hhf   32'd1396   // F6
`define hhfP   32'd1480   // F6#
`define hhg   32'd1568   // G6
`define hhgP   32'd1660   // G6#
`define hha   32'd1760   // A6
`define hhbM   32'd1864   // B6b
`define hhb   32'd1976   // B6

`define sil   32'd50000000 // slience

module fpga2(
    input clk,
    input rst,     //BTNC: rst
    input volUP,     // BTNU: Vol up
    input volDOWN,   // BTND: Vol down
    input candy,  //SW0: select candy
    input increase, //BTNR: increase the number of candy
    input decrease, //BTNL: decrease the number of candy
    input open, //SW1, Start the candy gate; 
    input mute,       //SW15
    input play,      //SW14
    input mode, // SW2: 0 for counting mode, 1 for free mode
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck,  // serial clock
    output audio_sdin, // serial audio data input
    output reg IA, //For motor A control
    output reg IB,  //For motor A control
    output reg IIA, //For motor B control
    output reg IIB, //For motor B control
    output wire [3:0] DIGIT, //The corresponding digit to the candy selected; 
    output wire [6:0] DISPLAY //The corresponding candy selected
); 
//變數宣告
wire curcandy;
reg [3:0] curcandy_num, next_candy_num; //糖果編號
wire volUP_db, volUP_pulse, volDOWN_db, volDOWN_pulse, increase_db, increase_pulse, decrease_db, decrease_pulse, rst_db, rst_pulse;

//button module引用
debounce(.clk(clk), .pb(volUP), .pb_debounced(volUP_db));
one_pulse(.clk(clk), .pb_in(volUP_db), .pb_out(volUP_pulse));
debounce(.clk(clk), .pb(volDOWN), .pb_debounced(volDOWN_db));
one_pulse(.clk(clk), .pb_in(volDOWN_db), .pb_out(volDOWN_pulse));
debounce(.clk(clk), .pb(increase), .pb_debounced(increase_db));
one_pulse(.clk(clk), .pb_in(increase_db), .pb_out(increase_pulse));
debounce(.clk(clk), .pb(decrease), .pb_debounced(decrease_db));
one_pulse(.clk(clk), .pb_in(decrease_db), .pb_out(decrease_pulse));
debounce(.clk(clk), .pb(rst), .pb_debounced(rst_db));
one_pulse(.clk(clk), .pb_in(rst_db), .pb_out(rst_pulse));

music_top(.clk(clk), .rst(rst_pulse), ._candy(curcandy), ._play(play), ._mute(mute), ._volUP(volUP_pulse), ._volDOWN(volDOWN_pulse),
 .audio_mclk(audio_mclk), .audio_lrck(audio_lrck), .audio_sck(audio_sck), .audio_sdin(audio_sdin));
//選糖果OK
assign curcandy = candy; //SW0: select candy

//算糖果數目, ok
always@(posedge clk or posedge rst) begin
    if(rst) begin
        curcandy_num  <= 4'd0; 
    end else begin
        curcandy_num <= next_candy_num;
    end
end
always@(*) begin
    if(increase_pulse && !decrease_pulse) begin
        if(curcandy_num == 4'd9)
            next_candy_num = curcandy_num;
        else 
            next_candy_num = curcandy_num + 1'b1;
    end
    else if(!increase_pulse && decrease_pulse) begin
        if(curcandy_num == 4'd0)
            next_candy_num = curcandy_num;
        else 
            next_candy_num = curcandy_num - 1'b1;
    end else begin
        next_candy_num = curcandy_num;
    end
end

reg [31:0] count, next_count;
wire [31:0] counter;
reg [3:0] sec = 4'd0, next_sec = 4'd0;

assign counter = (curcandy == 0) ? 32'd8500_0000 : 32'd6900_0000;

always@(posedge clk or posedge rst_pulse) begin
    if(rst_pulse) begin
        count <= 32'b0; 
        sec <= 4'd0; 
    end else begin
        count <= next_count;
        sec <= next_sec; 
    end
end
always@(*) begin
    if(open) begin
        if(count == counter) begin
            next_count = 32'd0;
            next_sec = sec + 4'd1; 
        end else begin
            if(sec <= curcandy_num) begin
                next_count = count + 32'd1;
                next_sec = sec; 
            end else begin
                next_count = count;
                next_sec = sec;
            end 
        end
    end else begin
        next_count = 32'd0;  
        next_sec = 4'd0;
    end
end

/*always@(posedge clk or posedge rst_pulse) begin
    if(rst_pulse) begin
        sec  <= 4'd0; 
    end else begin
        sec <= next_sec;
    end
end
always@(*) begin
    if(open) begin    
        if(sec < curcandy_num) begin
            if(count == counter) begin
                if(sec == 4'd9) begin
                    next_sec = 4'd0;
                end else begin
                    next_sec = sec + 4'd1;
                end
            end else begin
                next_sec = sec;
            end
        end else begin
            next_sec = 4'd0;
        end
    end else begin
        next_sec = 4'd0;  
    end
end*/

//control the motor by the number of candy
//one second for one candy.

reg next_IA, next_IB; 
reg next_IIA, next_IIB; 

always@(posedge clk or posedge rst_pulse) begin
    if(rst_pulse) begin
        IA  <= 1'b0; 
        IB  <= 1'b0; 
    end else begin
        IA <= next_IA;
        IB <= next_IB;
    end
end

always@(*) begin
    if(open) begin
        if(sec < curcandy_num && curcandy == 0) begin
            next_IA = 1'b1;
            next_IB = 1'b0;
        end else begin
            next_IA = 1'b0;
            next_IB = 1'b0;
        end
    end else begin
        next_IA = 1'b0;
        next_IB = 1'b0;
    end
end

always@(posedge clk or posedge rst_pulse) begin
    if(rst_pulse) begin
        IIA  <= 1'b0; 
        IIB  <= 1'b0; 
    end else begin
        IIA <= next_IIA;
        IIB <= next_IIB;
    end
end

always@(*) begin
    if(open) begin
        if(sec < curcandy_num && curcandy == 1) begin
            next_IIA = 1'b1;
            next_IIB = 1'b0;
        end else begin
            next_IIA = 1'b0;
            next_IIB = 1'b0;
        end
    end else begin
        next_IIA = 1'b0;
        next_IIB = 1'b0;
    end
end


//七段顯示器
SevenSegment sg0(.clk(clk), .rst(rst_pulse), .nums({{3'd0, curcandy}, 4'd0, 4'd0, curcandy_num}), .display(DISPLAY), .digit(DIGIT));
endmodule


//seven segment module
module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums, //4, 4, 4, 4
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
    					display_num <= 4'd10;
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= 4'd10; 
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
			10: display = 7'b011_1111;  //DASH
			default : display = 7'b1111111; //should not happen
    	endcase
    end
    
endmodule

//button module
module debounce (
	input wire clk,
	input wire pb, 
	output wire pb_debounced 
);
	reg [3:0] shift_reg; 

	always @(posedge clk) begin
		shift_reg[3:1] <= shift_reg[2:0];
		shift_reg[0] <= pb;
	end

	assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);

endmodule

module one_pulse (
    input wire clk,
    input wire pb_in,
    output reg pb_out
);

	reg pb_in_delay;
	always @(posedge clk) begin
		if (pb_in == 1'b1 && pb_in_delay == 1'b0) begin
			pb_out <= 1'b1;
		end else begin
			pb_out <= 1'b0;
		end
	end
	
	always @(posedge clk) begin
		pb_in_delay <= pb_in;
	end
endmodule





module music_control (
	input clk, 
	input reset, 
	input _play, //SW0: Play/Pause at demo mode
	output reg [11:0] ibeat
);
	parameter LEN = 4095; // 511 beats in a song, and the last beat is a rest
    reg [11:0] next_ibeat;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 0;
		end else begin
            ibeat <= next_ibeat;
		end
	end

    always @(*) begin
        if(_play) begin
            next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : 0;
        end else begin
            next_ibeat = 0;
        end
    end

endmodule


//Corresponding to the Buzzer control in teacher's PPT. 
module note_gen(
    input clk, // clock from crystal
    input rst, // active high reset
    input [3:0] volume, 
    input [21:0] note_div_left, // div for note generation
    input [21:0] note_div_right,
    output reg [15:0] audio_left,
    output reg [15:0] audio_right
    );

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @(*)
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cn)t_next_2, c_clk_next
    always @(*)
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    //b_clk = 0 -> negative amplitude, b_clk = 1 -> positive amplitude
    always@(*) begin
        if(note_div_left == 22'd1) begin
            audio_left = 16'h0000;
        end else begin
            if(b_clk == 1'b0) begin
                case(volume)
                    0: audio_left = 16'h0000;
                    1: audio_left = 16'hFFC0;
                    2: audio_left = 16'hFF00;
                    3: audio_left = 16'hFC00;
                    4: audio_left = 16'hF000;
                    5: audio_left = 16'hC000;
                    default: audio_left = 16'h0000;
                endcase
            end else begin
                case(volume)
                    0: audio_left = 16'h0000;
                    1: audio_left = 16'h0040;
                    2: audio_left = 16'h0100;
                    3: audio_left = 16'h0400;
                    4: audio_left = 16'h1000;
                    5: audio_left = 16'h4000;
                    default: audio_left = 16'h0000;
                endcase
            end
        end
    end

    always@(*) begin
        if(note_div_right == 22'd1) begin
            audio_right = 16'h0000;
        end else begin
            if(c_clk == 1'b0) begin
                case(volume)
                    0: audio_right = 16'h0000;
                    1: audio_right = 16'hFFC0;
                    2: audio_right = 16'hFF00;
                    3: audio_right = 16'hFC00;
                    4: audio_right = 16'hF000;
                    5: audio_right = 16'hC000;
                    default: audio_right = 16'h0000;
                endcase
            end else begin
                case(volume)
                    0: audio_right = 16'h0000;
                    1: audio_right = 16'h0040;
                    2: audio_right = 16'h0100;
                    3: audio_right = 16'h0400;
                    4: audio_right = 16'h1000;
                    5: audio_right = 16'h4000;
                    default: audio_right = 16'h0000;
                endcase
            end
        end
    end
    
endmodule


module clock_divider #(parameter n = 270) (
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule


module onepulse(
    input signal, 
    input clk, 
    output reg op
    );
    
    reg delay;
    
    always @(posedge clk) begin
        if((signal == 1) & (delay == 0)) op <= 1;
        else op <= 0; 
        delay <= signal;
    end
endmodule


module music_top(
    input clk,
    input rst,        // BTNC: active high reset
    input _play,      // SW0: Play/Pause
    input _mute,      // SW14: Mute
    input _candy,      // SW15: Candy
    input _volUP,     // BTNU: Vol up
    input _volDOWN,   // BTND: Vol down
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck,  // serial clock
    output audio_sdin // serial audio data input
    //output [6:0] DISPLAY,    
    //output [3:0] DIGIT
    );        

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR, freqL0, freqR0, freqL1, freqR1;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    //button internal signals
    /*wire rst_pulse, rst_db;
    wire volup_pulse, volup_db; 
    wire voldown_pulse, voldown_db;*/

    //volume control signals
    wire [3:0] volume;
    reg [3:0] cur_vol, next_vol;


    //button control
    /*debounce rst_debounce(.clk(clk), .pb(rst), .pb_debounced(rst_db));
    debounce volup_debounce(.clk(clk), .pb(_volUP), .pb_debounced(volup_db));
    debounce voldown_debounce(.clk(clk), .pb(_volDOWN), .pb_debounced(voldown_db));

    onepulse rst_onepulse(.clk(clk), .signal(rst_db), .op(rst_pulse));
    onepulse volup_onepulse(.clk(clk), .signal(volup_db), .op(volup_pulse));
    onepulse voldown_onepulse(.clk(clk), .signal(voldown_db), .op(voldown_pulse));*/


    // clkDiv22
    wire clkDiv22;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for audio

    // demo Control in demo mode and helper control in helper mode
    // [in]  reset, clock, _play, _music, and _mode
    // [out] beat number
    music_control #(.LEN(512)) demoCtrl_00 ( 
        .clk(clkDiv22),
        .reset(rst),
        ._play(_play), 
        .ibeat(ibeatNum)
    );



    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    wire music_en; 
    assign music_en = (_play ? 1 : 0); //helper mode or piano mode
    music_example0 music_00 (
        .ibeatNum(ibeatNum),
        .en(music_en),
        .toneL(freqL0),
        .toneR(freqR0)
    );
    music_example1 music_01 (
        .ibeatNum(ibeatNum),
        .en(music_en),
        .toneL(freqL1),
        .toneR(freqR1)
    );

    // freq_outL, freq_outR
    //Keyboard makes sound when _mode = 0
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freqL = (_candy) ? freqL1 : freqL0; 
    assign freqR = (_candy) ? freqR1 : freqR0;
    assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;


    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        //input
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        //output -> speaker_control
        .audio_left(audio_in_left),     // left sound audio, amplitude
        .audio_right(audio_in_right)    // right sound audio, amplitude
    );

    // Speaker controller, outputs are audio_mclk, audio_lrck, audio_sck, and audio_sdin,
    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        //outputs are connected to the pmod I2S2 audio codec
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );

    //Assign the volume  
    assign volume = (_mute) ? 4'd0 : cur_vol; //mute or not
    //Add volume control
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            cur_vol <= 4'd3;
        end else begin
            cur_vol <= next_vol;
        end
    end
    always@(*) begin
            if(_volUP && !_volDOWN) begin
                if(cur_vol == 4'd5)
                    next_vol = cur_vol;
                else 
                    next_vol = cur_vol + 1'b1;
            end
            else if(!_volUP && _volDOWN) begin
                if(cur_vol == 4'd0)
                    next_vol = cur_vol;
                else 
                    next_vol = cur_vol - 1'b1;
            end else begin
                next_vol = cur_vol;
            end
    end

endmodule
//music_example: 0 for the first candy while 1 for the second candy
module music_example0 (
	input [11:0] ibeatNum,
	input en,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @(*) begin
        if(en == 1) begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `hfP;      12'd1: toneR = `hfP; 
                12'd2: toneR = `hfP;      12'd3: toneR = `hfP;
                12'd4: toneR = `hfP;      12'd5: toneR = `hfP;
                12'd6: toneR = `hfP;      12'd7: toneR = `hfP;
                12'd8: toneR = `hfP;      12'd9: toneR = `hfP; 
                12'd10: toneR = `hfP;     12'd11: toneR = `hfP;
                12'd12: toneR = `hfP;     12'd13: toneR = `hfP;
                12'd14: toneR = `hfP;     12'd15: toneR = `hfP; 
                12'd16: toneR = `hfP;     12'd17: toneR = `hfP;
                12'd18: toneR = `hfP;     12'd19: toneR = `hfP;
                12'd20: toneR = `hfP;     12'd21: toneR = `hfP;
                12'd22: toneR = `hfP;     12'd23: toneR = `sil;
                
                12'd24: toneR = `hd;     12'd25: toneR = `hd;
                12'd26: toneR = `hd;     12'd27: toneR = `hd;
                12'd28: toneR = `hd;     12'd29: toneR = `hd;
                12'd30: toneR = `hd;     12'd31: toneR = `hd;

                12'd32: toneR = `hd;     12'd33: toneR = `hd; 
                12'd34: toneR = `hd;     12'd35: toneR = `hd;
                12'd36: toneR = `hd;     12'd37: toneR = `hd;
                12'd38: toneR = `hd;     12'd39: toneR = `hd;
                12'd40: toneR = `hd;     12'd41: toneR = `hd; // HD (half-beat)
                12'd42: toneR = `hd;     12'd43: toneR = `hd;
                12'd44: toneR = `hd;     12'd45: toneR = `hd;
                12'd46: toneR = `hd;     12'd47: toneR = `hd; 
                
                12'd48: toneR = `sil;     12'd49: toneR = `sil; // HD (one-beat)
                12'd50: toneR = `sil;     12'd51: toneR = `sil;
                12'd52: toneR = `sil;     12'd53: toneR = `sil;
                12'd54: toneR = `sil;     12'd55: toneR = `sil;
                
                12'd56: toneR = `hd;     12'd57: toneR = `hd;
                12'd58: toneR = `hd;     12'd59: toneR = `hd;
                
                12'd60: toneR = `he;     12'd61: toneR = `he;
                12'd62: toneR = `he;     12'd63: toneR = `he;

                // --- Measure 2 ---
                12'd64: toneR = `hf;     12'd65: toneR = `hf; 
                12'd66: toneR = `hf;     12'd67: toneR = `hf;
                12'd68: toneR = `hf;     12'd69: toneR = `hf;
                12'd70: toneR = `hf;     12'd71: toneR = `hf;
                12'd72: toneR = `hf;     12'd73: toneR = `hf; 
                12'd74: toneR = `hf;     12'd75: toneR = `hf;
                
                12'd76: toneR = `he;     12'd77: toneR = `he;
                12'd78: toneR = `he;     12'd79: toneR = `he;
                
                12'd80: toneR = `he;     12'd81: toneR = `he; 
                12'd82: toneR = `he;     12'd83: toneR = `he;
                12'd84: toneR = `he;     12'd85: toneR = `he;
                12'd86: toneR = `he;     12'd87: toneR = `he;
                
                12'd88: toneR = `hd;     12'd89: toneR = `hd; 
                12'd90: toneR = `hd;     12'd91: toneR = `hd;
                12'd92: toneR = `hd;     12'd93: toneR = `hd;
                12'd94: toneR = `hd;     12'd95: toneR = `hd;

                12'd96: toneR = `hcP;     12'd97: toneR = `hcP; // HG (half-beat)
                12'd98: toneR = `hcP;     12'd99: toneR = `hcP;
                12'd100: toneR = `hcP;    12'd101: toneR = `hcP;
                12'd102: toneR = `hcP;    12'd103: toneR = `hcP; // (Short break for repetitive notes: high D)
                12'd104: toneR = `hcP;    12'd105: toneR = `hcP; // HG (half-beat)
                12'd106: toneR = `hcP;    12'd107: toneR = `hcP;
                
                12'd108: toneR = `hd;    12'd109: toneR = `hd;
                12'd110: toneR = `hd;    12'd111: toneR = `hd; // (Short break for repetitive notes: high D)

                12'd112: toneR = `hd;    12'd113: toneR = `hd; // HG (one-beat)
                12'd114: toneR = `hd;    12'd115: toneR = `hd;
                12'd116: toneR = `hd;    12'd117: toneR = `hd;
                12'd118: toneR = `hd;    12'd119: toneR = `hd;
                
                12'd120: toneR = `he;    12'd121: toneR = `he;
                12'd122: toneR = `he;    12'd123: toneR = `he;
                12'd124: toneR = `he;    12'd125: toneR = `he;
                12'd126: toneR = `he;    12'd127: toneR = `he;
                
                // --- Measure 3 ---
                12'd128: toneR = `hfP;     12'd129: toneR = `hfP; // HC (half-beat)
                12'd130: toneR = `hfP;     12'd131: toneR = `hfP;
                12'd132: toneR = `hfP;     12'd133: toneR = `hfP;
                12'd134: toneR = `hfP;     12'd135: toneR = `hfP;
                12'd136: toneR = `hfP;     12'd137: toneR = `hfP; // HD (half-beat)
                12'd138: toneR = `hfP;     12'd139: toneR = `hfP;
                12'd140: toneR = `hfP;     12'd141: toneR = `hfP;
                12'd142: toneR = `hfP;     12'd143: toneR = `sil;

                12'd144: toneR = `hfP;     12'd145: toneR = `hfP; // HE (half-beat)
                12'd146: toneR = `hfP;     12'd147: toneR = `hfP;
                12'd148: toneR = `hfP;     12'd149: toneR = `hfP;
                12'd150: toneR = `hfP;     12'd151: toneR = `hfP;
                
                12'd152: toneR = `hb;     12'd153: toneR = `hb; // HF (half-beat)
                12'd154: toneR = `hb;     12'd155: toneR = `hb;
                12'd156: toneR = `hb;     12'd157: toneR = `hb;
                12'd158: toneR = `hb;     12'd159: toneR = `hb;

                12'd160: toneR = `hb;    12'd161: toneR = `hb; // HG (half-beat)
                12'd162: toneR = `hb;    12'd163: toneR = `hb;
                12'd164: toneR = `hb;    12'd165: toneR = `hb;
                12'd166: toneR = `hb;    12'd167: toneR = `hb; // (Short break for repetitive notes: high D)
                12'd168: toneR = `hb;    12'd169: toneR = `hb; // HG (half-beat)
                12'd170: toneR = `hb;    12'd171: toneR = `hb;
                12'd172: toneR = `hb;    12'd173: toneR = `hb;
                12'd174: toneR = `hb;    12'd175: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd176: toneR = `b;    12'd177: toneR = `b; // HG (one-beat)
                12'd178: toneR = `b;    12'd179: toneR = `b;
                12'd180: toneR = `b;    12'd181: toneR = `b;
                12'd182: toneR = `b;    12'd183: toneR = `b;
                
                12'd184: toneR = `hcP;    12'd185: toneR = `hcP;
                12'd186: toneR = `hcP;    12'd187: toneR = `hcP;
                12'd188: toneR = `hcP;    12'd189: toneR = `hcP;
                12'd190: toneR = `hcP;    12'd191: toneR = `hcP;
                
                // --- Measure 4 ---
                12'd192: toneR = `hd;     12'd193: toneR = `hd; // HC (half-beat)
                12'd194: toneR = `hd;     12'd195: toneR = `hd;
                12'd196: toneR = `hd;     12'd197: toneR = `hd;
                12'd198: toneR = `hd;     12'd199: toneR = `hd;
                12'd200: toneR = `hd;     12'd201: toneR = `hd; // HD (half-beat)
                12'd202: toneR = `hd;     12'd203: toneR = `hd;
                
                12'd204: toneR = `he;     12'd205: toneR = `he;
                12'd206: toneR = `he;     12'd207: toneR = `he;

                12'd208: toneR = `he;     12'd209: toneR = `he; // HE (half-beat)
                12'd210: toneR = `he;     12'd211: toneR = `he;
                12'd212: toneR = `he;     12'd213: toneR = `he;
                12'd214: toneR = `he;     12'd215: toneR = `he;
                
                12'd216: toneR = `hd;     12'd217: toneR = `hd; // HF (half-beat)
                12'd218: toneR = `hd;     12'd219: toneR = `hd;
                12'd220: toneR = `hd;     12'd221: toneR = `hd;
                12'd222: toneR = `hd;     12'd223: toneR = `hd;

                12'd224: toneR = `hcP;    12'd225: toneR = `hcP; // HG (half-beat)
                12'd226: toneR = `hcP;    12'd227: toneR = `hcP;
                12'd228: toneR = `hcP;    12'd229: toneR = `hcP;
                12'd230: toneR = `hcP;    12'd231: toneR = `hcP; // (Short break for repetitive notes: high D)
                12'd232: toneR = `hcP;    12'd233: toneR = `hcP; // HG (half-beat)
                12'd234: toneR = `hcP;    12'd235: toneR = `hcP;
                
                12'd236: toneR = `ha;    12'd237: toneR = `ha;
                12'd238: toneR = `ha;    12'd239: toneR = `ha; // (Short break for repetitive notes: high D)

                12'd240: toneR = `ha;    12'd241: toneR = `ha; // HG (one-beat)
                12'd242: toneR = `ha;    12'd243: toneR = `ha;
                12'd244: toneR = `ha;    12'd245: toneR = `ha;
                12'd246: toneR = `ha;    12'd247: toneR = `ha;
                
                12'd248: toneR = `hg;    12'd249: toneR = `hg;
                12'd250: toneR = `hg;    12'd251: toneR = `hg;
                12'd252: toneR = `hg;    12'd253: toneR = `hg;
                12'd254: toneR = `hg;    12'd255: toneR = `hg;
                
                // --- Measure 5---
                12'd256: toneR = `hfP;     12'd257: toneR = `hfP; // HC (half-beat)
                12'd258: toneR = `hfP;     12'd259: toneR = `hfP;
                12'd260: toneR = `hfP;     12'd261: toneR = `hfP;
                12'd262: toneR = `hfP;     12'd263: toneR = `hfP;
                12'd264: toneR = `hfP;     12'd265: toneR = `hfP; // HD (half-beat)
                12'd266: toneR = `hfP;     12'd267: toneR = `hfP;
                12'd268: toneR = `hfP;     12'd269: toneR = `hfP;
                12'd270: toneR = `hfP;     12'd271: toneR = `hfP;
                12'd272: toneR = `hfP;     12'd273: toneR = `hfP; // HE (half-beat)
                12'd274: toneR = `hfP;     12'd275: toneR = `hfP;
                12'd276: toneR = `hfP;     12'd277: toneR = `hfP;
                12'd278: toneR = `hfP;     12'd279: toneR = `hfP;
                
                12'd280: toneR = `hd;     12'd281: toneR = `hd; // HF (half-beat)
                12'd282: toneR = `hd;     12'd283: toneR = `hd;
                12'd284: toneR = `hd;     12'd285: toneR = `hd;
                12'd286: toneR = `hd;     12'd287: toneR = `hd;

                12'd288: toneR = `hd;    12'd289: toneR = `hd; // HG (half-beat)
                12'd290: toneR = `hd;    12'd291: toneR = `hd;
                12'd292: toneR = `hd;    12'd293: toneR = `hd;
                12'd294: toneR = `hd;    12'd295: toneR = `hd; // (Short break for repetitive notes: high D)
                12'd296: toneR = `hd;    12'd297: toneR = `hd; // HG (half-beat)
                12'd298: toneR = `hd;    12'd299: toneR = `hd;
                12'd300: toneR = `hd;    12'd301: toneR = `hd;
                12'd302: toneR = `hd;    12'd303: toneR = `hd; // (Short break for repetitive notes: high D)

                12'd304: toneR = `sil;    12'd305: toneR = `sil; // HG (one-beat)
                12'd306: toneR = `sil;    12'd307: toneR = `sil;
                12'd308: toneR = `sil;    12'd309: toneR = `sil;
                12'd310: toneR = `sil;    12'd311: toneR = `sil;
                
                12'd312: toneR = `hd;    12'd313: toneR = `hd;
                12'd314: toneR = `hd;    12'd315: toneR = `hd;
                
                12'd316: toneR = `he;    12'd317: toneR = `he;
                12'd318: toneR = `he;    12'd319: toneR = `he;
                
                // --- Measure 6 ---
                12'd320: toneR = `hf;     12'd321: toneR = `hf; // HC (half-beat)
                12'd322: toneR = `hf;     12'd323: toneR = `hf;
                12'd324: toneR = `hf;     12'd325: toneR = `hf;
                12'd326: toneR = `hf;     12'd327: toneR = `hf;
                12'd328: toneR = `hf;     12'd329: toneR = `hf; // HD (half-beat)
                12'd330: toneR = `hf;     12'd331: toneR = `hf;
                
                12'd332: toneR = `he;     12'd333: toneR = `he;
                12'd334: toneR = `he;     12'd335: toneR = `he;
                
                12'd336: toneR = `he;     12'd337: toneR = `he; // HE (half-beat)
                12'd338: toneR = `he;     12'd339: toneR = `he;
                12'd340: toneR = `he;     12'd341: toneR = `he;
                12'd342: toneR = `he;     12'd343: toneR = `he;
                
                12'd344: toneR = `hd;     12'd345: toneR = `hd; // HF (half-beat)
                12'd346: toneR = `hd;     12'd347: toneR = `hd;
                12'd348: toneR = `hd;     12'd349: toneR = `hd;
                12'd350: toneR = `hd;     12'd351: toneR = `hd;

                12'd352: toneR = `hcP;    12'd353: toneR = `hcP; // HG (half-beat)
                12'd354: toneR = `hcP;    12'd355: toneR = `hcP;
                12'd356: toneR = `hcP;    12'd357: toneR = `hcP;
                12'd358: toneR = `hcP;    12'd359: toneR = `hcP; // (Short break for repetitive notes: high D)
                12'd360: toneR = `hcP;    12'd361: toneR = `hcP; // HG (half-beat)
                12'd362: toneR = `hcP;    12'd363: toneR = `hcP;
                
                12'd364: toneR = `hd;    12'd365: toneR = `hd;
                12'd366: toneR = `hd;    12'd367: toneR = `hd; // (Short break for repetitive notes: high D)

                12'd368: toneR = `hd;    12'd369: toneR = `hd; // HG (one-beat)
                12'd370: toneR = `hd;    12'd371: toneR = `hd;
                12'd372: toneR = `hd;    12'd373: toneR = `hd;
                12'd374: toneR = `hd;    12'd375: toneR = `hd;
                
                12'd376: toneR = `he;    12'd377: toneR = `he;
                12'd378: toneR = `he;    12'd379: toneR = `he;
                12'd380: toneR = `he;    12'd381: toneR = `he;
                12'd382: toneR = `he;    12'd383: toneR = `he;
                
                // --- Measure 7 ---
                12'd384: toneR = `hfP;     12'd385: toneR = `hfP; // HC (half-beat)
                12'd386: toneR = `hfP;     12'd387: toneR = `hfP;
                12'd388: toneR = `hfP;     12'd389: toneR = `hfP;
                12'd390: toneR = `hfP;     12'd391: toneR = `hfP;
                12'd392: toneR = `hfP;     12'd393: toneR = `hfP; // HD (half-beat)
                12'd394: toneR = `hfP;     12'd395: toneR = `hfP;
                12'd396: toneR = `hfP;     12'd397: toneR = `hfP;
                12'd398: toneR = `hfP;     12'd399: toneR = `sil;
                
                12'd400: toneR = `hfP;     12'd401: toneR = `hfP; // HE (half-beat)
                12'd402: toneR = `hfP;     12'd403: toneR = `hfP;
                12'd404: toneR = `hfP;     12'd405: toneR = `hfP;
                12'd406: toneR = `hfP;     12'd407: toneR = `hfP;
                
                12'd408: toneR = `hb;     12'd409: toneR = `hb; // HF (half-beat)
                12'd410: toneR = `hb;     12'd411: toneR = `hb;
                12'd412: toneR = `hb;     12'd413: toneR = `hb;
                12'd414: toneR = `hb;     12'd415: toneR = `hb;

                12'd416: toneR = `hb;    12'd417: toneR = `hb; // HG (half-beat)
                12'd418: toneR = `hb;    12'd419: toneR = `hb;
                12'd420: toneR = `hb;    12'd421: toneR = `hb;
                12'd422: toneR = `hb;    12'd423: toneR = `hb; // (Short break for repetitive notes: high D)
                12'd424: toneR = `hb;    12'd425: toneR = `hb; // HG (half-beat)
                12'd426: toneR = `hb;    12'd427: toneR = `hb;
                12'd428: toneR = `hb;    12'd429: toneR = `hb;
                12'd430: toneR = `hb;    12'd431: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd432: toneR = `hb;    12'd433: toneR = `hb; // HG (one-beat)
                12'd434: toneR = `hb;    12'd435: toneR = `hb;
                12'd436: toneR = `hb;    12'd437: toneR = `hb;
                12'd438: toneR = `hb;    12'd439: toneR = `hb;
                
                12'd440: toneR = `hhcP;    12'd441: toneR = `hhcP;
                12'd442: toneR = `hhcP;    12'd443: toneR = `hhcP;
                12'd444: toneR = `hhcP;    12'd445: toneR = `hhcP;
                12'd446: toneR = `hhcP;    12'd447: toneR = `hhcP;
                
                // --- Measure 8 ---
                12'd448: toneR = `hhd;     12'd449: toneR = `hhd; // HC (half-beat)
                12'd450: toneR = `hhd;     12'd451: toneR = `hhd;
                12'd452: toneR = `hhd;     12'd453: toneR = `hhd;
                12'd454: toneR = `hhd;     12'd455: toneR = `hhd;
                12'd456: toneR = `hhd;     12'd457: toneR = `hhd; // HD (half-beat)
                12'd458: toneR = `hhd;     12'd459: toneR = `hhd;
                
                12'd460: toneR = `hg;     12'd461: toneR = `hg;
                12'd462: toneR = `hg;     12'd463: toneR = `hg;
                
                12'd464: toneR = `hg;     12'd465: toneR = `hg; // HE (half-beat)
                12'd466: toneR = `hg;     12'd467: toneR = `hg;
                12'd468: toneR = `hg;     12'd469: toneR = `hg;
                12'd470: toneR = `hg;     12'd471: toneR = `hg;
                
                12'd472: toneR = `hfP;     12'd473: toneR = `hfP; // HF (half-beat)
                12'd474: toneR = `hfP;     12'd475: toneR = `hfP;
                12'd476: toneR = `hfP;     12'd477: toneR = `hfP;
                12'd478: toneR = `hfP;     12'd479: toneR = `sil;

                12'd480: toneR = `hf;    12'd481: toneR = `hf; // HG (half-beat)
                12'd482: toneR = `hf;    12'd483: toneR = `hf;
                12'd484: toneR = `hf;    12'd485: toneR = `hf;
                12'd486: toneR = `hf;    12'd487: toneR = `hf; // (Short break for repetitive notes: high D)
                12'd488: toneR = `hf;    12'd489: toneR = `hf; // HG (half-beat)
                12'd490: toneR = `hf;    12'd491: toneR = `hf;
                
                12'd492: toneR = `hhd;    12'd493: toneR = `hhd;
                12'd494: toneR = `hhd;    12'd495: toneR = `hhd; // (Short break for repetitive notes: high D)

                12'd496: toneR = `hhd;    12'd497: toneR = `hhd; // HG (one-beat)
                12'd498: toneR = `hhd;    12'd499: toneR = `hhd;
                12'd500: toneR = `hhd;    12'd501: toneR = `hhd;
                12'd502: toneR = `hhd;    12'd503: toneR = `hhd;
                
                12'd504: toneR = `hhe;    12'd505: toneR = `hhe;
                12'd506: toneR = `hhe;    12'd507: toneR = `hhe;
                12'd508: toneR = `hhe;    12'd509: toneR = `hhe;
                12'd510: toneR = `hhe;    12'd511: toneR = `hhe;
                
                default: toneR = `sil;
            endcase
        end else begin
            toneR = `sil;
        end
    end

    always @(*) begin
        if(en == 1)begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneL = `llb;  	12'd1: toneL = `llb; // HC (two-beat)
                12'd2: toneL = `llb;  	12'd3: toneL = `llb;
                12'd4: toneL = `llb;    12'd5: toneL = `llb;
                12'd6: toneL = `llb;  	12'd7: toneL = `llb;
                12'd8: toneL = `llb;	12'd9: toneL = `llb;
                12'd10: toneL = `llb;	12'd11: toneL = `llb;
                12'd12: toneL = `llb;	12'd13: toneL = `llb;
                12'd14: toneL = `llb;	12'd15: toneL = `llb;
                12'd16: toneL = `llb;	12'd17: toneL = `llb;
                12'd18: toneL = `llb;	12'd19: toneL = `llb;
                12'd20: toneL = `llb;	12'd21: toneL = `llb;
                12'd22: toneL = `llb;	12'd23: toneL = `llb;
                
                12'd24: toneL = `llgP;	12'd25: toneL = `llgP;
                12'd26: toneL = `llgP;	12'd27: toneL = `llgP;
                12'd28: toneL = `llgP;	12'd29: toneL = `llgP;
                12'd30: toneL = `llgP;	12'd31: toneL = `sil;

                12'd32: toneL = `llgP;	    12'd33: toneL = `llgP; // G (one-beat)
                12'd34: toneL = `llgP;	    12'd35: toneL = `llgP;
                12'd36: toneL = `llgP;	    12'd37: toneL = `llgP;
                12'd38: toneL = `llgP;	    12'd39: toneL = `llgP;
                12'd40: toneL = `llgP;	    12'd41: toneL = `llgP;
                12'd42: toneL = `llgP;	    12'd43: toneL = `llgP;
                12'd44: toneL = `llgP;	    12'd45: toneL = `llgP;
                12'd46: toneL = `llgP;	    12'd47: toneL = `llgP;
                12'd48: toneL = `llgP;	    12'd49: toneL = `llgP; // B (one-beat)
                12'd50: toneL = `llgP;	    12'd51: toneL = `llgP;
                12'd52: toneL = `llgP;	    12'd53: toneL = `llgP;
                12'd54: toneL = `llgP;	    12'd55: toneL = `llgP;
                12'd56: toneL = `llgP;	    12'd57: toneL = `llgP;
                12'd58: toneL = `llgP;	    12'd59: toneL = `llgP;
                12'd60: toneL = `llgP;	    12'd61: toneL = `llgP;
                12'd62: toneL = `llgP;	    12'd63: toneL = `llgP;

                // --- Measure 2 ---
                12'd64: toneL = `lcP;	 12'd65: toneL = `lcP; // HC (two-beat)
                12'd66: toneL = `lcP;    12'd67: toneL = `lcP;
                12'd68: toneL = `lcP;	 12'd69: toneL = `lcP;
                12'd70: toneL = `lcP;	 12'd71: toneL = `lcP;
                12'd72: toneL = `lcP;	 12'd73: toneL = `lcP;
                12'd74: toneL = `lcP;	 12'd75: toneL = `lcP;
                12'd76: toneL = `lcP;	 12'd77: toneL = `lcP;
                12'd78: toneL = `lcP;	 12'd79: toneL = `lcP;
                12'd80: toneL = `lcP;	 12'd81: toneL = `lcP;
                12'd82: toneL = `lcP;    12'd83: toneL = `lcP;
                12'd84: toneL = `lcP;    12'd85: toneL = `lcP;
                12'd86: toneL = `lcP;    12'd87: toneL = `lcP;
                12'd88: toneL = `lcP;    12'd89: toneL = `lcP;
                12'd90: toneL = `lcP;    12'd91: toneL = `lcP;
                12'd92: toneL = `lcP;    12'd93: toneL = `lcP;
                12'd94: toneL = `lcP;    12'd95: toneL = `lcP;

                12'd96: toneL = `llfP;	    12'd97: toneL = `llfP; // G (one-beat)
                12'd98: toneL = `llfP; 	    12'd99: toneL = `llfP;
                12'd100: toneL = `llfP;	    12'd101: toneL = `llfP;
                12'd102: toneL = `llfP;	    12'd103: toneL = `llfP;
                12'd104: toneL = `llfP;	    12'd105: toneL = `llfP;
                12'd106: toneL = `llfP;	    12'd107: toneL = `llfP;
                12'd108: toneL = `llfP;	    12'd109: toneL = `llfP;
                12'd110: toneL = `llfP;	    12'd111: toneL = `llfP;
                12'd112: toneL = `llfP;	    12'd113: toneL = `llfP; // B (one-beat)
                12'd114: toneL = `llfP;	    12'd115: toneL = `llfP;
                12'd116: toneL = `llfP;	    12'd117: toneL = `llfP;
                12'd118: toneL = `llfP;	    12'd119: toneL = `llfP;
                12'd120: toneL = `llfP;	    12'd121: toneL = `llfP;
                12'd122: toneL = `llfP;	    12'd123: toneL = `llfP;
                12'd124: toneL = `llfP;	    12'd125: toneL = `llfP;
                12'd126: toneL = `llfP;	    12'd127: toneL = `llfP;
                
                // --- Measure 3 ---
                12'd128: toneL = `llb;     12'd129: toneL = `llb; // HC (half-beat)
                12'd130: toneL = `llb;     12'd131: toneL = `llb;
                12'd132: toneL = `llb;     12'd133: toneL = `llb;
                12'd134: toneL = `llb;     12'd135: toneL = `llb;
                12'd136: toneL = `llb;     12'd137: toneL = `llb; // HD (half-beat)
                12'd138: toneL = `llb;     12'd139: toneL = `llb;
                12'd140: toneL = `llb;     12'd141: toneL = `llb;
                12'd142: toneL = `llb;     12'd143: toneL = `llb;
                12'd144: toneL = `llb;     12'd145: toneL = `llb; // HE (half-beat)
                12'd146: toneL = `llb;     12'd147: toneL = `llb;
                12'd148: toneL = `llb;     12'd149: toneL = `llb;
                12'd150: toneL = `llb;     12'd151: toneL = `llb;
                
                12'd152: toneL = `llgP;     12'd153: toneL = `llgP; // HF (half-beat)
                12'd154: toneL = `llgP;     12'd155: toneL = `llgP;
                12'd156: toneL = `llgP;     12'd157: toneL = `llgP;
                12'd158: toneL = `llgP;     12'd159: toneL = `sil;

                12'd160: toneL = `llgP;    12'd161: toneL = `llgP; // HG (half-beat)
                12'd162: toneL = `llgP;    12'd163: toneL = `llgP;
                12'd164: toneL = `llgP;    12'd165: toneL = `llgP;
                12'd166: toneL = `llgP;    12'd167: toneL = `llgP; // (Short break for repetitive notes: high D)
                12'd168: toneL = `llgP;    12'd169: toneL = `llgP; // HG (half-beat)
                12'd170: toneL = `llgP;    12'd171: toneL = `llgP;
                12'd172: toneL = `llgP;    12'd173: toneL = `llgP;
                12'd174: toneL = `llgP;    12'd175: toneL = `llgP; // (Short break for repetitive notes: high D)
                12'd176: toneL = `llgP;    12'd177: toneL = `llgP; // HG (one-beat)
                12'd178: toneL = `llgP;    12'd179: toneL = `llgP;
                12'd180: toneL = `llgP;    12'd181: toneL = `llgP;
                12'd182: toneL = `llgP;    12'd183: toneL = `llgP;
                12'd184: toneL = `llgP;    12'd185: toneL = `llgP;
                12'd186: toneL = `llgP;    12'd187: toneL = `llgP;
                12'd188: toneL = `llgP;    12'd189: toneL = `llgP;
                12'd190: toneL = `llgP;    12'd191: toneL = `llgP;
                
                // --- Measure 4 ---
                12'd192: toneL = `lcP;     12'd193: toneL = `lcP; // HC (half-beat)
                12'd194: toneL = `lcP;     12'd195: toneL = `lcP;
                12'd196: toneL = `lcP;     12'd197: toneL = `lcP;
                12'd198: toneL = `lcP;     12'd199: toneL = `lcP;
                12'd200: toneL = `lcP;     12'd201: toneL = `lcP; // HD (half-beat)
                12'd202: toneL = `lcP;     12'd203: toneL = `lcP;
                12'd204: toneL = `lcP;     12'd205: toneL = `lcP;
                12'd206: toneL = `lcP;     12'd207: toneL = `lcP;
                12'd208: toneL = `lcP;     12'd209: toneL = `lcP; // HE (half-beat)
                12'd210: toneL = `lcP;     12'd211: toneL = `lcP;
                12'd212: toneL = `lcP;     12'd213: toneL = `lcP;
                12'd214: toneL = `lcP;     12'd215: toneL = `lcP;
                12'd216: toneL = `lcP;     12'd217: toneL = `lcP; // HF (half-beat)
                12'd218: toneL = `lcP;     12'd219: toneL = `lcP;
                12'd220: toneL = `lcP;     12'd221: toneL = `lcP;
                12'd222: toneL = `lcP;     12'd223: toneL = `lcP;

                12'd224: toneL = `llfP;    12'd225: toneL = `llfP; // HG (half-beat)
                12'd226: toneL = `llfP;    12'd227: toneL = `llfP;
                12'd228: toneL = `llfP;    12'd229: toneL = `llfP;
                12'd230: toneL = `llfP;    12'd231: toneL = `llfP; // (Short break for repetitive notes: high D)
                12'd232: toneL = `llfP;    12'd233: toneL = `llfP; // HG (half-beat)
                12'd234: toneL = `llfP;    12'd235: toneL = `llfP;
                12'd236: toneL = `llfP;    12'd237: toneL = `llfP;
                12'd238: toneL = `llfP;    12'd239: toneL = `llfP; 
                12'd240: toneL = `llfP;    12'd241: toneL = `llfP; // HG (one-beat)
                12'd242: toneL = `llfP;    12'd243: toneL = `llfP;
                12'd244: toneL = `llfP;    12'd245: toneL = `llfP;
                12'd246: toneL = `llfP;    12'd247: toneL = `llfP;
                12'd248: toneL = `llfP;    12'd249: toneL = `llfP;
                12'd250: toneL = `llfP;    12'd251: toneL = `llfP;
                12'd252: toneL = `llfP;    12'd253: toneL = `llfP;
                12'd254: toneL = `llfP;    12'd255: toneL = `llfP;
                
                // --- Measure 5---
                12'd256: toneL = `llb;     12'd257: toneL = `llb; // HC (half-beat)
                12'd258: toneL = `llb;     12'd259: toneL = `llb;
                12'd260: toneL = `llb;     12'd261: toneL = `llb;
                12'd262: toneL = `llb;     12'd263: toneL = `llb;
                12'd264: toneL = `llb;     12'd265: toneL = `llb; // HD (half-beat)
                12'd266: toneL = `llb;     12'd267: toneL = `llb;
                12'd268: toneL = `llb;     12'd269: toneL = `llb;
                12'd270: toneL = `llb;     12'd271: toneL = `sil;
                
                12'd272: toneL = `llb;     12'd273: toneL = `llb; // HE (half-beat)
                12'd274: toneL = `llb;     12'd275: toneL = `llb;
                12'd276: toneL = `llb;     12'd277: toneL = `llb;
                12'd278: toneL = `llb;     12'd279: toneL = `llb;
                
                12'd280: toneL = `llgP;     12'd281: toneL = `llgP; // HF (half-beat)
                12'd282: toneL = `llgP;     12'd283: toneL = `llgP;
                12'd284: toneL = `llgP;     12'd285: toneL = `llgP;
                12'd286: toneL = `llgP;     12'd287: toneL = `sil;

                12'd288: toneL = `llgP;    12'd289: toneL = `llgP; // HG (half-beat)
                12'd290: toneL = `llgP;    12'd291: toneL = `llgP;
                12'd292: toneL = `llgP;    12'd293: toneL = `llgP;
                12'd294: toneL = `llgP;    12'd295: toneL = `llgP; // (Short break for repetitive notes: high D)
                12'd296: toneL = `llgP;    12'd297: toneL = `llgP; // HG (half-beat)
                12'd298: toneL = `llgP;    12'd299: toneL = `llgP;
                12'd300: toneL = `llgP;    12'd301: toneL = `llgP;
                12'd302: toneL = `llgP;    12'd303: toneL = `sil; // (Short break for repetitive notes: high D)

                12'd304: toneL = `llgP;    12'd305: toneL = `llgP; // HG (one-beat)
                12'd306: toneL = `llgP;    12'd307: toneL = `llgP;
                12'd308: toneL = `llgP;    12'd309: toneL = `llgP;
                12'd310: toneL = `llgP;    12'd311: toneL = `llgP;
                12'd312: toneL = `llgP;    12'd313: toneL = `llgP;
                12'd314: toneL = `llgP;    12'd315: toneL = `llgP;
                12'd316: toneL = `llgP;    12'd317: toneL = `llgP;
                12'd318: toneL = `llgP;    12'd319: toneL = `llgP;
                
                // --- Measure 6 ---
                12'd320: toneL = `lcP;     12'd321: toneL = `lcP; // HC (half-beat)
                12'd322: toneL = `lcP;     12'd323: toneL = `lcP;
                12'd324: toneL = `lcP;     12'd325: toneL = `lcP;
                12'd326: toneL = `lcP;     12'd327: toneL = `lcP;
                12'd328: toneL = `lcP;     12'd329: toneL = `lcP; // HD (half-beat)
                12'd330: toneL = `lcP;     12'd331: toneL = `lcP;
                12'd332: toneL = `lcP;     12'd333: toneL = `lcP;
                12'd334: toneL = `lcP;     12'd335: toneL = `sil;
                
                12'd336: toneL = `lcP;     12'd337: toneL = `lcP; // HE (half-beat)
                12'd338: toneL = `lcP;     12'd339: toneL = `lcP;
                12'd340: toneL = `lcP;     12'd341: toneL = `lcP;
                12'd342: toneL = `lcP;     12'd343: toneL = `lcP;
                12'd344: toneL = `lcP;     12'd345: toneL = `lcP; // HF (half-beat)
                12'd346: toneL = `lcP;     12'd347: toneL = `lcP;
                12'd348: toneL = `lcP;     12'd349: toneL = `lcP;
                12'd350: toneL = `lcP;     12'd351: toneL = `sil;

                12'd352: toneL = `llfP;    12'd353: toneL = `llfP; // HG (half-beat)
                12'd354: toneL = `llfP;    12'd355: toneL = `llfP;
                12'd356: toneL = `llfP;    12'd357: toneL = `llfP;
                12'd358: toneL = `llfP;    12'd359: toneL = `llfP; // (Short break for repetitive notes: high D)
                12'd360: toneL = `llfP;    12'd361: toneL = `llfP; // HG (half-beat)
                12'd362: toneL = `llfP;    12'd363: toneL = `llfP;
                12'd364: toneL = `llfP;    12'd365: toneL = `llfP;
                12'd366: toneL = `llfP;    12'd367: toneL = `sil; // (Short break for repetitive notes: high D)

                12'd368: toneL = `llfP;    12'd369: toneL = `llfP; // HG (one-beat)
                12'd370: toneL = `llfP;    12'd371: toneL = `llfP;
                12'd372: toneL = `llfP;    12'd373: toneL = `llfP;
                12'd374: toneL = `llfP;    12'd375: toneL = `llfP;
                12'd376: toneL = `llfP;    12'd377: toneL = `llfP;
                12'd378: toneL = `llfP;    12'd379: toneL = `llfP;
                12'd380: toneL = `llfP;    12'd381: toneL = `llfP;
                12'd382: toneL = `llfP;    12'd383: toneL = `sil;
                
                // --- Measure 7 ---
                12'd384: toneL = `llb;     12'd385: toneL = `llb; // HC (half-beat)
                12'd386: toneL = `llb;     12'd387: toneL = `llb;
                12'd388: toneL = `llb;     12'd389: toneL = `llb;
                12'd390: toneL = `llb;     12'd391: toneL = `llb;
                12'd392: toneL = `llb;     12'd393: toneL = `llb; // HD (half-beat)
                12'd394: toneL = `llb;     12'd395: toneL = `llb;
                12'd396: toneL = `llb;     12'd397: toneL = `llb;
                12'd398: toneL = `llb;     12'd399: toneL = `sil;
                
                12'd400: toneL = `llb;     12'd401: toneL = `llb; // HE (half-beat)
                12'd402: toneL = `llb;     12'd403: toneL = `llb;
                12'd404: toneL = `llb;     12'd405: toneL = `llb;
                12'd406: toneL = `llb;     12'd407: toneL = `sil;
                
                12'd408: toneL = `llgP;     12'd409: toneL = `llgP; // HF (half-beat)
                12'd410: toneL = `llgP;     12'd411: toneL = `llgP;
                12'd412: toneL = `llgP;     12'd413: toneL = `llgP;
                12'd414: toneL = `llgP;     12'd415: toneL = `sil;

                12'd416: toneL = `llgP;    12'd417: toneL = `llgP; // HG (half-beat)
                12'd418: toneL = `llgP;    12'd419: toneL = `llgP;
                12'd420: toneL = `llgP;    12'd421: toneL = `llgP;
                12'd422: toneL = `llgP;    12'd423: toneL = `llgP; // (Short break for repetitive notes: high D)
                12'd424: toneL = `llgP;    12'd425: toneL = `llgP; // HG (half-beat)
                12'd426: toneL = `llgP;    12'd427: toneL = `llgP;
                12'd428: toneL = `llgP;    12'd429: toneL = `llgP;
                12'd430: toneL = `llgP;    12'd431: toneL = `sil; // (Short break for repetitive notes: high D)

                12'd432: toneL = `llgP;    12'd433: toneL = `llgP; // HG (one-beat)
                12'd434: toneL = `llgP;    12'd435: toneL = `llgP;
                12'd436: toneL = `llgP;    12'd437: toneL = `llgP;
                12'd438: toneL = `llgP;    12'd439: toneL = `llgP;                
                12'd440: toneL = `llgP;    12'd441: toneL = `llgP;
                12'd442: toneL = `llgP;    12'd443: toneL = `llgP;
                12'd444: toneL = `llgP;    12'd445: toneL = `llgP;
                12'd446: toneL = `llgP;    12'd447: toneL = `sil;
                
                // --- Measure 8 ---
                12'd448: toneL = `lcP;     12'd449: toneL = `lcP; // HC (half-beat)
                12'd450: toneL = `lcP;     12'd451: toneL = `lcP;
                12'd452: toneL = `lcP;     12'd453: toneL = `lcP;
                12'd454: toneL = `lcP;     12'd455: toneL = `lcP;
                12'd456: toneL = `lcP;     12'd457: toneL = `lcP; // HD (half-beat)
                12'd458: toneL = `lcP;     12'd459: toneL = `lcP;
                12'd460: toneL = `lcP;     12'd461: toneL = `lcP;
                12'd462: toneL = `lcP;     12'd463: toneL = `sil;
                
                12'd464: toneL = `lcP;     12'd465: toneL = `lcP; // HE (half-beat)
                12'd466: toneL = `lcP;     12'd467: toneL = `lcP;
                12'd468: toneL = `lcP;     12'd469: toneL = `lcP;
                12'd470: toneL = `lcP;     12'd471: toneL = `lcP;
                12'd472: toneL = `lcP;     12'd473: toneL = `lcP; // HF (half-beat)
                12'd474: toneL = `lcP;     12'd475: toneL = `lcP;
                12'd476: toneL = `lcP;     12'd477: toneL = `lcP;
                12'd478: toneL = `lcP;     12'd479: toneL = `lcP;

                12'd480: toneL = `llfP;    12'd481: toneL = `llfP; // HG (half-beat)
                12'd482: toneL = `llfP;    12'd483: toneL = `llfP;
                12'd484: toneL = `llfP;    12'd485: toneL = `llfP;
                12'd486: toneL = `llfP;    12'd487: toneL = `llfP; // (Short break for repetitive notes: high D)
                12'd488: toneL = `llfP;    12'd489: toneL = `llfP; // HG (half-beat)
                12'd490: toneL = `llfP;    12'd491: toneL = `llfP;
                12'd492: toneL = `llfP;    12'd493: toneL = `llfP;
                12'd494: toneL = `llfP;    12'd495: toneL = `sil; 
                
                12'd496: toneL = `llbM;    12'd497: toneL = `llbM; // HG (one-beat)
                12'd498: toneL = `llbM;    12'd499: toneL = `llbM;
                12'd500: toneL = `llbM;    12'd501: toneL = `llbM;
                12'd502: toneL = `llbM;    12'd503: toneL = `llbM;
                12'd504: toneL = `llbM;    12'd505: toneL = `llbM;
                12'd506: toneL = `llbM;    12'd507: toneL = `llbM;
                12'd508: toneL = `llbM;    12'd509: toneL = `llbM;
                12'd510: toneL = `llbM;    12'd511: toneL = `llbM;
				
                default : toneL = `sil;
            endcase
        end
        else begin
            toneL = `sil;
        end
    end
endmodule


module music_example1 (
	input [11:0] ibeatNum,
	input en,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @* begin
        if(en == 1) begin
             // --- Measure 1 ---
             case(ibeatNum)
                12'd0: toneR = `hb;      12'd1: toneR = `hb;
                12'd2: toneR = `hb;      12'd3: toneR = `hb;
                12'd4: toneR = `hb;      12'd5: toneR = `hb;
                12'd6: toneR = `hb;      12'd7: toneR = `hb;
                12'd8: toneR = `hb;      12'd9: toneR = `hb; 
                12'd10: toneR = `hb;     12'd11: toneR = `hb; // B

                12'd12: toneR = `hbM;     12'd13: toneR = `hbM;
                12'd14: toneR = `hbM;     12'd15: toneR = `hbM; // A#

                12'd16: toneR = `hb;     12'd17: toneR = `hb;
                12'd18: toneR = `hb;     12'd19: toneR = `hb;
                12'd20: toneR = `hb;     12'd21: toneR = `hb;
                12'd22: toneR = `hb;     12'd23: toneR = `hb;                
                12'd24: toneR = `hb;     12'd25: toneR = `hb;
                12'd26: toneR = `hb;     12'd27: toneR = `hb;
                12'd28: toneR = `hb;     12'd29: toneR = `hb;
                12'd30: toneR = `hb;     12'd31: toneR = `hb; // B

                12'd32: toneR = `hfP;     12'd33: toneR = `hfP; 
                12'd34: toneR = `hfP;     12'd35: toneR = `hfP;
                12'd36: toneR = `hfP;     12'd37: toneR = `hfP;
                12'd38: toneR = `hfP;     12'd39: toneR = `hfP;
                12'd40: toneR = `hfP;     12'd41: toneR = `hfP;
                12'd42: toneR = `hfP;     12'd43: toneR = `hfP;
                12'd44: toneR = `hfP;     12'd45: toneR = `hfP;
                12'd46: toneR = `hfP;     12'd47: toneR = `sil; // F#
                
                12'd48: toneR = `hfP;     12'd49: toneR = `hfP;
                12'd50: toneR = `hfP;     12'd51: toneR = `hfP;
                12'd52: toneR = `hfP;     12'd53: toneR = `hfP;
                12'd54: toneR = `hfP;     12'd55: toneR = `hfP;                
                12'd56: toneR = `hfP;     12'd57: toneR = `hfP;
                12'd58: toneR = `hfP;     12'd59: toneR = `hfP; // F#
                
                12'd60: toneR = `hb;     12'd61: toneR = `hb;
                12'd62: toneR = `hb;     12'd63: toneR = `hb; // B

                // --- Measure 2 ---
                12'd64: toneR = `hbM;     12'd65: toneR = `hbM; 
                12'd66: toneR = `hbM;     12'd67: toneR = `hbM;
                12'd68: toneR = `hbM;     12'd69: toneR = `hbM;
                12'd70: toneR = `hbM;     12'd71: toneR = `hbM;
                12'd72: toneR = `hbM;     12'd73: toneR = `hbM; 
                12'd74: toneR = `hbM;     12'd75: toneR = `hbM; // Bb
                
                12'd76: toneR = `hgP;     12'd77: toneR = `hgP;
                12'd78: toneR = `hgP;     12'd79: toneR = `hgP; // G#
                
                12'd80: toneR = `hbM;     12'd81: toneR = `hbM; 
                12'd82: toneR = `hbM;     12'd83: toneR = `hbM;
                12'd84: toneR = `hbM;     12'd85: toneR = `hbM;
                12'd86: toneR = `hbM;     12'd87: toneR = `hbM;                
                12'd88: toneR = `hbM;     12'd89: toneR = `hbM; 
                12'd90: toneR = `hbM;     12'd91: toneR = `hbM; // Bb

                12'd92: toneR = `hgP;     12'd93: toneR = `hgP;
                12'd94: toneR = `hgP;     12'd95: toneR = `hgP; // G#

                12'd96: toneR = `hg;     12'd97: toneR = `hg;
                12'd98: toneR = `hg;     12'd99: toneR = `hg;
                12'd100: toneR = `hg;    12'd101: toneR = `hg;
                12'd102: toneR = `hg;    12'd103: toneR = `hg; 
                12'd104: toneR = `hg;    12'd105: toneR = `hg;
                12'd106: toneR = `hg;    12'd107: toneR = `hg;                
                12'd108: toneR = `hg;    12'd109: toneR = `hg;
                12'd110: toneR = `hg;    12'd111: toneR = `hg; // G

                12'd112: toneR = `hgP;    12'd113: toneR = `hgP;
                12'd114: toneR = `hgP;    12'd115: toneR = `hgP;
                12'd116: toneR = `hgP;    12'd117: toneR = `hgP;
                12'd118: toneR = `hgP;    12'd119: toneR = `hgP;                
                12'd120: toneR = `hgP;    12'd121: toneR = `hgP;
                12'd122: toneR = `hgP;    12'd123: toneR = `hgP;
                12'd124: toneR = `hgP;    12'd125: toneR = `hgP;
                12'd126: toneR = `hgP;    12'd127: toneR = `hgP; // G#
                
                // --- Measure 3 ---
                12'd128: toneR = `hb;     12'd129: toneR = `hb;
                12'd130: toneR = `hb;     12'd131: toneR = `hb;
                12'd132: toneR = `hb;     12'd133: toneR = `hb;
                12'd134: toneR = `hb;     12'd135: toneR = `hb;
                12'd136: toneR = `hb;     12'd137: toneR = `hb;
                12'd138: toneR = `hb;     12'd139: toneR = `hb; // B

                12'd140: toneR = `hbM;     12'd141: toneR = `hbM;
                12'd142: toneR = `hbM;     12'd143: toneR = `hbM; // A#

                12'd144: toneR = `hb;     12'd145: toneR = `hb; 
                12'd146: toneR = `hb;     12'd147: toneR = `hb;
                12'd148: toneR = `hb;     12'd149: toneR = `hb;
                12'd150: toneR = `hb;     12'd151: toneR = `hb; // B             
                12'd152: toneR = `hb;     12'd153: toneR = `hb;
                12'd154: toneR = `hb;     12'd155: toneR = `hb;

                12'd156: toneR = `hbM;     12'd157: toneR = `hbM;
                12'd158: toneR = `hbM;     12'd159: toneR = `hbM; // A#

                12'd160: toneR = `hgP;    12'd161: toneR = `hgP;
                12'd162: toneR = `hgP;    12'd163: toneR = `hgP;
                12'd164: toneR = `hgP;    12'd165: toneR = `hgP;
                12'd166: toneR = `hgP;    12'd167: toneR = `hgP;
                12'd168: toneR = `hgP;    12'd169: toneR = `hgP;
                12'd170: toneR = `hgP;    12'd171: toneR = `hgP;
                12'd172: toneR = `hgP;    12'd173: toneR = `hgP;
                12'd174: toneR = `hgP;    12'd175: toneR = `hgP;
                12'd176: toneR = `hgP;    12'd177: toneR = `hgP;
                12'd178: toneR = `hgP;    12'd179: toneR = `hgP;
                12'd180: toneR = `hgP;    12'd181: toneR = `hgP;
                12'd182: toneR = `hgP;    12'd183: toneR = `hgP;                
                12'd184: toneR = `hgP;    12'd185: toneR = `hgP;
                12'd186: toneR = `hgP;    12'd187: toneR = `hgP; // G#

                12'd188: toneR = `hbM;    12'd189: toneR = `hbM;
                12'd190: toneR = `hbM;    12'd191: toneR = `hbM; // A#
                
                // --- Measure 4 ---
                12'd192: toneR = `hb;     12'd193: toneR = `hb;
                12'd194: toneR = `hb;     12'd195: toneR = `hb;
                12'd196: toneR = `hb;     12'd197: toneR = `hb;
                12'd198: toneR = `hb;     12'd199: toneR = `hb;
                12'd200: toneR = `hb;     12'd201: toneR = `hb;
                12'd202: toneR = `hb;     12'd203: toneR = `hb; // B
                
                12'd204: toneR = `hbM;     12'd205: toneR = `hbM;
                12'd206: toneR = `hbM;     12'd207: toneR = `hbM; // A#

                12'd208: toneR = `hb;     12'd209: toneR = `hb;
                12'd210: toneR = `hb;     12'd211: toneR = `hb;
                12'd212: toneR = `hb;     12'd213: toneR = `hb;
                12'd214: toneR = `hb;     12'd215: toneR = `hb;                
                12'd216: toneR = `hb;     12'd217: toneR = `hb;
                12'd218: toneR = `hb;     12'd219: toneR = `hb; // B

                12'd220: toneR = `hbM;     12'd221: toneR = `hbM;
                12'd222: toneR = `hbM;     12'd223: toneR = `hbM; // A#

                12'd224: toneR = `hgP;    12'd225: toneR = `hgP;
                12'd226: toneR = `hgP;    12'd227: toneR = `hgP;
                12'd228: toneR = `hgP;    12'd229: toneR = `hgP;
                12'd230: toneR = `hgP;    12'd231: toneR = `hgP;
                12'd232: toneR = `hgP;    12'd233: toneR = `hgP;
                12'd234: toneR = `hgP;    12'd235: toneR = `hgP;                
                12'd236: toneR = `hgP;    12'd237: toneR = `hgP;
                12'd238: toneR = `hgP;    12'd239: toneR = `hgP;
                12'd240: toneR = `hgP;    12'd241: toneR = `hgP;
                12'd242: toneR = `hgP;    12'd243: toneR = `hgP;
                12'd244: toneR = `hgP;    12'd245: toneR = `hgP;
                12'd246: toneR = `hgP;    12'd247: toneR = `hgP;                
                12'd248: toneR = `hgP;    12'd249: toneR = `hgP;
                12'd250: toneR = `hgP;    12'd251: toneR = `hgP; // G#

                12'd252: toneR = `hbM;    12'd253: toneR = `hbM;
                12'd254: toneR = `hbM;    12'd255: toneR = `hbM; // A#
                
                // --- Measure 5---
                12'd256: toneR = `hb;     12'd257: toneR = `hb;
                12'd258: toneR = `hb;     12'd259: toneR = `hb;
                12'd260: toneR = `hb;     12'd261: toneR = `hb;
                12'd262: toneR = `hb;     12'd263: toneR = `hb;
                12'd264: toneR = `hb;     12'd265: toneR = `hb;
                12'd266: toneR = `hb;     12'd267: toneR = `hb;
                12'd268: toneR = `hb;     12'd269: toneR = `hb;
                12'd270: toneR = `hb;     12'd271: toneR = `hb; // B

                12'd272: toneR = `hfP;     12'd273: toneR = `hfP;
                12'd274: toneR = `hfP;     12'd275: toneR = `hfP;
                12'd276: toneR = `hfP;     12'd277: toneR = `hfP;
                12'd278: toneR = `hfP;     12'd279: toneR = `hfP;                
                12'd280: toneR = `hfP;     12'd281: toneR = `hfP;
                12'd282: toneR = `hfP;     12'd283: toneR = `hfP;
                12'd284: toneR = `hfP;     12'd285: toneR = `hfP;
                12'd286: toneR = `hfP;     12'd287: toneR = `hfP; // F#

                12'd288: toneR = `hb;    12'd289: toneR = `hb;
                12'd290: toneR = `hb;    12'd291: toneR = `hb;
                12'd292: toneR = `hb;    12'd293: toneR = `hb;
                12'd294: toneR = `hb;    12'd295: toneR = `hb;
                12'd296: toneR = `hb;    12'd297: toneR = `hb;
                12'd298: toneR = `hb;    12'd299: toneR = `hb;
                12'd300: toneR = `hb;    12'd301: toneR = `hb;
                12'd302: toneR = `hb;    12'd303: toneR = `hb; // B

                12'd304: toneR = `hhcP;    12'd305: toneR = `hhcP;
                12'd306: toneR = `hhcP;    12'd307: toneR = `hhcP;
                12'd308: toneR = `hhcP;    12'd309: toneR = `hhcP;
                12'd310: toneR = `hhcP;    12'd311: toneR = `hhcP;                
                12'd312: toneR = `hhcP;    12'd313: toneR = `hhcP;
                12'd314: toneR = `hhcP;    12'd315: toneR = `hhcP;                
                12'd316: toneR = `hhcP;    12'd317: toneR = `hhcP;
                12'd318: toneR = `hhcP;    12'd319: toneR = `hhcP; // hC#
                
                // --- Measure 6 ---
                12'd320: toneR = `hbM;     12'd321: toneR = `hbM;
                12'd322: toneR = `hbM;     12'd323: toneR = `hbM;
                12'd324: toneR = `hbM;     12'd325: toneR = `hbM;
                12'd326: toneR = `hbM;     12'd327: toneR = `hbM;
                12'd328: toneR = `hbM;     12'd329: toneR = `hbM;
                12'd330: toneR = `hbM;     12'd331: toneR = `hbM;                
                12'd332: toneR = `hbM;     12'd333: toneR = `hbM;
                12'd334: toneR = `hbM;     12'd335: toneR = `hbM; // Bb
                
                12'd336: toneR = `hgP;     12'd337: toneR = `hgP;
                12'd338: toneR = `hgP;     12'd339: toneR = `hgP;
                12'd340: toneR = `hgP;     12'd341: toneR = `hgP;
                12'd342: toneR = `hgP;     12'd343: toneR = `hgP;                
                12'd344: toneR = `hgP;     12'd345: toneR = `hgP;
                12'd346: toneR = `hgP;     12'd347: toneR = `hgP;
                12'd348: toneR = `hgP;     12'd349: toneR = `hgP;
                12'd350: toneR = `hgP;     12'd351: toneR = `hgP; // G#

                12'd352: toneR = `hg;    12'd353: toneR = `hg;
                12'd354: toneR = `hg;    12'd355: toneR = `hg;
                12'd356: toneR = `hg;    12'd357: toneR = `hg;
                12'd358: toneR = `hg;    12'd359: toneR = `hg;
                12'd360: toneR = `hg;    12'd361: toneR = `hg;
                12'd362: toneR = `hg;    12'd363: toneR = `hg;                
                12'd364: toneR = `hg;    12'd365: toneR = `hg;
                12'd366: toneR = `hg;    12'd367: toneR = `hg; // G

                12'd368: toneR = `hbM;    12'd369: toneR = `hbM;
                12'd370: toneR = `hbM;    12'd371: toneR = `hbM;
                12'd372: toneR = `hbM;    12'd373: toneR = `hbM;
                12'd374: toneR = `hbM;    12'd375: toneR = `hbM;                
                12'd376: toneR = `hbM;    12'd377: toneR = `hbM;
                12'd378: toneR = `hbM;    12'd379: toneR = `hbM;
                12'd380: toneR = `hbM;    12'd381: toneR = `hbM;
                12'd382: toneR = `hbM;    12'd383: toneR = `hbM; // Bb
                
                // --- Measure 7 ---
                12'd384: toneR = `hgP;     12'd385: toneR = `hgP;
                12'd386: toneR = `hgP;     12'd387: toneR = `hgP;
                12'd388: toneR = `hgP;     12'd389: toneR = `hgP;
                12'd390: toneR = `hgP;     12'd391: toneR = `hgP;
                12'd392: toneR = `hgP;     12'd393: toneR = `hgP;
                12'd394: toneR = `hgP;     12'd395: toneR = `hgP;
                12'd396: toneR = `hgP;     12'd397: toneR = `hgP;
                12'd398: toneR = `hgP;     12'd399: toneR = `hgP;                
                12'd400: toneR = `hgP;     12'd401: toneR = `hgP;
                12'd402: toneR = `hgP;     12'd403: toneR = `hgP;
                12'd404: toneR = `hgP;     12'd405: toneR = `hgP;
                12'd406: toneR = `hgP;     12'd407: toneR = `hgP;                
                12'd408: toneR = `hgP;     12'd409: toneR = `hgP;
                12'd410: toneR = `hgP;     12'd411: toneR = `hgP;
                12'd412: toneR = `hgP;     12'd413: toneR = `hgP;
                12'd414: toneR = `hgP;     12'd415: toneR = `hgP; // G#

                12'd416: toneR = `sil;    12'd417: toneR = `sil;
                12'd418: toneR = `sil;    12'd419: toneR = `sil;
                12'd420: toneR = `sil;    12'd421: toneR = `sil;
                12'd422: toneR = `sil;    12'd423: toneR = `sil;
                12'd424: toneR = `sil;    12'd425: toneR = `sil;
                12'd426: toneR = `sil;    12'd427: toneR = `sil;
                12'd428: toneR = `sil;    12'd429: toneR = `sil;
                12'd430: toneR = `sil;    12'd431: toneR = `sil;
                12'd432: toneR = `sil;    12'd433: toneR = `sil;
                12'd434: toneR = `sil;    12'd435: toneR = `sil;
                12'd436: toneR = `sil;    12'd437: toneR = `sil;
                12'd438: toneR = `sil;    12'd439: toneR = `sil;                
                12'd440: toneR = `sil;    12'd441: toneR = `sil;
                12'd442: toneR = `sil;    12'd443: toneR = `sil;
                12'd444: toneR = `sil;    12'd445: toneR = `sil;
                12'd446: toneR = `sil;    12'd447: toneR = `sil; // pause
                
                // --- Measure 8 ---
                12'd448: toneR = `he;     12'd449: toneR = `he;
                12'd450: toneR = `he;     12'd451: toneR = `he;
                12'd452: toneR = `he;     12'd453: toneR = `he;
                12'd454: toneR = `he;     12'd455: toneR = `he;
                12'd456: toneR = `he;     12'd457: toneR = `he;
                12'd458: toneR = `he;     12'd459: toneR = `he;                
                12'd460: toneR = `he;     12'd461: toneR = `he;
                12'd462: toneR = `he;     12'd463: toneR = `he; // E
                
                12'd464: toneR = `heM;     12'd465: toneR = `heM;
                12'd466: toneR = `heM;     12'd467: toneR = `heM;
                12'd468: toneR = `heM;     12'd469: toneR = `heM;
                12'd470: toneR = `heM;     12'd471: toneR = `heM;                
                12'd472: toneR = `heM;     12'd473: toneR = `heM;
                12'd474: toneR = `heM;     12'd475: toneR = `heM;
                12'd476: toneR = `heM;     12'd477: toneR = `heM;
                12'd478: toneR = `heM;     12'd479: toneR = `heM; // D#

                12'd480: toneR = `hcP;    12'd481: toneR = `hcP;
                12'd482: toneR = `hcP;    12'd483: toneR = `hcP;
                12'd484: toneR = `hcP;    12'd485: toneR = `hcP;
                12'd486: toneR = `hcP;    12'd487: toneR = `hcP;
                12'd488: toneR = `hcP;    12'd489: toneR = `hcP;
                12'd490: toneR = `hcP;    12'd491: toneR = `hcP;                
                12'd492: toneR = `hcP;    12'd493: toneR = `hcP;
                12'd494: toneR = `hcP;    12'd495: toneR = `hcP; // C#

                12'd496: toneR = `b;    12'd497: toneR = `b;
                12'd498: toneR = `b;    12'd499: toneR = `b;
                12'd500: toneR = `b;    12'd501: toneR = `b;
                12'd502: toneR = `b;    12'd503: toneR = `b;                
                12'd504: toneR = `b;    12'd505: toneR = `b;
                12'd506: toneR = `b;    12'd507: toneR = `b;
                12'd508: toneR = `b;    12'd509: toneR = `b;
                12'd510: toneR = `b;    12'd511: toneR = `sil; // low B
                
                default: toneR = `sil;
            endcase
        end else begin
            toneR = `sil;
        end
    end

    always @(*) begin
        if(en == 1)begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneL = `llb;  	12'd1: toneL = `llb;
                12'd2: toneL = `llb;  	12'd3: toneL = `llb;
                12'd4: toneL = `llb;	12'd5: toneL = `llb;
                12'd6: toneL = `llb;  	12'd7: toneL = `llb;
                12'd8: toneL = `llb;	12'd9: toneL = `llb;
                12'd10: toneL = `llb;	12'd11: toneL = `llb; // B

                12'd12: toneL = `lfP;	12'd13: toneL = `lfP;
                12'd14: toneL = `lfP;	12'd15: toneL = `lfP; // F#

                12'd16: toneL = `leM;	12'd17: toneL = `leM;
                12'd18: toneL = `leM;	12'd19: toneL = `leM;
                12'd20: toneL = `leM;	12'd21: toneL = `leM;
                12'd22: toneL = `leM;	12'd23: toneL = `leM;                
                12'd24: toneL = `leM;	12'd25: toneL = `leM;
                12'd26: toneL = `leM;	12'd27: toneL = `leM; // D#

                12'd28: toneL = `lfP;	12'd29: toneL = `lfP;
                12'd30: toneL = `lfP;	12'd31: toneL = `lfP; // F#

                12'd32: toneL = `llb;	    12'd33: toneL = `llb;
                12'd34: toneL = `llb;	    12'd35: toneL = `llb;
                12'd36: toneL = `llb;	    12'd37: toneL = `llb;
                12'd38: toneL = `llb;	    12'd39: toneL = `llb;
                12'd40: toneL = `llb;	    12'd41: toneL = `llb;
                12'd42: toneL = `llb;	    12'd43: toneL = `llb; // B

                12'd44: toneL = `lfP;	    12'd45: toneL = `lfP;
                12'd46: toneL = `lfP;	    12'd47: toneL = `lfP; // F#

                12'd48: toneL = `leM;	    12'd49: toneL = `leM;
                12'd50: toneL = `leM;	    12'd51: toneL = `leM;
                12'd52: toneL = `leM;	    12'd53: toneL = `leM;
                12'd54: toneL = `leM;	    12'd55: toneL = `leM;
                12'd56: toneL = `leM;	    12'd57: toneL = `leM;
                12'd58: toneL = `leM;	    12'd59: toneL = `leM; // D#

                12'd60: toneL = `lfP;	    12'd61: toneL = `lfP;
                12'd62: toneL = `lfP;	    12'd63: toneL = `lfP; // F#

                // --- Measure 2 ---
                12'd64: toneL = `llbM;	 12'd65: toneL = `llbM;
                12'd66: toneL = `llbM;   12'd67: toneL = `llbM;
                12'd68: toneL = `llbM;	 12'd69: toneL = `llbM;
                12'd70: toneL = `llbM;	 12'd71: toneL = `llbM;
                12'd72: toneL = `llbM;	 12'd73: toneL = `llbM;
                12'd74: toneL = `llbM;	 12'd75: toneL = `llbM; // A#

                12'd76: toneL = `lg;	 12'd77: toneL = `lg;
                12'd78: toneL = `lg;	 12'd79: toneL = `lg; // G

                12'd80: toneL = `leM;	 12'd81: toneL = `leM;
                12'd82: toneL = `leM;    12'd83: toneL = `leM;
                12'd84: toneL = `leM;    12'd85: toneL = `leM;
                12'd86: toneL = `leM;    12'd87: toneL = `leM;
                12'd88: toneL = `leM;    12'd89: toneL = `leM;
                12'd90: toneL = `leM;    12'd91: toneL = `leM; // D#

                12'd92: toneL = `lg;    12'd93: toneL = `lg;
                12'd94: toneL = `lg;    12'd95: toneL = `lg; // G

                12'd96: toneL = `llbM;	    12'd97: toneL = `llbM;
                12'd98: toneL = `llbM; 	    12'd99: toneL = `llbM;
                12'd100: toneL = `llbM;	    12'd101: toneL = `llbM;
                12'd102: toneL = `llbM;	    12'd103: toneL = `llbM;
                12'd104: toneL = `llbM;	    12'd105: toneL = `llbM;
                12'd106: toneL = `llbM;	    12'd107: toneL = `llbM; // A#

                12'd108: toneL = `lg;	    12'd109: toneL = `lg;
                12'd110: toneL = `lg;	    12'd111: toneL = `lg; // G

                12'd112: toneL = `leM;	    12'd113: toneL = `leM;
                12'd114: toneL = `leM;	    12'd115: toneL = `leM;
                12'd116: toneL = `leM;	    12'd117: toneL = `leM;
                12'd118: toneL = `leM;	    12'd119: toneL = `leM;
                12'd120: toneL = `leM;	    12'd121: toneL = `leM;
                12'd122: toneL = `leM;	    12'd123: toneL = `leM; // D#

                12'd124: toneL = `lg;	    12'd125: toneL = `lg;                
                12'd126: toneL = `lg;	    12'd127: toneL = `lg; // G
                
                // --- Measure 3 ---
                12'd128: toneL = `llgP;     12'd129: toneL = `llgP;
                12'd130: toneL = `llgP;     12'd131: toneL = `llgP;
                12'd132: toneL = `llgP;     12'd133: toneL = `llgP;
                12'd134: toneL = `llgP;     12'd135: toneL = `llgP;
                12'd136: toneL = `llgP;     12'd137: toneL = `llgP;
                12'd138: toneL = `llgP;     12'd139: toneL = `llgP; // G#

                12'd140: toneL = `leM;     12'd141: toneL = `leM;
                12'd142: toneL = `leM;     12'd143: toneL = `leM; // D#

                12'd144: toneL = `llb;     12'd145: toneL = `llb;
                12'd146: toneL = `llb;     12'd147: toneL = `llb;
                12'd148: toneL = `llb;     12'd149: toneL = `llb;
                12'd150: toneL = `llb;     12'd151: toneL = `llb;                
                12'd152: toneL = `llb;     12'd153: toneL = `llb;
                12'd154: toneL = `llb;     12'd155: toneL = `llb; // B

                12'd156: toneL = `leM;     12'd157: toneL = `leM;
                12'd158: toneL = `leM;     12'd159: toneL = `leM; // D#

                12'd160: toneL = `llgP;    12'd161: toneL = `llgP;
                12'd162: toneL = `llgP;    12'd163: toneL = `llgP;
                12'd164: toneL = `llgP;    12'd165: toneL = `llgP;
                12'd166: toneL = `llgP;    12'd167: toneL = `llgP;
                12'd168: toneL = `llgP;    12'd169: toneL = `llgP;
                12'd170: toneL = `llgP;    12'd171: toneL = `llgP; // G#

                12'd172: toneL = `leM;    12'd173: toneL = `leM;
                12'd174: toneL = `leM;    12'd175: toneL = `leM; // D#

                12'd176: toneL = `llb;    12'd177: toneL = `llb;
                12'd178: toneL = `llb;    12'd179: toneL = `llb;
                12'd180: toneL = `llb;    12'd181: toneL = `llb;
                12'd182: toneL = `llb;    12'd183: toneL = `llb;
                12'd184: toneL = `llb;    12'd185: toneL = `llb;
                12'd186: toneL = `llb;    12'd187: toneL = `llb; // B

                12'd188: toneL = `leM;    12'd189: toneL = `leM;
                12'd190: toneL = `leM;    12'd191: toneL = `leM; // D#
                
                // --- Measure 4 ---
                12'd192: toneL = `lle;     12'd193: toneL = `lle;
                12'd194: toneL = `lle;     12'd195: toneL = `lle;
                12'd196: toneL = `lle;     12'd197: toneL = `lle;
                12'd198: toneL = `lle;     12'd199: toneL = `lle;
                12'd200: toneL = `lle;     12'd201: toneL = `lle;
                12'd202: toneL = `lle;     12'd203: toneL = `lle; // E

                12'd204: toneL = `llb;     12'd205: toneL = `llb;
                12'd206: toneL = `llb;     12'd207: toneL = `llb; // B

                12'd208: toneL = `llgP;     12'd209: toneL = `llgP;
                12'd210: toneL = `llgP;     12'd211: toneL = `llgP;
                12'd212: toneL = `llgP;     12'd213: toneL = `llgP;
                12'd214: toneL = `llgP;     12'd215: toneL = `llgP;
                12'd216: toneL = `llgP;     12'd217: toneL = `llgP;
                12'd218: toneL = `llgP;     12'd219: toneL = `llgP; // G#

                12'd220: toneL = `llb;     12'd221: toneL = `llb;
                12'd222: toneL = `llb;     12'd223: toneL = `llb; // B

                12'd224: toneL = `lle;    12'd225: toneL = `lle;
                12'd226: toneL = `lle;    12'd227: toneL = `lle;
                12'd228: toneL = `lle;    12'd229: toneL = `lle;
                12'd230: toneL = `lle;    12'd231: toneL = `lle;
                12'd232: toneL = `lle;    12'd233: toneL = `lle;
                12'd234: toneL = `lle;    12'd235: toneL = `lle; // E

                12'd236: toneL = `llb;    12'd237: toneL = `llb;
                12'd238: toneL = `llb;    12'd239: toneL = `llb; // B

                12'd240: toneL = `llgP;    12'd241: toneL = `llgP;
                12'd242: toneL = `llgP;    12'd243: toneL = `llgP;
                12'd244: toneL = `llgP;    12'd245: toneL = `llgP;
                12'd246: toneL = `llgP;    12'd247: toneL = `llgP;
                12'd248: toneL = `llgP;    12'd249: toneL = `llgP;
                12'd250: toneL = `llgP;    12'd251: toneL = `llgP; // G#

                12'd252: toneL = `llb;    12'd253: toneL = `llb;
                12'd254: toneL = `llb;    12'd255: toneL = `llb; // B
                
                // --- Measure 5---
                12'd256: toneL = `llb;     12'd257: toneL = `llb;
                12'd258: toneL = `llb;     12'd259: toneL = `llb;
                12'd260: toneL = `llb;     12'd261: toneL = `llb;
                12'd262: toneL = `llb;     12'd263: toneL = `llb;
                12'd264: toneL = `llb;     12'd265: toneL = `llb;
                12'd266: toneL = `llb;     12'd267: toneL = `llb; // B

                12'd268: toneL = `lfP;     12'd269: toneL = `lfP;
                12'd270: toneL = `lfP;     12'd271: toneL = `lfP; // F#
                
                12'd272: toneL = `leM;     12'd273: toneL = `leM;
                12'd274: toneL = `leM;     12'd275: toneL = `leM;
                12'd276: toneL = `leM;     12'd277: toneL = `leM;
                12'd278: toneL = `leM;     12'd279: toneL = `leM;                
                12'd280: toneL = `leM;     12'd281: toneL = `leM;
                12'd282: toneL = `leM;     12'd283: toneL = `leM; // D#

                12'd284: toneL = `lfP;     12'd285: toneL = `lfP;
                12'd286: toneL = `lfP;     12'd287: toneL = `lfP; // F#

                12'd288: toneL = `llb;    12'd289: toneL = `llb;
                12'd290: toneL = `llb;    12'd291: toneL = `llb;
                12'd292: toneL = `llb;    12'd293: toneL = `llb;
                12'd294: toneL = `llb;    12'd295: toneL = `llb;
                12'd296: toneL = `llb;    12'd297: toneL = `llb;
                12'd298: toneL = `llb;    12'd299: toneL = `llb; // B

                12'd300: toneL = `lfP;    12'd301: toneL = `lfP;
                12'd302: toneL = `lfP;    12'd303: toneL = `lfP; // F#

                12'd304: toneL = `leM;    12'd305: toneL = `leM;
                12'd306: toneL = `leM;    12'd307: toneL = `leM;
                12'd308: toneL = `leM;    12'd309: toneL = `leM;
                12'd310: toneL = `leM;    12'd311: toneL = `leM;
                12'd312: toneL = `leM;    12'd313: toneL = `leM;
                12'd314: toneL = `leM;    12'd315: toneL = `leM; // D#

                12'd316: toneL = `lfP;    12'd317: toneL = `lfP;
                12'd318: toneL = `lfP;    12'd319: toneL = `lfP; // F#
                
                // --- Measure 6 ---
                12'd320: toneL = `llbM;     12'd321: toneL = `llbM;
                12'd322: toneL = `llbM;     12'd323: toneL = `llbM;
                12'd324: toneL = `llbM;     12'd325: toneL = `llbM;
                12'd326: toneL = `llbM;     12'd327: toneL = `llbM;
                12'd328: toneL = `llbM;     12'd329: toneL = `llbM;
                12'd330: toneL = `llbM;     12'd331: toneL = `llbM; // A#

                12'd332: toneL = `lg;     12'd333: toneL = `lg;
                12'd334: toneL = `lg;     12'd335: toneL = `lg; // G
                
                12'd336: toneL = `leM;     12'd337: toneL = `leM;
                12'd338: toneL = `leM;     12'd339: toneL = `leM;
                12'd340: toneL = `leM;     12'd341: toneL = `leM;
                12'd342: toneL = `leM;     12'd343: toneL = `leM;
                12'd344: toneL = `leM;     12'd345: toneL = `leM;
                12'd346: toneL = `leM;     12'd347: toneL = `leM; // D#

                12'd348: toneL = `lg;     12'd349: toneL = `lg;
                12'd350: toneL = `lg;     12'd351: toneL = `lg; // G

                12'd352: toneL = `llbM;    12'd353: toneL = `llbM;
                12'd354: toneL = `llbM;    12'd355: toneL = `llbM;
                12'd356: toneL = `llbM;    12'd357: toneL = `llbM;
                12'd358: toneL = `llbM;    12'd359: toneL = `llbM;
                12'd360: toneL = `llbM;    12'd361: toneL = `llbM;
                12'd362: toneL = `llbM;    12'd363: toneL = `llbM; // A#

                12'd364: toneL = `lg;    12'd365: toneL = `lg;
                12'd366: toneL = `lg;    12'd367: toneL = `lg; // G

                12'd368: toneL = `leM;    12'd369: toneL = `leM;
                12'd370: toneL = `leM;    12'd371: toneL = `leM;
                12'd372: toneL = `leM;    12'd373: toneL = `leM;
                12'd374: toneL = `leM;    12'd375: toneL = `leM;
                12'd376: toneL = `leM;    12'd377: toneL = `leM;
                12'd378: toneL = `leM;    12'd379: toneL = `leM; // D#

                12'd380: toneL = `lg;    12'd381: toneL = `lg;
                12'd382: toneL = `lg;    12'd383: toneL = `lg; // G
                
                // --- Measure 7 ---
                12'd384: toneL = `llgP;     12'd385: toneL = `llgP;
                12'd386: toneL = `llgP;     12'd387: toneL = `llgP;
                12'd388: toneL = `llgP;     12'd389: toneL = `llgP;
                12'd390: toneL = `llgP;     12'd391: toneL = `llgP;
                12'd392: toneL = `llgP;     12'd393: toneL = `llgP;
                12'd394: toneL = `llgP;     12'd395: toneL = `llgP; // G#

                12'd396: toneL = `leM;     12'd397: toneL = `leM;
                12'd398: toneL = `leM;     12'd399: toneL = `leM; // D#
                
                12'd400: toneL = `llb;     12'd401: toneL = `llb;
                12'd402: toneL = `llb;     12'd403: toneL = `llb;
                12'd404: toneL = `llb;     12'd405: toneL = `llb;
                12'd406: toneL = `llb;     12'd407: toneL = `llb;                
                12'd408: toneL = `llb;     12'd409: toneL = `llb;
                12'd410: toneL = `llb;     12'd411: toneL = `llb; // B

                12'd412: toneL = `leM;     12'd413: toneL = `leM;
                12'd414: toneL = `leM;     12'd415: toneL = `leM; // D#

                12'd416: toneL = `llgP;    12'd417: toneL = `llgP;
                12'd418: toneL = `llgP;    12'd419: toneL = `llgP;
                12'd420: toneL = `llgP;    12'd421: toneL = `llgP;
                12'd422: toneL = `llgP;    12'd423: toneL = `llgP;
                12'd424: toneL = `llgP;    12'd425: toneL = `llgP;
                12'd426: toneL = `llgP;    12'd427: toneL = `llgP; // G#

                12'd428: toneL = `leM;    12'd429: toneL = `leM;
                12'd430: toneL = `leM;    12'd431: toneL = `leM; // D#

                12'd432: toneL = `llb;    12'd433: toneL = `llb;
                12'd434: toneL = `llb;    12'd435: toneL = `llb;
                12'd436: toneL = `llb;    12'd437: toneL = `llb;
                12'd438: toneL = `llb;    12'd439: toneL = `llb;                
                12'd440: toneL = `llb;    12'd441: toneL = `llb;
                12'd442: toneL = `llb;    12'd443: toneL = `llb; // B

                12'd444: toneL = `leM;    12'd445: toneL = `leM;
                12'd446: toneL = `leM;    12'd447: toneL = `leM; // D#
                
                // --- Measure 8 ---
                12'd448: toneL = `lle;     12'd449: toneL = `lle;
                12'd450: toneL = `lle;     12'd451: toneL = `lle;
                12'd452: toneL = `lle;     12'd453: toneL = `lle;
                12'd454: toneL = `lle;     12'd455: toneL = `lle;
                12'd456: toneL = `lle;     12'd457: toneL = `lle;
                12'd458: toneL = `lle;     12'd459: toneL = `lle;
                12'd460: toneL = `lle;     12'd461: toneL = `lle;
                12'd462: toneL = `lle;     12'd463: toneL = `lle; // E
                
                12'd464: toneL = `llgP;     12'd465: toneL = `llgP;
                12'd466: toneL = `llgP;     12'd467: toneL = `llgP;
                12'd468: toneL = `llgP;     12'd469: toneL = `llgP;
                12'd470: toneL = `llgP;     12'd471: toneL = `llgP;
                12'd472: toneL = `llgP;     12'd473: toneL = `llgP;
                12'd474: toneL = `llgP;     12'd475: toneL = `llgP;
                12'd476: toneL = `llgP;     12'd477: toneL = `llgP;
                12'd478: toneL = `llgP;     12'd479: toneL = `llgP; // G#

                12'd480: toneL = `llb;    12'd481: toneL = `llb;
                12'd482: toneL = `llb;    12'd483: toneL = `llb;
                12'd484: toneL = `llb;    12'd485: toneL = `llb;
                12'd486: toneL = `llb;    12'd487: toneL = `llb;
                12'd488: toneL = `llb;    12'd489: toneL = `llb;
                12'd490: toneL = `llb;    12'd491: toneL = `llb;
                12'd492: toneL = `llb;    12'd493: toneL = `llb;
                12'd494: toneL = `llb;    12'd495: toneL = `llb; // B
                
                12'd496: toneL = `le;    12'd497: toneL = `le;
                12'd498: toneL = `le;    12'd499: toneL = `le;
                12'd500: toneL = `le;    12'd501: toneL = `le;
                12'd502: toneL = `le;    12'd503: toneL = `le;
                12'd504: toneL = `le;    12'd505: toneL = `le;
                12'd506: toneL = `le;    12'd507: toneL = `le;
                12'd508: toneL = `le;    12'd509: toneL = `le;
                12'd510: toneL = `le;    12'd511: toneL = `le; // (high) E
				
                default : toneL = `sil;
            endcase
        end
        else begin
            toneL = `sil;
        end
    end
endmodule

module speaker_control(
    input clk,  // clock from the crystal
    input rst,  // active high reset
    input [15:0] audio_in_left, // left channel audio data input
    input [15:0] audio_in_right, // right channel audio data input
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    output audio_sck, // serial clock
    output reg audio_sdin // serial audio data input
    ); 

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1]; //25MHz
    assign audio_lrck = clk_cnt[8]; //100MHz/512 = 25MHz/128
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    //Control the left and right channel audio data input
    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

endmodule