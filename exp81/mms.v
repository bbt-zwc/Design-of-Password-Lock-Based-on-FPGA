module mm_lock(
    input wire clk,           // 系统时钟 (50MHz)
    input wire rst_n,         // 复位信号 (低有效)
    input wire [3:0] key_value,  // 按键值 (0-F)
    input wire key_valid,     // 按键有效信号
    output reg [31:0] display_num,    // 数码管显示数据
    output wire led1,         // 状态LED1 (解锁亮)
    output wire led2,         // 状态LED2 (锁定亮)
    output reg led3,          // 状态LED3 (修改模式/闪烁)
    output reg [31:0] error_count,   // 错误次数计数
    output wire start_count4, // 触发LED4报警
    output wire start_count5  // 触发LED5报警
);

    // 状态定义
    reg [3:0] input_count = 0;      // 当前输入计数
    reg current_state;              // 当前状态
    localparam LOCKED = 1'b0;       // 锁定状态
    localparam UNLOCKED = 1'b1;     // 解锁状态
    reg count5__begin = 0;          // 开锁倒计时，开锁重置
    
    // 密码存储
    reg [31:0] password = 32'h12345678; // 存储的密码
    
    // 密码修改相关信号
    reg change_password_mode;       // 修改模式标志
    reg [31:0] temp_password;       // 第一次输入暂存
    reg password_success;           // 修改成功标志
    
    // 闪烁控制
    reg [24:0] flash_counter;       // 125ms闪烁计数器 (50MHz时钟下6,250,000 cycles)
    wire led3_flash;                // 闪烁信号
    
    // 1秒计时器
    reg [26:0] success_timer;       // 1秒计时 (50,000,000 cycles)
    // 自动上锁信号声明
    reg [28:0] idle_timer;          // 10秒空闲计时器 (50MHz下500,000,000 cycles)
    wire idle_timeout;              // 超时信号
    localparam IDLE_TIMEOUT = 500_000_000 - 1; // 实际值需按时钟频率计算

    
    // 主状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // 复位初始化
            display_num <= 32'hFFFFFFFF; // 清空显示
            input_count <= 0;            // 清空输入计数
            current_state <= LOCKED;   // 初始化状态为锁定
            change_password_mode <= 0; // 默认不在修改密码模式
            error_count <= 0; // 初始化错误次数
            temp_password <= 0;
            password_success <= 0;
            success_timer <= 0;
            idle_timer <= 0;
        end else begin
            // 无按键处理
            if(!key_valid) begin
                // 自动上锁计时器控制
                if(current_state == UNLOCKED) begin
                    idle_timer <= (idle_timer >= IDLE_TIMEOUT) ? 0 : idle_timer + 1;
                end else begin
                    idle_timer <= 0;                    // 非解锁状态清零
                end
                // 自动上锁触发
                if(idle_timeout) begin
                    current_state = LOCKED; // 锁定
                    display_num = 32'hFFFFFFFF; // 清空显示
                    input_count = 0;            // 清空输入计数
                    change_password_mode = 0;  // 退出修改密码模式
                    temp_password = 0;
                    count5__begin = 0;
                end
                // 修改密码成功状态计时
                if(password_success) begin
                    if(success_timer < 27'd50_000_000) begin
                        success_timer <= success_timer + 1;
                    end else begin
                        password_success <= 0;
                        success_timer <= 0;
                    end
                end
            end
            // 按键处理
            if(key_valid) begin
                idle_timer <= 0;                // 重置计时器
                case(key_value)
                    4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                        count5__begin <= 1;
                        if(input_count < 8) begin
                            display_num <= {display_num[27:0], key_value};
                            input_count <= input_count + 1; // 更新显示
                        end
                    end
                    4'hA: begin // A键确认输入
                        if(current_state == LOCKED) begin
                            if(display_num == password) begin
                                current_state <= UNLOCKED; // 解锁成功
                                display_num <= 32'hFFFFFFFF; // 清空显示
                                error_count <= 0; // 重置错误次数
                            end else begin // 密码输入错误
                                input_count = 0;            // 清空输入计数
                                display_num = 32'hFFFFFFFF; // 清空显示
                                error_count = error_count + 1;  // 错误次数+1
                                display_num = error_count; // 显示错误次数
                            end
                        end else if(change_password_mode) begin // 修改密码流程
                            if(temp_password == 0) begin // 第一次输入
                                temp_password = display_num;
                                display_num = 32'hFFFFFFFF;
                                input_count = 0;
                            end else begin // 第二次输入
                                if(display_num == temp_password) begin
                                    password <= display_num;
                                    password_success <= 1; // 修改成功闪烁
                                end
                                // 无论是否成功都退出修改模式
                                change_password_mode <= 0;
                                temp_password <= 0;
                                display_num <= 32'hFFFFFFFF;
                                input_count <= 0;
                            end
                        end
                    end
                    4'hB: begin // B键锁定
                        current_state <= LOCKED; // 锁定
                        display_num <= 32'hFFFFFFFF; // 清空显示
                        input_count <= 0;            // 清空输入计数
                        change_password_mode <= 0;  // 退出修改密码模式
                        temp_password <= 0;
                        count5__begin <= 0;
                    end
                    4'hC: begin // C键清空
                        display_num <= 32'hFFFFFFFF; // 清空显示
                        input_count <= 0;            // 清空输入计数
                    end
                    4'hD: begin // D键切换修改模式
                        if(current_state == UNLOCKED) begin
                            change_password_mode <= ~change_password_mode;
                            input_count <= 0;            // 清空输入计数
                            display_num <= 32'hFFFFFFFF; // 清空显示
                            temp_password <= 0;
                        end
                    end
                    4'hE: begin // *键显示密码
                        if(current_state == UNLOCKED) begin
                            input_count <= 0;            // 清空输入计数
                            display_num <= password; // 显示密码
                        end
                    end
                    default: ; // 其他按键无操作
                endcase
            end
        end
    end

    // 闪烁信号生成
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            flash_counter <= 0;
        end else begin
            flash_counter <= (flash_counter == 25'd6_250_000) ? 0 : flash_counter + 1;
        end
    end
    assign led3_flash = (flash_counter < 25'd3_125_000); // 125ms周期
    
    // LED3输出控制
    always @(*) begin
        if(password_success) begin
            led3 = led3_flash;  // 成功时闪烁
        end else begin
            led3 = change_password_mode; // 修改模式常亮
        end
    end

    // 触发信号生成
    assign start_count4 = (current_state == LOCKED) && (error_count >= 1);
    assign start_count5 = (current_state == LOCKED) && (count5__begin > 0);

    // LED状态指示
    assign led1 = (current_state == UNLOCKED); // 解锁时LED1亮
    assign led2 = (current_state == LOCKED);   // 锁定时LED2亮
    // 超时信号生成
    assign idle_timeout = (idle_timer == IDLE_TIMEOUT);

endmodule