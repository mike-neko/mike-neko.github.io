#!/bin/bash
echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
hugo -t Hyde-X
cd public
git add -A
msg="hugo rebuilding site `date +%Y%m%d_%H-%M-%S`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"
git push origin master
