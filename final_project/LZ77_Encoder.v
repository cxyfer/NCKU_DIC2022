module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);
input 				clk;
input 				reset;
input 		[7:0] 	chardata;
output reg 			valid;
output reg 			encode;
output reg 			finish;
output reg 	[4:0] 	offset;
output reg 	[4:0] 	match_len; //0-31 -> 25(lookahead) -> golden data say 24
output reg 	[7:0] 	char_nxt;

/*
	1. Input (INPUT)
	2. Load Lookahead buffer (LOAD)
	3. Check match length for each match_len (MATCH24~MATCH1)
	4. Output current result (OUTPUT)
	5. Move Lookahead buffer match_len+1 times (MOVE)
	6. repeat 3~5, until $ (FINISH) 
*/

parameter INPUT=26, LOAD=27, OUTPUT=28, MOVE=29, FINISH=30;

reg [7:0] inputSeq [0:8192]; //32*128*2+1=8193
reg [13:0] inputCnt;
reg [5:0]  loadCnt;
reg [4:0] tmpMatch , curMatch; //tmp for C, cur for S
reg [4:0] tmpOffset, curOffset;
//search buffer is 30 bytes, look-ahead buffer is 25 bytes
reg [7:0] buffer [54:0]; // 54-25: search, 24-0: lookahead
reg [5:0] State, NextState;

integer i, j;

// State reg
always@(posedge clk or posedge reset) begin
	if(reset) begin
		State <= INPUT;
		inputCnt <= 0;
		loadCnt  <= 0;
		for (i=0; i<55; i=i+1) begin
			buffer[i] <= 8'h24;
		end
		curMatch <= 0;
		curOffset <= 0;
	end
	else begin
		State <= NextState;
		case(State)
			INPUT: begin
				inputSeq[inputCnt] <= chardata;
				if(inputCnt == 8192)
					inputCnt <= 0;
				else
					inputCnt <= inputCnt + 1;
			end
			LOAD: begin
				for (i=0; i<25; i=i+1) begin
					buffer[i] <= inputSeq[24-i];
				end
				inputCnt <= 25;
			end
			MOVE: begin
				// Shift Left
				buffer[0] <= inputSeq[inputCnt];
				for (i=1; i<55; i=i+1) begin
					buffer[i] <= buffer[i-1];
				end
				inputCnt <= inputCnt + 1;
				if (loadCnt == curMatch) begin //Go to MATCH7
					loadCnt <= 0;
					curMatch <= 0;
					curOffset <= 0;
				end
				else begin
					loadCnt <= loadCnt + 1;
				end
			end
			default: begin
				loadCnt <= 0;
				if(curMatch < tmpMatch) begin
					curMatch  <= tmpMatch;
					curOffset <= tmpOffset;
				end
				else begin
					curMatch  <= curMatch;
					curOffset <= curOffset;
				end
			end
		endcase
	end
