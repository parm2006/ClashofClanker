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

def run_fraction_ocr(img_path, client_height, mode):
    img = cv2.imread(img_path)
    if img is None:
        print(f"ERROR: Could not load image from {img_path}")
        sys.exit(1)

    h, w = img.shape[:2]
    # Mode-dependent target height: 44 for lab (scrH=44), 36 for builders (scrH=30)
    target_height = 44 if mode == "lab" else 36
    scale = target_height / h
    new_w = int(w * scale)
    resized = cv2.resize(img, (new_w, target_height), interpolation=cv2.INTER_LANCZOS4)
    gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    workspace_dir = script_dir
    template_dir = os.path.join(workspace_dir, "OCRimages", "cropped images")

    def load_template_mask(filename):
        path = os.path.join(template_dir, filename)
        if not os.path.exists(path):
            return None
        t_img = cv2.imread(path, cv2.IMREAD_UNCHANGED)
        if t_img is None:
            return None
        alpha = t_img[:, :, 3]
        _, mask = cv2.threshold(alpha, 128, 1, cv2.THRESH_BINARY)
        return mask

    slash_mask = load_template_mask("slash.png")
    if slash_mask is None:
        print("ERROR: slash.png template not found.")
        sys.exit(1)

    best_result = None
    best_overall_score = 0.0

    for thresh_val in [150, 170, 130, 190, 110]:
        _, thresh_img = cv2.threshold(gray, thresh_val, 1, cv2.THRESH_BINARY)
        
        # Shave off top part containing horizontal line
        shave_y = int(target_height * 0.12)
        thresh_img[0:shave_y, :] = 0

        best_slash_score = 0.0
        best_slash_loc = (-1, -1)
        sh_h, sh_w = slash_mask.shape
        th_h, th_w = thresh_img.shape

        for y in range(th_h - sh_h + 1):
            for x in range(th_w - sh_w + 1):
                sub_win = thresh_img[y:y+sh_h, x:x+sh_w]
                intersection = np.sum(np.logical_and(slash_mask, sub_win))
                union = np.sum(np.logical_or(slash_mask, sub_win))
                if union > 0:
                    score = intersection / union
                    if score > best_slash_score:
                        best_slash_score = score
                        best_slash_loc = (x, y)

        if best_slash_score < 0.28:
            continue

        slash_x, slash_y = best_slash_loc
        left_region = thresh_img[0:th_h, max(0, slash_x - 32):min(th_w, slash_x + 3)]
        right_region = thresh_img[0:th_h, max(0, slash_x + sh_w - 3):min(th_w, slash_x + sh_w + 32)]

        def find_digit_iou(region, allowed_digits):
            scores = {}
            r_h, r_w = region.shape

            for digit in allowed_digits:
                d_mask = load_template_mask(f"{digit}.png")
                if d_mask is None:
                    continue
                d_h, d_w = d_mask.shape
                if r_w < d_w or r_h < d_h:
                    continue

                best_score_for_digit = 0.0
                for y in range(r_h - d_h + 1):
                    for x in range(r_w - d_w + 1):
                        sub_win = region[y:y+d_h, x:x+d_w]
                        intersection = np.sum(np.logical_and(d_mask, sub_win))
                        union = np.sum(np.logical_or(d_mask, sub_win))
                        if union > 0:
                            score = intersection / union
                            if score > best_score_for_digit:
                                best_score_for_digit = score
                scores[digit] = best_score_for_digit

            best_digit = -1
            best_score = 0.0
            for d, s in scores.items():
                if s > best_score:
                    best_score = s
                    best_digit = d
                    
            return best_digit, best_score

        if mode == "lab":
            free_digit, free_score = find_digit_iou(left_region, [0, 1, 2])
            total_digit, total_score = find_digit_iou(right_region, [1, 2])
        else: # builders
            free_digit, free_score = find_digit_iou(left_region, [0, 1, 2, 3, 4, 5, 6, 7])
            total_digit, total_score = find_digit_iou(right_region, [1, 2, 3, 4, 5, 6, 7])

        if free_digit != -1 and total_digit != -1 and free_score > 0.25 and total_score > 0.25 and free_digit <= total_digit:
            combined_score = free_score + total_score + best_slash_score
            if combined_score > best_overall_score:
                best_overall_score = combined_score
                best_result = (free_digit, total_digit)

    if best_result is not None:
        print(f"SUCCESS: {best_result[0]}/{best_result[1]}")
    else:
        print(f"FAILED: No threshold yielded valid builder fraction")

def main():
    if len(sys.argv) < 4:
        print("ERROR: Missing arguments. Usage: vision_hook.py <mode> <image_path> <client_height>")
        sys.exit(1)

    mode = sys.argv[1]
    img_path = sys.argv[2]
    client_height = int(sys.argv[3])

    if mode == "hammer":
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
