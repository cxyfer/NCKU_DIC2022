`timescale 1ns/10ps

module ELA(clk, rst, ready, in_data, data_rd, req, wen, addr, data_wr, done);

	input				clk;
	input				rst;
	input				ready;
	input		[7:0]	in_data;
	input		[7:0]	data_rd; //Result Image Memory reaf data signal,
	output reg			req;
	output reg			wen; //Result Image Memory write enable signal
	output reg	[12:0]	addr; //Result Image Memory reaf/write address
	output reg	[7:0]	data_wr; //Result Image Memory write data signal
	output reg			done;


	/*-------------------------------------/
	/		Write your code here~		   /
	/-------------------------------------*/

/*
	1. Input first row, and write to Memory (INPUT_FIRST)
	2. Input next row, and write to Memory (INPUT_ROW)
	3. Calculate interpolation row, and write to Memory (CALC)
	4. Shift data array (SHIFT)
	5. Repeat 2~5, until process all 31 line (FINISH)
*/

parameter [2:0] INIT=0, INPUT_FIRST=1, REQ=2, INPUT_ROW=3, CALC=4, SHIFT=5, FINISH=6;
reg[2:0] State, NextState;

reg [7:0] data [0:255]; //128*2=256
reg [13:0] memCnt;
reg [6:0] rowCnt; //2^7=128

integer i;

// Calculate
wire [8:0] af, be, cd;
wire [8:0] cmp1, cmp2;
wire [9:0] calTmp;
wire [8:0] calVal;

/*
// HW4
assign af = (rowCnt>0 && rowCnt<127)? ((data[rowCnt-1]>=data[rowCnt+129])? data[rowCnt-1]-data[rowCnt+129]: data[rowCnt+129]-data[rowCnt-1]): 255;
assign be = (data[rowCnt]>=data[rowCnt+128])? data[rowCnt]-data[rowCnt+128]: data[rowCnt+128]-data[rowCnt];
assign cd = (rowCnt>0 && rowCnt<127)? ((data[rowCnt+1]>=data[rowCnt+127])? data[rowCnt+1]-data[rowCnt+127]: data[rowCnt+127]-data[rowCnt+1]): 255;
assign cmp1 = (af<be)? af: be;
assign cmp2 = (cmp1<cd)? cmp1: cd;
//Priorty: be > af > cd 23.7585
assign calTmp = (cmp2==be)? data[rowCnt]+data[rowCnt+128]: ((cmp2==af)? data[rowCnt-1]+data[rowCnt+129]: data[rowCnt+1]+data[rowCnt+127]) ;
assign calVal = calTmp[8:1];
*/


// https://sci-hub.se/10.1117/1.1305262
assign af = (rowCnt>0 && rowCnt<127)? ((data[rowCnt-1]>=data[rowCnt+129])? data[rowCnt-1]-data[rowCnt+129]: data[rowCnt+129]-data[rowCnt-1]): 255;
assign be = (data[rowCnt]>=data[rowCnt+128])? data[rowCnt]-data[rowCnt+128]: data[rowCnt+128]-data[rowCnt];
assign cd = (rowCnt>0 && rowCnt<127)? ((data[rowCnt+1]>=data[rowCnt+127])? data[rowCnt+1]-data[rowCnt+127]: data[rowCnt+127]-data[rowCnt+1]): 255;
assign cmp1 = (af<be)? af: be;
assign cmp2 = (cmp1<cd)? cmp1: cd;
wire [7:0] p1, p2, q1, q2;
wire [8:0] P, Q, GTR, EQL, LSS;
assign p1 = (rowCnt>0)? ((data[rowCnt-1]>=data[rowCnt+128])? data[rowCnt-1]-data[rowCnt+128]: data[rowCnt+128]-data[rowCnt-1]): 0;
assign p2 = (rowCnt<127)? ((data[rowCnt]>=data[rowCnt+129])? data[rowCnt]-data[rowCnt+129]: data[rowCnt+129]-data[rowCnt]): 0;
assign q1 = (rowCnt>0)? ((data[rowCnt+1]>=data[rowCnt+128])? data[rowCnt+1]-data[rowCnt+128]: data[rowCnt+128]-data[rowCnt+1]): 0;
assign q2 = (rowCnt<127)? ((data[rowCnt]>=data[rowCnt+127])? data[rowCnt]-data[rowCnt+127]: data[rowCnt+127]-data[rowCnt]): 0;
assign P = p1 + p2;
assign Q = q1 + q2;
assign GTR = (be<cd)? data[rowCnt]+data[rowCnt+128]: data[rowCnt+1]+data[rowCnt+127];
assign EQL = (cmp2==be)? data[rowCnt]+data[rowCnt+128]: ((cmp2==af)? data[rowCnt-1]+data[rowCnt+129]: data[rowCnt+1]+data[rowCnt+127]) ;
assign LSS = (be<af)? data[rowCnt]+data[rowCnt+128]: data[rowCnt-1]+data[rowCnt+129];
assign calTmp = (P==Q)? EQL: ((P>Q)? GTR: LSS);
assign calVal = calTmp[8:1];

/*
// a b c d e
// f g h i j
wire [7:0] aj, bi, ch, dg, ef;
wire [7:0] cmp1, cmp2, cmp3, cmp4;
wire [8:0] calTmp;
wire [7:0] calVal;

assign aj = (rowCnt>1 && rowCnt<126)? ((data[rowCnt-2]>=data[rowCnt+130])? data[rowCnt-2]-data[rowCnt+130]: data[rowCnt+130]-data[rowCnt-2]): 255;
assign bi = (rowCnt>0 && rowCnt<127)? ((data[rowCnt-1]>=data[rowCnt+129])? data[rowCnt-1]-data[rowCnt+129]: data[rowCnt+129]-data[rowCnt-1]): 255;
assign ch = (data[rowCnt]>=data[rowCnt+128])? data[rowCnt]-data[rowCnt+128]: data[rowCnt+128]-data[rowCnt];
assign dg = (rowCnt>0 && rowCnt<127)? ((data[rowCnt+1]>=data[rowCnt+127])? data[rowCnt+1]-data[rowCnt+127]: data[rowCnt+127]-data[rowCnt+1]): 255;
assign ef = (rowCnt>1 && rowCnt<126)? ((data[rowCnt+2]>=data[rowCnt+126])? data[rowCnt+2]-data[rowCnt+126]: data[rowCnt+126]-data[rowCnt+2]): 255;
assign cmp1 = (aj<bi)? aj: bi;
assign cmp2 = (dg<ef)? dg: ef;
assign cmp3 = (cmp1<ch)? cmp1: ch;
assign cmp4 = (cmp3<cmp2)? cmp3: cmp2;
//Priorty: ch > bi > dg > aj > ef 
assign calTmp = (cmp4==ch)? data[rowCnt]+data[rowCnt+128]: ((cmp4==bi)? data[rowCnt-1]+data[rowCnt+129]: ((cmp4==dg)? data[rowCnt+1]+data[rowCnt+127]: ((cmp4==bi)? data[rowCnt-1]+data[rowCnt+129]: ((cmp4==aj)? data[rowCnt-2]+data[rowCnt+130]: data[rowCnt+2]+data[rowCnt+126])))) ;
assign calVal = calTmp[8:1];
*/

// State reg
always @(posedge clk or posedge rst) begin
	if(rst) State <= INIT;
	else State <= NextState;
end

always @(posedge clk or posedge rst) begin
	if(rst) begin
		memCnt <= 0;
		rowCnt <= 0;
		for (i=0; i<256; i=i+1) begin
			data[i] <= 0;
		end
		req <= 1'b0;
		wen <= 1'b0;
		addr <= 0 ;
		data_wr <= 0;
		done <= 1'b0;
	end
	else begin
		case(State)
			INIT: begin
				req <= (ready == 1)? 1'b1: 1'b0;
			end
			INPUT_FIRST: begin
				rowCnt <= (rowCnt == 127)? 0: rowCnt+1;
				memCnt <= (rowCnt == 127)? memCnt+129: memCnt+1;
				data[rowCnt] <= in_data;
				//req <= (rowCnt == 31)? 1: 0;
				req <= 0;
				wen <= 1;
				addr <= memCnt;
				data_wr <= in_data;
				//$display("INPUT_FIST: %d %d %h", rowCnt, memCnt, in_data);
			end
			REQ: begin
				req <= (ready == 1)? 1'b1: 1'b0;
			end
			INPUT_ROW: begin
				rowCnt <= (rowCnt == 127)? 0: rowCnt+1;
				memCnt <= (rowCnt == 127)? memCnt-255: memCnt+1;
				data[rowCnt+128] <= in_data;
				req <= 0;
				wen <= 1;
				addr <= memCnt;
				data_wr <= in_data;
				//$display("INPUT: %d %h", memCnt, in_data);
			end
			CALC: begin
				rowCnt <= (rowCnt == 127)? 0: rowCnt+1;
				memCnt <= (rowCnt == 127)? memCnt+257: memCnt+1;
				req <= 0;
				wen <= 1;
				addr <= memCnt;
				data_wr <= calVal;
				//$display("CALC: %d %h", memCnt, calVal);
			end
			SHIFT: begin
				for (i=0;i<128;i=i+1) begin
					data[i] <= data[i+128];
				end
				for (i=128;i<256;i=i+1) begin
					data[i] <= 0;
				end
				//req <= 1;
			end
			FINISH: begin
				done <= 1'b1;
			end
			default: begin
				req <= 1'b0;
				wen <= 1'b0;
				done <= 1'b0;
			end
		endcase
	end
end

//Next State Logic
always@(*) begin
	case(State)
		INIT: begin
			NextState = (ready == 1)? INPUT_FIRST: INIT;
		end
		INPUT_FIRST: begin
			NextState = (rowCnt == 127)? REQ: INPUT_FIRST;
		end
		REQ: begin
			NextState = (ready == 1)? INPUT_ROW: REQ;
		end
		INPUT_ROW: begin
			NextState = (rowCnt == 127)? CALC: INPUT_ROW;
		end
		CALC: begin
			NextState = (rowCnt == 127)? SHIFT: CALC;
		end
		SHIFT: begin
			NextState = (memCnt>=8192)? FINISH: REQ;
		end
		FINISH: begin
			NextState = FINISH;
		end
		default: begin
			NextState = State;
		end
	endcase
end

endmodule