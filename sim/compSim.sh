#!/bin/bash

WORK_DIR=work
WAVE_FILE=result.ghw
GTKPROJ_FILE=result.gtkw
VCD_FILE=result.vcd
SAIF_FILE=result.saif

# create work dir if it does not exist
mkdir -p $WORK_DIR

# importing source files
ghdl -i --workdir=$WORK_DIR ../src/Top.vhd
ghdl -i --workdir=$WORK_DIR ../src/unitAESEncrypt_pipline.vhd
ghdl -i --workdir=$WORK_DIR ../src/unitAESDecrypt_pipline.vhd
ghdl -i --workdir=$WORK_DIR ../src/unitAESEncrypt.vhd
ghdl -i --workdir=$WORK_DIR ../src/unitAESDecrypt.vhd
ghdl -i --workdir=$WORK_DIR ../src/sub_bytes.vhd
ghdl -i --workdir=$WORK_DIR ../src/inv_sub_bytes.vhd
ghdl -i --workdir=$WORK_DIR ../src/shift_rows.vhd
ghdl -i --workdir=$WORK_DIR ../src/inv_shift_rows.vhd
ghdl -i --workdir=$WORK_DIR ../src/move_columns.vhd
ghdl -i --workdir=$WORK_DIR ../src/inv_move_columns.vhd
ghdl -i --workdir=$WORK_DIR ../src/key_expansion.vhd
ghdl -i --workdir=$WORK_DIR ../src/add_round_key.vhd
ghdl -i --workdir=$WORK_DIR ../src/next_key.vhd

ghdl -i --workdir=$WORK_DIR ./tb_AES.vhd
#ghdl -i --workdir=$WORK_DIR ./tb_next_key.vhd
#ghdl -i --workdir=$WORK_DIR ./tb_sub_bytes.vhd
#ghdl -i --workdir=$WORK_DIR ./tb_check.vhd



# building simulation files
ghdl -m --workdir=$WORK_DIR tb

# running the simulation
ghdl -r --workdir="$WORK_DIR" tb --wave="$WORK_DIR/$WAVE_FILE" --vcd="$WORK_DIR/$VCD_FILE" --stop-time=1ms

python3 ./vcd_automation.py -i "$WORK_DIR/$VCD_FILE" --vdd 1.2 --ceff 2e-15

#python3 ./vcd2saif.py "$WORK_DIR/$VCD_FILE" "$WORK_DIR/${VCD_FILE%.vcd}.saif"

# running the simulation
#ghdl -r --workdir=$WORK_DIR tb_multi_bank_memory --wave=$WORK_DIR/result.vcd --stop-time=1ms

# open gtkwave with project with new waveform if project exists, if not then just open the waveform in new project
if [ -f $WORK_DIR/$GTKPROJ_FILE ]; then
   gtkwave $WORK_DIR/$GTKPROJ_FILE &
else
   gtkwave $WORK_DIR/$WAVE_FILE &
fi