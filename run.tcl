proc reset {index} {
    set jtag_debug_path [lindex [get_service_paths jtag_debug] $index]
    set claim_jtag_debug_path [claim_service jtag_debug $jtag_debug_path system_console_example]
    jtag_debug_reset_system $claim_jtag_debug_path; 
    close_service jtag_debug $claim_jtag_debug_path
}

set service_type "master"
set master_service_paths [get_service_paths $service_type]
puts $master_service_paths


set master_index 0
set master_path [lindex $master_service_paths $master_index]
set claim_path [claim_service $service_type $master_path system_console_example];




set mat_size_in_bytes 4194304
set dram_base   0x00000000 
set matA_base $dram_base
set matB_base [expr {$dram_base + $mat_size_in_bytes}]
set matC_base [expr {$dram_base + $mat_size_in_bytes * 2}]


set csr_base 0x80000000
set start_addr [expr $csr_base + 0x4]
set done_addr  [expr $csr_base + 0x8]
set cycle_count_lsb_addr  [expr $csr_base + 0xC]
set write_buffer_throushold_addr  [expr $csr_base + 0x10]
set burst_count_addr [expr $csr_base + 0x14]

# reset everything by master 0
reset 0

puts "before copying A and B"
master_write_from_file $claim_path "A.bin" $matA_base
puts "after copying A"
master_write_from_file $claim_path "B.bin" $matB_base
puts "after copying B"


# send start signal and deassert
master_write_32 $claim_path $write_buffer_throushold_addr 2048
master_write_32 $claim_path $burst_count_addr 64
master_write_32 $claim_path $start_addr 1
master_write_32 $claim_path $start_addr 0
puts "start"

set done 0
# poll for done
while {$done == 0} {
    set done [expr [master_read_32 $claim_path $done_addr 1]]
}


puts "done"

puts "cycle_count:"
puts [master_read_32 $claim_path $cycle_count_lsb_addr 0x1]


master_read_to_file $claim_path "C.bin" $matC_base $mat_size_in_bytes
puts "after writing C"

close_service master $claim_path;