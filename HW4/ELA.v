`timescale 1ns/10ps

module ELA(clk, rst, in_data, data_rd, req, wen, addr, data_wr, done);

	input				clk;
	input				rst;
	input		[7:0]	in_data;
	input		[7:0]	data_rd; //Result Image Memory reaf data signal,
	output reg			req; 
	output reg 			wen; //Result Image Memory write enable signal
	output reg	[9:0]	addr; //Result Image Memory reaf/write address
	output reg	[7:0]	data_wr; //Result Image Memory write data signal
	output reg			done;


	//--------------------------------------
	//		Write your code here
	//--------------------------------------

/*
	1. Input first row, and write to Memory (INPUT_FIRST)
	2. Input next row, and write to Memory (INPUT_ROW)
	3. Calculate interpolation row, and write to Memory (CALC)
	4. Shift data array (SHIFT)
	5. Repeat 2~5, until process all 31 line (FINISH)
*/

parameter [2:0] INIT=0, INPUT_FIRST=1, REQ=2, INPUT_ROW=3, CALC=4, SHIFT=5, FINISH=6;
reg[2:0] State, NextState;

reg [7:0] data[0:63]; //32*2=64
reg [10:0] memCnt;
reg [4:0] rowCnt;

integer i;

// Calculate
wire [7:0] af, be, cd;
wire [7:0] cmp1, cmp2;
wire [8:0] calTmp;
wire [7:0] calVal;

assign af = (rowCnt>0 && rowCnt<31)? ((data[rowCnt-1]>=data[rowCnt+33])? data[rowCnt-1]-data[rowCnt+33]: data[rowCnt+33]-data[rowCnt-1]): 255;
assign be = (data[rowCnt]>=data[rowCnt+32])? data[rowCnt]-data[rowCnt+32]: data[rowCnt+32]-data[rowCnt];
assign cd = (rowCnt>0 && rowCnt<31)? ((data[rowCnt+1]>=data[rowCnt+31])? data[rowCnt+1]-data[rowCnt+31]: data[rowCnt+31]-data[rowCnt+1]): 255;
assign cmp1 = (af<=be)? af: be;
assign cmp2 = (cmp1<=cd)? cmp1: cd;
//Priorty: be > af > cd 
//assign calTmp = (cmp2==af)? data[rowCnt-1]+data[rowCnt+33]: ((cmp2==be)? data[rowCnt]+data[rowCnt+32]: data[rowCnt+1]+data[rowCnt+31]) ;
assign calTmp = (cmp2==be)? data[rowCnt]+data[rowCnt+32]: ((cmp2==af)? data[rowCnt-1]+data[rowCnt+33]: data[rowCnt+1]+data[rowCnt+31]) ;
assign calVal = calTmp[8:1];

// State reg
always @(posedge clk or posedge rst) begin
	if(rst) State <= INIT;
	else State <= NextState;
end

always @(posedge clk or posedge rst) begin
	if(rst) begin
		memCnt <= 0;
		rowCnt <= 0;
		for (i=0; i<64; i=i+1) begin
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
				req <= 1'b1;
			end
			INPUT_FIRST: begin
				rowCnt <= (rowCnt == 31)? 0: rowCnt+1;
				memCnt <= (rowCnt == 31)? memCnt+33: memCnt+1;
				data[rowCnt] <= in_data;
				//req <= (rowCnt == 31)? 1: 0;
				req <= 0;
				wen <= 1;
				addr <= memCnt;
				data_wr <= in_data;
				//$display("INPUT_FIST: %d %d %h", rowCnt, memCnt, in_data);
			end
			REQ: begin
				req <= 1'b1;
			end
			INPUT_ROW: begin
				rowCnt <= (rowCnt == 31)? 0: rowCnt+1;
				memCnt <= (rowCnt == 31)? memCnt-63: memCnt+1;
				data[rowCnt+32] <= in_data;
				req <= 0;
				wen <= 1;
				addr <= memCnt;
				data_wr <= in_data;
				//$display("INPUT: %d %h", memCnt, in_data);
			end
			CALC: begin
				rowCnt <= (rowCnt == 31)? 0: rowCnt+1;
				memCnt <= (rowCnt == 31)? memCnt+65: memCnt+1;
				req <= 0;
				wen <= 1;
				addr <= memCnt;
				data_wr <= calVal;
				//$display("CALC: %d %h", memCnt, calVal);
			end
			SHIFT: begin
				for (i=0;i<32;i=i+1) begin
					data[i] <= data[i+32];
				end
				for (i=32;i<63;i=i+1) begin
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
			NextState = INPUT_FIRST;
		end
		INPUT_FIRST: begin
			NextState = (rowCnt == 31)? REQ: INPUT_FIRST;
		end
		REQ: begin
			NextState = INPUT_ROW;
		end
		INPUT_ROW: begin
			NextState = (rowCnt == 31)? CALC: INPUT_ROW;
		end
		CALC: begin
			NextState = (rowCnt == 31)? SHIFT: CALC;
		end
		SHIFT: begin
			NextState = (memCnt>=1024)? FINISH: REQ;
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