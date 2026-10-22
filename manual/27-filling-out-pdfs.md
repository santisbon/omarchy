# Filling out PDFs

Omarchy ships with a nice, basic PDF viewer called Document Viewer. This is the program that'll open any PDFs you just double click on.

> **Oaxaca: works differently.** Oaxaca's PDF viewer is Papers, GNOME's successor to Document Viewer (Evince), because Ubuntu 26.10 carries Evince only as an alpha (the distro's docs/6, choice 28).

But you can only use Document Viewer to fill out PDFs that have been setup as forms. If you need to fill out PDFs that haven't, or you need to sign a PDF, you'll have to right-click the file, select _Open With..._, and pick Xournal++.

Xournal++ is not part of the base install: install it from _Install > Productivity > Xournal++_ in the Omarchy menu (`Super + Space`), which installs the Xournal++ team's Flatpak from Flathub.

> **Oaxaca: works differently.** The paragraph above is Oaxaca's. Omarchy preinstalls Xournal++ (`xournalpp` in Omarchy's base package list) with a setting file that forces dark mode (`config/xournalpp/settings.xml`). Oaxaca installs the Xournal++ team's Flatpak on request, without that setting file, and _Remove > Productivity > Xournal++_ removes Xournal++ again (the distro's docs/6, choice 84).

Xournal++ will let you write anywhere on a PDF using the T tool. If you need to sign a document, you'll need an image of your signature, and you can use the Image tool to insert this signature and resize it.

When you're done filling out the PDF, use _File > Export as PDF_ to save the final version.
