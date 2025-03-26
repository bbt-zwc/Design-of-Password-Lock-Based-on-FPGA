`timescale 1ns / 1ps

module test;

    // 定义信号
    reg clk;
    reg rst_n;
    reg [3:0] key_value;
    reg key_valid;
    wire [31:0] display_num;
    wire led1;
    wire led2;
    wire led3;
    wire [31:0] error_count;
    wire start_count4;
    wire start_count5;

    // 实例化被测试模块
    mm_lock uut (
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

    // 时钟生成
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 20ns 周期，对应 50MHz 时钟
    end

    // 测试序列
    initial begin
        // 初始化信号
        rst_n = 0;
        key_value = 4'h0;
        key_valid = 0;
        #20; // 保持复位一段时间
        rst_n = 1; // 释放复位信号

        // 模拟输入正确密码以解锁
        #100;
        key_valid = 1;
        key_value = 4'h1; #20;
        key_value = 4'h2; #20;
        key_value = 4'h3; #20;
        key_value = 4'h4; #20;
        key_value = 4'h5; #20;
        key_value = 4'h6; #20;
        key_value = 4'h7; #20;
        key_value = 4'h8; #20;
        key_value = 4'hA; #20; // 确认输入
        key_valid = 0;

        // 等待一段时间确保解锁成功
        #200;

        // 模拟清空显示操作（解锁状态）
        key_valid = 1;
        key_value = 4'hC; #20;
        key_valid = 0;

        // 等待一段时间
        #200;

        // 模拟切换到修改密码模式（在解锁状态下）
        key_valid = 1;
        key_value = 4'hD; #20;
        key_valid = 0;

        // 等待一段时间
        #200;

        // 模拟第一次输入新密码
        key_valid = 1;
        key_value = 4'h9; #20;
        key_value = 4'h8; #20;
        key_value = 4'h7; #20;
        key_value = 4'h6; #20;
        key_value = 4'h5; #20;
        key_value = 4'h4; #20;
        key_value = 4'h3; #20;
        key_value = 4'h2; #20;
        key_value = 4'hA; #20; // 第一次确认输入
        key_valid = 0;

        // 等待一段时间
        #200;

        // 模拟第二次输入新密码
        key_valid = 1;
        key_value = 4'h9; #20;
        key_value = 4'h8; #20;
        key_value = 4'h7; #20;
        key_value = 4'h6; #20;
        key_value = 4'h5; #20;
        key_value = 4'h4; #20;
        key_value = 4'h3; #20;
        key_value = 4'h2; #20;
        key_value = 4'hA; #20; // 第二次确认输入
        key_valid = 0;

        // 等待一段时间确保密码修改完成
        #200;

        // 模拟显示密码操作（在解锁状态下）
        key_valid = 1;
        key_value = 4'hE; #20;
        key_valid = 0;

        // 等待一段时间
        #200;

        // 模拟锁定操作
        key_valid = 1;
        key_value = 4'hB; #20;
        key_valid = 0;

        // 等待一段时间确保锁定成功
        #200;

        // 模拟输入错误密码
        key_valid = 1;
        key_value = 4'h8; #20;
        key_value = 4'h7; #20;
        key_value = 4'h6; #20;
        key_value = 4'h5; #20;
        key_value = 4'h4; #20;
        key_value = 4'h3; #20;
        key_value = 4'h2; #20;
        key_value = 4'h1; #20;
        key_value = 4'hA; #20; // 确认输入
        key_valid = 0;

        // 等待一段时间
        #200;

        // 模拟清空显示操作（锁定状态）
        key_valid = 1;
        key_value = 4'hC; #20;
        key_valid = 0;

        // 等待一段时间
        #200;

        // 尝试在锁定状态下切换修改密码模式（应无效）
        key_valid = 1;
        key_value = 4'hD; #20;
        key_valid = 0;

        // 等待一段时间
        #200;

        // 尝试在锁定状态下显示密码（应无效）
        key_valid = 1;
        key_value = 4'hE; #20;
        key_valid = 0;

        // 结束仿真
        #200;
        $finish;
    end

    // 监控信号
    initial begin
        $monitor("Time: %0t, key_value: %h, key_valid: %b, display_num: %h, led1: %b, led2: %b, led3: %b, error_count: %d, start_count4: %b, start_count5: %b",
                 $time, key_value, key_valid, display_num, led1, led2, led3, error_count, start_count4, start_count5);
    end

endmodule