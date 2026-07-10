import sys
import os
import cv2
import numpy as np

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

    if scale != 1.0:
        new_w = int(template.shape[1] * scale)
        new_h = int(template.shape[0] * scale)
        template = cv2.resize(template, (new_w, new_h), interpolation=cv2.INTER_CUBIC)

    lower_magenta = np.array([250, 0, 250])
    upper_magenta = np.array([255, 5, 255])
    magenta_mask = cv2.inRange(template, lower_magenta, upper_magenta)
    mask = cv2.bitwise_not(magenta_mask)

    res = cv2.matchTemplate(img, template, cv2.TM_CCOEFF_NORMED, mask=mask)
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
    
    # We won't print the max match score line because AHK parses the output
    # Just print SUCCESS or FAILED
    if max_val > 0.65:
        h_t, w_t = template.shape[:2]
        match_x = max_loc[0] + w_t // 2
        match_y = max_loc[1] + h_t // 2
        print(f"SUCCESS: {match_x}/{match_y}")
    else:
        print("FAILED")

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
    _, thresh_img = cv2.threshold(gray, 150, 1, cv2.THRESH_BINARY)
    
    # Shave off top part containing horizontal line
    shave_y = int(target_height * 0.12)
    thresh_img[0:shave_y, :] = 0

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

    if best_slash_score < 0.50:
        print(f"FAILED: Slash not found (max IoU={best_slash_score:.3f})")
        sys.exit(0)

    slash_x, slash_y = best_slash_loc
    # Widened regions to prevent clipping
    left_region = thresh_img[0:th_h, max(0, slash_x - 28):min(th_w, slash_x + 3)]
    right_region = thresh_img[0:th_h, max(0, slash_x + sh_w - 3):min(th_w, slash_x + sh_w + 25)]

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

        # Heuristic: '1' can falsely get a very high IoU on the thick vertical edges of other digits.
        # However, if it's truly a '1', its score will be very high (>0.85).
        # If another digit scores decently (>0.40) AND '1' doesn't look perfect (<0.85), pick the other digit.
        if 1 in allowed_digits:
            score_1 = scores.get(1, 0)
            best_non_1 = -1
            best_non_1_score = 0
            for d, s in scores.items():
                if d != 1 and s > best_non_1_score:
                    best_non_1_score = s
                    best_non_1 = d
            
            if best_non_1_score > 0.40 and score_1 < 0.85:
                return best_non_1, best_non_1_score

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
        free_digit, free_score = find_digit_iou(left_region, [0, 1, 2, 3, 4, 5, 6])
        total_digit, total_score = find_digit_iou(right_region, [2, 3, 4, 5, 6, 7])

    if free_digit != -1 and total_digit != -1 and free_score > 0.25 and total_score > 0.25:
        print(f"SUCCESS: {free_digit}/{total_digit}")
    else:
        print(f"FAILED: Left={free_digit} (IoU={free_score:.3f}), Right={total_digit} (IoU={total_score:.3f})")

def main():
    if len(sys.argv) < 4:
        print("ERROR: Missing arguments. Usage: vision_hook.py <mode> <image_path> <client_height>")
        sys.exit(1)

    mode = sys.argv[1]
    img_path = sys.argv[2]
    client_height = int(sys.argv[3])

    if mode == "hammer":
        run_hammer_match(img_path, client_height)
    elif mode == "lab":
        run_fraction_ocr(img_path, client_height, "lab")
    elif mode == "builders":
        run_fraction_ocr(img_path, client_height, "builders")
    else:
        print(f"ERROR: Unknown mode '{mode}'")
        sys.exit(1)

if __name__ == "__main__":
    main()
