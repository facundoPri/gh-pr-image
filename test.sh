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
    if [[ " $* " == *" --json body "* ]]; then printf 'Existing body\n'; else printf '7\n'; fi
    ;;
  "pr comment") cat >"$GH_PR_IMAGE_TEST_COMMENT"; printf 'https://github.com/facundoPri/demo/pull/7#issuecomment-1\n' ;;
  "pr edit") cat >"$GH_PR_IMAGE_TEST_BODY"; printf 'https://github.com/facundoPri/demo/pull/7\n' ;;
  "api repos/facundoPri/demo/git/ref/gh-pr-images/pr-7") printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1 ;;
  "api repos/facundoPri/demo") printf 'main\n' ;;
  "api repos/facundoPri/demo/git/ref/heads/main") printf '1111111111111111111111111111111111111111\n' ;;
  "api repos/facundoPri/demo/git/commits/1111111111111111111111111111111111111111") printf '2222222222222222222222222222222222222222\n' ;;
  "api --method")
    input=$(cat)
    case " $* " in
      *"/git/blobs "*) printf '3333333333333333333333333333333333333333\n' ;;
      *"/git/trees "*) printf '4444444444444444444444444444444444444444\n' ;;
      *"/git/commits "*) printf '5555555555555555555555555555555555555555\n' ;;
      *"/git/refs "*) : ;;
      *) printf 'unexpected API call: %s\n' "$*" >&2; exit 1 ;;
    esac
    ;;
  *) printf 'unexpected gh call: %s\n' "$*" >&2; exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/gh"

export PATH="$tmp/bin:$PATH"
export GH_PR_IMAGE_TEST_LOG="$tmp/gh.log"
export GH_PR_IMAGE_TEST_COMMENT="$tmp/comment.md"
export GH_PR_IMAGE_TEST_BODY="$tmp/body.md"
printf 'fake png' >"$tmp/screen shot.png"

markdown=$("$root/gh-pr-image" "$tmp/screen shot.png" --pr 7)
[[ $markdown == '!['*'](https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/gh-pr-images/pr-7/'*'?raw=true)' ]]

"$root/gh-pr-image" "$tmp/screen shot.png" --pr 7 --comment >/dev/null
grep -Fq 'https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/' "$tmp/comment.md"

"$root/gh-pr-image" "$tmp/screen shot.png" --pr 7 --body >/dev/null
grep -Fq 'Existing body' "$tmp/body.md"
grep -Fq 'https://github.com/facundoPri/demo/blob/5555555555555555555555555555555555555555/' "$tmp/body.md"

printf 'ok\n'
