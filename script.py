import json
import svgwrite

# Load ShellCheck JSON output
with open('shellcheck_output.json') as f:
    data = json.load(f)

# Initialize the SVG document
dwg = svgwrite.Drawing('shellcheck_report.svg', profile='tiny', size=("800px", "600px"))

# Set starting coordinates for the text
y_offset = 20
x_offset = 20

# Title
dwg.add(dwg.text("ShellCheck Report", insert=(x_offset, y_offset), font_size="16", font_weight="bold"))
y_offset += 30

# Loop through each message in the JSON output and add to SVG
for entry in data:
    if "file" in entry:
        filename = entry["file"]
        message = entry["message"]
        line = entry["line"]
        column = entry["column"]

        # Format each message
        text = f"{filename}: Line {line}, Column {column} - {message}"

        # Add to SVG
        dwg.add(dwg.text(text, insert=(x_offset, y_offset), font_size="12"))
        y_offset += 20  # Move to next line

        if y_offset > 580:  # If the text exceeds the page size, add a page break
            y_offset = 20

# Save the SVG file
dwg.save()

