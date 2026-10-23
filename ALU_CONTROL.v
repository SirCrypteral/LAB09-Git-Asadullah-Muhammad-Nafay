module ALUControl (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [2:0] ALUControl
);
    always @(*) begin
        casez ({ALUOp, funct7, funct3})
            12'b00_???????_???: ALUControl = 3'b010; // ADD (load/store address)
            12'b01_???????_???: ALUControl = 3'b110; // SUB (BEQ)
            12'b10_0000000_000: ALUControl = 3'b010; // ADD
            12'b10_0100000_000: ALUControl = 3'b110; // SUB
            12'b10_0000000_001: ALUControl = 3'b100; // SLL
            12'b10_0000000_100: ALUControl = 3'b011; // XOR
            12'b10_0000000_101: ALUControl = 3'b101; // SRL
            12'b10_0000000_110: ALUControl = 3'b001; // OR
            12'b10_0000000_111: ALUControl = 3'b000; // AND
            12'b11_???????_000: ALUControl = 3'b010; // ADDI -> ADD
            default:            ALUControl = 3'b010; // safe default
        endcase
    end
endmodule