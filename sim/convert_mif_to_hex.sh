#!/bin/bash
#===============================================================================
# Convert Intel MIF files to plain hex format for ModelSim $readmemh
#===============================================================================

set -e

SRC_DIR="../downloads/j68_cpu/rtl"
DEST_DIR="."

echo "Converting MIF files to HEX format for ModelSim..."

for i in 0 1 2 3 4; do
    MIF_FILE="$SRC_DIR/j68_ram_${i}.mif"
    HEX_FILE="$DEST_DIR/j68_ram_${i}.hex"

    echo "  $MIF_FILE -> $HEX_FILE"

    # Extract data section (after "BEGIN"), convert binary to hex
    # MIF format: "ADDR : DATA; -- comment"
    # We want just the hex value of DATA
    grep -A 2048 "^BEGIN" "$MIF_FILE" | \
        grep -E "^[0-9A-F]+" | \
        awk '{
            # Extract binary value between : and ;
            match($0, /: ([01]+);/, arr);
            binary = arr[1];

            # Convert binary to hex (4 bits -> 1 hex digit)
            hex = "";
            if (binary == "0000") hex = "0";
            else if (binary == "0001") hex = "1";
            else if (binary == "0010") hex = "2";
            else if (binary == "0011") hex = "3";
            else if (binary == "0100") hex = "4";
            else if (binary == "0101") hex = "5";
            else if (binary == "0110") hex = "6";
            else if (binary == "0111") hex = "7";
            else if (binary == "1000") hex = "8";
            else if (binary == "1001") hex = "9";
            else if (binary == "1010") hex = "A";
            else if (binary == "1011") hex = "B";
            else if (binary == "1100") hex = "C";
            else if (binary == "1101") hex = "D";
            else if (binary == "1110") hex = "E";
            else if (binary == "1111") hex = "F";

            print hex;
        }' > "$HEX_FILE"

    echo "    $(wc -l < $HEX_FILE) lines written"
done

echo ""
echo "✓ Conversion complete"
echo "  Created: j68_ram_0.hex through j68_ram_4.hex"
