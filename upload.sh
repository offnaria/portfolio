#!/usr/bin/env bash

echo "addするファイルたちを取得"
git add -A
read -p "コミットのコメント: " comment
git commit -m "${comment}"
git push -u origin main