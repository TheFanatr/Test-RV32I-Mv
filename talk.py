import socket
import argparse
import sys
import time
import functools
from enum import Enum, Flag, auto

#REVIEW - apply FIXME anchor for BIOS state machine bug
#REVIEW - apply FIXME anchors for RAM addressing and data endianness bugs

# Example command line ensuring all defaults:
# python3.13 script_name.py \
#   -H localhost \
#   -p 8880 \
#   --retry-interval 5 \
#   --minor-pause 0.0 \
#   --major-pause 0.0 \
#   --write \
#   --check Off \
#   -f firmware/obj_dir/main.bin \
#   --start-address 0x00000000
#   --boot \
#   -log-level Fatal,Error,Status \

class Checks(Enum):
    Write = 'Write'
    On = 'On'
    Off = 'Off'

class Levels(Flag):
    Off = 0

    Fatal = auto()
    Error = auto()
    
    Status = auto()
    Progress = auto()
    
    Wire = auto()
    Calculation = auto()

    @property
    def synchronous(self):
        """Log level intervenes in overwriting reports; must print one report per line."""
        return self.has_any(self.Wire | self.Calculation)
    
    @property
    def errors(self):
        """Flags instance includes error levels."""
        return self.has_any(self.Fatal | self.Error)
    
    def has_any(self, levels):
        return any(level in self for level in levels)
    
    def of(levels):
        return functools.reduce(lambda a, b: a | b, levels, Levels(0))

# Global constants
HOST = 'localhost'
PORT = 8880
RETRY_INTERVAL = 5  # seconds

MINOR_PAUSE = 0.0
MAJOR_PAUSE = 0.0

WRITE = True
CHECK = Checks.Off  # Default check mode
FILE = 'firmware/obj_dir/main.bin'
START_ADDRESS = 0x00000000  # Default start address

BOOT = True

LEVEL = Levels.Fatal | Levels.Error | Levels.Status  # Default to Fatal, Error, and Status

class Codes(Enum):
    NOP = 0x00
    BOOT = 0x01
    RST = 0x02
    
    READ_ONE = 0x03
    READ_TWO = 0x04
    READ_THREE = 0x05
    READ_FOUR = 0x06
    
    WRITE_ONE = 0x07
    WRITE_TWO = 0x08
    WRITE_THREE = 0x09
    WRITE_FOUR = 0x0a
    
    ADR_LOWER = 0x0b
    ADR_UPPER = 0x0c

    @property
    def raw_bytes(self):
        return bytes([self.value])

def report(level: Levels, *args, **kwargs):
    if level in LEVEL:
        if Levels.Progress in level and not LEVEL.synchronous:
            print(f'\r{[*args[0:1], ''][0]}', *args[1:], end='', flush=True, **kwargs)
            return

        print(*args, file=sys.stderr if level.errors else None, **kwargs)

        if Levels.Fatal in level:
            sys.exit(1)

def start():
    try:
        # Attempt to connect to the server with retries every RETRY_INTERVAL seconds
        while True:
            # Create a TCP socket
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as test_socket:
                try:
                    test_socket.connect((HOST, PORT))
                    report(Levels.Status, f"Connected to {HOST}:{PORT}.")

                    data = b''
                    if WRITE or CHECK != Checks.Off:
                        with open(FILE, 'rb') as f:
                            data = f.read()
                            if not data:
                                report(Levels.Error, f"File '{FILE}' is empty.")
                                report(Levels.Error, "Continuing.")

                    talk(test_socket, data)
                    break
                except ConnectionRefusedError:
                    report(Levels.Error, f"Error: Unable to connect to {HOST} on port {PORT}. Retrying in {RETRY_INTERVAL} seconds...")
                    time.sleep(RETRY_INTERVAL)

    except FileNotFoundError:
        report(Levels.Fatal, f"Error: File '{FILE}' not found.")

    except KeyboardInterrupt:
        report(Levels.Status, "\nOperation cancelled by user.")
        return

