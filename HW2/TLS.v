module TLS(clk, reset, Set, Stop, Jump, Gin, Yin, Rin, Gout, Yout, Rout);
input           clk;
input           reset;
input           Set;
input           Stop;
input           Jump;
input     [3:0] Gin;
input     [3:0] Yin;
input     [3:0] Rin;
output reg      Gout;
output reg      Yout;
output reg      Rout;

reg [1:0] State=2'b0, NextState=2'b0; // 1,2,3 correspond to G,Y,R
reg [3:0] Count, NextCount;
reg [3:0] Gt, Yt, Rt; //time of each state

//State Reg
always @(posedge clk or posedge reset)
begin
  if (reset) begin
    State <= 2'd1;
    Count <= 4'd0;
  end
  else if (Set) begin
    State <= 2'd1;
    Count <= 4'd0;
    Gt <= Gin;
    Yt <= Yin;
    Rt <= Rin;
  end
  else if (Stop) begin
    State <= State;
    Count <= Count;
  end
  else if (Jump) begin
    State <= 2'd3;
    Count <= 4'd0;
  end
  else begin
    State <= NextState;
    Count <= NextCount;
  end
end

//Next state logic
always @(*)
begin
  case(State)
    2'd0: begin
      NextState = 2'd0;
      NextCount = Count;
    end
    2'd1: begin //G
      if(Count==Gt-1) begin //G->Y
        NextState = 2'd2;
        NextCount = 4'd0;
      end
      else begin //Stay in G
        NextState = 2'd1;
        NextCount = Count + 4'd1;
      end
    end
    2'd2: begin //Y
      if(Count==Yt-1) begin //Y->R
        NextState = 2'd3;
        NextCount = 4'd0;
      end
      else begin //Stay in Y
        NextState = 2'd2;
        NextCount = Count + 4'd1;
      end
    end
    2'd3: begin //R
      if(Count==Rt-1) begin //R->G
        NextState = 2'd1;
        NextCount = 4'd0;
      end
      else begin //Stay in R
        NextState = 2'd3;
        NextCount = Count + 4'd1;
      end
    end
  endcase
end

//output logic
always @(State)
begin
  case (State)
    2'd0: begin
      Gout = 1'b0; Yout = 1'b0; Rout = 1'b0;
    end
    2'd1: begin
      Gout = 1'b1; Yout = 1'b0; Rout = 1'b0;
    end
    2'd2: begin
      Gout = 1'b0; Yout = 1'b1; Rout = 1'b0;
    end
    2'd3: begin
      Gout = 1'b0; Yout = 1'b0; Rout = 1'b1;
    end
  endcase
end
endmodule