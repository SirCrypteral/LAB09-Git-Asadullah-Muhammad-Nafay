`timescale 1ns / 1ps

module Top (
    input  wire        clk,
    input  wire        btnC,   // reset
    input  wire        btnR,   // hold: freeze the display while pressed
    input  wire [15:0] sw,
    output wire [15:0] led
);
    // Debounced buttons
    wire rst, hold;
    debouncer db_rst  (.clk(clk), .pbin(btnC), .pbout(rst));
    debouncer db_hold (.clk(clk), .pbin(btnR), .pbout(hold));

    // Switch interface (module named "leds")
    wire [31:0] sw_data;
    leds sw_reader (
        .clk(clk), .rst(rst), .btns(16'd0),
        .writeData(32'd0), .writeEnable(1'b0), .readEnable(1'b1),
        .memAddress(30'd0), .switches(sw), .readData(sw_data)
    );

    // Switch fields: sw[6:0]=opcode, sw[9:7]=funct3, sw[10]=funct7[5]
    wire [6:0] opcode_live = sw_data[6:0];
    wire [2:0] funct3_live = sw_data[9:7];
    wire [6:0] funct7_live = {1'b0, sw_data[10], 5'b00000};

    // FSM: S_SAMPLE (read switches) -> S_UPDATE (control path settles) -> S_SAMPLE ...
    localparam S_SAMPLE = 1'b0, S_UPDATE = 1'b1;
    reg state;
    reg [6:0] opcode_r;
    reg [2:0] funct3_r;
    reg [6:0] funct7_r;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_SAMPLE;
            opcode_r <= 7'd0;
            funct3_r <= 3'd0;
            funct7_r <= 7'd0;
        end else begin
            case (state)
                S_SAMPLE: begin
                    if (!hold) begin           // btnR held = freeze current result
                        opcode_r <= opcode_live;
                        funct3_r <= funct3_live;
                        funct7_r <= funct7_live;
                    end
                    state <= S_UPDATE;
                end
                S_UPDATE: state <= S_SAMPLE;
                default:  state <= S_SAMPLE;
            endcase
        end
    end

    // Control path
    wire RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch;
    wire [1:0] ALUOp;
    wire [2:0] ALUCtl;

    MainControl mc (
        .opcode(opcode_r), .RegWrite(RegWrite), .ALUSrc(ALUSrc),
        .MemRead(MemRead), .MemWrite(MemWrite), .MemtoReg(MemtoReg),
        .Branch(Branch), .ALUOp(ALUOp)
    );
    ALUControl ac (
        .ALUOp(ALUOp), .funct3(funct3_r), .funct7(funct7_r),
        .ALUControl(ALUCtl)
    );

    // Heartbeat: led[15] blinks about every 1.3 s
    reg [26:0] hb = 27'd0;
    always @(posedge clk) hb <= hb + 1'b1;

    // LED map: [0]RegWrite [1]ALUSrc [2]MemRead [3]MemWrite [4]MemtoReg
    //          [5]Branch [7:6]ALUOp [10:8]ALUControl [14:11]unused [15]heartbeat
    wire [15:0] led_val = {hb[26], 4'b0000, ALUCtl, ALUOp, Branch, MemtoReg, MemWrite, MemRead, ALUSrc, RegWrite};

    // LED interface (module named "switches")
    switches led_writer (
        .clk(clk), .rst(rst),
        .writeData({16'd0, led_val}), .writeEnable(1'b1),
        .readEnable(1'b0), .memAddress(30'd0),
        .readData(), .leds(led)
    );
endmodule