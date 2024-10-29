import re

def update_txt_variable(new_text, file_path='./website/index.html'):
    # Read the content of index.html
    with open(file_path, 'r') as file:
        content = file.read()

    # Regular expression to find the txt variable in the script
    txt_pattern = r"(var txt = ')(.*?)(';)"
    
    # Replace the current txt value with new_text
    updated_content = re.sub(txt_pattern, f"\\1{new_text}\\3", content)

    # Write the updated content back to index.html
    with open(file_path, 'w') as file:
        file.write(updated_content)

    print(f"'txt' variable updated to: {new_text}")

# Usage example
new_text = "Chanto Github 10"  # Modify this to your desired text
update_txt_variable(new_text)
