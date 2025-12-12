module execute #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0]    RD1E_i,
    input logic [DATA_WIDTH-1:0]    RD2E_i,
    input logic [DATA_WIDTH-1:0]    PCE_i,
    input logic [DATA_WIDTH-1:0]    ImmExtE_i,
    input logic [DATA_WIDTH-1:0]    PCPlus4E_i,
    
    input logic [4:0]               RdD_i,
    input logic [2:0]               BranchSrc_i, //controls branching MUX
    input logic [4:0]               Rs1E_i,  
    input logic [4:0]               Rs2E_i,      

    input logic [DATA_WIDTH-1:0]    ResultW_i,   //result from writeback
    input logic [DATA_WIDTH-1:0]    ALUResultM_i,

    /* verilator lint_off UNUSED */
    input logic                     RegWriteE_i,
    input logic [1:0]               ResultSrcE_i,
    input logic                     MemWriteE_i,
    /* verilator lint_on UNUSED */
    
    input logic                     JumpE_i,
    input logic                     BranchE_i,
    input logic [3:0]               ALUCtrlE_i,
    input logic                     ALUSrcE_i,
    input logic [1:0]               Op1SrcE_i,

    //from hazard unit
    input logic [1:0]               ForwardAEctrl_i,
    input logic [1:0]               ForwardBEctrl_i,

    // Prediction Input
    input logic                     PredictTakenE_i,

    //to hazard unit
    output logic [4:0]              Rs1E_o,
    output logic [4:0]              Rs2E_o,

    output logic [DATA_WIDTH-1:0]   ALUResultE_o,
    output logic [DATA_WIDTH-1:0]   WriteDataE_o,
    
    output logic [DATA_WIDTH-1:0]   PCPlus4E_o,
    output logic [4:0]              RdE_o,
    output logic                    branchTaken_o,
    output logic [DATA_WIDTH-1:0]   PCTargetE_o,
    output logic                    PCSrcE_o 
);
    logic [DATA_WIDTH-1:0]  SrcAE_Forwarded;

    // Resolve Forwarding for SrcA
    always_comb begin
        case(ForwardAEctrl_i)
            2'b00: SrcAE_Forwarded = RD1E_i;
            2'b01: SrcAE_Forwarded = ResultW_i;
            2'b10: SrcAE_Forwarded = ALUResultM_i;
            default: SrcAE_Forwarded = RD1E_i;
        endcase 
    end

    // Resolve Op1 Source (Reg vs PC vs Zero)
    logic [DATA_WIDTH-1:0]  SrcAE_Final;
    always_comb begin
        case(Op1SrcE_i)
            2'b00: SrcAE_Final = SrcAE_Forwarded;   // Normal (Rs1)
            2'b01: SrcAE_Final = PCE_i;             // AUIPC, JAL
            2'b10: SrcAE_Final = 32'b0;             // LUI
            default: SrcAE_Final = SrcAE_Forwarded; // Assign to Final, not Forwarded
        endcase
    end

    // Resolve Forwarding for SrcB (WriteData)
    always_comb begin
        case(ForwardBEctrl_i)
            2'b00: WriteDataE_o = RD2E_i;
            2'b01: WriteDataE_o = ResultW_i;
            2'b10: WriteDataE_o = ALUResultM_i;
            default: WriteDataE_o = RD2E_i;
        endcase 
    end

    // ALU SrcB Selection (Reg vs Imm)
    logic [DATA_WIDTH-1:0] SrcB_ALU;
    assign SrcB_ALU = (ALUSrcE_i) ? ImmExtE_i : WriteDataE_o;

    // ALU Instance
    ALU ALU(
        .srcA_i(SrcAE_Final), 
        .srcB_i(SrcB_ALU),
        .ALUCtrl_i(ALUCtrlE_i),
        .branch_i(BranchSrc_i),
        .ALUResult_o(ALUResultE_o),
        .branchTaken_o(branchTaken_o)
    );

    // Branch/Jump Target Logic
    logic [DATA_WIDTH-1:0] BranchTarget;
    assign PCPlus4E_o = PCPlus4E_i;
    assign BranchTarget = ImmExtE_i + PCE_i; // PC + Imm

    assign RdE_o = RdD_i;
    assign Rs1E_o = Rs1E_i;
    assign Rs2E_o = Rs2E_i;

    // Misprediction Logic
    logic ActualTaken;
    assign ActualTaken = (BranchE_i && branchTaken_o) || JumpE_i;

    // Flush if Actual decision != Predicted decision
    assign PCSrcE_o = (ActualTaken != PredictTakenE_i);

    // Target Calculation
    // If Actual=Taken:
    //    For Jumps (JumpE_i is high), the ALU calculates the target (PC+Imm for JAL, Rs1+Imm for JALR)
    //    For Branches, we use the BranchTarget adder (PC+Imm)
    // If Actual=NotTaken:
    //    We recover to PC+4
    assign PCTargetE_o = (ActualTaken) ? 
                         (JumpE_i ? ALUResultE_o : BranchTarget) : 
                         PCPlus4E_i;

endmodule
