# Text Extraction & Dictation

### Text Extraction

Hit `Super + Ctrl + PrtScr` to select a region on the screen for text extraction. The tesseract open source OCR model will then quickly convert that selection into text and place it on the clipboard. Then you just hit `Super + V` to paste.

This is very helpful for grabbing addresses out of image footers or phone numbers embedded in website headlines.

> **Oaxaca: works differently.** The OCR engine comes from Ubuntu's archive as the `tesseract-ocr` and `tesseract-ocr-eng` packages, which Oaxaca preinstalls in place of Arch's `tesseract` and `tesseract-data-eng`.

 ![text-extraction](images/text-extraction.webp)

### Dictation

Omarchy offers AI dictation via [Voxtype](https://voxtype.io/). You install it via _Install > AI > Dictation_ through the Omarchy menu. By default, it'll load a base English model that takes up 150MB. But you can tweak which model you'd like to use by running `voxtype setup model` in the terminal. And you can tweak all the settings via `~/.config/voxtype/config.toml`.

> **Oaxaca: works differently.** _Install > AI > Dictation_ installs the `voxtype` package from Oaxaca's own apt repository, which repackages Voxtype's release package without its ONNX GPU builds for CUDA and MIGraphX, instead of `voxtype-bin` from the AUR. GPU mode is not switched on with `voxtype setup gpu --enable`: the installer writes a drop-in for the user's voxtype service (`~/.config/systemd/user/voxtype.service.d/`) that picks the discrete GPU when its Vulkan driver is installed, else the integrated one, and falls back to the CPU with no Vulkan driver; with two GPUs, Voxtype's `gpu_isolation` lets the discrete GPU sleep between dictations.

Once installed, you dictate by holding down `F9` or by toggling with `Super + Ctrl + X`, and the dictated text will appear in the focused input area.

> **Oaxaca: works differently.** Besides Omarchy's notification, the Dictation installer prints the two dictation keys in its terminal window, where they stay until the done screen's key press.
