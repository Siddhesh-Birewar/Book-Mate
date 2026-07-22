import json
import os
from fpdf import FPDF

transcript_path = "/Users/siddheshbirewar/.gemini/antigravity-ide/brain/3e16a003-4825-4b0e-95d7-edae72063654/.system_generated/logs/transcript_full.jsonl"

def create_pdf():
    target_content = ""
    # Find the last USER_INPUT containing ==Start of PDF==
    with open(transcript_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        for line in reversed(lines):
            try:
                data = json.loads(line)
                if data.get('type') == 'USER_INPUT' and '==Start of PDF==' in data.get('content', ''):
                    target_content = data['content']
                    break
            except:
                pass
                
    if not target_content:
        print("Could not find PDF content in transcript.")
        return

    # Extract OCR blocks
    pdf_text = ""
    lines = target_content.split('\n')
    in_ocr = False
    for line in lines:
        if line.startswith('==Start of OCR'):
            in_ocr = True
            continue
        if line.startswith('==End of OCR'):
            in_ocr = False
            pdf_text += '\n'
            continue
        if in_ocr:
            pdf_text += line + '\n'

    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.set_font("Helvetica", size=12)
    
    # We must handle unicode chars properly. fpdf2 handles it better, or we can encode to latin-1 and ignore errors
    for text_line in pdf_text.split('\n'):
        # replace smart quotes and other non-latin1 characters if necessary
        text_line = text_line.encode('latin-1', 'replace').decode('latin-1')
        pdf.multi_cell(0, 5, txt=text_line)

    output_file = "The_Millionaire_Fastlane_Excerpt.pdf"
    pdf.output(output_file)
    print(f"Successfully generated {output_file}")

if __name__ == "__main__":
    create_pdf()
