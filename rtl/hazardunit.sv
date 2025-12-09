module hazardunit #(
) (
    input logic [4:0]   Rs1D_i,
    input logic [4:0]   Rs2D_i,
    input logic [4:0]   Rs1E_i,
    input logic [4:0]   Rs2E_i,
    input logic [4:0]   RdE_i,
    input logic         PCSrcE_i,
    input logic         ResultSrcE_i,   //first bit of ResultSrc
    input logic [4:0]   RdM_i,
    input logic         RegWriteM_i,
    input logic [4:0]   RdW_i,
    input logic         RegWriteW_i,
    input logic [31:0]  Instr_i,        //must come from DECODE

    output logic        StallF_o,
    output logic        StallD_o,
    output logic        FlushD_o,
    output logic        FlushE_o,
    output logic [1:0]  ForwardAE_o,
    output logic [1:0]  ForwardBE_o
);

logic [6:0] op;
assign op = Instr_i[6:0];

//forwarding:
always_comb begin
    if((Rs1E_i == RdM_i) && RegWriteM_i && (Rs1E_i != 0))
        ForwardAE_o = 2'b10;                              //forward from memory stage
    else if((Rs1E_i == RdW_i) && RegWriteW_i && (Rs1E_i != 0))
        ForwardAE_o = 2'b01;                              //forward from writeback stage
    else
        ForwardAE_o = 2'b00;                              //no forwarding

    if((Rs2E_i == RdM_i) && RegWriteM_i && (Rs2E_i != 0))
        ForwardBE_o = 2'b10;  
    else if((Rs2E_i == RdW_i) && RegWriteW_i && (Rs2E_i != 0))
        ForwardBE_o = 2'b01;  
    else
        ForwardBE_o = 2'b00;  
end

//stalling
logic lwStall;
logic jalrStall;
always_comb begin
    lwStall = (ResultSrcE_i && ((Rs1D_i == RdE_i) || (Rs2D_i == RdE_i)));  
    jalrStall = (op == 7'b1100111) && (((Rs1D_i == RdE_i) && ResultSrcE_i) || ((Rs1D_i == RdM_i) && RegWriteM_i)); 
    StallF_o = (lwStall || jalrStall);
    StallD_o = (lwStall || jalrStall);
    FlushD_o = PCSrcE_i; //flush when branch is taken or load introduces a bubble
    FlushE_o = (lwStall || jalrStall || PCSrcE_i);
end

endmodule
