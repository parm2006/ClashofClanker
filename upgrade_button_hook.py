import sys
import os
import cv2
import numpy as np

def main():
    if len(sys.argv) < 3:
        print("ERROR: Missing arguments. Usage: test_masked_match.py <image_path> <client_height>")
        sys.exit(1)
        
    img_path = sys.argv[1]
    client_height = int(sys.argv[2])
    
    img = cv2.imread(img_path)
    if img is None:
        print(f"ERROR: Could not load image from {img_path}")
        sys.exit(1)
        
    # Load user's hand-cleaned magenta template
    script_dir = os.path.dirname(os.path.abspath(__file__))
    workspace_dir = script_dir
    template_path = os.path.join(workspace_dir, "OCRimages", "cropped images", "hammer_template_trans.png")
    
    template = cv2.imread(template_path)
    if template is None:
        print("ERROR: Could not load hammer_template_trans.png")
        sys.exit(1)
        
    # Scale template to match resolution
    REF_CLIENT_HEIGHT = 1028
    scale = client_height / REF_CLIENT_HEIGHT
    
    if scale != 1.0:
        new_w = int(template.shape[1] * scale)
        new_h = int(template.shape[0] * scale)
        template = cv2.resize(template, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
        
    # Create mask: 0 where color is pure magenta (BGR: [255, 0, 255]), 255 elsewhere
    # Magenta in BGR is [255, 0, 255]
    lower_magenta = np.array([250, 0, 250])
    upper_magenta = np.array([255, 5, 255])
    
    # In range returns 255 for magenta, 0 elsewhere
    magenta_mask = cv2.inRange(template, lower_magenta, upper_magenta)
    
    # Invert it so 255 is the hammer (foreground) and 0 is the magenta background
    mask = cv2.bitwise_not(magenta_mask)
    
    # Run masked template matching
    res = cv2.matchTemplate(img, template, cv2.TM_CCOEFF_NORMED, mask=mask)
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
    
    print(f"Max match score: {max_val:.3f}")
    
    # Draw visualization
    debug_img = img.copy()
    h_t, w_t = template.shape[:2]
    
    # Draw a green box around the best match
    top_left = max_loc
    bottom_right = (top_left[0] + w_t, top_left[1] + h_t)
    cv2.rectangle(debug_img, top_left, bottom_right, (0, 255, 0), 2)
    
    # Draw text with the score
    cv2.putText(debug_img, f"Score: {max_val:.3f}", (top_left[0], top_left[1] - 10), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                
    # Save the debug image to workspace root
    out_path = os.path.join(workspace_dir, "debug_match_result.png")
    cv2.imwrite(out_path, debug_img)
    print(f"Saved visualization to: {out_path}")
    
    if max_val > 0.65:
        match_x = max_loc[0] + w_t // 2
        match_y = max_loc[1] + h_t // 2
        print(f"SUCCESS: {match_x}/{match_y}")
    else:
        print("FAILED")

if __name__ == "__main__":
    main()
