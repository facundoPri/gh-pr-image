---
name: gh-pr-image
description: Upload, place, update, and download UI screenshots in GitHub pull request descriptions and comments with the gh-pr-image GitHub CLI extension. Use when an agent needs to publish a local PNG, JPEG, GIF, WebP, SVG, or BMP as PR evidence, insert it at a stable Markdown marker, automate screenshot evidence in CI, or download PR images for visual inspection.
---

# GitHub PR Images

Use `gh-pr-image` for image storage and use native `gh pr` commands for general PR and comment editing.

## Set up

1. Require an authenticated GitHub CLI session: `gh auth status`.
2. Install the extension if `gh pr-image --help` is unavailable:

   ```sh
   gh extension install facundoPri/gh-pr-image
   ```

3. Resolve the target repository and PR before uploading. Pass `--repo OWNER/REPO --pr NUMBER` when the current checkout is not unambiguous.

## Choose the operation

| Intent | Command |
| --- | --- |
| Get image Markdown for a PR being created or fully composed | `gh pr-image upload IMAGE` |
| Add an image-only comment | `gh pr-image comment create IMAGE` |
| Append images to the PR description | `gh pr-image body append IMAGE...` |
| Fill or refresh a marked slot in the PR description | `gh pr-image body replace IMAGE --marker MARKER` |
| Fill or refresh a marked slot in an existing comment | `gh pr-image comment edit COMMENT IMAGE --marker MARKER` |
| Download extension-managed PR images for inspection | `gh pr-image download` |

Prefer `upload` when composing substantial text. Capture its stdout Markdown, insert it at the desired position, then use the native command that already owns the content: `gh pr create`, `gh pr edit`, `gh pr comment`, or `gh api` for a specific existing comment.

## Use exact slots

Place one unique HTML comment where the screenshot belongs:

```md
## Checkout

<!-- gh-pr-image:checkout -->

## Test plan
```

Fill it with:

```sh
gh pr-image body replace checkout.png \
  --marker '<!-- gh-pr-image:checkout -->' \
  --pr 42 --repo owner/repo \
  --alt 'Updated checkout screen'
```

Keep the two invisible markers that the command writes around the image. Later runs replace the content between them, making the slot safe for repeated CI jobs. The command rejects missing markers, ambiguous marker counts, and comments belonging to another PR before uploading.

For an existing conversation comment, pass its database ID or quoted `#issuecomment-...` URL:

```sh
gh pr-image comment edit \
  'https://github.com/owner/repo/pull/42#issuecomment-123456' \
  checkout.png --marker '<!-- gh-pr-image:checkout -->' \
  --pr 42 --repo owner/repo
```

## Run in CI

Set `GH_TOKEN`, `GH_REPO`, and `GH_PR_IMAGE_PR`. Grant only the permissions the chosen operation needs:

- Grant `contents: write` to store images.
- Grant `pull-requests: write` to update a PR description.
- Grant `issues: write` to create or update conversation comments.

Use the repository `GITHUB_TOKEN` for same-repository pull requests. Expect fork and Dependabot pull requests to have read-only tokens. Do not solve that restriction by checking out untrusted code under `pull_request_target`; use an approved trusted follow-up workflow instead.

## Read images

Download every image managed by the extension and pass the printed absolute paths to the available image-reading tool:

```sh
gh pr-image download --pr 42 --repo owner/repo --dir /tmp/pr-images
```

Use `--force` only when replacing existing local downloads is intentional.

## Verify

Inspect the final PR body or comment, confirm the descriptive alt text and surrounding content, and return the resulting PR or comment URL. Treat a successful upload without correct rendered placement as incomplete.
