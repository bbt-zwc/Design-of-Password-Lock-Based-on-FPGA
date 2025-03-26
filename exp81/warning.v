// warning.v
module warning(
    input wire clk,
    input wire rst_n,
    input wire [31:0] error_count,       // 闁挎瑨顕ゅ▎鈩冩殶
    input wire start_count4,            // 鐟欙箑褰侺ED4閹躲儴顒
    input wire start_count5,            // 鐟欙箑褰侺ED5閹躲儴顒
    output reg led4,                    // LED4鏉堟挸鍤
    output reg led5                     // LED5鏉堟挸鍤
);

    // 閸欏倹鏆熺€规矮绠熼敍鍫熺壌閹诡喖鐤勯梽鍛闁界喖顣堕悳鍥殶閺佽揪绱
    parameter COUNT_1S = 50_000_000 - 1;     // 50MHz閺冨爼鎸撴稉缁夋帟顓搁弫鏉库偓
    parameter COUNT_5S = 5 * (COUNT_1S + 1) - 1;
    parameter COUNT_30S = 30 * (COUNT_1S + 1) - 1;
    parameter FLASH_PERIOD = (COUNT_1S + 1) / 8 -1; // 125ms闂傤亞鍎婇崨銊︽埂
    
    // LED4閹貉冨煑闁槒绶
    reg [31:0] counter4;
    reg [31:0] prev_error_count;  // 新增：记录上一次错误次数
    reg counter4_reset_flag;      // 新增：计数器重置标志

     always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter4 <= 0;
            led4 <= 0;
            prev_error_count <= 0;
            counter4_reset_flag <= 0;
        end else begin
            // 检测error_count变化
            if (error_count != prev_error_count) begin
                counter4 <= 0;              // 错误次数变化时重置计数器
                prev_error_count <= error_count;
                counter4_reset_flag <= 1;    // 设置重置标志
            end else begin
                counter4_reset_flag <= 0;
            end

            if (start_count4) begin
                if (counter4_reset_flag) begin
                    counter4 <= 0;           // 确保新周期从0开始
                end
                
                case (error_count)
                    32'h1, 32'h2: begin  // 合并1-2次错误逻辑
                        if (counter4 < COUNT_5S) begin
                            counter4 <= counter4 + 1;
                            led4 <= (counter4 % FLASH_PERIOD < FLASH_PERIOD/2);
                        end else begin
                            led4 <= 0;
                        end
                    end
                    32'h3: begin         // 3次错误
                        if (counter4 < COUNT_30S) begin
                            counter4 <= counter4 + 1;
                            led4 <= (counter4 % FLASH_PERIOD < FLASH_PERIOD/2);
                        end else begin
                            led4 <= 0;
                        end
                    end
                    default: begin       // 3次以上错误
                        if (error_count > 32'h3) begin
                            led4 <= 1;  // 常亮报警
                            counter4 <= 0;
                        end
                    end
                endcase
            end else begin
                counter4 <= 0;
                led4 <= 0;
            end
        end
    end

    // LED5閹貉冨煑闁槒绶
    reg [31:0] counter5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter5 <= 0;
            led5 <= 0;
        end else if (start_count5) begin  // 鐡掑懏妞傞張顏呮惙娴ｆ粍濮ょ拃
            counter5 <= counter5 + 1;
            if (counter5 < COUNT_30S) begin
                led5 <= 0;
            end else if (counter5 >= COUNT_30S && counter5 < 2 * COUNT_30S) begin
                led5 <= (counter5 % FLASH_PERIOD < FLASH_PERIOD/2);
            end else begin
                counter5 <= 0;
                led5 <= 0;
            end
        end else begin
            counter5 <= 0;
            led5 <= 0;
        end
    end

endmodule