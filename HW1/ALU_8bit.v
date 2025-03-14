module ALU_8bit(
	input [7:0] ALU_src1,
	input [7:0] ALU_src2,
	input Ainvert,
	input Binvert,
	input [1:0] op,
	output [7:0] result,
	output reg zero,
	output reg overflow
);

reg c_in = 1'b0;
wire OV[7:0];
wire set[7:0];
reg less1 = 1'b0;
reg less2 = 1'b0;
wire carry[7:0];

ALU_1bit ALU_1bit_0(.a(ALU_src1[0]), .b(ALU_src2[0]), .less(less1), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(c_in), .result(result[0]), .c_out(carry[0]), .set(set[0]), .overflow(OV[0]));
ALU_1bit ALU_1bit_1(.a(ALU_src1[1]), .b(ALU_src2[1]), .less(less2), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(carry[0]), .result(result[1]), .c_out(carry[1]), .set(set[1]), .overflow(OV[1]));
ALU_1bit ALU_1bit_2(.a(ALU_src1[2]), .b(ALU_src2[2]), .less(less2), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(carry[1]), .result(result[2]), .c_out(carry[2]), .set(set[2]), .overflow(OV[2]));
ALU_1bit ALU_1bit_3(.a(ALU_src1[3]), .b(ALU_src2[3]), .less(less2), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(carry[2]), .result(result[3]), .c_out(carry[3]), .set(set[3]), .overflow(OV[3]));
ALU_1bit ALU_1bit_4(.a(ALU_src1[4]), .b(ALU_src2[4]), .less(less2), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(carry[3]), .result(result[4]), .c_out(carry[4]), .set(set[4]), .overflow(OV[4]));
ALU_1bit ALU_1bit_5(.a(ALU_src1[5]), .b(ALU_src2[5]), .less(less2), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(carry[4]), .result(result[5]), .c_out(carry[5]), .set(set[5]), .overflow(OV[5]));
ALU_1bit ALU_1bit_6(.a(ALU_src1[6]), .b(ALU_src2[6]), .less(less2), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(carry[5]), .result(result[6]), .c_out(carry[6]), .set(set[6]), .overflow(OV[6]));
ALU_1bit ALU_1bit_7(.a(ALU_src1[7]), .b(ALU_src2[7]), .less(less2), .Ainvert(Ainvert), .Binvert(Binvert), .op(op), .c_in(carry[6]), .result(result[7]), .c_out(carry[7]), .set(set[7]), .overflow(OV[7]));

always @(*)
begin
	zero = result==0 ? 1 : 0;
	overflow = OV[7];
	c_in = Binvert? 1'b1: 1'b0; //for a-b, 2's complement
	less1 = set[7] ^ OV[7];
end
endmodule


