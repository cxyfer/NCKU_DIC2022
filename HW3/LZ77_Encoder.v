module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);
input 				clk;
input 				reset;
input 		[7:0] 	chardata;
output reg 			valid;
output reg 			encode;
output reg 			finish;
output reg	[3:0] 	offset;
output reg	[2:0] 	match_len;
output reg	[7:0] 	char_nxt;

/*
	1. Input (INPUT)
	2. Load Lookahead buffer (LOAD)
	3. Check match length for each match_len (MATCH7~MATCH1)
	4. Output current result (OUTPUT)
	5. Move Lookahead buffer match_len+1 times (MOVE)
	6. repeat 3~5, until $ (FINISH) 
*/

parameter INPUT=0, LOAD=1, OUTPUT=9, MOVE=10, FINISH=11;
parameter MATCH7=2, MATCH6=3, MATCH5=4, MATCH4=5, MATCH3=6, MATCH2=7, MATCH1=8;

reg [7:0] inputSeq [0:2048]; //32*32*2+1=2049
reg [11:0] inputCnt;
reg [3:0]  loadCnt;
reg [2:0] tmpMatch , curMatch; //tmp for C, cur for S
reg [3:0] tmpOffset, curOffset;
reg [7:0] buffer [16:0]; // 16-8: search, 7-0: lookahead
reg [3:0] State, NextState;

