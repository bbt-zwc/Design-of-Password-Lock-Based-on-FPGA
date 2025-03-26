module smg_display(
    input wire clk,           // 系统时钟
    input wire rst_n,         // 复位信号，低电平有效
    input wire [31:0] number, // 要显示的数字，范围0~99999999
    output reg [7:0] seg,     // 段选信号 (a,b,c,d,e,f,g,dp)
    output reg [2:0] sel     // 位选信号，用于3-8译码器
);

// 分频计数器
reg [7:0] div_cnt;
wire scan_clk;

// 显示数据存储
reg [3:0] display_data [7:0];  // 8个数码管显示的数据
reg [2:0] scan_cnt;           // 扫描计数器

// 分频生成扫描时钟
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        div_cnt <= 8'd0;
    else
        div_cnt <= div_cnt + 8'd1;
end

assign scan_clk = div_cnt[4]; // 扫描时钟分频

// 扫描计数器控制
always @(posedge scan_clk or negedge rst_n) begin
    if (!rst_n)
        scan_cnt <= 3'd0;
    else
        scan_cnt <= scan_cnt + 3'd1;
end

// 位选信号生成
always @(posedge scan_clk or negedge rst_n) begin
    if (!rst_n)
        sel <= 3'd1;
    else
        sel <= 3'd1 + scan_cnt;
end

// 数字转换显示数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 初始化显示全部"-"
        display_data[0] <= 4'hf;
        display_data[1] <= 4'hf;
        display_data[2] <= 4'hf;
        display_data[3] <= 4'hf; 
        display_data[4] <= 4'hf;
        display_data[5] <= 4'hf;
        display_data[6] <= 4'hf;
        display_data[7] <= 4'hf;
    end else begin
        if (number == 32'hFFFFFFFF) begin
            // 显示全部"-"
            display_data[0] <= 4'hf;
            display_data[1] <= 4'hf;
            display_data[2] <= 4'hf;
            display_data[3] <= 4'hf;
            display_data[4] <= 4'hf;
            display_data[5] <= 4'hf;
            display_data[6] <= 4'hf;
            display_data[7] <= 4'hf;
        end else begin
            // 直接提取每个4位段
            display_data[0] <= number[31:28];
            display_data[1] <= number[27:24];
            display_data[2] <= number[23:20];
            display_data[3] <= number[19:16];
            display_data[4] <= number[15:12];
            display_data[5] <= number[11:8];
            display_data[6] <= number[7:4];
            display_data[7] <= number[3:0];
        end
    end
end

// 七段数码管译码
always @(*) begin
    case(display_data[scan_cnt])
        4'h0: seg = 8'b00111111;  // 0
        4'h1: seg = 8'b00000110;  // 1
        4'h2: seg = 8'b01011011;  // 2
        4'h3: seg = 8'b01001111;  // 3
        4'h4: seg = 8'b01100110;  // 4
        4'h5: seg = 8'b01101101;  // 5
        4'h6: seg = 8'b01111101;  // 6
        4'h7: seg = 8'b00000111;  // 7
        4'h8: seg = 8'b01111111;  // 8
        4'h9: seg = 8'b01101111;  // 9
        4'hf: seg = 8'b01000000;  // "-"
        default: seg = 8'b00000000;
    endcase
end

endmodule