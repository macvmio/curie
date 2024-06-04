clean:
	xcrun swift package clean

env: 
	xcrun sw_vers
	xcrun xcode-select -p
	xcrun xcodebuild -version

build: env
	xcrun swift build

test:
	xcrun swift test

sign:
	codesign --sign - --entitlements Resources/curie.entitlements --force .build/debug/curie

format:
	swiftformat .

generate:
    swift build -c release --product protoc-gen-swift
	swift build -c release --product protoc-gen-grpc-swift

autocorrect:
	swiftlint autocorrect --quiet

lint:
	swiftlint version
	swiftformat --version
	swiftlint --strict --quiet
	swiftformat . --lint

install_tools:
	./Scripts/brew.sh
