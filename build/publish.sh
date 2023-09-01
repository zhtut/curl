name="curl"
version=$(grep VERSION= ${name}/${name}-build.sh)
version=${version#*${name}-}
version=${version%\"*}
echo "查找到${name}的版本号：${version}"

cd ..
version_str=$(grep s.version *.podspec | grep -v to_s)
new_version_str="  s.version          = '$version'"
sed -i '' "s/$version_str/$new_version_str/" *.podspec
git add .
git commit -m "feat: add version '$version'"
git tag -a $version -m "feat: add version '$version'"
git push --all
pod trunk push *.podspec --verbose --use-libraries --allow-warnings --skip-import-validation --skip-tests
