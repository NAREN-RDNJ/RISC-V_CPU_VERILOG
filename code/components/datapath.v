
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input [1:0]   ImmSrc,
    input [3:0]   ALUControl,
	 input Jalr,
    output        Zero,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
	 output AluR31
);

wire [31:0] PCNext, PCPlus4, PCTarget,AuiPC,lAuiPC,PCJalr;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;
reg [31:0] LoadData;

// next PC logic
reset_ff #(32) pcreg(clk, reset, PCNext, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PC, ImmExt, PCTarget);
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
mux2 #(32)		jalrmux(PCNext,ALUResult,Jalr,PCJalr);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

// ALU logic
mux2 #(32)     srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
alu            alu (SrcA, SrcB, ALUControl, ALUResult, Zero);
adder #(32) auipcadder({Instr[31:12],12'b0},PC,AuiPC);//lui aui
mux2 #(32) lauipcmux (AuiPC,{Instr[31:12],12'b0},Instr[5],lAuiPC);//lui aui

always @(*) begin
    case (Instr[14:12])  // funct3 field
        3'b010: LoadData = ReadData;                 // lw
        3'b101: LoadData = {16'b0, ReadData[15:0]};  // lhu (zero-extend)
        3'b100: LoadData = {24'b0, ReadData[7:0]};   // lbu (zero-extend byte)
		  3'b001: LoadData = {{16{ReadData[15]}}, ReadData[15:0]}; // LH (sign-extend)
        3'b000: LoadData = {{24{ReadData[7]}}, ReadData[7:0]};   // LB (sign-extend)
        default: LoadData = ALUResult;                // Default case
    endcase
end

mux4 #(32)     resultmux(ALUResult, LoadData, PCPlus4,lAuiPC, ResultSrc, Result);

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;
assign AluR31 = ALUResult[31];

endmodule

