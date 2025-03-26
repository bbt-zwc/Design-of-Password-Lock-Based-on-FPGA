module smg_display(
    input wire clk,           // ϵͳʱ��
    input wire rst_n,         // ��λ�źţ��͵�ƽ��Ч
    input wire [31:0] number, // Ҫ��ʾ�����֣���Χ0~99999999
    output reg [7:0] seg,     // ��ѡ�ź� (a,b,c,d,e,f,g,dp)
    output reg [2:0] sel     // λѡ�źţ�����3-8������
);

// ��Ƶ������
reg [7:0] div_cnt;
wire scan_clk;

// ��ʾ���ݴ洢
reg [3:0] display_data [7:0];  // 8���������ʾ������
reg [2:0] scan_cnt;           // ɨ�������

// ��Ƶ����ɨ��ʱ��
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        div_cnt <= 8'd0;
    else
        div_cnt <= div_cnt + 8'd1;
end

assign scan_clk = div_cnt[4]; // ɨ��ʱ�ӷ�Ƶ

// ɨ�����������
always @(posedge scan_clk or negedge rst_n) begin
    if (!rst_n)
        scan_cnt <= 3'd0;
    else
        scan_cnt <= scan_cnt + 3'd1;
end

// λѡ�ź�����
always @(posedge scan_clk or negedge rst_n) begin
    if (!rst_n)
        sel <= 3'd1;
    else
        sel <= 3'd1 + scan_cnt;
end

// ����ת����ʾ����
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // ��ʼ����ʾȫ��"-"
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
            // ��ʾȫ��"-"
            display_data[0] <= 4'hf;
            display_data[1] <= 4'hf;
            display_data[2] <= 4'hf;
            display_data[3] <= 4'hf;
            display_data[4] <= 4'hf;
            display_data[5] <= 4'hf;
            display_data[6] <= 4'hf;
            display_data[7] <= 4'hf;
        end else begin
            // ֱ����ȡÿ��4λ��
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

// �߶����������
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