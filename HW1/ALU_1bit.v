module ALU_1bit (
	input a,
	input b,
	input less,
	input Ainvert,
	input Binvert,
	input c_in,
	input [1:0] op,
	output reg result,
	output reg c_out,
	output reg set,
	output reg overflow
);

reg tempA;
reg tempB;
wire tempOut;
wire tempCout;

FA FA_1(.s(tempOut), .carry_out(tempCout), .x(tempA), .y(tempB), .carry_in(c_in));

always @(*)
begin
	tempA = (Ainvert==1'b1)? ~a: a;
	tempB = (Binvert==1'b1)? ~b: b;
	case(op)
		2'b00: begin //And & Nor
			result = tempA & tempB ;
		end
		2'b01: begin //Or & Nand
			result = tempA | tempB ;
		end
		2'b10: begin //Add & Sub
			result = tempOut;
			c_out = tempCout;
			overflow = c_in ^ c_out;
			// $display("%b,%b,%b \n", a, b, result);
		end
		2'b11: begin //SLT
			result = less; // The less signal will be passed to the result port.
			c_out = tempCout;
			overflow = c_in ^ c_out;
			set = (tempA~^tempB) ~^ c_in; //If the subtraction result is minus, the set port should output 1.
			//if tempA + tempB + c_in = x1, set = 1;
		end
	endcase
end
endmodule
