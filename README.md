# gh-pr-image

Upload local screenshots with the GitHub CLI, place them exactly in pull request descriptions or comments, and download them again for AI inspection.

`gh-pr-image` is designed for agents and CI jobs. It uses the authenticated `gh` client, works with private repositories, and does not require browser cookies or GitHub's undocumented attachment-upload endpoint.

## Install

```sh
gh extension install facundoPri/gh-pr-image
```

Upgrade later with `gh extension upgrade pr-image`.

## Commands

| Intent | Command |
| --- | --- |
| Upload and print image Markdown | `gh pr-image upload IMAGE...` |
| Add an image-only PR comment | `gh pr-image comment create IMAGE...` |
| Append images to the PR description | `gh pr-image body append IMAGE...` |
| Fill or refresh a description slot | `gh pr-image body replace IMAGE... --marker MARKER` |
| Fill or refresh a slot in an existing comment | `gh pr-image comment edit COMMENT IMAGE... --marker MARKER` |
| Download extension-managed images | `gh pr-image download` |

The current repository and current branch's PR are detected automatically. Use explicit targets in agents and automation:

```sh
gh pr-image comment create screenshot.png \
  --pr 42 --repo owner/repo \
  --alt 'Checkout confirmation screen'
```

`COMMENT` may be a comment database ID or a quoted GitHub URL ending in `#issuecomment-<id>`.

The original flag API remains compatible, but new integrations should use the commands above.

## Compose with native GitHub commands

For a substantial PR description or comment, keep GitHub's native command responsible for editing the content. Use `upload` to obtain ordinary Markdown, insert it anywhere in your document, and then call `gh pr create`, `gh pr edit`, or `gh pr comment` as usual:

```sh
gh pr-image upload screenshot.png --pr 42 --repo owner/repo
```

Output:

```md
![screenshot.png](https://github.com/owner/repo/blob/<sha>/gh-pr-images/pr-42/<file>?raw=true)
```

This is the most flexible interface for agents: an image behaves like any other Markdown link after upload.

## Place and refresh images exactly

Put one unique HTML marker wherever the image belongs:

```md
## Checkout

The updated payment flow:

<!-- gh-pr-image:checkout -->

## Test plan
```

Fill that slot:

```sh
gh pr-image body replace checkout.png \
  --marker '<!-- gh-pr-image:checkout -->' \
  --pr 42 --repo owner/repo \
  --alt 'Updated checkout flow'
```

The first run leaves an invisible pair of markers around the image. Later runs update only the content between them, so the same command is safe to rerun in CI. Missing markers, more than two matching markers, and comments from another PR are rejected before an image is uploaded.

Edit an existing conversation comment the same way:

```sh
gh pr-image comment edit \
  'https://github.com/owner/repo/pull/42#issuecomment-123456' \
  checkout.png \
  --marker '<!-- gh-pr-image:checkout -->' \
  --pr 42 --repo owner/repo
```

## CI/CD

The CLI is non-interactive when these values are set:

| Setting | Purpose |
| --- | --- |
| `GH_TOKEN` or `GITHUB_TOKEN` | Authentication used by `gh` |
| `GH_REPO` | Default `OWNER/REPO` |
| `GH_PR_IMAGE_PR` | Default PR number |
| `GITHUB_REPOSITORY` | Automatic repository fallback in GitHub Actions |
| `GITHUB_REF` | Automatically resolves `refs/pull/<number>/merge` events |

GitHub Actions needs only the permissions required by the operation:

```yaml
permissions:
  contents: write       # Store image blobs on the hidden ref
  pull-requests: write  # Update the PR description
  issues: write         # Create or edit conversation comments
```

Set `GH_TOKEN: ${{ github.token }}` in the step environment. A complete same-repository workflow is available at [`examples/github-actions/pr-screenshot.yml`](examples/github-actions/pr-screenshot.yml).

Pull requests from forks and Dependabot normally receive a read-only `GITHUB_TOKEN`, so they cannot upload images. Do not work around this by checking out untrusted PR code in a privileged `pull_request_target` job. Use an approved trusted follow-up workflow if fork support becomes necessary.

## Agent skill

This repository publishes an Agent Skill that teaches coding agents the operation-selection, placement, CI, and verification workflow:

```sh
gh skill install facundoPri/gh-pr-image gh-pr-image --agent codex --scope user
```

The source lives in [`skills/gh-pr-image`](skills/gh-pr-image). `gh skill` is currently a preview GitHub CLI feature.

## Download images for AI inspection

Download every image added by this extension from a PR:

```sh
gh pr-image download --pr 42 --repo owner/repo --dir /tmp/pr-images
```

The command prints absolute local paths, ready to pass to an image-reading tool. Add `--force` only when existing downloads should be replaced.

## How it works

The extension uses GitHub's documented Git Data API to write image blobs to `refs/gh-pr-images/pr-<number>`. The images do not appear in the PR diff or normal branch list. Their Markdown URLs point to immutable commits on that ref.

Images inherit the repository's visibility and remain available while the hidden ref exists. The token needs Contents write access to upload, plus permission to update the chosen PR surface.

Supported formats: PNG, JPEG, GIF, WebP, SVG, and BMP, up to 25 MiB each.

## Development

The extension is one Bash script with no runtime package dependencies.

```sh
./test.sh
gh skill publish --dry-run
```
