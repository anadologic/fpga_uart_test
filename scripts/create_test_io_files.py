import random
import os

def calculate_checksum(packet):
    """
    Calculate checksum based on the sum of the packet bytes.
    The checksum is the value that makes the sum of all bytes
    (including the checksum byte itself) end with 00 in hex.
    """
    total_sum = sum(packet)  # Sum of all bytes in the packet
    checksum = (256 - (total_sum % 256)) % 256  # The value that makes the sum end with 00
    return checksum

def generate_packet():
    """
    Generate a single packet with the structure: [Header – Num1 – Num2 – Opcode – Checksum].
    """
    header = [0xBA, 0xCD]  # Fixed header "BACD"

    # Random 16-bit numbers for num1 and num2
    num1 = random.randint(0, 0xFFFF)
    num2 = random.randint(0, 0xFFFF)

    # Random opcode: either 0x00 or 0x01
    opcode = random.choice([0x00, 0x01])

    # Initial checksum as 0 (it will be recalculated)
    checksum = 0

    # Create the packet (excluding checksum byte for now)
    packet = header + [num1 >> 8, num1 & 0xFF, num2 >> 8, num2 & 0xFF, opcode, checksum]

    # Calculate the checksum and replace the checksum byte
    checksum = calculate_checksum(packet)
    packet[-1] = checksum

    # Convert the packet to a string of hexadecimal values
    packet_hex = ''.join(f'{byte:02X}' for byte in packet)

    return packet_hex

def write_packets_to_file(filepath, num_packets):
    """
    Generate and write n packets to a file, each on a new line.
    """
    with open(filepath, 'w') as file:
        for _ in range(num_packets):
            packet = generate_packet()
            file.write(packet + '\n')

def hex_string_to_bytes(hex_string):
    """
    Convert a hexadecimal string (e.g., "BACD001000200049") to a list of bytes.
    """
    return [int(hex_string[i:i + 2], 16) for i in range(0, len(hex_string), 2)]

def bytes_to_hex_string(byte_list):
    """
    Convert a list of bytes to a hexadecimal string.
    """
    return ''.join(f"{byte:02X}" for byte in byte_list)

def process_message(header, num1, num2, opcode):
    """
    Process the message based on the given opcode.
    If opcode is 0, do num1 + num2, if 1, do num1 - num2.
    Then, calculate the checksum and return the new message.
    """
    # Perform the operation based on the opcode
    if opcode == 0:
        result = num1 + num2
    elif opcode == 1:
        result = num1 - num2
    else:
        raise ValueError("Invalid opcode. Only 0 or 1 are allowed.")

    # Ensure result fits in 2 bytes (16 bits)
    result &= 0xFFFF  # Mask to keep the result within 16 bits

    # Convert result to two bytes
    result_bytes = [(result >> 8) & 0xFF, result & 0xFF]

    # Construct the packet [Header (0xABCD) – Result (2 bytes) – Checksum (1 byte)]
    new_header = [0xAB, 0xCD]  # Fixed header "ABCD"
    packet = new_header + result_bytes

    # Calculate checksum
    checksum = calculate_checksum(packet)

    # Add the checksum to the packet
    packet.append(checksum)

    # Return the final 5-byte message
    return packet

def main():
    # Base directory (PWD)
    base_dir = os.getcwd()  # Current working directory

    # Define the file paths
    input_file = os.path.join(base_dir, "test_input.txt")
    output_file = os.path.join(base_dir, "golden_result.txt")

    # Number of packets to generate
    num_packets = 50

    # Ensure directories exist
    os.makedirs(os.path.dirname(input_file), exist_ok=True)
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    # Step 1: Write packets to the input file
    write_packets_to_file(input_file, num_packets)
    print(f'{num_packets} packets have been written to {input_file}')

    # Step 2: Read packets from the input file and process them
    if not os.path.exists(input_file):
        print(f"Error: Input file {input_file} does not exist.")
        return

    # Open test_input.txt file and read all lines
    with open(input_file, "r") as infile:
        input_lines = infile.readlines()

    # Prepare to write the output to output.txt
    with open(output_file, "w") as outfile:
        for line in input_lines:
            # Remove any whitespace or newline characters
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            # Convert the hexadecimal string to a list of bytes
            packet = hex_string_to_bytes(line)

            # Parse the incoming packet
            header = packet[:2]  # First 2 bytes (Header, e.g., "BACD")
            num1 = (packet[2] << 8) | packet[3]  # Next 2 bytes (Num1)
            num2 = (packet[4] << 8) | packet[5]  # Next 2 bytes (Num2)
            opcode = packet[6]  # 7th byte (Opcode)
            checksum = packet[7]  # 8th byte (Checksum)

            # Print the parsed values (for debugging)
            print(f"Processing: Header = {bytes_to_hex_string(header)}, "
                  f"Num1 = {num1:04X}, Num2 = {num2:04X}, Opcode = {opcode:02X}, Checksum = {checksum:02X}")

            # Process the message to get the new 5-byte packet
            new_packet = process_message(header, num1, num2, opcode)

            # Convert the new packet to a hexadecimal string
            new_packet_hex = bytes_to_hex_string(new_packet)

            # Write the result to the output file
            outfile.write(new_packet_hex + "\n")

            # Print the new packet (for debugging)
            print(f"New Packet: {new_packet_hex}")

    print(f"Processing complete. Output written to {output_file}")

if __name__ == "__main__":
    main()