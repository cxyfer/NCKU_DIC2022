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
	1. Input 
	2. Read Lookahead buffer
	3. Check match length
		a. for each match_len
		b. for each bit in Lookahead buffer
	4. Move Lookahead buffer according match_len
	5. Output current result
	6. repeat 3~5, until $
*/

parameter INPUT = 0, READ8=1, READ=11, OUTPUT=12, FINISH=13;
parameter OFFSET_8=2, OFFSET_7=3, OFFSET_6=4, OFFSET_5=5, OFFSET_4=6, OFFSET_3=7, OFFSET_2=8, OFFSET_1=9, OFFSET_0=10;

reg [7:0] inputSeq [0:2048];
reg [11:0] inputCnt=0;
reg [3:0]  readCnt =0;
reg [2:0] curMatch;
reg [2:0] maxMatch;
reg [3:0] offset_new;
reg [7:0] buffer [0:16]; // 0-7: lookahead, 8-16: search
reg [3:0] State, NextState;

integer i, j;
//State reg
always@(posedge clk or posedge reset)begin
	if(reset) begin
		State <= INPUT;
		inputCnt <= 12'd0;
		readCnt  <=  4'd0;
	end
	else begin
		State <= NextState;
		case(State)
			INPUT: begin
				if(inputCnt == 12'd2048)
					inputCnt <= 12'd0;
				else
					inputCnt <= inputCnt + 12'd1;
			end
			READ8: begin
				inputCnt <= 12'd8;
			end
			READ: begin
				inputCnt <= inputCnt + 12'd1;
				if (readCnt+1 == maxMatch)
					readCnt <= 4'd0;
				else
					readCnt <= readCnt + 4'd1;
			end
			OUTPUT: begin
				inputCnt <= inputCnt + 12'd1;
			end
			default: begin
				readCnt <= 4'd0;
			end
		endcase
	end
end
always@(posedge clk or posedge reset) begin
	if(reset) begin
		for (i=0; i<8; i=i+1) begin //lookahead
			buffer[i] <= 8'h0;
		end
		for (i=8; i<17; i=i+1) begin //search
			buffer[i] <= 8'h24;
		end
		maxMatch <= 3'd0;
		offset_new <= 4'd0;
	end
	else begin
		if(State == INPUT) begin
			inputSeq[inputCnt] <= chardata;
		end
		else if(State == READ8) begin
			for (i=0; i<8; i=i+1) begin
				buffer[i] = inputSeq[7-i];
			end
		end
		else if(State == OFFSET_8 || State == OFFSET_7 || State == OFFSET_6 || State == OFFSET_5 || State == OFFSET_4 || State == OFFSET_3 || State == OFFSET_2 || State == OFFSET_1 || State == OFFSET_0) begin
			if(maxMatch < curMatch) begin
				maxMatch  <= curMatch;
				offset_new <= 10 - State;
			end
			else begin
				maxMatch  <= maxMatch;
				offset_new <= offset_new;
			end
		end
		else if(State == READ || State == OUTPUT) begin
			buffer[0] <= inputSeq[inputCnt];
			for (i=1;i<17;i=i+1) begin
				buffer[i] <= buffer[i-1];
			end
			if(State == READ) begin
				if(readCnt == maxMatch - 4'b1)
					{maxMatch, offset_new} <= 'd0;
			end	
		end
	end		
end
//Next State Logic
always@(*) begin
	case(State)
		INPUT: begin
			if(inputCnt == 12'd2048)
				NextState = READ8;
			else
				NextState = INPUT;
		end
		READ8: begin
			NextState = OFFSET_8;
		end
		OFFSET_8: begin
			NextState = OFFSET_7;
		end
		OFFSET_7: begin
			NextState = OFFSET_6;
		end
		OFFSET_6: begin
			NextState = OFFSET_5;
		end
		OFFSET_5: begin
			NextState = OFFSET_4;
		end
		OFFSET_4: begin
			NextState = OFFSET_3;
		end
		OFFSET_3: begin
			NextState = OFFSET_2;
		end
		OFFSET_2: begin
			NextState = OFFSET_1;
		end
		OFFSET_1: begin
			NextState = OFFSET_0;
		end
		OFFSET_0: begin
			NextState = OUTPUT;
		end
		READ: begin
			if(readCnt == maxMatch - 4'b1)
				NextState = OFFSET_8;
			else
				NextState = READ;
		end
		OUTPUT: begin
			if(char_nxt == 8'h24)
				NextState = FINISH;
			else if (maxMatch == 4'b0)
				NextState = OFFSET_8;
			else
				NextState = READ;
		end
		FINISH: begin
			NextState = FINISH;
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
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
		end
		READ8: begin
			encode = 1'b0; finish = 1'b0; valid = 1'b0;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
		end
		/*MATCH7: begin
			encode = 1'b1; finish = 1'b0; valid = 1'b0;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			for (i=16;i>=8;i=i-1) begin //從左到右，如果break不可用則從右到左或拆開
				if(buffer[7] == buffer[i] && buffer[6] == buffer[i-1] && buffer[5] == buffer[i-2] && buffer[4] == buffer[i-3] && buffer[3] == buffer[i-4] && buffer[2] == buffer[i-5] && buffer[1] == buffer[i-6]) begin
					offset_new = 4'd8;
					break;
				end
			end
			if(buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13] && buffer[3] == buffer[12] && buffer[2] == buffer[11] && buffer[1] == buffer[10])
				offset_new = 4'd8;
			else if(buffer[7] == buffer[15] & buffer[6] == buffer[14] & buffer[5] == buffer[13] & buffer[4] == buffer[12] & buffer[3] == buffer[11] & buffer[2] == buffer[10] & buffer[1] == buffer[9])
				offset_new = 4'd7;
if(buffer[7] == buffer[8] & buffer[6] == buffer[7] & buffer[5] == buffer[6] & buffer[4] == buffer[5] & buffer[3] == buffer[4] & buffer[2] == buffer[3] & buffer[1] == buffer[2])
				curMatch = 3'd7;
		end*/
		OFFSET_8: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13] && buffer[3] == buffer[12] && buffer[2] == buffer[11] && buffer[1] == buffer[10])
				curMatch = 3'd7;
			else if(buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13] && buffer[3] == buffer[12] && buffer[2] == buffer[11])
				curMatch = 3'd6;
			else if(buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13] && buffer[3] == buffer[12])
				curMatch = 3'd5;
			else if(buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14] && buffer[4] == buffer[13])
				curMatch = 3'd4;
			else if(buffer[7] == buffer[16] && buffer[6] == buffer[15] && buffer[5] == buffer[14])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[16] && buffer[6] == buffer[15])
				curMatch = 3'd2;
			else if	(buffer[7] == buffer[16])
				curMatch = 3'd1;
			else
				curMatch = 3'd0;
		end
		OFFSET_7: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[15] & buffer[6] == buffer[14] & buffer[5] == buffer[13] & buffer[4] == buffer[12] & buffer[3] == buffer[11] & buffer[2] == buffer[10] & buffer[1] == buffer[9])
				curMatch = 3'd7; 
			else if(buffer[7] == buffer[15] & buffer[6] == buffer[14] & buffer[5] == buffer[13] & buffer[4] == buffer[12] & buffer[3] == buffer[11] & buffer[2] == buffer[10])
				curMatch = 3'd6; 
			else if(buffer[7] == buffer[15] & buffer[6] == buffer[14] & buffer[5] == buffer[13] & buffer[4] == buffer[12] & buffer[3] == buffer[11])
				curMatch = 3'd5; 
			else if(buffer[7] == buffer[15] & buffer[6] == buffer[14] & buffer[5] == buffer[13] & buffer[4] == buffer[12])
				curMatch = 3'd4; 
			else if(buffer[7] == buffer[15] & buffer[6] == buffer[14] & buffer[5] == buffer[13])
				curMatch = 3'd3; 
			else if(buffer[7] == buffer[15] & buffer[6] == buffer[14])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[15])
				curMatch = 3'd1;
			else
				curMatch = 3'd0;	
		end
		OFFSET_6: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[14] & buffer[6] == buffer[13] & buffer[5] == buffer[12] & buffer[4] == buffer[11] & buffer[3] == buffer[10] & buffer[2] == buffer[9] & buffer[1] == buffer[8])
				curMatch = 3'd7;                                            
			else if(buffer[7] == buffer[14] & buffer[6] == buffer[13] & buffer[5] == buffer[12] & buffer[4] == buffer[11] & buffer[3] == buffer[10] & buffer[2] == buffer[9])
				curMatch = 3'd6;                                 
			else if(buffer[7] == buffer[14] & buffer[6] == buffer[13] & buffer[5] == buffer[12] & buffer[4] == buffer[11] & buffer[3] == buffer[10])
				curMatch = 3'd5;                      
			else if(buffer[7] == buffer[14] & buffer[6] == buffer[13] & buffer[5] == buffer[12] & buffer[4] == buffer[11])
				curMatch = 3'd4;           
			else if(buffer[7] == buffer[14] & buffer[6] == buffer[13] & buffer[5] == buffer[12])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[14] & buffer[6] == buffer[13])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[14])
				curMatch = 3'd1;
			else    
				curMatch = 3'd0;
		end
		OFFSET_5: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[13] & buffer[6] == buffer[12] & buffer[5] == buffer[11] & buffer[4] == buffer[10] & buffer[3] == buffer[9] & buffer[2] == buffer[8] & buffer[1] == buffer[7])
				curMatch = 3'd7;                                            
			else if(buffer[7] == buffer[13] & buffer[6] == buffer[12] & buffer[5] == buffer[11] & buffer[4] == buffer[10] & buffer[3] == buffer[9] & buffer[2] == buffer[8])
				curMatch = 3'd6;                                 
			else if(buffer[7] == buffer[13] & buffer[6] == buffer[12] & buffer[5] == buffer[11] & buffer[4] == buffer[10] & buffer[3] == buffer[9])
				curMatch = 3'd5;                      
			else if(buffer[7] == buffer[13] & buffer[6] == buffer[12] & buffer[5] == buffer[11] & buffer[4] == buffer[10])
				curMatch = 3'd4;           
			else if(buffer[7] == buffer[13] & buffer[6] == buffer[12] & buffer[5] == buffer[11])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[13] & buffer[6] == buffer[12])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[13])
				curMatch = 3'd1;
			else    
				curMatch = 3'd0;
		end
		OFFSET_4: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[12] & buffer[6] == buffer[11] & buffer[5] == buffer[10] & buffer[4] == buffer[9] & buffer[3] == buffer[8] & buffer[2] == buffer[7] & buffer[1] == buffer[6])
				curMatch = 3'd7;                                                       
			else if(buffer[7] == buffer[12] & buffer[6] == buffer[11] & buffer[5] == buffer[10] & buffer[4] == buffer[9] & buffer[3] == buffer[8] & buffer[2] == buffer[7])
				curMatch = 3'd6;                                 
			else if(buffer[7] == buffer[12] & buffer[6] == buffer[11] & buffer[5] == buffer[10] & buffer[4] == buffer[9] & buffer[3] == buffer[8])
				curMatch = 3'd5;                      
			else if(buffer[7] == buffer[12] & buffer[6] == buffer[11] & buffer[5] == buffer[10] & buffer[4] == buffer[9])
				curMatch = 3'd4;           
			else if(buffer[7] == buffer[12] & buffer[6] == buffer[11] & buffer[5] == buffer[10])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[12] & buffer[6] == buffer[11])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[12])
				curMatch = 3'd1;
			else    
				curMatch = 3'd0;
		end
		OFFSET_3: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[11] & buffer[6] == buffer[10] & buffer[5] == buffer[9] & buffer[4] == buffer[8] & buffer[3] == buffer[7] & buffer[2] == buffer[6] & buffer[1] == buffer[5])
				curMatch = 3'd7;                                                 
			else if(buffer[7] == buffer[11] & buffer[6] == buffer[10] & buffer[5] == buffer[9] & buffer[4] == buffer[8] & buffer[3] == buffer[7] & buffer[2] == buffer[6])
				curMatch = 3'd6;                                 
			else if(buffer[7] == buffer[11] & buffer[6] == buffer[10] & buffer[5] == buffer[9] & buffer[4] == buffer[8] & buffer[3] == buffer[7])
				curMatch = 3'd5;                      
			else if(buffer[7] == buffer[11] & buffer[6] == buffer[10] & buffer[5] == buffer[9] & buffer[4] == buffer[8])
				curMatch = 3'd4;           
			else if(buffer[7] == buffer[11] & buffer[6] == buffer[10] & buffer[5] == buffer[9])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[11] & buffer[6] == buffer[10])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[11])
				curMatch = 3'd1;
			else    
				curMatch = 3'd0;
		end
		OFFSET_2: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[10] & buffer[6] == buffer[9] & buffer[5] == buffer[8] & buffer[4] == buffer[7] & buffer[3] == buffer[6] & buffer[2] == buffer[5] & buffer[1] == buffer[4])
				curMatch = 3'd7;                                                  
			else if(buffer[7] == buffer[10] & buffer[6] == buffer[9] & buffer[5] == buffer[8] & buffer[4] == buffer[7] & buffer[3] == buffer[6] & buffer[2] == buffer[5])
				curMatch = 3'd6;                                 
			else if(buffer[7] == buffer[10] & buffer[6] == buffer[9] & buffer[5] == buffer[8] & buffer[4] == buffer[7] & buffer[3] == buffer[6])
				curMatch = 3'd5;                    
			else if(buffer[7] == buffer[10] & buffer[6] == buffer[9] & buffer[5] == buffer[8] & buffer[4] == buffer[7])
				curMatch = 3'd4;           
			else if(buffer[7] == buffer[10] & buffer[6] == buffer[9] & buffer[5] == buffer[8])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[10] & buffer[6] == buffer[9])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[10])
				curMatch = 3'd1;
			else    
				curMatch = 3'd0;
		end
		OFFSET_1: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[9] & buffer[6] == buffer[8] & buffer[5] == buffer[7] & buffer[4] == buffer[6] & buffer[3] == buffer[5] & buffer[2] == buffer[4] & buffer[1] == buffer[3])
				curMatch = 3'd7;                     	
			else if(buffer[7] == buffer[9] & buffer[6] == buffer[8] & buffer[5] == buffer[7] & buffer[4] == buffer[6] & buffer[3] == buffer[5] & buffer[2] == buffer[4])
				curMatch = 3'd6;                                 
			else if(buffer[7] == buffer[9] & buffer[6] == buffer[8] & buffer[5] == buffer[7] & buffer[4] == buffer[6] & buffer[3] == buffer[5])
				curMatch = 3'd5;                      
			else if(buffer[7] == buffer[9] & buffer[6] == buffer[8] & buffer[5] == buffer[7] & buffer[4] == buffer[6])
				curMatch = 3'd4;           
			else if(buffer[7] == buffer[9] & buffer[6] == buffer[8] & buffer[5] == buffer[7])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[9] & buffer[6] == buffer[8])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[9])
				curMatch = 3'd1;
			else    
				curMatch = 3'd0;
		end
		OFFSET_0: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
			if(buffer[7] == buffer[8] & buffer[6] == buffer[7] & buffer[5] == buffer[6] & buffer[4] == buffer[5] & buffer[3] == buffer[4] & buffer[2] == buffer[3] & buffer[1] == buffer[2])
				curMatch = 3'd7;                                                  
			else if(buffer[7] == buffer[8] & buffer[6] == buffer[7] & buffer[5] == buffer[6] & buffer[4] == buffer[5] & buffer[3] == buffer[4] & buffer[2] == buffer[3])
				curMatch = 3'd6;                                 
			else if(buffer[7] == buffer[8] & buffer[6] == buffer[7] & buffer[5] == buffer[6] & buffer[4] == buffer[5] & buffer[3] == buffer[4])
				curMatch = 3'd5;                      
			else if(buffer[7] == buffer[8] & buffer[6] == buffer[7] & buffer[5] == buffer[6] & buffer[4] == buffer[5])
				curMatch = 3'd4;           
			else if(buffer[7] == buffer[8] & buffer[6] == buffer[7] & buffer[5] == buffer[6])
				curMatch = 3'd3;
			else if(buffer[7] == buffer[8] & buffer[6] == buffer[7])
				curMatch = 3'd2;
			else if(buffer[7] == buffer[8])
				curMatch = 3'd1;
			else    
				curMatch = 3'd0;
		end
		READ: begin
			{encode,finish,valid} = 3'b100;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
		end
		OUTPUT: begin
			{encode,finish,valid} = 3'b101;
			offset = offset_new;
			match_len = maxMatch;
			case(maxMatch)
				'd0: char_nxt = buffer[7];
				'd1: char_nxt = buffer[6];
				'd2: char_nxt = buffer[5];
				'd3: char_nxt = buffer[4];
				'd4: char_nxt = buffer[3];
				'd5: char_nxt = buffer[2];
				'd6: char_nxt = buffer[1];
				'd7: char_nxt = buffer[0];
			endcase
		end
		FINISH: begin
			{encode,finish,valid} = 3'b110;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
		end
		default: begin
			{encode,finish,valid} = 3'b000;
			offset = 4'd0;
			match_len = 3'd0;
			char_nxt = 8'h0;
		end
	endcase
end
endmodule

