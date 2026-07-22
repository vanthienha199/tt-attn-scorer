\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
\SV
   module tt_um_hale_attn_scorer (
     input  wire [7:0] ui_in,
     output wire [7:0] uo_out,
     input  wire [7:0] uio_in,
     output wire [7:0] uio_out,
     output wire [7:0] uio_oe,
     input  wire       ena,
     input  wire       clk,
     input  wire       rst_n
   );
   assign uio_out = 8'b0;
   assign uio_oe  = 8'b0;
   wire reset = ~rst_n;
\TLV
   |scorer
      @0
         // Inputs
         $cmd[1:0]        = *uio_in[1:0];
         $data[7:0]       = *ui_in;

         // Command decode
         $is_idle         = ($cmd == 2'b00);
         $is_load_q       = ($cmd == 2'b01);
         $is_stream_k     = ($cmd == 2'b10);
         $is_read         = ($cmd == 2'b11);

         // Query buffer: 8 separate flops
         $qsel[7:0]       = ($dim == 0) ? $q0 : ($dim == 1) ? $q1 : ($dim == 2) ? $q2 : ($dim == 3) ? $q3 :
                            ($dim == 4) ? $q4 : ($dim == 5) ? $q5 : ($dim == 6) ? $q6 : $q7;
         $load_q_write    = $is_load_q;
         $q_idx[2:0]      = ($qfill >= 8) ? 3'b0 : $qfill[2:0];

         // qfill (next state)
         $qfill_next[3:0] = *reset ? 4'b0 :
                            $is_load_q ? (($qfill >= 8) ? 4'd1 : $qfill + 1'd1) :
                            ($qfill < 8) ? 4'b0 : $qfill;

         // Query byte loading
         <<1$q0[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 0) ? $data : $q0;
         <<1$q1[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 1) ? $data : $q1;
         <<1$q2[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 2) ? $data : $q2;
         <<1$q3[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 3) ? $data : $q3;
         <<1$q4[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 4) ? $data : $q4;
         <<1$q5[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 5) ? $data : $q5;
         <<1$q6[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 6) ? $data : $q6;
         <<1$q7[7:0]      = *reset ? 8'b0 : ($load_q_write && $q_idx == 7) ? $data : $q7;
         <<1$qfill[3:0]   = $qfill_next;

         // Load complete detection (resets best/idx/key_idx)
         $load_complete    = $is_load_q && ($qfill == 7);

         // Accumulator and dimension
         $reset_acc_dim   = $is_load_q || $is_idle;
         $inc_dim         = $is_stream_k && ($key_idx <= 63);
         $prod[15:0]      = \$signed($qsel) * \$signed($data);
         $acc_temp[16:0]  = \$signed($acc) + \$signed($prod);
         $acc_full[15:0]  = ($acc_temp[16:15] == 2'b01) ? 16'h7FFF :
                            ($acc_temp[16:15] == 2'b10) ? 16'h8000 : $acc_temp[15:0];
         $dim_next[3:0]   = *reset ? 4'b0 :
                            ($reset_acc_dim || ($inc_dim && $dim == 7)) ? 4'b0 :
                            $inc_dim ? $dim + 1'd1 : $dim;
         $acc_next[15:0]  = *reset ? 16'b0 :
                            ($reset_acc_dim || ($inc_dim && $dim == 7)) ? 16'b0 :
                            $inc_dim ? $acc_full : $acc;
         <<1$dim[3:0]     = $dim_next;
         <<1$acc[15:0]    = $acc_next;

         // Key index, best score, best index
         $key_idx_next[5:0] = *reset ? 6'b0 :
                              $load_complete ? 6'b0 :
                              ($inc_dim && $dim == 7 && $key_idx <= 63) ? ($key_idx + 1'd1) : $key_idx;
         $best_next[15:0]   = *reset ? 16'h8000 : // -32768
                              $load_complete ? 16'h8000 :
                              ($inc_dim && $dim == 7 && $key_idx <= 63 && (\$signed($acc_full) > \$signed($best))) ? $acc_full : $best;
         $best_idx_next[5:0] = *reset ? 6'b0 :
                               $load_complete ? 6'b0 :
                               ($inc_dim && $dim == 7 && $key_idx <= 63 && (\$signed($acc_full) > \$signed($best))) ? $key_idx : $best_idx;
         <<1$key_idx[5:0]    = $key_idx_next;
         <<1$best[15:0]      = $best_next;
         <<1$best_idx[5:0]   = $best_idx_next;

         // Read phase and output
         $read_phase_next[1:0] = *reset ? 2'b0 :
                                 $is_read ? (($read_phase == 2) ? 2'b0 : $read_phase + 1'd1) : 2'b0;
         $out_next[7:0]        = *reset ? 8'b0 :
                                 $is_read ? (($read_phase == 2'b00) ? $best_idx[5:0] :
                                             ($read_phase == 2'b01) ? $best[15:8] : $best[7:0]) : $out;
         <<1$read_phase[1:0]   = $read_phase_next;
         <<1$out[7:0]          = $out_next;

         // Output assignment
         *uo_out = $out;
\SV
   endmodule
