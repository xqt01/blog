hugo # 生成public文件夹
cd public
git init
git remote set-url origin https://github.com/xqt01/xqt01.github.io.git
git remote add origin https://github.com/xqt01/xqt01.github.io.git
git add .
git commit -m 'init'
git push -f --set-upstream origin master
cd ..
rm -rf public
