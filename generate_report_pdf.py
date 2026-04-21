from pathlib import Path
import re
import textwrap
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(r"c:\Users\Hp\Documents\ABCD\ABCD")
SOURCE = ROOT / "final_report.md"
OUTPUT = ROOT / "Productivitree_Final_Report.pdf"

PAGE_W = 1240
PAGE_H = 1754
MARGIN_X = 90
MARGIN_Y = 90
CONTENT_W = PAGE_W - 2 * MARGIN_X
BG = "white"
FG = "black"
LINE_GAP = 10


def load_font(name: str, size: int) -> ImageFont.FreeTypeFont:
    font_path = Path(r"C:\Windows\Fonts") / name
    return ImageFont.truetype(str(font_path), size=size)


FONTS = {
    "title": load_font("timesbd.ttf", 34),
    "subtitle": load_font("timesbd.ttf", 28),
    "heading1": load_font("timesbd.ttf", 28),
    "heading2": load_font("timesbd.ttf", 23),
    "heading3": load_font("timesbd.ttf", 20),
    "body": load_font("times.ttf", 20),
    "bold": load_font("timesbd.ttf", 20),
    "italic": load_font("timesi.ttf", 20),
    "small": load_font("times.ttf", 17),
}


def strip_markdown(text: str) -> str:
    text = text.replace(r"\&", "&")
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    return text.strip()


class PDFBuilder:
    def __init__(self):
        self.pages = []
        self.new_page()

    def new_page(self):
        self.page = Image.new("RGB", (PAGE_W, PAGE_H), BG)
        self.draw = ImageDraw.Draw(self.page)
        self.y = MARGIN_Y
        self.pages.append(self.page)

    def ensure_space(self, needed: int):
        if self.y + needed > PAGE_H - MARGIN_Y:
            self.new_page()

    def line_height(self, font):
        bbox = self.draw.textbbox((0, 0), "Ag", font=font)
        return bbox[3] - bbox[1]

    def wrap(self, text, font, width=CONTENT_W):
        words = text.split()
        if not words:
            return [""]
        lines = []
        current = words[0]
        for word in words[1:]:
            trial = current + " " + word
            bbox = self.draw.textbbox((0, 0), trial, font=font)
            if bbox[2] - bbox[0] <= width:
                current = trial
            else:
                lines.append(current)
                current = word
        lines.append(current)
        return lines

    def add_blank(self, amount=1):
        self.y += amount * (self.line_height(FONTS["body"]) + LINE_GAP)

    def add_text(self, text, font_key="body", center=False, indent=0):
        font = FONTS[font_key]
        width = CONTENT_W - indent
        lines = self.wrap(text, font, width=width)
        lh = self.line_height(font) + LINE_GAP
        self.ensure_space(lh * len(lines) + 4)
        for line in lines:
            if center:
                bbox = self.draw.textbbox((0, 0), line, font=font)
                x = (PAGE_W - (bbox[2] - bbox[0])) // 2
            else:
                x = MARGIN_X + indent
            self.draw.text((x, self.y), line, fill=FG, font=font)
            self.y += lh

    def add_placeholder(self, text):
        box_h = 150
        self.ensure_space(box_h + 20)
        x1 = MARGIN_X + 60
        x2 = PAGE_W - MARGIN_X - 60
        y1 = self.y
        y2 = self.y + box_h
        self.draw.rectangle([x1, y1, x2, y2], outline="gray", width=3)
        lines = self.wrap(strip_markdown(text), FONTS["italic"], width=(x2 - x1 - 40))
        lh = self.line_height(FONTS["italic"]) + 6
        start_y = y1 + (box_h - lh * len(lines)) // 2
        for i, line in enumerate(lines):
            bbox = self.draw.textbbox((0, 0), line, font=FONTS["italic"])
            x = (PAGE_W - (bbox[2] - bbox[0])) // 2
            self.draw.text((x, start_y + i * lh), line, fill="gray", font=FONTS["italic"])
        self.y = y2 + 20

    def add_image(self, image_path: Path):
        img = Image.open(image_path).convert("RGB")
        max_w = CONTENT_W
        max_h = 700
        scale = min(max_w / img.width, max_h / img.height, 1.0)
        new_size = (int(img.width * scale), int(img.height * scale))
        img = img.resize(new_size)
        needed = new_size[1] + 20
        self.ensure_space(needed)
        x = (PAGE_W - new_size[0]) // 2
        self.page.paste(img, (x, self.y))
        self.y += new_size[1] + 20


def render():
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    pdf = PDFBuilder()
    in_yaml = False
    center_mode = False
    for raw in lines:
        line = raw.rstrip()
        if line == "---":
            in_yaml = not in_yaml
            continue
        if in_yaml:
            continue
        if line == r"\begin{center}":
            center_mode = True
            continue
        if line == r"\end{center}":
            center_mode = False
            pdf.add_blank(1)
            continue
        if line.startswith(r"\vspace"):
            pdf.add_blank(1)
            continue
        if line == r"\newpage":
            pdf.new_page()
            continue
        if not line.strip():
            pdf.add_blank(1)
            continue

        image_match = re.match(r"!\[(.*?)\]\((.*?)\)", line.strip())
        if image_match:
            pdf.add_image(ROOT / image_match.group(2))
            continue

        if line.strip().startswith("[Insert Screenshot:"):
            pdf.add_placeholder(line.strip())
            continue

        if line.startswith("# "):
            pdf.add_text(strip_markdown(line[2:]), "heading1")
            continue
        if line.startswith("## "):
            pdf.add_text(strip_markdown(line[3:]), "heading2")
            continue
        if line.startswith("### "):
            pdf.add_text(strip_markdown(line[4:]), "heading3")
            continue

        if line.startswith("- "):
            pdf.add_text(u"\u2022 " + strip_markdown(line[2:]), "body", indent=10)
            continue

        title_match = re.match(r"\{\\Large \\textbf\{(.+)\}\}\\\\", line)
        if title_match:
            pdf.add_text(strip_markdown(title_match.group(1)), "subtitle", center=True)
            continue

        big_title_match = re.match(r"\{\\LARGE \\textbf\{(.+)\}\}", line)
        if big_title_match:
            pdf.add_text(strip_markdown(big_title_match.group(1)), "title", center=True)
            continue

        if line.endswith(r"\\"):
            content = strip_markdown(line[:-2])
            pdf.add_text(content, "body", center=center_mode)
            continue

        if line.startswith("**") and line.endswith("**"):
            pdf.add_text(strip_markdown(line), "bold", center=center_mode)
            continue

        segments = [strip_markdown(part) for part in line.split("  ") if strip_markdown(part)]
        if len(segments) > 1 and center_mode:
            for segment in segments:
                pdf.add_text(segment, "body", center=True)
            continue

        pdf.add_text(strip_markdown(line), "body", center=center_mode)

    pdf.pages[0].save(OUTPUT, "PDF", resolution=150.0, save_all=True, append_images=pdf.pages[1:])


if __name__ == "__main__":
    render()
