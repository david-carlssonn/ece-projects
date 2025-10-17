`timescale 1ns / 1ps

module clock_top(
    input CLK100MHZ,
    input btnC, btnU, btnD, btnL, btnR,
    output alarm_sound,
    output [6:0] seg,
    output [3:0] an
);

    wire [3:0] alarm_min;
    wire [3:0] alarm_minten;
    wire [3:0] alarm_hour;
    wire [3:0] alarm_hourten;
    wire alarm_mode;
    wire btnC_debounced;

    alarm U00 (
        .CLK100MHZ(CLK100MHZ),
        .btnC(btnC),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .alarm_min(alarm_min),
        .alarm_minten(alarm_minten),
        .alarm_hour(alarm_hour),
        .alarm_hourten(alarm_hourten),
        .alarm_mode(alarm_mode),
        .btnC_debounced(btnC_debounced)
    );

    digital_clk U01 (
        .hourten(alarm_hourten),
        .hour(alarm_hour),
        .minten(alarm_minten),
        .min(alarm_min),
        .CLK100MHZ(CLK100MHZ),
        .alarm_flag(alarm_mode),
        .btn_reset(btnC_debounced),
        .alarm_sound(alarm_sound),
        .seg(seg),
        .an(an)
    );

endmodule
