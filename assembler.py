import math 
# Enkel Python-assembler för GRx-format (med automatisk adresseringsmod)
# Instruktionsformat:
# | 31 – 26 | 25 – 22 | 21 – 20 | 19 – 0 |
# | opcode  | GRx     | M       | A      |

OPCODES = {
    'NOP': 0x00,
    'ADD': 0x01,
    'SUB': 0x02,
    'MUL': 0x03,
    'AND': 0x04,
    'OR':  0x05,
    'XOR': 0x06,
    'LSL': 0x07,
    'LSR': 0x08,
    'LOAD':0x09,
    'STORE':0x0A,
    'JMP': 0x0B,
    'BEQ': 0x0C,
    'BNE': 0x0D,
    'BLT': 0x0E,
    'BGT': 0x0F,
    'HALT':0x10,
    'IN':  0x11,
    'OUT': 0x12,
    'SUM_TIME': 0x13,
    'INC_CLK' : 0x14,
    'INC_PALETTE': 0x15,
    'DEC_PALETTE': 0x16,
    'WAIT': 0x17,
    'RRE' : 0x18, # reset rotary encoder dir
    'CRE' : 0x19,
    'CMP' : 0x1A,
}

REGS = {
    "R0" : 0,
    "R1" : 1,
    "R2" : 2,
    "R3" : 3,
    "CLK_H" : 4,
    "CLK_h" : 5,
    "CLK_M" : 6,
    "CLK_m" : 7
}
INDEX_REGISTER = REGS['R3']
SPEC_REGS = {
    "RE_D" : 0,
    "RE_V" : 1,
}

# Adresseringslägen
MODE_DIRECT    = 0b00
MODE_INDIRECT  = 0b10
MODE_INDEXED   = 0b11
MODE_IMMEDIATE = 0b01   # fixed correct address modes

PM_SIZE = 256

def assemble_instruction(opcode, grx=0, mode=0, a=0):
    """Packa opcode, GRx, M och A i 32-bitars ord"""
    return ((opcode & 0x3F) << 26) | ((grx & 0xF) << 22) | ((mode & 0x3) << 20) | (a & 0xFFFFF)


def parse_operand(operand):
    operand = operand.strip()

    # Direkt adress ($05 → hex)
    if operand.startswith('$'):
        return MODE_DIRECT, int(operand[1:], 16), None

    # Indirekt ([$05])
    if operand.startswith('[$') and operand.endswith(']'):
        return MODE_INDIRECT, int(operand[2:-1], 16), None

    # Indexerad ({100} → GR3 + 100)
    if operand.startswith('{') and operand.endswith('}'):
        return MODE_INDEXED, int(operand[1:-1]), INDEX_REGISTER

    # Register (R2)
    if operand in REGS:
        return MODE_DIRECT, 0, REGS[operand]

    if operand in SPEC_REGS:
        return MODE_DIRECT, PM_SIZE - 1 - SPEC_REGS[operand], None

    # Default: immediate (100)
    return MODE_IMMEDIATE, int(operand), None


def parse_line(line):
    line = line.split(';')[0].strip()
    if not line:
        return None

    parts = line.replace(',', ' ').split()
    instr = parts[0].upper()

    if instr not in OPCODES:
        raise ValueError(f"Okänd instruktion: {instr}")

    opcode = OPCODES[instr]
    grx = 0
    mode = 0
    a = 0

    # Instruktioner med register + operand
    if instr in ['ADD','SUB','MUL','AND','OR','XOR','LSL','LSR','LOAD','STORE','IN','CMP','INC_CLK']:
        grx = REGS[parts[1]]

        if len(parts) > 2:
            mode, a, extra_reg = parse_operand(parts[2])

            # Packa indexregister i övre delen av A (enkel lösning)
            if extra_reg is not None:
                a = (extra_reg << 16) | a

    # Branch / jump
    elif instr in ['JMP','BEQ','BNE','BLT','BGT','CRE','SUM_TIME']:
        if len(parts) == 2:
            mode, a, _ = parse_operand(parts[1])
        elif len(parts) >= 3:
            grx = REGS[parts[1]]
            mode, a, _ = parse_operand(parts[2])
    
    elif instr in ['WAIT']:
        mode = MODE_IMMEDIATE
        a = int(int(parts[1]) * (math.pow(10, 2) / 2))

    elif instr in ['RRE']:
        mode = 0
        a = 0

    # Om vi använder immediate mode, genererar vi TVÅ ord.
    if mode == MODE_IMMEDIATE:
        # Ord 1: Själva instruktionen. Vi kan sätta A-fältet till 0 eftersom CPU:n ska läsa nästa ord istället.
        instruction_word = assemble_instruction(opcode, grx, mode, 0)
        # Ord 2: Datan, maskerad till 32 bitar så att även negativa tal hanteras rätt.
        data_word = a & 0xFFFFFFFF
        return [instruction_word, data_word]
    else:
        # Returnera en lista med ett enda ord för alla andra adresseringslägen
        return [assemble_instruction(opcode, grx, mode, a)]


def assemble_file(input_lines):
    hex_output = []
    for line in input_lines:
        words = parse_line(line)
        if words is not None:
            # Eftersom parse_line nu returnerar en lista av ord, lägger vi till alla i vår output
            for word in words:
                hex_output.append(f"{word:08X}")
    return hex_output


def write_hex_file(hex_list, filename):
    current = 0
    with open(filename, "w") as f:
        for i, h in enumerate(hex_list):
            f.write('x"' + h + '",\n')
            current = i
        # Fyll ut resten av minnet med nollor
        for n in range(PM_SIZE - 1 - current):
            if n != PM_SIZE - current - 2:
                f.write('x"00000000",\n')
            else:
                f.write('x"00000000"')

