# Flutter Releases Info

Useful info about Flutter PRs and the releases they fall into.

See it live at [https://justinmc.github.io/flutter_releases/](https://justinmc.github.io/flutter_releases/).

## Publishing

 1. `flutter build web`
 2. `rm -rf docs`
 3. `cp -r build/web/ docs`
 4. Modify docs/index.html `<base href="/">` to `<base href="/flutter_releases/">`
 5. Commit and push to main.
