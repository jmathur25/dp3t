PROJECT?=dp3t

test:
	xcodebuild test \
		-project ${PROJECT}.xcodeproj \
		-scheme ${PROJECT} \
		-destination 'platform=iOS Simulator,name=iPhone 11,OS=13.6' | xcpretty

