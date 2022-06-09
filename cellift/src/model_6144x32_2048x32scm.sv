module model_6144x32_2048x32scm
(
    input  logic        CLK,
    input  logic        RSTN,

    input  logic        CEN,
    input  logic        CEN_scm0,
    input  logic        CEN_scm1,

    input  logic        WEN,
    input  logic        WEN_scm0,
    input  logic        WEN_scm1,

    input  logic  [3:0] BEN,
    input  logic  [3:0] BEN_scm0,

    input  logic [10:0] A,
    input  logic [10:0] A_scm0,
    input  logic [10:0] A_scm1,

    input  logic [31:0] D,
    input  logic [31:0] D_scm0,

    output logic [31:0] Q,
    output logic [31:0] Q_scm0,
    output logic [31:0] Q_scm1
);

    assign Q = '0;
    assign Q_scm0 = '0;
    assign Q_scm1 = '0;

endmodule
