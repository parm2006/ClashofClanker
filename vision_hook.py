import sys
import os
import cv2
import numpy as np


def run_info_match(img_path, client_height):
    img = cv2.imread(img_path)
    if img is None:
        print(f"ERROR: Could not load image from {img_path}")
        sys.exit(1)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    template_path = os.path.join(
        script_dir,
        "OCRimages",
        "cropped images",
        "info_button_template.png",
    )
    template = cv2.imread(template_path)
    if template is None:
        print("ERROR: Could not load info_button_template.png")
        sys.exit(1)

    reference_height = 1028
    base_scale = client_height / reference_height
    best_score = -1.0
    best_loc = (0, 0)
    best_size = (0, 0)

    # The ADB frame has a stable logical size, but this sweep tolerates a
    # recalibrated emulator and small UI-scale changes.
    for scale_mult in [1.0, 0.9, 1.1, 0.8, 1.2, 0.7, 1.3]:
        scale = base_scale * scale_mult
        width = max(1, round(template.shape[1] * scale))
        height = max(1, round(template.shape[0] * scale))
        if width > img.shape[1] or height > img.shape[0]:
            continue

        scaled = cv2.resize(
            template,
            (width, height),
            interpolation=cv2.INTER_AREA if scale < 1 else cv2.INTER_CUBIC,
        )
        result = cv2.matchTemplate(img, scaled, cv2.TM_CCOEFF_NORMED)
        _, score, _, location = cv2.minMaxLoc(result)
        if score > best_score:
            best_score = score
            best_loc = location
            best_size = (width, height)

    if best_score >= 0.60:
        width, height = best_size
        center_x = best_loc[0] + width // 2
        center_y = best_loc[1] + height // 2
        print(
            "SUCCESS: "
            f"{center_x}/{center_y}/{best_score:.4f}/"
            f"{best_loc[0]}/{best_loc[1]}/{width}/{height}"
        )
    else:
        print(f"FAILED: Best Info template score {best_score:.4f}")


def run_hammer_match(img_path, client_height):
    img = cv2.imread(img_path)
    if img is None:
        print(f"ERROR: Could not load image from {img_path}")
        sys.exit(1)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    workspace_dir = script_dir
    template_path = os.path.join(workspace_dir, "OCRimages", "cropped images", "hammer_template_trans.png")

    template = cv2.imread(template_path)
    if template is None:
        print("ERROR: Could not load hammer_template_trans.png")
        sys.exit(1)

    REF_CLIENT_HEIGHT = 1028
    scale = client_height / REF_CLIENT_HEIGHT

    lower_magenta = np.array([250, 0, 250])
    upper_magenta = np.array([255, 5, 255])

    best_val = 0.0
    best_loc = (0, 0)
    best_template_shape = (0, 0)

    # Multi-scale sweep to match different screen resolutions / DPI scaling
    for scale_mult in [1.0, 0.85, 1.15, 0.75, 1.25]:
        s = scale * scale_mult
        new_w = int(template.shape[1] * s)
        new_h = int(template.shape[0] * s)
        if new_w < 10 or new_h < 10 or new_w > img.shape[1] or new_h > img.shape[0]:
            continue

        scaled_template = cv2.resize(template, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
        scaled_magenta = cv2.inRange(scaled_template, lower_magenta, upper_magenta)
        scaled_mask = cv2.bitwise_not(scaled_magenta)

        res = cv2.matchTemplate(img, scaled_template, cv2.TM_CCOEFF_NORMED, mask=scaled_mask)
        _, max_val, _, max_loc = cv2.minMaxLoc(res)

        if max_val > best_val:
            best_val = max_val
            best_loc = max_loc
            best_template_shape = scaled_template.shape[:2]

    if best_val > 0.45:
        h_t, w_t = best_template_shape
        match_x = best_loc[0] + w_t // 2
        match_y = best_loc[1] + h_t // 2
        print(f"SUCCESS: {match_x}/{match_y}")
    else:
        print(f"FAILED (Best Match Score: {best_val:.2f})")

def binary_template_match(region, template, whole_region=False):
    if region.shape[0] < template.shape[0] or region.shape[1] < template.shape[1]:
        return 0.0, (0, 0)
    region = region.astype(np.float32)
    template = template.astype(np.float32)
    intersection = cv2.matchTemplate(region, template, cv2.TM_CCORR)
    foreground = float(region.sum()) if whole_region else cv2.matchTemplate(region, np.ones_like(template), cv2.TM_CCORR)
    union = foreground + float(template.sum()) - intersection
    scores = intersection / np.maximum(union, 1.0)
    _, score, _, location = cv2.minMaxLoc(scores)
    return score, location


def read_fraction_ocr(img, mode):
    if mode not in ("builders", "lab"):
        raise ValueError("Unsupported fraction mode: " + mode)
    template_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "OCRimages", "cropped images")
    templates = {}
    for name in ["slash"] + [str(digit) for digit in range(8)]:
        template = cv2.imread(os.path.join(template_dir, name + ".png"), cv2.IMREAD_UNCHANGED)
        if template is None or template.ndim != 3 or template.shape[2] != 4:
            raise ValueError("Missing alpha template: " + name)
        templates[name] = (template[:, :, 3] > 128).astype(np.uint8)

    best = None
    for target_height in ([36, 44, 32, 40, 48, 52, 56] if mode == "builders" else [44, 36, 32, 40, 48, 52, 56]):
        scale = target_height / img.shape[0]
        resized = cv2.resize(img, (max(1, round(img.shape[1] * scale)), target_height), interpolation=cv2.INTER_LANCZOS4)
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
        contrast = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(4, 4)).apply(gray)
        # Counts are white; suppress colored portraits, hammer art and overlay borders.
        neutral = cv2.cvtColor(resized, cv2.COLOR_BGR2HSV)[:, :, 1] <= 90
        for variant, source in [("grayscale", gray), ("contrast", contrast)]:
            for threshold in [150, 170, 130, 190, 210]:
                mask = ((source >= threshold) & neutral).astype(np.uint8)
                mask[:round(target_height * 0.10), :] = 0
                slash_score, (slash_x, _) = binary_template_match(mask, templates["slash"])
                if slash_score < 0.30:
                    continue
                slash_width = templates["slash"].shape[1]
                left = mask[:, max(0, slash_x - 32):min(mask.shape[1], slash_x + 3)]
                right = mask[:, max(0, slash_x + slash_width - 7):min(mask.shape[1], slash_x + slash_width + 32)]
                free_digits = range(3) if mode == "lab" else range(8)
                total_digits = range(1, 3) if mode == "lab" else range(1, 8)
                free, free_score = max(((digit, binary_template_match(left, templates[str(digit)], whole_region=True)[0]) for digit in free_digits), key=lambda item: item[1])
                total, total_score = max(((digit, binary_template_match(right, templates[str(digit)], whole_region=True)[0]) for digit in total_digits), key=lambda item: item[1])
                if free_score <= 0.30 or total_score <= 0.30 or free > total:
                    continue
                score = slash_score + free_score + total_score
                if best is None or score > best["score"]:
                    best = {"free": free, "total": total, "score": score,
                            "variant": variant, "threshold": threshold,
                            "height": target_height, "mask": mask * 255}
    return best