# Exempel
if __name__ == "__main__":
    asm_code = [
    # INIT:
        "LOAD CLK_H, 0",
        "LOAD CLK_h, 6",
        "LOAD CLK_M, 0",
        "LOAD CLK_m, 0",

    # START:
        "WAIT 488",         # slow down the program
        "ADD R2, 1",        # increment status counter
        "SUM_TIME 1",       # increment time
        "CMP R2, 91",       # should we increment clock?
        "BNE 48",           # if not, jump to READ_DIRECTION

    # CLOCK_COUNTER:
        "ADD CLK_m, 2",     # add 2 to small minute
        "CMP CLK_m, 10",    # small minute overflow?
        "BNE 40",           # if not, jump to CLOCK_DONE

    # CARRY_SMALL_MIN:
        "LOAD CLK_m, 0",    # reset small minute
        "ADD CLK_M, 1",     # add 1 to big minute
        "CMP CLK_M, 6",     # big minute overflow?
        "BNE 32",           # if not, jump to CLOCK_DONE

    # CARRY_BIG_MIN: 
        "LOAD CLK_M, 0",    # reset big minute
        "ADD CLK_h, 1",     # add 1 to small hour
        "CMP CLK_H, 2",     # are we on hour 2x?
        "BNE 10",           # not on hour 2x, jump to NORM_CARRY_SMALL_HOUR
        "CMP CLK_h, 4",     # are we on hour 24?
        "BNE 20",           # not on hour 24, jump to CLOCK_DONE

    # NEW_DAY:
        "LOAD CLK_h, 0",    # reset small hour
        "JMP 14",           # jump to RESET_BIG_HOUR

    # NORM_CARRY_SMALL_HOUR:
        "CMP CLK_h, 10",    # small hour overflow?
        "BNE 12",           # no overflow, jump to CLOCK_DONE
        "LOAD CLK_h, 0",    # reset small hour
        "ADD CLK_H, 1",     # add 1 to big hour
        "CMP CLK_H, 3",     # big hour overflow?
        "BNE 4",            # no overflow, jump to CLOCK_DONE

    # RESET_BIG_HOUR:
        "LOAD CLK_H, 0",    # reset big hour

    # CLOCK_DONE:
        "LOAD R2, 0",       # reset status counter

    # READ_DIRECTION:
        "IN R0, RE_D",      # read and save direction
        "CMP R0, 0",        # have we turned the knob?
        "BEQ -60",          # no turn, jump to START

    # PARSE_TURN:
        "IN R1, RE_V",      # read and save speed
        "CMP R0, 1",        # right turn of knob?
        "BNE 42",           # knob was turned left, jump to LEFT_TURN

    # RIGHT_TURN:
        "SUB R1, 1",        # decrement from speed value        
        "SUM_TIME 2731",    # add time
        
        "ADD CLK_h, 1",     # add 1 to small hour
        "CMP CLK_H, 2",     # are we on hour 2x?
        "BNE 10",           # not on hour 2x, jump to NORM_CARRY_SMALL_HOUR
        "CMP CLK_h, 4",     # are we on hour 24?
        "BNE 20",           # not on hour 24, jump to SPEED_CHECK

        # NEW_DAY:
        "LOAD CLK_h, 0",    # reset small hour
        "JMP 14",           # jump to RESET_BIG_HOUR

        # NORM_CARRY_SMALL_HOUR:
        "CMP CLK_h, 10",    # small hour overflow?
        "BNE 12",           # no overflow, jump to SPEED_CHECK
        "LOAD CLK_h, 0",    # reset small hour
        "ADD CLK_H, 1",     # add 1 to big hour
        "CMP CLK_H, 3",     # big hour overflow?
        "BNE 4",            # no overflow, jump to SPEED_CHECK

        # RESET_BIG_HOUR:
        "LOAD CLK_H, 0",    # reset big hour

        # SPEED_CHECK:
        "LOAD R2, 0",       # reset status counter
        "CMP R1, 0",        # speed > 0?
        "BNE -36",          # speed > 0, jump to RIGHT_TURN
        "JMP 32",           # speed = 0, jump to END

    # LEFT_TURN:
        "SUB R1, 1",        # decrement from speed value  
        "SUM_TIME -2731",   # subtract time

        # SUB_SMALL_HOUR:
        "CMP CLK_h, 0",     # small hour underflow?
        "BNE 10",           # no underflow, jump to NORM_DEC_SMALL_HOUR

        # DEC_BIG_HOUR:
        "CMP CLK_H, 0",     # big hour underflow?
        "BEQ 10",           # underflow, jump to PREV_DAY
        "SUB CLK_H, 1",     # sub as normal
        "LOAD CLK_h, 9",    # load small hour with 9

        # NORM_DEC_SMALL_HOUR:
        "SUB CLK_h, 1",     # subtract as normal
        "JMP 6",            # jump to SPEED_CHECK

        # PREV_DAY:
        "LOAD CLK_H, 2",    # set time to 23:xx
        "LOAD CLK_h, 3",    # set time to 23:xx

        # SPEED_CHECK:
        "LOAD R2, 0",       # reset status counter
        "CMP R1, 0",        # speed > 0?
        "BNE -28",          # speed > 0, jump to LEFT_TURN

    # END:
        "RRE",              # clear direction register
        "JMP -137",         # jump to START
    ]
    
    hexcode = assemble_file(asm_code)
    write_hex_file(hexcode, "program.hex")

    # Skriv ut resultatet i terminalen för att verifiera
    for i, h in enumerate(hexcode):
        print(f"Addr {i:02X}: {h}")