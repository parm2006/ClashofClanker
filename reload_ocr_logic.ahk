#Requires AutoHotkey v2.0

NormalizeOCRFromFileWord(word, scale) {
    if !IsObject(word)
        throw TypeError("OCR word must be an object.")
    if (scale <= 0)
        throw ValueError("OCR scale must be positive.")
    return {
        text: word.Text,
        x: word.x / scale,
        y: word.y / scale,
        w: word.w / scale,
        h: word.h / scale
    }
}
