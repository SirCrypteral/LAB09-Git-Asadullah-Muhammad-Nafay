`timescale 1ns/1ps

module tb_ControlPath;
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    reg  [8*5:1] curr_name;   // instruction label for the waveform

    wire       RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch;
    wire [1:0] ALUOp;
    wire [2:0] ALUControl;

    integer errors = 0;

    MainControl mc (
        .opcode(opcode), .RegWrite(RegWrite), .ALUSrc(ALUSrc),
        .MemRead(MemRead), .MemWrite(MemWrite), .MemtoReg(MemtoReg),
        .Branch(Branch), .ALUOp(ALUOp)
    );

    ALUControl ac (
        .ALUOp(ALUOp), .funct3(funct3), .funct7(funct7),
        .ALUControl(ALUControl)
    );

    // exp_main = {RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch, ALUOp}
    task check;
        input [8*5:1] name;
        input [6:0]   op;
        input [2:0]   f3;
        input [6:0]   f7;
        input [7:0]   exp_main;
        input [2:0]   exp_alu;
        begin
            opcode = op; funct3 = f3; funct7 = f7;
            curr_name = name;
            #10;
            if ({RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch, ALUOp} === exp_main
                && ALUControl === exp_alu)
                $display("PASS  %s", name);
            else begin
                $display("FAIL  %s  main=%b (exp %b)  alu=%b (exp %b)", name,
                    {RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch, ALUOp},
                    exp_main, ALUControl, exp_alu);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // R-type
        check("ADD",  7'b0110011, 3'b000, 7'b0000000, 8'b10000010, 3'b010);
        check("SUB",  7'b0110011, 3'b000, 7'b0100000, 8'b10000010, 3'b110);
        check("SLL",  7'b0110011, 3'b001, 7'b0000000, 8'b10000010, 3'b100);
        check("SRL",  7'b0110011, 3'b101, 7'b0000000, 8'b10000010, 3'b101);
        check("AND",  7'b0110011, 3'b111, 7'b0000000, 8'b10000010, 3'b000);
        check("OR",   7'b0110011, 3'b110, 7'b0000000, 8'b10000010, 3'b001);
        check("XOR",  7'b0110011, 3'b100, 7'b0000000, 8'b10000010, 3'b011);
        // I-type arithmetic (funct7 bits are immediate bits, so use a nonzero value to prove X)
        check("ADDI", 7'b0010011, 3'b000, 7'b0100000, 8'b11000011, 3'b010);
        // Loads
        check("LB",   7'b0000011, 3'b000, 7'b0000000, 8'b11101000, 3'b010);
        check("LH",   7'b0000011, 3'b001, 7'b0000000, 8'b11101000, 3'b010);
        check("LW",   7'b0000011, 3'b010, 7'b0000000, 8'b11101000, 3'b010);
        // Stores
        check("SB",   7'b0100011, 3'b000, 7'b0000000, 8'b01010000, 3'b010);
        check("SH",   7'b0100011, 3'b001, 7'b0000000, 8'b01010000, 3'b010);
        check("SW",   7'b0100011, 3'b010, 7'b0000000, 8'b01010000, 3'b010);
        // Branch
        check("BEQ",  7'b1100011, 3'b000, 7'b0000000, 8'b00000101, 3'b110);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule