module FPADD(opA_i, opB_i, ADD_o);
	input [15:0] opA_i;
	input [15:0] opB_i;
	output reg [15:0] ADD_o;
/*
step 1: compare exponents
step 2: fraction adder
step 3: consider result=0
step 4: consider overflow and add 1 to the exponent
step 5: normalize
step 6: check overflow in exponent
step 7: rounding
*/
reg [15:0] opA_ii, opB_ii;

reg A_sign, B_sign;
reg [4:0] A_ex, B_ex;
reg [9:0] A_man, B_man;

reg [10:0] A_man_1, B_man_1;
reg [15:0] A_man_1_extend, B_man_1_extend;

reg [19:0] temp_1;

//ADD_o = {ADD_sign, ADD_ex, ADD_man}
reg ADD_sign;
reg [4:0] ADD_ex;
reg [9:0] ADD_man;

always@(*) begin
	//always (exponent of opA_ii) >= (exponent of opB_ii)
	if((opA_i[14:10] == 5'b00000) || (opB_i[14:10] == 5'b00000) || (opA_i[14:10] == 5'b11111) || (opB_i[14:10] == 5'b11111)) begin
        ADD_o = 0;
	end
	else begin
	{opA_ii, opB_ii} = (opA_i[14:10] >= opB_i[14:10]) ? {opA_i, opB_i} : {opB_i, opA_i};

	{A_sign, A_ex, A_man} = opA_ii;
	{B_sign, B_ex, B_man} = opB_ii;
	
	A_man_1 = {1'b1, A_man};
	B_man_1 = {1'b1, B_man};

	A_man_1_extend = {A_man_1,5'd0};
	B_man_1_extend = {B_man_1,5'd0};

	//equalize the exponet of B to the exponent of A
	//and put in ADD_man
	while (A_ex > B_ex) begin
		B_ex = B_ex + 1;
		B_man_1_extend = (B_man_1_extend[0]==1'b1) ?
		 ((B_man_1_extend >> 1) + 1) : (B_man_1_extend >> 1) ; //round
	end
	
	//add the fractions wildly
	temp_1 = (A_sign ^ B_sign) ? ((A_man_1_extend > B_man_1_extend) ? (A_man_1_extend-B_man_1_extend) : (B_man_1_extend-A_man_1_extend)):
								 (A_man_1_extend + B_man_1_extend);
	
	//decide ADD_sign
	if((A_sign==1) & (B_sign==0)) begin
		if(A_man_1_extend > B_man_1_extend)
			ADD_sign = 1;
		else
			ADD_sign = 0;
	end
	else if((A_sign==0) & (B_sign==1)) begin
		if(A_man_1_extend > B_man_1_extend)
			ADD_sign = 0;
		else
			ADD_sign = 1;
	end
	else if(A_sign & B_sign) begin
		ADD_sign = 1;
	end
	else begin
		ADD_sign = 0;
	end
	
	//put in ADD_ex
	ADD_ex = (A_ex == B_ex) ? A_ex : 0;

	//leading 1(normalization)
	if(temp_1[16]==1'b1) begin
		ADD_ex = ADD_ex+1;
		temp_1 = temp_1 >> 1;
	end
	else begin
		while(temp_1[15] != 1) begin
			ADD_ex = ADD_ex - 1;
			temp_1 = temp_1 << 1;
		end
	end
	
	//put in ADD_man
	ADD_man = (temp_1[4]==1) ? (temp_1[14:5] + 1) : (temp_1[14:5]);

	//exception
	case({ADD_ex, ADD_man})
		15'b11111_00000_00000: ADD_o = 0; //overflow
		15'b00000_00000_00000: ADD_o = 0; //zero
		default: ADD_o = {ADD_sign, ADD_ex, ADD_man};
	endcase
end
	end
	

endmodule
