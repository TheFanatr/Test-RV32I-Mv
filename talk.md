# Implementation Details of the `talk.py` Python Script

The `talk.py` script is designed to send a binary file over a TCP connection using a custom BIOS protocol. It includes features such as retries on connection failure, adjustable pauses between commands, verbose logging with multiple levels, and support for writing and verifying data.

## Table of Contents

- [Implementation Details of the `talk.py` Python Script](#implementation-details-of-the-talkpy-python-script)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Command-Line Arguments](#command-line-arguments)
  - [Enum Classes](#enum-classes)
    - [Checks](#checks)
    - [Levels](#levels)
    - [Codes](#codes)
      - [Read Opcodes](#read-opcodes)
      - [Write Opcodes](#write-opcodes)
      - [Address Opcodes](#address-opcodes)
  - [Global Constants](#global-constants)
  - [Verbose Logging Mechanism](#verbose-logging-mechanism)
  - [Main Functions](#main-functions)
    - [`start()` Function](#start-function)
    - [`talk()` Function](#talk-function)
      - [Address Initialization](#address-initialization)
      - [`send()` Function](#send-function)
      - [`address_per()` Function](#address_per-function)
      - [Write and Check Operations](#write-and-check-operations)
      - [Progress Reporting](#progress-reporting)
      - [`check()` Function](#check-function)
  - [Intentional Workarounds](#intentional-workarounds)
  - [Usage Example](#usage-example)
  - [Conclusion](#conclusion)

---

## Overview

The `talk.py` script is a Python utility for sending binary files to a target device over TCP using a custom BIOS protocol. It handles connection retries, supports various operational modes (writing, checking, booting), and provides detailed logging capabilities. The script now uses **quad-word addressing** (addresses are in terms of 32-bit words) and updated opcodes to align with the latest BIOS protocol specifications. It includes intentional workarounds for known BIOS bugs, marked with `#FIXME` comments, which should not be applied until the BIOS issues are resolved.

---

## Command-Line Arguments

The script uses the `argparse` module to parse command-line arguments, allowing users to customize its behavior. The available arguments are:

- `-H`, `--host`: TCP host to connect to (default: `localhost`).
- `-p`, `--port`: TCP port to connect to (default: `8880`).
- `-r`, `--retry-interval`: Pause in seconds between connection attempts (default: `5`).
- `-s`, `--minor-pause`: Pause in seconds between socket writes for the same BIOS command (default: `0.0`).
- `-l`, `--major-pause`: Pause in seconds between commands (default: `0.0`).
- `-w`, `--write`: Enable writing data (default: `True`).
- `-c`, `--check`: Verification mode (`Write`, `On`, `Off`) (default: `Off`).
- `-f`, `--file`: Binary file to send (default: `firmware/obj_dir/main.bin`).
- `-a`, `--start-address`: **Start address (addresses quad-words of RAM)** to perform BIOS RAM operations at (default: `0x0`).
- `-b`, `--boot`: Enable boot command after operations (default: `True`).
- `-o`, `--log-level`: Output mode with multiple levels (`Off`, `Fatal`, `Error`, `Status`, `Progress`, `Wire`, `Calculation`) (default: `Fatal,Error,Status`).

---

## Enum Classes

### Checks

The `Checks` enum defines the verification modes:

- `Write`: Verify data during the write process.
- `On`: Verify data after writing.
- `Off`: No verification.

### Levels

The `Levels` `Flag` enum defines verbose logging levels:

- `Off`: No logging.
- `Fatal`: Fatal errors causing immediate exit.
- `Error`: Non-fatal errors.
- `Status`: General status messages.
- `Progress`: Progress updates during operations.
- `Wire`: Logs raw data sent and received over the network.
- `Calculation`: Logs internal calculations, such as address computations.

The `Levels` enum includes two properties:

- `synchronous`: Determines if the current level requires synchronous logging (one report per line) to avoid overwriting outputs.
- `errors`: Checks if the level includes error messages.

### Codes

The `Codes` enum represents BIOS opcodes:

- `NOP` (`0x00`): No operation.
- `BOOT` (`0x01`): Boot command.
- `RST` (`0x02`): Reset command.

#### Read Opcodes

- `READ_ONE` (`0x03`): Read byte 0 of the current quad-word.
- `READ_TWO` (`0x04`): Read byte 1 of the current quad-word.
- `READ_THREE` (`0x05`): Read byte 2 of the current quad-word.
- `READ_FOUR` (`0x06`): Read byte 3 of the current quad-word.

#### Write Opcodes

- `WRITE_ONE` (`0x07`): Write byte 0 of the current quad-word.
- `WRITE_TWO` (`0x08`): Write byte 1 of the current quad-word.
- `WRITE_THREE` (`0x09`): Write byte 2 of the current quad-word.
- `WRITE_FOUR` (`0x0a`): Write byte 3 of the current quad-word.

#### Address Opcodes

- `ADR_LOWER` (`0x0b`): Set lower 16 bits of the address.
- `ADR_UPPER` (`0x0c`): Set upper 16 bits of the address.

Each opcode has:

- `raw_bytes`: Returns the byte representation of the opcode.
- `__bytes__`: Allows conversion to bytes using `bytes(Codes.OPCODE)`.
- `__int__`: Allows conversion to integer using `int(Codes.OPCODE)`.
- `__add__`: Enables arithmetic addition with other opcodes or integers, useful for calculating read/write opcodes with offsets.

---

## Global Constants

The script defines several global constants with default values:

- `HOST`: `localhost`
- `PORT`: `8880`
- `RETRY_INTERVAL`: `5`
- `MINOR_PAUSE`: `0.0`
- `MAJOR_PAUSE`: `0.0`
- `WRITE`: `True`
- `CHECK`: `Checks.Off`
- `FILE`: `firmware/obj_dir/main.bin`
- `START_QUAD_WORD_ADDRESS`: `0x00000000_00`
- `BOOT`: `True`
- `LEVEL`: `Levels.Fatal | Levels.Error | Levels.Status`

---

## Verbose Logging Mechanism

The script uses a custom `report()` function for logging, which checks if a message's level is included in the current `LEVEL` levels before printing. It handles progress reporting differently based on whether synchronous logging is required.

```python
def report(level: Levels, *args, **kwargs):
    if level in LEVEL:
        if Levels.Progress in level and not LEVEL.synchronous:
            print(f'\r{[*args[0:1], ''][0]}', *args[1:], end='', flush=True, **kwargs)
            return

        print(*args, file=sys.stderr if level.errors else None, **kwargs)

        if Levels.Fatal in level:
            sys.exit(1)
```

---

## Main Functions

### `start()` Function

The `start()` function handles command-line argument parsing and initiates the connection to the target device. It attempts to connect with retries and reads the binary file if required.

Key points:

- Parses command-line arguments and updates global variables.
- Attempts to connect to the target device, retrying every `RETRY_INTERVAL` seconds upon failure.
- Reads the binary file specified by `FILE` if writing or checking is enabled.
- Calls the `talk()` function upon successful connection.

### `talk()` Function

The `talk()` function manages communication with the target device over the established socket connection. It includes sending data, handling verification, and sending the boot command if enabled.

Key points:

#### Address Initialization

  - `byte_address_counter`: Initialized by shifting the `START_QUAD_WORD_ADDRESS` left by 2 bits to convert quad-word address to byte address.
    ```python
    byte_address_counter = 0x00000000_00 | (START_QUAD_WORD_ADDRESS << 2)
    ```
  - `quad_word_address_counter`: Initialized with `START_QUAD_WORD_ADDRESS`.
  - `per_quad_word_address_byte_number`: Tracks the byte offset within the current quad-word.

#### `send()` Function

  - Sends raw data over the socket.
  - Logs the sent data if `Wire` level is enabled.
    ```python
    def send(raw_data, pause=0):
        link.sendall(raw_data)
        report(Levels.Wire, f"raw: {raw_data.hex()}")
        if pause > 0:
            time.sleep(pause)
    ```

#### `address_per()` Function

  - Iterates over the data, calculates addresses, and performs the specified action at each address.
  - Updates `quad_word_address_counter` and `per_quad_word_address_byte_number` based on `byte_address_counter`.
  - Sends `ADR_UPPER` and `ADR_LOWER` opcodes correctly.
  - Logs calculations if `Calculation` level is enabled.

#### Write and Check Operations

  - Uses adjusted opcodes (`WRITE_ONE` plus offset) to write to specific bytes within a quad-word.
    ```python
    send(bytes(Codes.WRITE_ONE + per_quad_word_address_byte_number), MINOR_PAUSE)
    ```
  - Reads data using adjusted opcodes (`READ_ONE` plus offset) during verification.
    ```python
    send(bytes(Codes.READ_ONE + per_quad_word_address_byte_number))
    ```

#### Progress Reporting
  - Reports before sending data to accurately reflect the operation in progress.

#### `check()` Function

The `check()` function reads a byte from the target device and compares it to the expected byte, handling any mismatches or errors.

Key points:

- Sends the appropriate `READ` opcode based on the byte offset within the quad-word.
- Performs an intentional duplicate read to accommodate a BIOS state machine bug.
- Logs received data if `Wire` level is enabled.
- Reports errors with detailed address and byte offset information.

---

## Intentional Workarounds

The script contains intentional deviations from standard logic to work around known BIOS bugs, marked with `#FIXME` comments.

Key workarounds:

1. **Duplicate Reads in `check()` Function**:
   - The function performs duplicate reads to adjust for a BIOS state machine bug.
     ```python
     for _ in range(2):  # FIXME - don't do update read
         send(bytes(Codes.READ_ONE + per_quad_word_address_byte_number))
         received_byte = link.recv(1, socket.MSG_WAITALL)
     ```

---

## Usage Example

To run the script with all default settings, ensuring all options are explicitly set, use the following command:

```bash
python3.13 script_name.py \
  -H localhost \
  -p 8880 \
  -r 5 \
  -s 0.0 \
  -l 0.0 \
  -w \
  -c Off \
  -f firmware/obj_dir/main.bin \
  -a 0x0 \
  -b \
  -o Fatal,Error,Status
```

---

## Conclusion

The `talk.py` script is a robust utility for sending binary files to a target device using a custom BIOS protocol over TCP. It includes features such as adjustable pauses, verbose logging with multiple levels, support for writing and verifying data, and intentional workarounds for known BIOS issues.

Key takeaways:

- **Quad-Word Addressing**: The script uses quad-word addressing to align with the BIOS protocol.
- **Updated Opcodes**: Uses specific opcodes for reading and writing individual bytes within a quad-word.
- **Flexible Command-Line Interface**: Allows users to customize behavior extensively.
- **Verbose Logging**: Offers granular control over logging levels to aid in debugging and monitoring.
- **Intentional Workarounds**: Contains necessary adjustments to function with the current BIOS, marked for future correction.
- **Modular Design**: Functions are well-organized, making the script maintainable and extensible.

---

**Note**: Developers should be aware of the `#FIXME` comments indicating where code changes will be required once the BIOS bugs are addressed. These intentional adjustments are crucial for the script's current operation and should not be modified until the underlying issues are resolved.