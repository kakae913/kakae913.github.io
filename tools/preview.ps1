$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$volumeMount = "${projectRoot}:/workspace"

docker run --rm -it `
  -p 4000:4000 `
  -p 35729:35729 `
  -v $volumeMount `
  -w /workspace `
  mcr.microsoft.com/devcontainers/jekyll:2-bullseye `
  bash -lc "bundle install && bundle exec jekyll serve --host 0.0.0.0 --force_polling --livereload"
