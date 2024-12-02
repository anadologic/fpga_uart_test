import os

def compare_files(file1, file2):
    """
    Compare the contents of two files line by line and display differences.
    """
    try:
        with open(file1, "r") as f1, open(file2, "r") as f2:
            # Read lines from both files
            lines1 = f1.readlines()
            lines2 = f2.readlines()

            # Check if the files have the same number of lines
            if len(lines1) != len(lines2):
                print("The files have different numbers of lines.")
                print(f"File1 has {len(lines1)} lines, File2 has {len(lines2)} lines.")
                return

            # Compare each line from both files
            differences_found = False
            for i, (line1, line2) in enumerate(zip(lines1, lines2), start=1):
                if line1.strip() != line2.strip():
                    print(f"Difference found on line {i}:\nFile1: {line1.strip()}\nFile2: {line2.strip()}")
                    differences_found = True

            if not differences_found:
                print("The data in the files are the same.")

    except FileNotFoundError as e:
        print(f"Error: {e}")


def main():
    # File paths
    # Base directory (PWD)
    base_dir = os.getcwd()  # Current working directory
    # Define the file paths
    file1 = os.path.join(base_dir, "golden_result.txt")
    file2 = os.path.join(base_dir, "test_output.txt")

    # Compare the two files
    compare_files(file1, file2)

if __name__ == "__main__":
    main()
