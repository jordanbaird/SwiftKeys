generate_documentation:
	swift package \
		--allow-writing-to-directory ./docs \
		generate-documentation \
		--output-path ./docs
