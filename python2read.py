import os

# Define the base directory for the modules
module_base_dir = "./modules"

# Create a new Python script to store the module data
output_script = "generate_modules.py"
with open(output_script, "w") as f:
    f.write("import os\n\n")

    # Iterate through the modules directory
    for module_name in os.listdir(module_base_dir):
        module_path = os.path.join(module_base_dir, module_name)

        # Ensure it's a directory
        if os.path.isdir(module_path):
            f.write(f"# Module: {module_name}\n")
            for file_name in os.listdir(module_path):
                file_path = os.path.join(module_path, file_name)

                # Read the content of the Terraform file
                if os.path.isfile(file_path) and file_name.endswith(".tf"):
                    with open(file_path, "r") as tf_file:
                        content = tf_file.read()
                    f.write(f"modules['{module_name}']['{file_name}'] = '''\n{content}\n'''\n")
            f.write("\n")

    f.write("modules = {\n")
    for module_name in os.listdir(module_base_dir):
        module_path = os.path.join(module_base_dir, module_name)
        if os.path.isdir(module_path):
            f.write(f"    '{module_name}': {{\n")
            for file_name in os.listdir(module_path):
                if file_name.endswith(".tf"):
                    f.write(f"        '{file_name}': modules['{module_name}']['{file_name}'],\n")
            f.write("    },\n")
    f.write("}\n")

print(f"Module data generated in '{output_script}'")