end
//Next State Logic
always@(*) begin
	case(State)
		INPUT: begin
			NextState = (inputCnt == 8192)? LOAD: INPUT;
		end
		LOAD: begin
			NextState = 24;
		end
		24: NextState = (curMatch == 0)? 23: OUTPUT;
		23: NextState = (curMatch == 0)? 22: OUTPUT;
		22: NextState = (curMatch == 0)? 21: OUTPUT;
		21: NextState = (curMatch == 0)? 20: OUTPUT;
		20: NextState = (curMatch == 0)? 19: OUTPUT;
		19: NextState = (curMatch == 0)? 18: OUTPUT;
		18: NextState = (curMatch == 0)? 17: OUTPUT;
		17: NextState = (curMatch == 0)? 16: OUTPUT;
		16: NextState = (curMatch == 0)? 15: OUTPUT;
		15: NextState = (curMatch == 0)? 14: OUTPUT;
		14: NextState = (curMatch == 0)? 13: OUTPUT;
		13: NextState = (curMatch == 0)? 12: OUTPUT;
		12: NextState = (curMatch == 0)? 11: OUTPUT;
		11: NextState = (curMatch == 0)? 10: OUTPUT;
		10: NextState = (curMatch == 0)? 9: OUTPUT;
		9 : NextState = (curMatch == 0)? 8: OUTPUT;
		8 : NextState = (curMatch == 0)? 7: OUTPUT;
		7 : NextState = (curMatch == 0)? 6: OUTPUT;
		6 : NextState = (curMatch == 0)? 5: OUTPUT;
		5 : NextState = (curMatch == 0)? 4: OUTPUT;
		4 : NextState = (curMatch == 0)? 3: OUTPUT;
		3 : NextState = (curMatch == 0)? 2: OUTPUT;
		2 : NextState = (curMatch == 0)? 1: OUTPUT;
		1: begin
			NextState = OUTPUT;
		end
		OUTPUT: begin
			NextState = (char_nxt == 8'h24)? FINISH: MOVE;
		end
		MOVE: begin
			NextState = (loadCnt == curMatch)? 24: MOVE;
		end
		default: begin
			NextState = State;
		end
	endcase
end


always@(*) begin
	case(State)
		INPUT: begin
			encode = 1'b0; finish = 1'b0; valid = 1'b0;
		end 
		LOAD: begin
			encode = 1'b0; finish = 1'b0; valid = 1'b0;
		end
		OUTPUT: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b1;
		end
		MOVE: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
		end
		FINISH: begin
			encode = 1'b1; finish = 1'b1; valid = 1'b0;
		end
		default: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
		end
	endcase
end
always@(*) begin
	case(State)
		OUTPUT: begin
			offset = curOffset;
			match_len = curMatch;
			char_nxt = buffer[24-curMatch];
		end
		default: begin
			offset = 0; match_len = 0; char_nxt = 8'h0;
		end
	endcase
end
//Output Logic
always@(*) begin
	case(State)
		INPUT: begin
			tmpMatch = 0; tmpOffset = 0;
		end
		LOAD: begin
			tmpMatch = 0; tmpOffset = 0;
		end
		/*25: begin
			// 54-25: search, 24-0: lookahead
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17] && buffer[6] == buffer[i-18] && buffer[5] == buffer[i-19] && buffer[4] == buffer[i-20] && buffer[3] == buffer[i-21] && buffer[2] == buffer[i-22] && buffer[1] == buffer[i-23] && buffer[0] == buffer[i-24])
				begin
					tmpOffset = i-25;
					tmpMatch = 25;
					for (j=54;j>=0;j=j-1) begin
						$display("%d: %d", j, buffer[j]);
					end
				end
			end
		end*/
		24: begin
			// 54-25: search, 24-0: lookahead
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17] && buffer[6] == buffer[i-18] && buffer[5] == buffer[i-19] && buffer[4] == buffer[i-20] && buffer[3] == buffer[i-21] && buffer[2] == buffer[i-22] && buffer[1] == buffer[i-23])
				begin
					tmpOffset = i-25;
					tmpMatch = 24;
				end
			end
		end
		23: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17] && buffer[6] == buffer[i-18] && buffer[5] == buffer[i-19] && buffer[4] == buffer[i-20] && buffer[3] == buffer[i-21] && buffer[2] == buffer[i-22])
				begin
					tmpOffset = i-25;
					tmpMatch = 23;
				end
			end
		end
		22: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17] && buffer[6] == buffer[i-18] && buffer[5] == buffer[i-19] && buffer[4] == buffer[i-20] && buffer[3] == buffer[i-21])
				begin
					tmpOffset = i-25;
					tmpMatch = 22;
				end
			end
		end
		21: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17] && buffer[6] == buffer[i-18] && buffer[5] == buffer[i-19] && buffer[4] == buffer[i-20])
				begin
					tmpOffset = i-25;
					tmpMatch = 21;
				end
			end
		end
		20: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17] && buffer[6] == buffer[i-18] && buffer[5] == buffer[i-19])
				begin	
					tmpOffset = i-25;
					tmpMatch = 20;
				end
			end
		end
		19: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17] && buffer[6] == buffer[i-18])
				begin
					tmpOffset = i-25;
					tmpMatch = 19;
				end
			end
		end
		18: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16] && buffer[7] == buffer[i-17])
				begin
					tmpOffset = i-25;
					tmpMatch = 18;
				end
			end
		end
		17: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15] && buffer[8] == buffer[i-16])
				begin
					tmpOffset = i-25;
					tmpMatch = 17;
				end
			end
		end
		16: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14] && buffer[9] == buffer[i-15])
				begin
					tmpOffset = i-25;
					tmpMatch = 16;
				end
			end
		end
		15: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13] && buffer[10] == buffer[i-14])
				begin
					tmpOffset = i-25;
					tmpMatch = 15;
				end
			end
		end
		14: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12] && buffer[11] == buffer[i-13])
				begin
					tmpOffset = i-25;
					tmpMatch = 14;
				end
			end
		end
		13: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11] && buffer[12] == buffer[i-12])
				begin
					tmpOffset = i-25;
					tmpMatch = 13;
				end
			end
		end
		12: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10] && buffer[13] == buffer[i-11])
				begin
					tmpOffset = i-25;
					tmpMatch = 12;
				end
			end
		end
		11: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9] && buffer[14] == buffer[i-10])
				begin
					tmpOffset = i-25;
					tmpMatch = 11;
				end
			end
		end
		10: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8] && buffer[15] == buffer[i-9])
				begin
					tmpOffset = i-25;
					tmpMatch = 10;
				end
			end
		end
		9: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7] && buffer[16] == buffer[i-8])
				begin
					tmpOffset = i-25;
					tmpMatch = 9;
				end
			end
		end
		8: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6] && buffer[17] == buffer[i-7])
				begin
					tmpOffset = i-25;
					tmpMatch = 8;
				end
			end
		end
		7: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5] && buffer[18] == buffer[i-6])
				begin
					tmpOffset = i-25;
					tmpMatch = 7;
				end
			end
		end	
		6: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4] && buffer[19] == buffer[i-5])
				begin
					tmpOffset = i-25;
					tmpMatch = 6;
				end
			end
		end	
		5: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3] && buffer[20] == buffer[i-4])
				begin
					tmpOffset = i-25;
					tmpMatch = 5;
				end
			end
		end	
		4: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2] && buffer[21] == buffer[i-3])
				begin
					tmpOffset = i-25;
					tmpMatch = 4;
				end
			end
		end	
		3: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1] && buffer[22] == buffer[i-2])
				begin
					tmpOffset = i-25;
					tmpMatch = 3;
				end
			end
		end	
		2: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i] && buffer[23] == buffer[i-1])
				begin
					tmpOffset = i-25;
					tmpMatch = 2;
				end
			end
		end	
		1: begin
			for (i=25;i<=54;i=i+1) begin //從右到左
				if(buffer[24] == buffer[i])
				begin
					tmpOffset = i-25;
					tmpMatch = 1;
				end
			end
		end	
		OUTPUT: begin
			tmpMatch = 0; tmpOffset = 0;
		end
		MOVE: begin
			tmpMatch = 0; tmpOffset = 0;
		end
		FINISH: begin
			tmpMatch = 0; tmpOffset = 0;
		end
		default: begin
			tmpMatch = 0; tmpOffset = 0;
		end
	endcase
end
endmodule
