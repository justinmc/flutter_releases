# Flutter Releases Info

Useful info about Flutter PRs and the releases they fall into.

## Publishing

 1. `flutter build web`
 2. rm -rf docs
 3. cp -r build/web/ docs
 4. Modify docs/index.html `<base href="/">` to `<base href="/flutter_releases/">`
 5. Commit and push to main.
