module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);
input 				clk;
input 				reset;
input 		[3:0] 	code_pos;
input 		[2:0] 	code_len;
input 		[7:0] 	chardata;
output reg 			encode;
output reg 			finish;
output reg	[7:0] 	char_nxt;

/*
	參考作業說明的Fig5，輸入信號會剛好持續code_len+1個clk，沒有多餘的clk
	因此直接在每個clk計算char_nxt，再把char_nxt插入buffer末端就行了，不用先把全部計算完再輸出
*/

reg [2:0] Count, NextCount;
//reg [7:0] buffer [0:8];
reg [7:0] buffer [8:0];
reg [7:0] char_tmp;
integer i;

always @(posedge clk, posedge reset) begin
	if(reset) begin
		for (i=0; i<9; i=i+1) begin
			buffer[i] <= 8'h0;
		end
		Count  <= 3'b0;
		finish <= 1'b0; // data input when !finish, 不設low的話資料不會進來
		encode <= 1'b0; // always low
	end
	else begin
		for (i=1; i<9; i=i+1) begin
			buffer[i] <= buffer[i-1];
		end
		Count <= NextCount;
		buffer[0] <= char_tmp;
		char_nxt  <= char_tmp; 
		finish <= (char_tmp == 8'h24) ? 1'b1 : 1'b0;
	end
end
// NextState(Count) & Output(char_nxt)
always @(*) begin
	if(code_len == 3'b0 || Count == code_len) begin
		NextCount = 3'b0;
		char_tmp = chardata; //不能在組合電路給char_nxt賦值，否則新資料進來就會跑掉，TB會取到錯的結果，一定要在正緣時賦值
	end
	else begin
		NextCount = Count + 3'b1;
		char_tmp = buffer[code_pos];
	end
end
endmodule