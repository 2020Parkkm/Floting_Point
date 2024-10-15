module FPMUL(opA_i, opB_i, MUL_o);
    input [15:0] opA_i;
    input [15:0] opB_i;
    output reg [15:0] MUL_o;

/*
step 0: XOR sign
step 1: exponent adder
step 2: fraction multiplier
step 3: consider the exception(zero case)
step 4: shift when fraction is too big or too small
step 5: consider the exception(overflow)
step 6: rounding
*/
reg A_sign, B_sign;
reg [4:0] A_ex, B_ex;
reg [9:0] A_man, B_man;

//MUL_o = {MUL_sign, MUL_ex, MUL_man}
reg MUL_sign;
reg [4:0] MUL_ex;
reg [9:0] MUL_man;

//temporary 
reg [31:0] temp_fr;
reg [6:0] temp_ex;

//bit of considering round(need: 1)
reg round;

always@* begin
	//declare each bit
	if(((opA_i & opB_i) == 0) | ((opA_i[14:10] | opB_i[14:10]) == 5'b11111))
		MUL_o = 0;
	else begin
		{A_sign, A_ex, A_man} = opA_i;
    	{B_sign, B_ex, B_man} = opB_i;

	//sign
		MUL_sign = (A_sign ^ B_sign);

	//exponent (consider overflow)
		temp_ex = A_ex + B_ex - 5'b01111;
		MUL_ex = (temp_ex[6:5] == 0) ? temp_ex[4:0] : 0;

	//multiple
		temp_fr = {1'b1, A_man} * {1'b1, B_man};
		if(temp_fr[12] == 1'b1)
			MUL_ex = MUL_ex+1;
		while(temp_fr[31] == 0) begin
			temp_fr = temp_fr << 1; 
		end

		round = (temp_fr[20:18] == 3'd0) ? 1'b0 : 1'b1;
		MUL_man = (round) ? (temp_fr[30:21] + 1) : temp_fr[30:21];


		if((MUL_ex | MUL_man)==0) //0
			MUL_o = 0;
		else if(temp_ex >= 7'b0011111) //exponent overflow
			MUL_o = 0;
		else if((MUL_ex == 5'b11111) & (MUL_man == 0)) //result overflow
			MUL_o = 0;
		else
			MUL_o = {MUL_sign, MUL_ex, MUL_man};
	end
end
endmodule
