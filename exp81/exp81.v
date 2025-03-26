module exp81(
    input wire clk,  // 外部时钟输入
    input wire rst_n, // 外部复位信号输入
    input wire [3:0] key_in, // 外部按键输入
    output wire [3:0] key_out, // 输出到外部的按键信号
    output wire [7:0] seg, // 输出到数码管的段选信号
    output wire [2:0] sel, // 输出到数码管的位选信号
    output wire led1, // 输出到 LED 的信号
    output wire led2,
    output wire led3,
    output wire led4,
    output wire led5
);

    // 中间信号
    wire [3:0] key_value;
    wire key_valid;
    wire [31:0] display_num;
    wire [31:0] error_count;
    wire start_count4, start_count5;

    // 实例化按键扫描模块
    KeyValue key_inst(
       .CLK(clk),
       .nRST(rst_n),
       .KEY_COL(key_in),      // 按键列
       .KEY_ROW(key_out),     // 按键行
       .KEY_Value(key_value),  // 按键值
       .Value_en(key_valid)    // 按键有效信号
    );

    // 实例化数码管显示模块
    smg_display smg_inst(
       .clk(clk),
       .rst_n(rst_n),
       .number(display_num),
       .seg(seg),
       .sel(sel)
    );

    // 实例化密码锁逻辑模块
    mm_lock mm_lock_inst (
       .clk(clk),
       .rst_n(rst_n),
       .key_value(key_value),
       .key_valid(key_valid),
       .display_num(display_num),
       .led1(led1),
       .led2(led2),
       .led3(led3),
       .error_count(error_count),
       .start_count4(start_count4),
       .start_count5(start_count5)
    );

    // 实例化报警控制模块
    warning warning_inst(
        .clk(clk),
        .rst_n(rst_n),
        .error_count(error_count),
        .start_count4(start_count4),
        .start_count5(start_count5),
        .led4(led4),
        .led5(led5)
    );
    
endmodule