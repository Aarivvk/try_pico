cc_library(
    name = "fmt",
    hdrs = glob([
        "include/fmt/*.h",
        "src/format.cc",  # Required for header-only mode
    ]),
    includes = ["include"],
    defines = [
        "FMT_HEADER_ONLY=1",  # Enable header-only mode
        "FMT_EXCEPTIONS=0",    # Disable exceptions
    ],
    visibility = ["//visibility:public"],
)
