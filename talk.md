# Implementation Details of the `talk.py` Python Script

The script is designed to send a binary file over a TCP connection using a custom BIOS protocol. It includes features such as retries on connection failure, adjustable pauses between commands, verbose logging with multiple levels, and support for writing and verifying data.

## Table of Contents

- [Implementation Details of the `talk.py` Python Script](#implementation-details-of-the-talkpy-python-script)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Command-Line Arguments](#command-line-arguments)
  - [Enum Classes](#enum-classes)
    - [Checks](#checks)
    - [Levels](#levels)
    - [Codes](#codes)
  - [Global Constants](#global-constants)
  - [Verbose Logging Mechanism](#verbose-logging-mechanism)
  - [Main Functions](#main-functions)
    - [`start()` Function](#start-function)
    - [`talk()` Function](#talk-function)
    - [`send()` Function](#send-function)
    - [`address_per()` Function](#address_per-function)
    - [`check()` Function](#check-function)
  - [Intentional Workarounds](#intentional-workarounds)
  - [Usage Example](#usage-example)
  - [Conclusion](#conclusion)

---

## Overview

The `talk.py` script is a Python utility for sending binary files to a target device over TCP using a custom BIOS protocol. It handles connection retries, supports various operational modes (writing, checking, booting), and provides detailed logging capabilities. The script includes intentional workarounds for known BIOS bugs, marked with `#FIXME` comments, which should not be applied until the BIOS issues are resolved.

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
- `-f`, `--file`: Binary file to send (default: `tmp/main.bin`).
- `-a`, `--start-address`: Start address to perform BIOS RAM operations at (default: `0x00000000`).
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

- `NOP`: No operation.
- `BOOT`: Boot command.
- `RST`: Reset command.
- `READ`: Read command.
- `WRITE`: Write command.
- `ADR_LOWER`: Set lower address bits.
- `ADR_UPPER`: Set upper address bits.

Each opcode has a `raw_bytes` property to get its byte representation.

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
- `FILE`: `tmp/main.bin`
- `START_ADDRESS`: `0x00000000`
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

- Defines the `send()` function for sending data over the socket with optional pauses.
- Initializes `address_counter` with `START_ADDRESS`.
- Implements the `address_per()` function for iterating over the data and performing actions at each address.
- Manages writing data, verifying data, and sending the boot command based on the provided options.

### `send()` Function

The `send()` function sends raw bytes over the socket and logs the sent data if the `Wire` log level is enabled.

```python
def send(raw_data, pause=0):
    link.sendall(raw_data)
    report(Levels.Wire, f"Sent: {raw_data.hex()}")

    if pause > 0:
        time.sleep(pause)
```

### `address_per()` Function

The `address_per()` function iterates over the provided data, calculates addresses, and performs the specified action at each address.

Key points:

- Calculates upper and lower address bits.
- Handles sending address opcodes and address data to the target device.
- Calls the provided `action` function at each address.
- Increments the `address_counter` accordingly.
- Logs calculations if the `Calculation` log level is enabled.

### `check()` Function

The `check()` function reads a byte from the target device and compares it to the expected byte, handling any mismatches or errors.

Key points:

- Sends the `READ` opcode and reads the response.
- Performs an intentional duplicate read to adjust for a known BIOS state machine bug (marked with `#FIXME` comments).
- Logs received data if the `Wire` log level is enabled.
- Exits the script with a fatal error if the read fails or the data does not match.

---

## Intentional Workarounds

The script contains intentional deviations from standard logic to work around known BIOS bugs. These are marked with `#FIXME` comments and should **not** be corrected until the BIOS issues are resolved.

Key workarounds:

1. **Opcode Swapping**: The `ADR_LOWER` and `ADR_UPPER` opcodes are intentionally swapped when sending addresses.
   ```python
   send(Codes.ADR_LOWER.raw_bytes, MINOR_PAUSE) #FIXME - Use ADR_UPPER
   ```

2. **Byte Order Adjustment**: The script uses `'little'` byte order instead of `'big'` when sending address data.
   ```python
   send(upper_address.to_bytes(2, byteorder='little'), MAJOR_PAUSE) #FIXME - Use byteorder='big'
   ```

3. **Duplicate Reads**: The `check()` function performs duplicate reads to accommodate a BIOS state machine bug.
   ```python
   for _ in range(2): #FIXME - don't do update read
       send(Codes.READ.raw_bytes)
       received_byte = link.recv(1, socket.MSG_WAITALL)
   ```

These workarounds are necessary for the script to function correctly with the current BIOS implementation and should remain until the BIOS is fixed.

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
  -a 0x00000000 \
  -b \
  -o Fatal,Error,Status
```

---

## Conclusion

The `talk.py` script is a robust utility for sending binary files to a target device using a custom BIOS protocol over TCP. It includes features such as adjustable pauses, verbose logging with multiple levels, support for writing and verifying data, and intentional workarounds for known BIOS issues.

Key takeaways:

- **Flexible Command-Line Interface**: Allows users to customize behavior extensively.
- **Verbose Logging**: Offers granular control over logging levels to aid in debugging and monitoring.
- **Intentional Workarounds**: Contains necessary adjustments to function with the current BIOS, marked for future correction.
- **Modular Design**: Functions are well-organized, making the script maintainable and extensible.

---

**Note**: Developers should be aware of the `#FIXME` comments indicating where code changes will be required once the BIOS bugs are addressed. These intentional "errors" are crucial for the script's current operation and should not be modified until the underlying issues are resolved.