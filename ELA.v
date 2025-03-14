`timescale 1ns/10ps

module ELA(clk, rst, ready, in_data, data_rd, req, wen, addr, data_wr, done);

	input				clk;
	input				rst;
	input				ready;
	input		[7:0]	in_data;
	input		[7:0]	data_rd;
	output reg				req;
	output reg				wen;
	output reg		[12:0]	addr;
	output reg		[7:0]	data_wr;
	output reg				done;


reg [6:0] x,a;
reg [6:0] y,b;
//reg [7:0] original_img [0:31][0:15];//
reg [7:0] img [0:127][0:62];
reg [7:0] img_check, imgab,imga1b;//
reg [2:0] state, n_state;
reg [8:0]D1,D2,D3;
reg [12:0] interpolation_count;
parameter [3:0] REQUEST = 4'd0, DATAIN = 4'd1, INTERPOLATION = 4'd2;
parameter [3:0] WRITEX = 4'd3, WRITEY = 4'd4, WRITE_REST = 4'd5;
parameter [3:0] READ_FINISH = 4'd6, INTERPOLATION_FINISH = 4'd7;


always@(posedge clk) begin
  
  if (rst) begin
    req<=0;
    x<=7'd0;a<=7'd0;
    y<=7'd0;b<=7'd0;
    //D1<=9'd0;D2<=9'd0;D3<=9'd0;
    interpolation_count<=13'd0;
    data_wr<=8'd0;
    state<=REQUEST;
  end
  
  else if (ready)begin
      
      case(state)
        REQUEST: begin
          req<=1;
          //wen <= 1;
        end
        DATAIN:  begin
          req<=0;
          img[x][y]<=in_data;
          
          //tuning wen, incase overflow happens but write wrong value
          if (x == 7'd0 &&y  == 7'd64) wen<=0;
          else wen <= 1;
            
          addr<=(128*y+x);
          data_wr<=in_data;//write
          
          if (x!=7'd0) img_check<= img[x-1][y];
          x<=x+7'd1;
          if(x == 7'd127) y<=y+7'd2;
        end
        
        INTERPOLATION:begin
          interpolation_count<=interpolation_count+13'd1;
          wen <= 1;
          addr <= (128*b+a);
  
          if (a>0 && a<127)begin
			  /* hw4 algorithm!!!!!  PSNR = 23.8
            if      (D2<=D1 && D2<=D3) data_wr <= (img[a][b-1]+img[a][b+1])/2;
            else if (D1<=D2 && D1<=D3) data_wr <= (img[a-1][b-1]+img[a+1][b+1])/2;
            else if (D3<=D1 && D3<=D2) data_wr <= (img[a+1][b-1]+img[a-1][b+1])/2;
            else begin end 
            img[a][b]<=data_wr;//dont write into img to save time
            a <= a+7'd1;
			*/
			 /* try1, PSNR = 12.9
			data_wr <= ((img[a-1][b-1]+img[a-1][b+1]) + (img[a+1][b-1]+img[a+1][b+1])/8)+(img[a][b-1]+img[a][b+1])/4;
			a <= a+7'd1;
			*/
			
			//original weight:[121][242][121] //bilinear interpolation
            data_wr<=((img[a-1][b-1]+3*img[a][b-1]+img[a+1][b-1]) + (1*img[a-1][b]+12*img[a][b]+1*img[a+1][b]) + (img[a-1][b+1]+3*img[a][b+1]+img[a+1][b+1]))/24;

			img_check<= img[a-1][b];
            a <= a+7'd1;

		  end
  
          else if (a == 7'd0 && b == 7'd63)begin
            //n_state = INTERPOLATION_FINISH;
            wen <= 0;
          end
  
          else if (a == 7'd0) begin
            data_wr <= (img[a][b-1]+img[a][b+1])/2;
            //img[a][b]<=data_wr;
			img[a][b]<=(img[a][b-1]+img[a][b+1])/2;
            a <= a+7'd1;
          end
  
  
          else begin
            data_wr <= (img[a][b-1]+img[a][b+1])/2;
            img[a][b]=data_wr;
            a <= 7'd0;
            b <= b+7'd2;
          end
  
  

        end
        
        READ_FINISH:begin
          a<=7'd0;
          b<=7'd1;
          wen <= 0;
          addr <= (32*b+a);
        end
        INTERPOLATION_FINISH: begin
          done<=1;
        end
      endcase
      
      state<=n_state;  
        
  end
end   


//next_state()
always@(*)begin
   case(state)
     REQUEST: begin
       if(x==7'd127) n_state<=REQUEST;
       else n_state<=DATAIN;
     end
     DATAIN: begin
       if(x==7'd127) begin n_state<=REQUEST;  end //y<=y+1;should not be here
       else if(y >= 7'd63) begin n_state<=READ_FINISH; end
       else n_state<=DATAIN;
     end
     READ_FINISH:
       n_state<=INTERPOLATION;
     INTERPOLATION:
       if (a == 7'd0 && b == 7'd63)begin
          n_state <= INTERPOLATION_FINISH;//
       end
       else 
          n_state <= INTERPOLATION;
     //INTERPOLATION_FINISH:

    endcase
end


always@(interpolation_count)begin
  //reference point: img[a][b]

if (state == INTERPOLATION)begin
  //wen = 1;
  //addr = (32*b+a);
  //img[a][b]=data_wr;
  if (a>0 && a<127)begin
    D1 = ((img[a-1][b-1]>img[a+1][b+1]))? (img[a-1][b-1]-img[a+1][b+1]):(img[a+1][b+1]-img[a-1][b-1]);
    D2 = ((img[a][b-1]>img[a][b+1]))? (img[a][b-1]-img[a][b+1]):(img[a][b+1]-img[a][b-1]);
    D3 = ((img[a+1][b-1]>img[a-1][b+1]))? (img[a+1][b-1]-img[a-1][b+1]):(img[a-1][b+1]-img[a+1][b-1]);
    
	// below is added(different from hw4)(line 172~line188)
	if      (D2<=D1 && D2<=D3) img[a][b] = (img[a][b-1]+img[a][b+1])/2;
    else if (D1<=D2 && D1<=D3) img[a][b] = (img[a-1][b-1]+img[a+1][b+1])/2;
    else if (D3<=D1 && D3<=D2) img[a][b] = (img[a+1][b-1]+img[a-1][b+1])/2;
	
	//(a+1,b)
	if (a == 126) begin
		img[a+1][b] = (img[a+1][b-1]+img[a+1][b+1])/2;
	end
	else begin
		D1 = ((img[a][b-1]>img[a+2][b+1]))? (img[a][b-1]-img[a+2][b+1]):(img[a+2][b+1]-img[a][b-1]);
		D2 = ((img[a+1][b-1]>img[a+1][b+1]))? (img[a+1][b-1]-img[a+1][b+1]):(img[a+1][b+1]-img[a+1][b-1]);
		D3 = ((img[a+2][b-1]>img[a][b+1]))? (img[a+2][b-1]-img[a][b+1]):(img[a][b+1]-img[a+2][b-1]);

		if      (D2<=D1 && D2<=D3) img[a+1][b] = (img[a+1][b-1]+img[a+1][b+1])/2;
		else if (D1<=D2 && D1<=D3) img[a+1][b] = (img[a][b-1]+img[a+2][b+1])/2;
		else if (D3<=D1 && D3<=D2) img[a+1][b] = (img[a+2][b-1]+img[a][b+1])/2;
	end
	//imgab = img[a][b];
	//imga1b = img[a+1][b];
	//img[a][b] = ((img[a-1][b-1]+2*img[a][b-1]+img[a+1][b-1]) + (2*img[a-1][b]+4*img[a][b]+2*img[a+1][b]) + (img[a-1][b+1]+2*img[a][b+1]+img[a+1][b+1]))/4;
  end
  
  else if (a == 7'd0 && b == 7'd31)begin
    //n_state = INTERPOLATION_FINISH;//
    //wen = 0;
  end
  
  else if (a == 7'd0) begin
    //data_wr = (img[a][b-1]+img[a][b+1])/2;
    //img[a][b]=data_wr;//dont write into img to save time
    //a = a+5'd1;
  end
  
  
  else begin
    //data_wr = (img[a][b-1]+img[a][b+1])/2;
    //img[a][b]=data_wr;//dont write into img to save time
    //a = 5'd0;
    //b = b+6'd2;
  end
  
  
end     
end

endmodule