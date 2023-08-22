clean:
	xcrun swift package clean

build:
	xcrun swift build

sign:
	codesign --sign - --entitlements Resources/curie.entitlements --force .build/debug/curie

format:
	swiftformat .

autocorrect:s
	swiftlint autocorrect --quiet

lint:
	swiftlint version
	swiftformat --version
	swiftlint --strict --quiet
	swiftformat . --lint

install_tools:
	./Scripts/brew.sh
