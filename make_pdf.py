import os
from fpdf import FPDF

def create_pdf():
    input_file = "sample_text.txt"
    output_file = "sample_book.pdf"
    
    if not os.path.exists(input_file):
        print(f"File {input_file} not found.")
        return

    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.set_font("Helvetica", size=12)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    for text_line in content.split('\n'):
        text_line = text_line.encode('latin-1', 'replace').decode('latin-1')
        pdf.write(5, text_line + '\n')

    pdf.output(output_file)
    print(f"Successfully generated {output_file}")

if __name__ == "__main__":
    create_pdf()
