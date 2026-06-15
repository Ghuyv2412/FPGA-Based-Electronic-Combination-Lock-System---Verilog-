`timescale 1ns / 1ps

module tb_top_module();

    // 1. Khai báo các tín hiệu
    reg         clk;
    reg         reset_n;
    reg  [3:0]  col;
    wire [3:0]  row;
    
    wire [6:0]  HEX3, HEX2, HEX1, HEX0;
    wire   LEDG;  
    wire  LEDR;  
    wire        BUZZER;
    wire [7:0]  LCD_DATA;
    wire        LCD_RS, LCD_RW, LCD_EN, LCD_ON, LCD_BLON;

    // 2. Khởi tạo Module cần test (UUT - Unit Under Test)
    top_module uut (
        .clk        (clk),
        .reset_n    (reset_n),
        .col        (col),
        .row        (row),
        .HEX3       (HEX3),
        .HEX2       (HEX2),
        .HEX1       (HEX1),
        .HEX0       (HEX0),
        .LEDG       (LEDG),
        .LEDR       (LEDR),
        .BUZZER     (BUZZER),
        .LCD_DATA   (LCD_DATA),
        .LCD_RS     (LCD_RS),
        .LCD_RW     (LCD_RW),
        .LCD_EN     (LCD_EN),
		.LCD_ON	    (LCD_ON), 
		.LCD_BLON	(LCD_BLON)
    );

    // 3. Tạo Clock 50MHz (Chu kỳ 20ns)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // =======================================================
    // TASK: GIẢ LẬP BẤM PHÍM TRÊN KEYPAD MA TRẬN
    // =======================================================
    task press_key(input [3:0] key_val);
        integer target_row;
        integer target_col;
        begin
            // Giải mã phím bấm sang tọa độ (Row, Col) dựa theo RTL của bạn
            case (key_val)
                4'h1: begin target_row = 0; target_col = 0; end
                4'h2: begin target_row = 0; target_col = 1; end
                4'h3: begin target_row = 0; target_col = 2; end
                4'hA: begin target_row = 0; target_col = 3; end // Nút Enter
                
                4'h4: begin target_row = 1; target_col = 0; end
                4'h5: begin target_row = 1; target_col = 1; end
                4'h6: begin target_row = 1; target_col = 2; end
                4'hB: begin target_row = 1; target_col = 3; end // Nút Backspace
                
                4'h7: begin target_row = 2; target_col = 0; end
                4'h8: begin target_row = 2; target_col = 1; end
                4'h9: begin target_row = 2; target_col = 2; end
                4'hC: begin target_row = 2; target_col = 3; end // Nút Clear
                
                4'hE: begin target_row = 3; target_col = 0; end
                4'h0: begin target_row = 3; target_col = 1; end
                4'hF: begin target_row = 3; target_col = 2; end
                4'hD: begin target_row = 3; target_col = 3; end // Nút Đổi Pass
                default: begin target_row = 0; target_col = 0; end
            endcase

            $display("[%0t] Nhan Phim: %X", $time, key_val);
            
            // Dùng fork-join để liên tục quét tín hiệu row phản hồi lại col
            fork
                begin : key_hold_loop
                    forever @(negedge clk) begin
                        col = 4'b1111; // Mặc định thả ra
                        // Nếu mạch quét đang kích hoạt đúng hàng của phím này
                        if (row[target_row] == 1'b0) begin
                            col[target_col] = 1'b0; // Kéo cột xuống 0
                        end
                    end
                end
                begin : key_hold_timeout
                    // Giữ phím trong 30ms (1,500,000 chu kỳ clk) để qua vòng chống nhiễu
                    #(30_000_000); 
                    disable key_hold_loop; // Ngắt vòng lặp
                end
            join
            
            // Nhả phím và đợi 30ms để mạch FSM xử lý xong tín hiệu nhả
            col = 4'b1111; 
            #(30_000_000);
        end
    endtask

    // =======================================================
    // TASK: TUA NHANH THỜI GIAN (FAST-FORWARD TIMERS)
    // =======================================================
    // Nếu không dùng lệnh force, bạn sẽ phải đợi 5 giây mô phỏng (tốn rất nhiều CPU/RAM)
    task skip_door_timer;
        begin
            $display("[%0t] ---> TUA NHANH THOI GIAN DONG CUA (5 giay) <---", $time);
            // Ép giá trị biến timer trong FSM lên mức sát 250,000,000
            force uut.u_logic.u_fsm_controller.timer = 32'd249_999_900;
            #(50_000); // Đợi chạy nốt vài chu kỳ cuối
            release uut.u_logic.u_fsm_controller.timer; // Trả lại quyền đếm cho RTL
            #(1_000_000);
        end
    endtask

    task skip_wrong_timer;
        begin
            $display("[%0t] ---> TUA NHANH THOI GIAN KHOA SAI PASS (1 giay) <---", $time);
            force uut.u_logic.u_fsm_controller.timer = 32'd49_999_900;
            #(50_000);
            release uut.u_logic.u_fsm_controller.timer;
            #(1_000_000);
        end
    endtask

    // =======================================================
    // KỊCH BẢN TEST CÁC CHỨC NĂNG (SCENARIO)
    // =======================================================
    initial begin
        // Thiết lập file xuất waveform
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top_module);

        // Khởi tạo trạng thái ban đầu
        col = 4'b1111;
        reset_n = 0;
        #(1000);
        reset_n = 1;
        $display("[%0t] He thong da khoi dong xong", $time);
        #(5_000_000); // Đợi màn hình LCD khởi tạo (ST_POWER_ON)

        // ---------------------------------------------------
        // TEST 1: NHẬP PASSWORD MẶC ĐỊNH (0000)
        // ---------------------------------------------------
        $display("\n--- TEST 1: NHAP DUNG MAT KHAU MAC DINH ---");
        press_key(4'h0); press_key(4'h0); press_key(4'h0); press_key(4'h0);
        press_key(4'hA); // Bấm A (Enter)
        #(1_000_000);
        if (LEDG) $display("-> PASS! Cua da mo (LEDG = 1)");
        else      $display("-> FAIL! Cua chua mo");
        skip_door_timer(); // Tua qua 5s mở cửa

        // ---------------------------------------------------
        // TEST 2: ĐỔI PASSWORD (MỚI = 1234)
        // ---------------------------------------------------
        $display("\n--- TEST 2: DOI MAT KHAU (Moi: 1234) ---");
        // B1: Nhập đúng pass cũ để mở cửa trước
        press_key(4'h0); press_key(4'h0); press_key(4'h0); press_key(4'h0);
        press_key(4'hA);
        #(1_000_000);
        // B2: Khi cửa đang mở, bấm D để đổi pass
        press_key(4'hD);
        $display("Dang nhap pass moi...");
        press_key(4'h1); press_key(4'h2); press_key(4'h3); press_key(4'h4);
        press_key(4'hA); // Lưu pass mới
        skip_door_timer(); // Tua nhanh cho hết trạng thái mở cửa

        // ---------------------------------------------------
        // TEST 3: NHẬP LẠI PASS CŨ (0000) ĐỂ KIỂM TRA ĐÃ ĐỔI THÀNH CÔNG CHƯA
        // ---------------------------------------------------
        $display("\n--- TEST 3: THU MO CUA BANG PASS CU (0000) ---");
        press_key(4'h0); press_key(4'h0); press_key(4'h0); press_key(4'h0);
        press_key(4'hA);
        #(1_000_000);
        if (uut.u_logic.u_fsm_controller.current_state == 3'd4) 
             $display("-> PASS! He thong bao sai pass (Dung logic)");
        else $display("-> FAIL! He thong van chap nhan pass cu");
        skip_wrong_timer();

        // ---------------------------------------------------
        // TEST 4: NHẬP PASS MỚI (1234) VÀ TEST NÚT BACKSPACE (B) & CLEAR (C)
        // ---------------------------------------------------
        $display("\n--- TEST 4: TEST BACKSPACE (B) VA PASS MOI (1234) ---");
        press_key(4'h1); press_key(4'h2); press_key(4'h5); // Bấm nhầm số 5
        press_key(4'hB); // Bấm Backspace (B) để xóa số 5
        press_key(4'h3); press_key(4'h4); // Nhập tiếp 3, 4 (Thành 1234)
        press_key(4'hA); // Enter
        #(1_000_000);
        if (LEDG) $display("-> PASS! Mo cua thanh cong bang pass moi 1234, Backspace hoat dong tot!");
        else      $display("-> FAIL! Mo cua that bai");
        skip_door_timer();

        // ---------------------------------------------------
        // TEST 5: TEST BÁO ĐỘNG (NHẬP SAI 3 LẦN)
        // ---------------------------------------------------
        $display("\n--- TEST 5: TEST HE THONG CANH BAO BUZZER (Sai 3 lan) ---");
        // Lần 1
        press_key(4'h9); press_key(4'h9); press_key(4'h9); press_key(4'h9); press_key(4'hA);
        skip_wrong_timer();
        // Lần 2
        press_key(4'h8); press_key(4'h8); press_key(4'h8); press_key(4'h8); press_key(4'hA);
        skip_wrong_timer();
        // Lần 3
        press_key(4'h7); press_key(4'h7); press_key(4'h7); press_key(4'h7); press_key(4'hA);
        #(1_000_000);
        if (BUZZER == 1) $display("-> PASS! Coi bao dong da keu!");
        else        $display("-> FAIL! Coi khong keu!");
        
        #(20_000_000);
        $display("\n==== HOAN THANH TESTBENCH ====");
        $finish; // Kết thúc mô phỏng
    end
endmodule