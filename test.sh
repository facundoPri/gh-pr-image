#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat >"$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$GH_PR_IMAGE_TEST_LOG"

case "$1 $2" in
  "repo view") printf 'facundoPri/demo\n' ;;
  "pr view")
    if [[ " $* " == *" --json body,comments "* ]]; then
      printf '%s\n' '![screen](https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/gh-pr-images/pr-7/123-456-1-screen_shot.png?raw=true)'
    elif [[ " $* " == *" --json body "* ]]; then
      printf 'Existing body\n\n<!-- screenshot -->\n\nEnd\n'
    else
      printf '7\n'
    fi
    ;;
  "pr comment") cat >"$GH_PR_IMAGE_TEST_COMMENT"; printf 'https://github.com/facundoPri/demo/pull/7#issuecomment-1\n' ;;
  "pr edit") cat >"$GH_PR_IMAGE_TEST_BODY"; printf 'https://github.com/facundoPri/demo/pull/7\n' ;;
  "api repos/facundoPri/demo/git/ref/gh-pr-images/pr-7") printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1 ;;
  "api repos/facundoPri/demo") printf 'main\n' ;;
  "api repos/facundoPri/demo/git/ref/heads/main") printf '1111111111111111111111111111111111111111\n' ;;
  "api repos/facundoPri/demo/git/commits/1111111111111111111111111111111111111111") printf '2222222222222222222222222222222222222222\n' ;;
  "api repos/facundoPri/demo/issues/comments/99")
    if [[ " $* " == *" --jq .issue_url "* ]]; then
      printf 'https://api.github.com/repos/facundoPri/demo/issues/7\n'
    else
      printf 'Before\n\n<!-- screenshot -->\n\nAfter\n'
    fi
    ;;
  "api --method")
    input=$(cat)
    case " $* " in
      *"/git/blobs "*) printf '3333333333333333333333333333333333333333\n' ;;
      *"/git/trees "*) printf '4444444444444444444444444444444444444444\n' ;;
      *"/git/commits "*) printf '5555555555555555555555555555555555555555\n' ;;
      *"/git/refs "*) : ;;
      *"PATCH repos/facundoPri/demo/issues/comments/99 "*)
        for argument in "$@"; do
          [[ $argument == body=* ]] && printf '%s' "${argument#body=}" >"$GH_PR_IMAGE_TEST_EDIT_COMMENT"
        done
        printf 'https://github.com/facundoPri/demo/pull/7#issuecomment-99\n'
        ;;
      *) printf 'unexpected API call: %s\n' "$*" >&2; exit 1 ;;
    esac
    ;;
  "api -H") printf 'fake png' ;;
  *) printf 'unexpected gh call: %s\n' "$*" >&2; exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/gh"

export PATH="$tmp/bin:$PATH"
export GH_PR_IMAGE_TEST_LOG="$tmp/gh.log"
export GH_PR_IMAGE_TEST_COMMENT="$tmp/comment.md"
export GH_PR_IMAGE_TEST_BODY="$tmp/body.md"
export GH_PR_IMAGE_TEST_EDIT_COMMENT="$tmp/edit-comment.md"
printf 'fake png' >"$tmp/screen shot.png"

markdown=$("$root/gh-pr-image" "$tmp/screen shot.png" --pr 7)
[[ $markdown == '!['*'](https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/gh-pr-images/pr-7/'*'?raw=true)' ]]

"$root/gh-pr-image" "$tmp/screen shot.png" --pr 7 --comment >/dev/null
grep -Fq 'https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/' "$tmp/comment.md"

"$root/gh-pr-image" "$tmp/screen shot.png" --pr 7 --body >/dev/null
grep -Fq 'Existing body' "$tmp/body.md"
grep -Fq 'https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/' "$tmp/body.md"

"$root/gh-pr-image" "$tmp/screen shot.png" --pr 7 --body --replace '<!-- screenshot -->' >/dev/null
grep -Fq 'Existing body' "$tmp/body.md"
grep -Fq 'End' "$tmp/body.md"
grep -Fq 'https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/' "$tmp/body.md"
! grep -Fq '<!-- screenshot -->' "$tmp/body.md"

"$root/gh-pr-image" "$tmp/screen shot.png" --pr 7 \
  --edit-comment 'https://github.com/facundoPri/demo/pull/7#issuecomment-99' \
  --replace '<!-- screenshot -->' >/dev/null
grep -Fq 'Before' "$tmp/edit-comment.md"
grep -Fq 'After' "$tmp/edit-comment.md"
grep -Fq 'https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/' "$tmp/edit-comment.md"
! grep -Fq '<!-- screenshot -->' "$tmp/edit-comment.md"

downloaded=$("$root/gh-pr-image" download --pr 7 --dir "$tmp/downloads")
[[ $downloaded == "$tmp/downloads/123-456-1-screen_shot.png" ]]
[[ $(<"$downloaded") == 'fake png' ]]
grep -Fq 'repos/facundoPri/demo/contents/gh-pr-images/pr-7/123-456-1-screen_shot.png?ref=5555555555555555555555555555555555555555' "$tmp/gh.log"
grep -Fq 'Accept: application/vnd.github.raw' "$tmp/gh.log"

printf 'ok\n'
