import os

# Define the content
index_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
</head>
<body>
    <h1>Hello, World chanto_v6 </h1>
    <p>This content was dynamically generated with Python.</p>
</body>
</html>
"""

# Define full path for index.html
file_path = os.path.join(os.path.dirname(__file__), "index.html")

# Write content to index.html
with open(file_path, "w") as file:
    file.write(index_content)

print(f"{file_path} has been generated with dynamic content.")