integer i, j;
// State reg
always@(posedge clk or posedge reset) begin
	if(reset) begin
		State <= INPUT;
		inputCnt <= 12'd0;
		loadCnt  <=  4'd0;
		for (i=0; i<17; i=i+1) begin
			buffer[i] <= 8'h24;
		end
		curMatch <= 3'd0;
		curOffset <= 4'd0;
	end
	else begin
		State <= NextState;
		case(State)
			INPUT: begin
				inputSeq[inputCnt] <= chardata;
				if(inputCnt == 12'd2048)
					inputCnt <= 12'd0;
				else
					inputCnt <= inputCnt + 12'd1;
			end
			LOAD: begin
				for (i=0; i<8; i=i+1) begin
					buffer[i] <= inputSeq[7-i];
				end
				inputCnt <= 12'd8;
			end
			MOVE: begin
				// Shift Left
				buffer[0] <= inputSeq[inputCnt];
				for (i=1;i<17;i=i+1) begin
					buffer[i] <= buffer[i-1]; 
				end
				inputCnt <= inputCnt + 12'd1;
				if (loadCnt == curMatch) begin //Go to MATCH7
					loadCnt <= 4'd0;
					curMatch <= 3'd0;
					curOffset <= 3'd0;
				end
				else begin
					loadCnt <= loadCnt + 4'd1;
				end
			end
			default: begin
				loadCnt <= 4'd0;
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
			NextState = (inputCnt == 12'd2048)? LOAD: INPUT;
		end
		LOAD: begin
			NextState = MATCH7;
		end
		MATCH7: begin
			NextState = MATCH6;
		end
		MATCH6: begin
			NextState = MATCH5;
		end
		MATCH5: begin
			NextState = MATCH4;
		end
		MATCH4: begin
			NextState = MATCH3;
		end
		MATCH3: begin
			NextState = MATCH2;
		end
		MATCH2: begin
			NextState = MATCH1;
		end
		/*MATCH7: begin
			NextState = (curMatch == 0)? MATCH6: OUTPUT;
		end
		MATCH6: begin
			NextState = (curMatch == 0)? MATCH5: OUTPUT;
		end
		MATCH5: begin
			NextState = (curMatch == 0)? MATCH4: OUTPUT;
		end
		MATCH4: begin
			NextState = (curMatch == 0)? MATCH3: OUTPUT;
		end
		MATCH3: begin
			NextState = (curMatch == 0)? MATCH2: OUTPUT;
		end
		MATCH2: begin
			NextState = (curMatch == 0)? MATCH1: OUTPUT;
		end*/
		MATCH1: begin
			NextState = OUTPUT;
		end
		OUTPUT: begin
			NextState = (char_nxt == 8'h24)? FINISH: MOVE;
		end
		MOVE: begin
			NextState = (loadCnt == curMatch)? MATCH7: MOVE;
		end
		default: begin
			NextState = State;
		end
	endcase
end

//Output Logic
always@(*) begin
	case(State)
		INPUT: begin
			encode = 1'b0; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			tmpMatch = 3'd0; tmpOffset = 4'd0;
		end
		LOAD: begin
			encode = 1'b0; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			tmpMatch = 3'd0; tmpOffset = 4'd0;
		end
		MATCH7: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			//合成失敗
			//for (i=16;i>=8;i=i-1) begin //從左到右，如果break不可用則從右到左(較消耗時間)或用if else拆開
			/*for (i=8;i<=16;i=i+1) begin //從右到左
				if(buffer[7] == buffer[i] && buffer[6] == buffer[i-1] && buffer[5] == buffer[i-2] && buffer[4] == buffer[i-3] && buffer[3] == buffer[i-4] && buffer[2] == buffer[i-5] && buffer[1] == buffer[i-6]) begin
					tmpOffset = i-8;
					tmpMatch = 3'd7;
				end
			end*/
			tmpMatch = 3'd7;
			if (buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13] && buffer[3] == buffer[12] && buffer[2] == buffer[11] && buffer[1] == buffer[10])
				tmpOffset = 4'd8;
			else if (buffer[7] == buffer[15] && buffer[6] == buffer[14] && buffer[5] == buffer[13] && buffer[4] == buffer[12] && buffer[3] == buffer[11] && buffer[2] == buffer[10] && buffer[1] == buffer[9])
				tmpOffset = 4'd7;
			else if (buffer[7] == buffer[14] && buffer[6] == buffer[13] && buffer[5] == buffer[12] && buffer[4] == buffer[11] && buffer[3] == buffer[10] && buffer[2] == buffer[9] && buffer[1] == buffer[8])
				tmpOffset = 4'd6;
			else if (buffer[7] == buffer[13] && buffer[6] == buffer[12] && buffer[5] == buffer[11] && buffer[4] == buffer[10] && buffer[3] == buffer[9] && buffer[2] == buffer[8] && buffer[1] == buffer[7])
				tmpOffset = 4'd5;
			else if (buffer[7] == buffer[12] && buffer[6] == buffer[11] && buffer[5] == buffer[10] && buffer[4] == buffer[9] && buffer[3] == buffer[8] && buffer[2] == buffer[7] && buffer[1] == buffer[6])
				tmpOffset = 4'd4; 
			else if (buffer[7] == buffer[11] && buffer[6] == buffer[10] && buffer[5] == buffer[9] && buffer[4] == buffer[8] && buffer[3] == buffer[7] && buffer[2] == buffer[6] && buffer[1] == buffer[5])
				tmpOffset = 4'd3;
			else if (buffer[7] == buffer[10] && buffer[6] == buffer[9] && buffer[5] == buffer[8] && buffer[4] == buffer[7] && buffer[3] == buffer[6] && buffer[2] == buffer[5] && buffer[1] == buffer[4])
				tmpOffset = 4'd2;
			else if (buffer[7] == buffer[9] && buffer[6] == buffer[8] && buffer[5] == buffer[7] && buffer[4] == buffer[6] && buffer[3] == buffer[5] && buffer[2] == buffer[4] && buffer[1] == buffer[3])
				tmpOffset = 4'd1;
			else if (buffer[7] == buffer[8] && buffer[6] == buffer[7] && buffer[5] == buffer[6] && buffer[4] == buffer[5] && buffer[3] == buffer[4] && buffer[2] == buffer[3] && buffer[1] == buffer[2])
				tmpOffset = 4'd0;
			else begin
				tmpOffset = 0;
				tmpMatch = 3'd0;
			end
		end
		MATCH6: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			/*for (i=8;i<=16;i=i+1) begin
				if(buffer[7] == buffer[i] && buffer[6] == buffer[i-1] && buffer[5] == buffer[i-2] && buffer[4] == buffer[i-3] && buffer[3] == buffer[i-4] && buffer[2] == buffer[i-5]) begin
					tmpOffset = i-8;
					tmpMatch = 3'd6;
				end
			end*/
			tmpMatch = 3'd6;
			if (buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13] && buffer[3] == buffer[12] && buffer[2] == buffer[11])
				tmpOffset = 4'd8;
			else if (buffer[7] == buffer[15] && buffer[6] == buffer[14] && buffer[5] == buffer[13] && buffer[4] == buffer[12] && buffer[3] == buffer[11] && buffer[2] == buffer[10])
				tmpOffset = 4'd7;
			else if (buffer[7] == buffer[14] && buffer[6] == buffer[13] && buffer[5] == buffer[12] && buffer[4] == buffer[11] && buffer[3] == buffer[10] && buffer[2] == buffer[9])
				tmpOffset = 4'd6;
			else if (buffer[7] == buffer[13] && buffer[6] == buffer[12] && buffer[5] == buffer[11] && buffer[4] == buffer[10] && buffer[3] == buffer[9] && buffer[2] == buffer[8])
				tmpOffset = 4'd5;
			else if (buffer[7] == buffer[12] && buffer[6] == buffer[11] && buffer[5] == buffer[10] && buffer[4] == buffer[9] && buffer[3] == buffer[8] && buffer[2] == buffer[7])
				tmpOffset = 4'd4; 
			else if (buffer[7] == buffer[11] && buffer[6] == buffer[10] && buffer[5] == buffer[9] && buffer[4] == buffer[8] && buffer[3] == buffer[7] && buffer[2] == buffer[6])
				tmpOffset = 4'd3;
			else if (buffer[7] == buffer[10] && buffer[6] == buffer[9] && buffer[5] == buffer[8] && buffer[4] == buffer[7] && buffer[3] == buffer[6] && buffer[2] == buffer[5])
				tmpOffset = 4'd2;
			else if (buffer[7] == buffer[9] && buffer[6] == buffer[8] && buffer[5] == buffer[7] && buffer[4] == buffer[6] && buffer[3] == buffer[5] && buffer[2] == buffer[4])
				tmpOffset = 4'd1;
			else if (buffer[7] == buffer[8] && buffer[6] == buffer[7] && buffer[5] == buffer[6] && buffer[4] == buffer[5] && buffer[3] == buffer[4] && buffer[2] == buffer[3])
				tmpOffset = 4'd0;
			else begin
				tmpOffset = 4'd0;
				tmpMatch = 3'd0;
			end
		end
		MATCH5: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			/*for (i=8;i<=16;i=i+1) begin
				if(buffer[7] == buffer[i] && buffer[6] == buffer[i-1] && buffer[5] == buffer[i-2] && buffer[4] == buffer[i-3] && buffer[3] == buffer[i-4]) begin
					tmpOffset = i-8;
					tmpMatch = 3'd5;
				end
			end*/
			tmpMatch = 3'd5;
			if (buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13] && buffer[3] == buffer[12])
				tmpOffset = 4'd8;
			else if (buffer[7] == buffer[15] && buffer[6] == buffer[14] && buffer[5] == buffer[13] && buffer[4] == buffer[12] && buffer[3] == buffer[11])
				tmpOffset = 4'd7;
			else if (buffer[7] == buffer[14] && buffer[6] == buffer[13] && buffer[5] == buffer[12] && buffer[4] == buffer[11] && buffer[3] == buffer[10])
				tmpOffset = 4'd6;
			else if (buffer[7] == buffer[13] && buffer[6] == buffer[12] && buffer[5] == buffer[11] && buffer[4] == buffer[10] && buffer[3] == buffer[9])
				tmpOffset = 4'd5;
			else if (buffer[7] == buffer[12] && buffer[6] == buffer[11] && buffer[5] == buffer[10] && buffer[4] == buffer[9] && buffer[3] == buffer[8])
				tmpOffset = 4'd4; 
			else if (buffer[7] == buffer[11] && buffer[6] == buffer[10] && buffer[5] == buffer[9] && buffer[4] == buffer[8] && buffer[3] == buffer[7])
				tmpOffset = 4'd3;
			else if (buffer[7] == buffer[10] && buffer[6] == buffer[9] && buffer[5] == buffer[8] && buffer[4] == buffer[7] && buffer[3] == buffer[6])
				tmpOffset = 4'd2;
			else if (buffer[7] == buffer[9] && buffer[6] == buffer[8] && buffer[5] == buffer[7] && buffer[4] == buffer[6] && buffer[3] == buffer[5])
				tmpOffset = 4'd1;
			else if (buffer[7] == buffer[8] && buffer[6] == buffer[7] && buffer[5] == buffer[6] && buffer[4] == buffer[5] && buffer[3] == buffer[4])
				tmpOffset = 4'd0;
			else begin
				tmpOffset = 4'd0;
				tmpMatch = 3'd0;
			end
		end
		MATCH4: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			/*for (i=8;i<=16;i=i+1) begin
				if(buffer[7] == buffer[i] && buffer[6] == buffer[i-1] && buffer[5] == buffer[i-2] && buffer[4] == buffer[i-3]) begin
					tmpOffset = i-8;
					tmpMatch = 3'd4;
				end
			end*/
			tmpMatch = 3'd4;
			if (buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13])
				tmpOffset = 4'd8;
			else if (buffer[7] == buffer[15] && buffer[6] == buffer[14] && buffer[5] == buffer[13] && buffer[4] == buffer[12])
				tmpOffset = 4'd7;
			else if (buffer[7] == buffer[14] && buffer[6] == buffer[13] && buffer[5] == buffer[12] && buffer[4] == buffer[11])
				tmpOffset = 4'd6;
			else if (buffer[7] == buffer[13] && buffer[6] == buffer[12] && buffer[5] == buffer[11] && buffer[4] == buffer[10])
				tmpOffset = 4'd5;
			else if (buffer[7] == buffer[12] && buffer[6] == buffer[11] && buffer[5] == buffer[10] && buffer[4] == buffer[9])
				tmpOffset = 4'd4; 
			else if (buffer[7] == buffer[11] && buffer[6] == buffer[10] && buffer[5] == buffer[9] && buffer[4] == buffer[8])
				tmpOffset = 4'd3;
			else if (buffer[7] == buffer[10] && buffer[6] == buffer[9] && buffer[5] == buffer[8] && buffer[4] == buffer[7])
				tmpOffset = 4'd2;
			else if (buffer[7] == buffer[9] && buffer[6] == buffer[8] && buffer[5] == buffer[7] && buffer[4] == buffer[6])
				tmpOffset = 4'd1;
			else if (buffer[7] == buffer[8] && buffer[6] == buffer[7] && buffer[5] == buffer[6] && buffer[4] == buffer[5])
				tmpOffset = 4'd0;
			else begin
				tmpOffset = 4'd0;
				tmpMatch = 3'd0;
			end
		end
		MATCH3: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			/*for (i=8;i<=16;i=i+1) begin
				if(buffer[7] == buffer[i] && buffer[6] == buffer[i-1] && buffer[5] == buffer[i-2]) begin
					tmpOffset = i-8;
					tmpMatch = 3'd3;
				end
			end*/
			tmpMatch = 3'd3;
			if (buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14])
				tmpOffset = 4'd8;
			else if (buffer[7] == buffer[15] && buffer[6] == buffer[14] && buffer[5] == buffer[13])
				tmpOffset = 4'd7;
			else if (buffer[7] == buffer[14] && buffer[6] == buffer[13] && buffer[5] == buffer[12])
				tmpOffset = 4'd6;
			else if (buffer[7] == buffer[13] && buffer[6] == buffer[12] && buffer[5] == buffer[11])
				tmpOffset = 4'd5;
			else if (buffer[7] == buffer[12] && buffer[6] == buffer[11] && buffer[5] == buffer[10])
				tmpOffset = 4'd4; 
			else if (buffer[7] == buffer[11] && buffer[6] == buffer[10] && buffer[5] == buffer[9])
				tmpOffset = 4'd3;
			else if (buffer[7] == buffer[10] && buffer[6] == buffer[9] && buffer[5] == buffer[8])
				tmpOffset = 4'd2;
			else if (buffer[7] == buffer[9] && buffer[6] == buffer[8] && buffer[5] == buffer[7])
				tmpOffset = 4'd1;
			else if (buffer[7] == buffer[8] && buffer[6] == buffer[7] && buffer[5] == buffer[6])
				tmpOffset = 4'd0;
			else begin
				tmpOffset = 4'd0;
				tmpMatch = 3'd0;
			end
		end
		MATCH2: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			/*for (i=8;i<=16;i=i+1) begin
				if(buffer[7] == buffer[i] && buffer[6] == buffer[i-1]) begin
					tmpOffset = i-8;
					tmpMatch = 3'd2;
				end
			end*/
			tmpMatch = 3'd2;
			if (buffer[7] == buffer[16] && buffer[6] == buffer[15])
				tmpOffset = 4'd8;
			else if (buffer[7] == buffer[15] && buffer[6] == buffer[14])
				tmpOffset = 4'd7;
			else if (buffer[7] == buffer[14] && buffer[6] == buffer[13])
				tmpOffset = 4'd6;
			else if (buffer[7] == buffer[13] && buffer[6] == buffer[12])
				tmpOffset = 4'd5;
			else if (buffer[7] == buffer[12] && buffer[6] == buffer[11])
				tmpOffset = 4'd4; 
			else if (buffer[7] == buffer[11] && buffer[6] == buffer[10])
				tmpOffset = 4'd3;
			else if (buffer[7] == buffer[10] && buffer[6] == buffer[9])
				tmpOffset = 4'd2;
			else if (buffer[7] == buffer[9] && buffer[6] == buffer[8])
				tmpOffset = 4'd1;
			else if (buffer[7] == buffer[8] && buffer[6] == buffer[7])
				tmpOffset = 4'd0;
			else begin
				tmpOffset = 4'd0;
				tmpMatch = 3'd0;
			end
		end
		MATCH1: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			/*for (i=8;i<=16;i=i+1) begin
				if(buffer[7] == buffer[i]) begin
					tmpOffset = i-8;
					tmpMatch = 3'd1;
				end
			end*/
			tmpMatch = 3'd1;
			if (buffer[7] == buffer[16])
				tmpOffset = 4'd8;
			else if (buffer[7] == buffer[15])
				tmpOffset = 4'd7;
			else if (buffer[7] == buffer[14])
				tmpOffset = 4'd6;
			else if (buffer[7] == buffer[13])
				tmpOffset = 4'd5;
			else if (buffer[7] == buffer[12])
				tmpOffset = 4'd4; 
			else if (buffer[7] == buffer[11])
				tmpOffset = 4'd3;
			else if (buffer[7] == buffer[10])
				tmpOffset = 4'd2;
			else if (buffer[7] == buffer[9])
				tmpOffset = 4'd1;
			else if (buffer[7] == buffer[8])
				tmpOffset = 4'd0;
			else begin
				tmpOffset = 4'd0;
				tmpMatch = 3'd0;
			end
		end
		OUTPUT: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b1;
			tmpMatch = 3'd0; tmpOffset = 4'd0;
			offset = curOffset;
			match_len = curMatch;
			char_nxt = buffer[7-curMatch];
		end
		MOVE: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			tmpMatch = 3'd0; tmpOffset = 4'd0;
		end
		FINISH: begin
			encode = 1'b1; finish = 1'b1; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			tmpMatch = 3'd0; tmpOffset = 4'd0;
		end
		default: begin
			encode = 1'b0; finish = 1'b0; valid = 1'b0;
			offset = 4'd0; match_len = 3'd0; char_nxt = 8'h0;
			tmpMatch = 3'd0; tmpOffset = 4'd0;
		end
	endcase
end
endmodule