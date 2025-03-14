module LZ77_Decoder(clk,reset,ready,code_pos,code_len,chardata,encode,finish,char_nxt);
input 				clk;
input 				reset;
input				ready; // When ready signal is high, the input code(code_pos, code_len, chardata) is valid.
input 		[4:0] 	code_pos;
input 		[4:0] 	code_len;
input 		[7:0] 	chardata;
output reg 			encode;
output reg 			finish;
output reg	[7:0] 	char_nxt;


	/*-------------------------------------/
	/		Write your code here~		   /
	/-------------------------------------*/

reg [7:0] buffer [29:0]; //The search buffer is 30 characters long
reg [4:0] Count;
integer i;

always @(posedge clk, posedge reset) begin
	if(reset) begin
		for (i=0; i<30; i=i+1) begin
			buffer[i] <= 8'h0;
		end
		finish <= 0;
		encode <= 0;
		char_nxt <= 0;
		Count <= 0;
	end
	else begin
		for (i=1; i<30; i=i+1) begin
			buffer[i] <= (ready==1)? buffer[i-1]: buffer[i];
		end
		if (Count == code_len) begin
			Count <= (ready==1)? 0: Count;
			char_nxt <= (ready==1)? chardata: char_nxt;
			buffer[0] <= (ready==1)? chardata: buffer[0];
		end
		else begin
			Count <= (ready==1)? Count+1: Count;
			char_nxt <= (ready==1)? buffer[code_pos]: char_nxt;
			buffer[0] <= (ready==1)? buffer[code_pos]: buffer[0];
		end
		finish <= (char_nxt==8'h24 && ready==1) ? 1'b1 : 1'b0;
	end
end
endmodule