def run_fraction_ocr(img_path, client_height, mode):
    img = cv2.imread(img_path)
    if img is None:
        print(f"ERROR: Could not load image from {img_path}")
        sys.exit(1)
    try:
        result = read_fraction_ocr(img, mode)
    except ValueError as error:
        print("ERROR: " + str(error))
        sys.exit(1)
    if result is None:
        print("FAILED: No contrast/threshold pass yielded a valid count")
        return
    diagnostic_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scratch")
    os.makedirs(diagnostic_dir, exist_ok=True)
    cv2.imwrite(os.path.join(diagnostic_dir, f"availability_{mode}_ocr.png"), result["mask"])
    cv2.imwrite(os.path.join(diagnostic_dir, f"availability_{mode}_crop.png"), img)
    print(f"SUCCESS: {result['free']}/{result['total']}")
    print(f"PREPROCESS: {result['variant']}, binary={result['threshold']}, height={result['height']}, score={result['score']:.3f}")


def run_upgrade_contrast(img_path):
    img = cv2.imread(img_path)
    if img is None:
        raise ValueError(f"Could not load image from {img_path}")
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    contrast = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)).apply(gray)
    output_path = os.path.splitext(img_path)[0] + "_contrast.png"
    if not cv2.imwrite(output_path, contrast):
        raise OSError(f"Could not write contrast image to {output_path}")
    # White lettering has black outlines that CLAHE can merge into the drawer.
    text_path = os.path.splitext(img_path)[0] + "_text.png"
    if not cv2.imwrite(text_path, cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY_INV)[1]):
        raise OSError(f"Could not write text image to {text_path}")
    print("SUCCESS: " + output_path)


def main():
    if len(sys.argv) < 4:
        print("ERROR: Missing arguments. Usage: vision_hook.py <mode> <image_path> <client_height>")
        sys.exit(1)

    mode = sys.argv[1]
    img_path = sys.argv[2]
    client_height = int(sys.argv[3])

    if mode == "upgrade_contrast":
        run_upgrade_contrast(img_path)
    elif mode == "hammer":
        run_hammer_match(img_path, client_height)
    elif mode == "info":
        run_info_match(img_path, client_height)
    elif mode == "lab":
        run_fraction_ocr(img_path, client_height, "lab")
    elif mode == "builders":
        run_fraction_ocr(img_path, client_height, "builders")
    else:
        print(f"ERROR: Unknown mode '{mode}'")
        sys.exit(1)

if __name__ == "__main__":
    main()
