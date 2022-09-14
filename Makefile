generate_documentation:
	swift package \
		--allow-writing-to-directory ./docs \
		generate-documentation \
		--target SwiftKeys \
		--disable-indexing \
		--transform-for-static-hosting \
		--output-path ./docs