def talk(link, data):
    # Define send function
    def send(raw_data, pause=0):
        link.sendall(raw_data)
        report(Levels.Wire, f"Sent: {raw_data.hex()}")
        
        if pause > 0:
            time.sleep(pause)

    # Initialize *_address_counter with START_ADDRESS
    byte_address_counter = 0x00000000_00 | START_ADDRESS
    quad_word_address_counter = START_ADDRESS

    # Define per_address function
    def address_per(enumerable, action, address_increment=1, reset_address=None):
        nonlocal byte_address_counter, quad_word_address_counter
        if reset_address is not None:
            byte_address_counter = 0x00000000_00 | reset_address
            quad_word_address_counter = reset_address
        previous_upper_address = -1  # For checking if upper address changed
        count = len(enumerable)

        for iota, item in enumerate(enumerable):
            # Split the address into upper and lower 16 bits
            quad_word_address_counter = (byte_address_counter >> 2)
            
            upper_address = (quad_word_address_counter >> 16) & 0xFFFF
            lower_address = quad_word_address_counter & 0xFFFF

            report(Levels.Calculation, f"calculation: address_upper={hex(upper_address)} address_lower={hex(lower_address)}")

            # Update upper address if it changed
            if upper_address != previous_upper_address:
                # Send opcode and data
                send(Codes.ADR_UPPER.raw_bytes, MINOR_PAUSE)  
                send(upper_address.to_bytes(2, byteorder='big'), MAJOR_PAUSE) 
                previous_upper_address = upper_address

            # Send ADR_LOWER opcode and lower address
            send(Codes.ADR_LOWER.raw_bytes, MINOR_PAUSE)  
            send(lower_address.to_bytes(2, byteorder='big'), MAJOR_PAUSE) 

            # Call the function
            action(item, iota, count)

            # Increment the address counter
            byte_address_counter += address_increment

            report(Levels.Progress)

    def check(expected_byte):
        nonlocal byte_address_counter

        for _ in range(2): #FIXME - don't do update read
            # Send READ opcode
            send(Codes(Codes.WRITE_ONE.value + (byte_address_counter & 0b11)).raw_bytes)

            # Read one byte from the socket (blocking)
            received_byte = link.recv(1, socket.MSG_WAITALL)
            
            report(Levels.Wire, f"raw in: {received_byte.hex()}")

        if not received_byte:
            report(Levels.Fatal, f"Error: Did not receive data when reading at address {hex(byte_address_counter)}")
        elif received_byte[0] != expected_byte:
            report(Levels.Fatal, f"Data mismatch at address {hex(byte_address_counter)}: expected {expected_byte}, got {received_byte[0]}")

    if WRITE:
        # Define write function
        def write_action(byte, iota, count):
            # Send WRITE opcode and the data byte
            send(Codes(Codes.WRITE_ONE.value + (byte_address_counter & 0b11)).raw_bytes, MINOR_PAUSE)
            send(bytes([byte]), MAJOR_PAUSE)

            # If check is 'Write', perform read and verify
            if CHECK == Checks.Write:
                check(byte)

            # Progress reporting
            if Levels.Progress in LEVEL:
                status = 'Writing and Verifying' if CHECK == Checks.Write else 'Writing'
                report(Levels.Progress, f"{status}: Byte {iota+1}/{count}")

        # Write data
        address_per(enumerable=data, action=write_action)
        report(Levels.Status, f"\nSuccessfully sent '{FILE}' to {HOST}:{PORT}.")

    # If check is 'On', perform verification
    if CHECK == Checks.On:
        # Define check function
        def check_action(expected_byte, iota, count):
            check(expected_byte)

            # Progress reporting
            if Levels.Progress in LEVEL:
                report(Levels.Progress, f"Verifying: Byte {iota+1}/{count}", flush=True)

        report(Levels.Status, "Starting data verification...")
        address_per(enumerable=data, action=check_action, reset_address=START_ADDRESS)
        report(Levels.Status, "\nData verification successful.")

    # Send BOOT opcode at the end if boot is True
    if BOOT:
        send(Codes.BOOT.raw_bytes, MAJOR_PAUSE)
        report(Levels.Status, "Sent boot command.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Send binary file over TCP using BIOS protocol.')
    parser.add_argument('-H', '--host', type=str, default=HOST,
                        help=f'TCP host to connect to (default: {HOST})')
    parser.add_argument('-p', '--port', type=int, default=PORT,
                        help=f'TCP port to connect to (default: {PORT})')
    parser.add_argument('-r', '--retry-interval', type=float, default=RETRY_INTERVAL,
                        help=f'Pause in seconds between connection attempts (default: {RETRY_INTERVAL})')

    parser.add_argument('-s', '--minor-pause', type=float, default=MINOR_PAUSE,
                        help=f'Pause in seconds between TCP socket writes for the same BIOS command (default: {MINOR_PAUSE})')
    parser.add_argument('-l', '--major-pause', type=float, default=MAJOR_PAUSE,
                        help=f'Pause in seconds between commands (default: {MAJOR_PAUSE})')

    parser.add_argument('-w', '--write', action='store_true', default=WRITE,
                        help='Enable writing data (default: write data)')
    parser.add_argument('-c', '--check', type=lambda value: Checks[value], default=CHECK,
                        help=f'Verification mode: {", ".join(check.name for check in Checks)} (default: {CHECK.name})')
    parser.add_argument('-f', '--file', type=str, default=FILE,
                        help=f'Binary file to send (default: {FILE})')
    parser.add_argument('-a', '--start-address', type=lambda value: int(value, 0), default=START_ADDRESS,
                        help=f'Start address to perform BIOS RAM operations at (default: {hex(START_ADDRESS)})')

    parser.add_argument('-b', '--boot', action='store_true', default=BOOT,
                        help=f'Enable boot command after operations (default: {BOOT})')

    parser.add_argument('-o', '--log-level', type=lambda value: Levels.of(Levels[item.strip()] for item in value.replace('|', ',').split(',')), default=LEVEL,
                        help=f'Output/log level: Off, {", ".join(level.name for level in Levels)} (default: {",".join(level.name for level in LEVEL)})')
    args = parser.parse_args()

    HOST = args.host
    PORT = args.port
    RETRY_INTERVAL = args.retry_interval

    MINOR_PAUSE = args.minor_pause
    MAJOR_PAUSE = args.major_pause

    WRITE = args.write
    CHECK = args.check
    FILE = args.file
    START_ADDRESS = args.start_address

    BOOT = args.boot

    LEVEL = args.log_level

    start()
