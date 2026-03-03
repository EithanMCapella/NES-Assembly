from capstone import *
import capstone  # import the module to access constants

# ARM 32-bit mode, little endian
md = Cs(CS_ARCH_ARM, CS_MODE_ARM)

# Use the constant via the module
md.syntax = CS_OPT_SYNTAX_ATT  # ensures standard ARM mnemonics

# Example: a 32-bit instruction (binary)
binary_str = "11101001101011010000111111101010"  # replace with your binary string
code_bytes = int(binary_str, 2).to_bytes(4, byteorder='little')

for i in md.disasm(code_bytes, 0x1000):
    print(f"0x{i.address:x}:\t{i.mnemonic}\t{i.op_str}")