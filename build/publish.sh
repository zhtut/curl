name="curl"
version=$(grep VERSION= ${name}/${name}-build.sh)
version=${version#*${name}-}
version=${version%\"*}
echo "查找到${name}的版本号：${version}"

cd ..
git add .
git commit -m "feat: add version '$version'"
git tag -a $version -m "feat: add version '$version'"
git push --tags
pod trunk push *.podspec --verbose --use-libraries --allow-warnings --skip-import-validation --skip-tests
