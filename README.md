# gh-pr-image

Upload screenshots with the GitHub CLI, then add them to a pull request description or comment.

```sh
gh extension install facundoPri/gh-pr-image

# Print Markdown for an agent or another command
gh pr-image screenshot.png

# Post it as a PR comment
gh pr-image screenshot.png --comment

# Append it to the PR description
gh pr-image before.png after.png --body

# Download every image added by this extension from the PR
gh pr-image download
```

The current repository and current branch's pull request are detected automatically. Target another PR with `--pr` and `--repo`:

```sh
gh pr-image screenshot.png --pr 42 --repo owner/repo --comment
gh pr-image download --pr 42 --repo owner/repo --dir /tmp/pr-images
```

Run `gh pr-image --help` for all options.

## How it works

`gh-pr-image` uses the authenticated `gh` client and GitHub's documented Git Data API. It writes image blobs to a hidden `refs/gh-pr-images/pr-<number>` ref, so screenshots do not appear in the pull request diff or normal branch list. It then prints the image Markdown or passes it to `gh pr comment` / `gh pr edit`.

The `download` command scans the PR description and comments for images uploaded by `gh-pr-image`, downloads them through the authenticated Contents API, and prints absolute local paths. That gives an AI agent local files it can pass directly to its image-reading tool, including for private repositories.

This deliberately does not copy browser cookies or call GitHub's undocumented `user-attachments` upload endpoint. The token used by `gh` needs Contents write access plus permission to read and update the target pull request. Images inherit the repository's visibility and remain available while their hidden ref exists.

Supported image types: PNG, JPEG, GIF, WebP, SVG, and BMP, up to 25 MiB each.

## Development

```sh
./test.sh
```

The extension is a single Bash script with no package dependencies.
