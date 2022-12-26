#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

#change working directory to script file directory
cd [getScriptDirectory]
#set result directory
set resultDir .\/result
#set ip_repo_path to script dir
set ip_repo_path [getScriptDirectory]\/..\/
#redifine resultDir HERE if needed
#set resutDir C:\/User\/result

file mkdir $resultDir

# CONNECT SYSTEM
create_project VGA_BRAM_controller $resultDir  -part xc7z010clg400-1 -force
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
create_bd_design "VGA_BRAM_controller"
update_compile_order -fileset sources_1
#add ip-s to main repo
set_property  ip_repo_paths  $ip_repo_path [current_project]
update_ip_catalog



#add and configure zynq
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
endgroup

set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_IRQ_F2P_INTR {1} CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} CONFIG.PCW_SD0_GRP_CD_ENABLE {1} CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} CONFIG.PCW_SD0_GRP_WP_ENABLE {1} CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1}] [get_bd_cells processing_system7_0]

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

#add AXI Timer and connect interrupt signal
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0
endgroup
set_property -dict [list CONFIG.mode_64bit {1}] [get_bd_cells axi_timer_0]

connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins processing_system7_0/IRQ_F2P]

#add LED_GPIO

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
endgroup
set_property -dict [list CONFIG.C_GPIO_WIDTH {4} CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells axi_gpio_0]
create_bd_port -dir O -from 3 -to 0 -type data led_o
connect_bd_net [get_bd_ports led_o] [get_bd_pins axi_gpio_0/gpio_io_o]

#add BUTTON_GPIO
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_1
endgroup
set_property -dict [list CONFIG.C_GPIO_WIDTH {4} CONFIG.C_ALL_INPUTS {1}] [get_bd_cells axi_gpio_1]
create_bd_port -dir I -from 3 -to 0 button_i
connect_bd_net [get_bd_ports button_i] [get_bd_pins axi_gpio_1/gpio_io_i]

#add SWITCH_GPIO
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_2
endgroup
set_property -dict [list CONFIG.C_GPIO_WIDTH {4} CONFIG.C_ALL_INPUTS {1}] [get_bd_cells axi_gpio_2]
create_bd_port -dir I -from 3 -to 0 switch_i
connect_bd_net [get_bd_ports switch_i] [get_bd_pins axi_gpio_2/gpio_io_i]

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_1/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_1/S_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_2/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_2/S_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]

endgroup

#add BRAM and configure it
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup

set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Enable_32bit_Address {true} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Assume_Synchronous_Clk {false} CONFIG.Write_Depth_A {36864} CONFIG.Operating_Mode_A {WRITE_FIRST} CONFIG.Enable_A {Always_Enabled} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Use_RSTA_Pin {false} CONFIG.Use_RSTB_Pin {false} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.use_bram_block {Stand_Alone} CONFIG.EN_SAFETY_CKT {false}] [get_bd_cells blk_mem_gen_0]


startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
endgroup
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
set_property range 256K [get_bd_addr_segs {processing_system7_0/Data/SEG_axi_bram_ctrl_0_Mem0}]

# add Concat module
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
endgroup
set_property -dict [list CONFIG.IN0_WIDTH.VALUE_SRC USER CONFIG.IN1_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_0]
set_property -dict [list CONFIG.IN0_WIDTH {18} CONFIG.IN1_WIDTH {14}] [get_bd_cells xlconcat_0]

#add constant module
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
endgroup
set_property location {3 616 -264} [get_bd_cells xlconstant_0]
set_property -dict [list CONFIG.CONST_WIDTH {14} CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_0]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_addr_a] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_clk_a] [get_bd_pins blk_mem_gen_0/clka]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_we_a] [get_bd_pins blk_mem_gen_0/wea]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_wrdata_a] [get_bd_pins blk_mem_gen_0/dina]


#add VGA controller 
startgroup
create_bd_cell -type ip -vlnv FTN:user:VGA_IP:1.0 VGA_IP_0
endgroup
connect_bd_net [get_bd_pins VGA_IP_0/bram_addr] [get_bd_pins blk_mem_gen_0/addrb]
connect_bd_net [get_bd_pins VGA_IP_0/bram_en] [get_bd_pins blk_mem_gen_0/enb]


#add slice
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
endgroup
set_property -dict [list CONFIG.DIN_FROM {15} CONFIG.DOUT_WIDTH {16}] [get_bd_cells xlslice_0]


#create output ports and connect them
create_bd_port -dir O -from 15 -to 0 -type data RGB_Out
connect_bd_net [get_bd_ports RGB_Out] [get_bd_pins xlslice_0/Dout]

create_bd_port -dir O -type data Hsync
connect_bd_net [get_bd_ports Hsync] [get_bd_pins VGA_IP_0/hsync]

create_bd_port -dir O -type data Vsync
connect_bd_net [get_bd_ports Vsync] [get_bd_pins VGA_IP_0/vsync]


connect_bd_net [get_bd_pins VGA_IP_0/reset] [get_bd_pins rst_ps7_0_100M/peripheral_aresetn]
connect_bd_net [get_bd_pins VGA_IP_0/clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins xlslice_0/Din]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins blk_mem_gen_0/addra]

#add constraint file
add_files -fileset constrs_1 -norecurse Top.xdc

regenerate_bd_layout
#validating design
validate_bd_design
#Creating hdl wrapper
make_wrapper -files [get_files $resultDir/VGA_BRAM_controller.srcs/sources_1/bd/VGA_BRAM_controller/VGA_BRAM_controller.bd] -top
add_files -norecurse $resultDir/VGA_BRAM_controller.srcs/sources_1/bd/VGA_BRAM_controller/hdl/VGA_BRAM_controller_wrapper.v
#running synthesis and implementation
launch_runs impl_1 -to_step write_bitstream -jobs 4

#exporting hardware
wait_on_run impl_1
update_compile_order -fileset sources_1


set version [version -short]

if {$version < 2019.2} {
    file mkdir $resultDir/VGA_BRAM_controller.sdk
    file copy -force $resultDir/VGA_BRAM_controller.runs/impl_1/VGA_BRAM_controller_wrapper.sysdef $resultDir/VGA_BRAM_controller.sdk/VGA_DMA_controller_wrapper.hdf
} else {
    write_hw_platform -fixed -force  -include_bit -file $resultDir/VGA_BRAM_controller_wrapper.xsa
}

