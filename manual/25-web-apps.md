# Web Apps

You can add your own web apps using _Install > Web App_ in the Omarchy menu (`Super + Space`). It'll ask you for the app name, app URL, and the icon URL, if it can't retrieve it via favicon. You can get great PNG icons for many popular web apps on [Dashboard Icons](https://dashboardicons.com).

They'll then be accessible through the app launcher (`Super + Space`), and use the beautiful frameless web-app window.

> **Oaxaca: works differently.** Because Chromium can be removed in Oaxaca, a web app opens in the default browser when the default browser is Chromium-family, and otherwise in the first installed of Chromium, Chrome, Brave Origin, Brave, Edge and Vivaldi. With none of those installed, a notification points to _Install > Browser_ (the distro's docs/6, choice 18).

If you wish to remove a web app, just go to _Remove > Web App_ in the Omarchy menu.

It's best if you log into all your accounts using a regular browser before using the web app shortcuts. The thin wrapper frame doesn't work well with 1password, so just easier to be logged in directly first.

All the keyboard hotkeys for these web apps can be changed in `~/.config/hypr/bindings.lua`.

When you're in a web app, you can copy the current URL to the clipboard using `Shift + Alt + L`.

By default, Omarchy already ships with an assortment of default apps:

> **Oaxaca: works differently.** Oaxaca ships none of Omarchy's web-app launchers, so none of the apps below is in the app launcher until you add the app with _Install > Web App_. The keybindings below for ChatGPT, Grok, WhatsApp, Google Messages, Google Photos, Google Maps, X and YouTube still work: each binding opens its site as a web app without a launcher.

## HEY

[HEY](https://www.hey.com/) is an email and calendar service that serves as a great alternative to people tired of Gmail, Outlook, or Apple Mail. It's made by [37signals](https://37signals.com/) where Omarchy originated.

You can start HEY Email using `Super + Shift + E`, jump straight to composing a new email using `Super + Shift + Alt + E`, and start HEY Calendar using `Super + Shift + C`.

> **Oaxaca: removed.** HEY's launcher, HEY's handler for email links and the `Super + Shift + E`, `Super + Shift + Alt + E` and `Super + Shift + C` bindings are gone; HEY can still be added with _Install > Web App_. While Thunderbird is installed from _Install > Service > Thunderbird_, `Super + Shift + E` opens Thunderbird instead (the distro's docs/6, choice 27).

## Basecamp

[Basecamp](https://basecamp.com/) is a project management service that helps small teams move faster and make more progress. Instead of patching together a mishmash of Trello, Slack, Asana, Notion, or whatever, you can have it all in one place with Basecamp. It's made by [37signals](https://37signals.com/) where Omarchy originated.

You can start Basecamp using the application launcher (`Super + Space`)

> **Oaxaca: removed.** Oaxaca ships no Basecamp launcher; Basecamp can be added with _Install > Web App_ (the distro's docs/6, choice 27).

## ChatGPT

[ChatGPT](https://chatgpt.com) is the most popular AI chat bot in the world.

You can start ChatGPT using `Super + Shift + A`.

## Grok

[Grok](https://grok.com) is xAI's chat bot.

You can start Grok using `Super + Shift + Alt + A`.

## WhatsApp

[WhatsApp](https://www.whatsapp.com/) is one of the most popular messaging services in the world, and the web version is a great option for Linux.

You can start WhatsApp using `Super + Shift + Alt + G`.

## Google apps

Google Messages, Google Photos, Google Maps, and Google Contacts are all included as web apps too.

You can start Google Messages using `Super + Shift + Ctrl + G`, Google Photos using `Super + Shift + P`, and Google Maps using `Super + Shift + S`. Google Contacts is available through the app launcher (`Super + Space`).

> **Oaxaca: removed.** Oaxaca ships no Google Contacts launcher; Google Contacts can be added with _Install > Web App_.

## X

X is where news break.

You can start X using `Super + Shift + X` and go straight to writing a new post with `Super + Shift + Alt + X`.

## YouTube

[YouTube](https://youtube.com/) is the most popular video platform in the world.

You can start YouTube using `Super + Shift + Y`.

## Zoom

[Zoom](https://zoom.us/) is the most popular video chat system used in the US. Great connections across the world. And 40-minute meetings can be held without a paying account. Omarchy wraps Zoom's web client, and zoom meeting links will open straight into it.

You start Zoom using the application launcher (`Super + Space`).

> **Oaxaca: removed.** Oaxaca ships no Zoom launcher, so Zoom is not in the app launcher and no application is registered to open Zoom meeting links. Zoom's web client can be added with _Install > Web App_.

## Discord

[Discord](https://discord.com/) is where most gaming and open source communities hang out, including [Omarchy's own](https://discord.gg/tXFUdasqhY).

You start Discord using the application launcher (`Super + Space`).

> **Oaxaca: removed.** Oaxaca ships no Discord launcher; Discord can be added with _Install > Web App_.
