vlib work

vlog -sv ../rtl/lifo.sv
vlog -sv top_tb.sv
vlog -sv lifo_interface.sv

vsim -novopt top_tb
add log -r /*
add wave -r *
run -all